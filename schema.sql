-- ═══════════════════════════════════════════════════════
--  JagX Websites – Supabase Database Schema
--  Run this entire file in: Supabase Dashboard → SQL Editor
-- ═══════════════════════════════════════════════════════

-- ── EXTENSIONS ────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ── PROFILES ──────────────────────────────────────────
create table if not exists profiles (
  id                  uuid primary key references auth.users(id) on delete cascade,
  full_name           text not null,
  email               text not null unique,
  phone               text,
  role                text not null default 'buyer' check (role in ('buyer','seller','browser','admin')),
  avatar_url          text,
  is_verified_seller  boolean not null default false,
  seller_expires_at   timestamptz,
  created_at          timestamptz not null default now()
);

-- ── LISTINGS ──────────────────────────────────────────
create table if not exists listings (
  id              uuid primary key default uuid_generate_v4(),
  seller_id       uuid not null references profiles(id) on delete cascade,
  title           text not null,
  description     text not null,
  price           numeric(12,2) not null,
  category        text not null,
  tech_stack      text not null default '',
  demo_url        text,
  status          text not null default 'available' check (status in ('available','sold','pending')),
  screenshots     text[] not null default '{}',
  features        text[] not null default '{}',
  views           integer not null default 0,
  rating          numeric(3,1) not null default 0,
  review_status   text not null default 'pending' check (review_status in ('pending','approved','rejected')),
  created_at      timestamptz not null default now()
);

-- ── CHATS ─────────────────────────────────────────────
create table if not exists chats (
  id               uuid primary key default uuid_generate_v4(),
  listing_id       uuid not null references listings(id) on delete cascade,
  buyer_id         uuid not null references profiles(id) on delete cascade,
  seller_id        uuid not null references profiles(id) on delete cascade,
  last_message     text,
  last_message_at  timestamptz,
  created_at       timestamptz not null default now(),
  unique(listing_id, buyer_id)
);

-- ── MESSAGES ──────────────────────────────────────────
create table if not exists messages (
  id          uuid primary key default uuid_generate_v4(),
  chat_id     uuid not null references chats(id) on delete cascade,
  sender_id   uuid not null references profiles(id) on delete cascade,
  content     text not null,
  created_at  timestamptz not null default now()
);

-- ── PAYMENT PROOFS ────────────────────────────────────
create table if not exists payment_proofs (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references profiles(id) on delete cascade,
  receipt_url text not null,
  bank        text not null,
  amount      numeric(12,2) not null default 2000,
  status      text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at  timestamptz not null default now()
);

-- ══════════════════════════════════════════════════════
--  ROW LEVEL SECURITY (RLS) – CRITICAL FOR PRODUCTION
-- ══════════════════════════════════════════════════════

alter table profiles       enable row level security;
alter table listings       enable row level security;
alter table chats          enable row level security;
alter table messages       enable row level security;
alter table payment_proofs enable row level security;

-- ── PROFILES ──────────────────────────────────────────
create policy "Public can read profiles"
  on profiles for select using (true);

create policy "Users can update own profile"
  on profiles for update using (auth.uid() = id);

create policy "Users can insert own profile"
  on profiles for insert with check (auth.uid() = id);

-- ── LISTINGS ──────────────────────────────────────────
create policy "Everyone can read approved listings"
  on listings for select using (review_status = 'approved');

create policy "Sellers can insert listings"
  on listings for insert
  with check (
    auth.uid() = seller_id
    and exists (
      select 1 from profiles
      where id = auth.uid()
        and role = 'seller'
        and is_verified_seller = true
    )
  );

create policy "Sellers can update own listings"
  on listings for update
  using (auth.uid() = seller_id);

-- Admin can do everything (by email)
create policy "Admin full access to listings"
  on listings for all
  using (
    exists (
      select 1 from profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- ── CHATS ─────────────────────────────────────────────
create policy "Chat participants can read"
  on chats for select
  using (auth.uid() = buyer_id or auth.uid() = seller_id);

create policy "Buyers can create chats"
  on chats for insert
  with check (auth.uid() = buyer_id);

create policy "Participants can update chat"
  on chats for update
  using (auth.uid() = buyer_id or auth.uid() = seller_id);

-- ── MESSAGES ──────────────────────────────────────────
create policy "Chat participants can read messages"
  on messages for select
  using (
    exists (
      select 1 from chats
      where chats.id = messages.chat_id
        and (chats.buyer_id = auth.uid() or chats.seller_id = auth.uid())
    )
  );

create policy "Chat participants can send messages"
  on messages for insert
  with check (
    auth.uid() = sender_id
    and exists (
      select 1 from chats
      where chats.id = chat_id
        and (chats.buyer_id = auth.uid() or chats.seller_id = auth.uid())
    )
  );

-- ── PAYMENT PROOFS ────────────────────────────────────
create policy "Users can upload own payment proofs"
  on payment_proofs for insert
  with check (auth.uid() = user_id);

create policy "Users can view own payment proofs"
  on payment_proofs for select
  using (auth.uid() = user_id);

create policy "Admin can view all payment proofs"
  on payment_proofs for all
  using (
    exists (
      select 1 from profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- ══════════════════════════════════════════════════════
--  REALTIME (enable on tables you want live updates)
-- ══════════════════════════════════════════════════════
alter publication supabase_realtime add table messages;
alter publication supabase_realtime add table chats;
alter publication supabase_realtime add table listings;

-- ══════════════════════════════════════════════════════
--  AUTO-CREATE PROFILE ON SIGNUP
-- ══════════════════════════════════════════════════════
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, phone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.email,
    new.raw_user_meta_data->>'phone',
    coalesce(new.raw_user_meta_data->>'role', 'buyer')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ══════════════════════════════════════════════════════
--  AUTO-UPDATE chat.last_message ON NEW MESSAGE
-- ══════════════════════════════════════════════════════
create or replace function public.update_chat_last_message()
returns trigger language plpgsql security definer
as $$
begin
  update chats
  set last_message    = new.content,
      last_message_at = new.created_at
  where id = new.chat_id;
  return new;
end;
$$;

drop trigger if exists on_new_message on messages;
create trigger on_new_message
  after insert on messages
  for each row execute procedure public.update_chat_last_message();

-- ══════════════════════════════════════════════════════
--  SEED DATA (optional demo listings)
-- ══════════════════════════════════════════════════════
-- (Run after creating an admin account to assign seller_id)
