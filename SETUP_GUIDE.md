# 🚀 JagX Websites — Complete Setup Guide
*Developed by JRILISECE & JagX*

---

## ⚡ QUICK START (5 minutes)

```bash
# 1. Install dependencies
npm install

# 2. Set up environment variables
cp .env.local .env.local  # already created — edit values

# 3. Run Supabase schema
# Go to: https://supabase.com/dashboard/project/zigolwmewrjvmlrekrbw/sql
# Paste & run: lib/supabase/schema.sql

# 4. Run dev server
npm run dev
# → Open http://localhost:3000
```

---

## 🔧 SUPABASE MCP SETUP (for Claude Code)

```bash
# Step 1 — Add MCP server
claude mcp add --scope project --transport http supabase \
  "https://mcp.supabase.com/mcp?project_ref=zigolwmewrjvmlrekrbw"

# Step 2 — Authenticate (in terminal, NOT IDE)
claude /mcp
# Select: supabase → Authenticate

# Step 3 — Install Agent Skills (optional but recommended)
npx skills add supabase/agent-skills
```

---

## 📦 PROJECT STRUCTURE

```
jagx-websites/
├── app/
│   ├── layout.tsx              ← Root layout + fonts + SEO
│   ├── page.tsx                ← Home page (SSR)
│   ├── globals.css             ← All global styles
│   ├── marketplace/page.tsx   ← Real-time listings
│   ├── chat/page.tsx          ← Real-time Supabase chat
│   ├── auth/
│   │   ├── login/page.tsx
│   │   ├── signup/page.tsx
│   │   ├── otp/page.tsx
│   │   └── forgot/page.tsx
│   ├── post-website/page.tsx  ← Seller listing form
│   ├── seller/pay/page.tsx    ← ₦2,000 payment page
│   ├── admin/page.tsx         ← Admin dashboard
│   ├── about/page.tsx
│   ├── contact/page.tsx
│   └── api/
│       ├── send-otp/route.ts  ← Email OTP via Resend
│       ├── contact/route.ts   ← Contact form emails
│       └── payment/route.ts   ← Payment proof + admin alert
│
├── components/
│   ├── layout/
│   │   ├── Navbar.tsx         ← Desktop nav + mobile sidebar
│   │   └── MobileSidebar.tsx  ← Animated slide-in sidebar
│   ├── sections/
│   │   ├── Hero.tsx           ← Animated hero with mockups
│   │   ├── Stats.tsx          ← Animated counters
│   │   ├── Features.tsx
│   │   ├── FeaturedListings.tsx
│   │   └── Testimonials.tsx
│   └── ui/
│       ├── ListingCard.tsx    ← Animated listing card
│       ├── Button.tsx
│       ├── CounterNum.tsx     ← Scroll-triggered counter
│       └── Ticker.tsx
│
├── hooks/
│   ├── useAuth.ts             ← Supabase session hook
│   └── useRealtimeChat.ts     ← Real-time chat hook
│
├── lib/
│   └── supabase/
│       ├── client.ts          ← Browser Supabase client
│       ├── server.ts          ← Server Supabase client
│       └── schema.sql         ← ← RUN THIS FIRST ← ←
│
├── types/
│   └── database.ts            ← TypeScript types for all tables
│
├── .env.local                 ← Your credentials (DO NOT COMMIT)
├── BUYER_LEADS.md             ← Who to sell to + message templates
└── tailwind.config.ts
```

---

## 🗄️ SUPABASE SETUP (CRITICAL)

### 1. Run the Schema
1. Go to: https://supabase.com/dashboard/project/zigolwmewrjvmlrekrbw/sql
2. Click **New Query**
3. Paste the entire contents of `lib/supabase/schema.sql`
4. Click **Run**

### 2. Enable Storage (for screenshots + receipts)
```
Supabase Dashboard → Storage → Create buckets:
- "screenshots" (public)
- "receipts" (private, only authenticated)
```

### 3. Enable Email Auth
```
Supabase Dashboard → Authentication → Providers → Email
✅ Enable Email Confirmations
✅ Confirm email template (customize with your branding)
```

### 4. Set Your Admin User
After creating your account, run in SQL Editor:
```sql
UPDATE profiles
SET role = 'admin'
WHERE email = 'gbadamositajudeeneh@gmail.com';
```

---

## 📧 EMAIL SETUP WITH RESEND

1. Sign up at **resend.com** (free: 3,000 emails/month)
2. Add your domain (jagxwebsites.ng) or use their sandbox
3. Create an API key
4. Add to `.env.local`:
```
RESEND_API_KEY=re_your_actual_key_here
```

---

## 🚀 DEPLOYMENT TO VERCEL (free)

```bash
# 1. Push to GitHub
git init && git add . && git commit -m "Initial JagX Websites"
git remote add origin https://github.com/youruser/jagx-websites.git
git push -u origin main

# 2. Deploy on Vercel
# → Go to vercel.com → New Project → Import from GitHub
# → Add ALL environment variables from .env.local
# → Deploy!

# 3. Add custom domain
# → Vercel Dashboard → Domains → jagxwebsites.ng
# → Update nameservers with your domain registrar
```

---

## 🔐 SECURITY CHECKLIST

- [ ] RLS enabled on all Supabase tables (done in schema.sql)
- [ ] `.env.local` added to `.gitignore` (never commit secrets)
- [ ] Admin role set only for gbadamositajudeeneh@gmail.com
- [ ] Receipt storage bucket is PRIVATE (only admins/owner can view)
- [ ] Resend domain verified (to avoid spam)
- [ ] Supabase anon key: safe for frontend (RLS protects the data)

---

## 📱 ADD FEATURES (next steps)

| Feature | How |
|---------|-----|
| Push notifications | Supabase Edge Functions + Expo |
| SMS OTP | Integrate Africa's Talking API |
| Paystack payments | Add Paystack inline JS for ₦2,000 |
| Mobile app | React Native with same Supabase backend |
| Analytics | Add Vercel Analytics (free) |
| Reviews & ratings | Add `reviews` table to schema |

---

*© 2025 JagX Websites · Developed by JRILISECE & JagX*
*Support: jagwaxresearchinnovation@gmail.com | +234 916 065 4415*
