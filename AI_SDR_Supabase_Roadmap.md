# AI SDR Workflow Ko Expand Karne Ka Complete Suggestion Aur Roadmap

**Author:** Manus AI
**Date:** 11 February 2026
**For:** Copilots.in AI SDR System

---

## 1. Aapka Current System: Ek Overview

Bhai, maine aapka poora n8n workflow JSON analyze kiya hai. Aapne ek bahut hi solid **AI SDR (Sales Development Representative)** system banaya hai jo Copilots.in ke liye leads ko automatically process karta hai. Pehle samajh lete hain ki aapka current system kya kya karta hai:

### 1.1 Current Architecture Ka Summary

Aapke system mein **3 main flows** hain:

| Flow | Trigger | Kya Karta Hai |
|---|---|---|
| **New Lead Processing** | Manual Execute button | Google Sheet se leads uthata hai, email verify karta hai, company research karta hai (Apify + OpenAI), behavior analyze karta hai, 3-email sequence generate karta hai, pehla email bhejta hai |
| **Reply Detection** | Gmail Trigger (har ghante) | Jab lead reply kare toh detect karta hai, AI se reply generate karta hai, Gmail se bhejta hai, Sheet update karta hai |
| **Scheduled Follow-Up** | Schedule Trigger (daily 9:30 AM) | "Replied" leads check karta hai, agar 4+ din ho gaye toh next email bhejta hai (Stage 1→Email 2, Stage 2→Email 3) |

### 1.2 Current Tech Stack

| Component | Tool/Service |
|---|---|
| Database | Google Sheets ("AI SDR" spreadsheet) |
| Automation | n8n (self-hosted ya cloud) |
| Email Sending | Gmail OAuth2 (2 accounts) |
| Email Verification | Reoon API |
| Web Scraping | Apify (Contact Info Scraper, LinkedIn Scraper, LinkedIn Posts) |
| AI/LLM | OpenAI (GPT-4o, GPT-4o-mini, o3-mini, GPT-4.1-mini) |

### 1.3 Google Sheet Ka Current Schema

Aapki "Leads Database" sheet mein yeh columns hain:

| # | Column Name | Purpose |
|---|---|---|
| 1 | Lead ID | Unique identifier |
| 2 | ID | Matching key (Gmail thread se link) |
| 3 | Full Name | Lead ka naam |
| 4 | Email | Lead ka email |
| 5 | Company Name | Company ka naam |
| 6 | Company Website | Website URL |
| 7 | Job Title | Lead ka designation |
| 8 | Pain Points | Lead ke challenges |
| 9 | Lead Source | Kahan se aaya lead |
| 10 | Lead Company Research | AI-generated company research |
| 11-14 | 1st Email (Subject, Content, CTA, Trigger) | Pehle email ka data |
| 15-18 | 2nd Email (Subject, Content, CTA, Trigger) | Doosre email ka data |
| 19-22 | 3rd Email (Subject, Content, CTA, Trigger) | Teesre email ka data |
| 23 | Latest Email Thread ID | Gmail thread tracking |
| 24 | Lead Reply Status | Reply aaya ya nahi |
| 25 | Stage | Current stage (1, 2, 3) |
| 26 | Last Email Sent | Aakhri email ki date |
| 27 | Last Modified Time | Last update time |

---

## 2. Current System Ki Problems (Kyun Change Karna Zaroori Hai)

Bhai, aapka system abhi single-user ke liye kaam kar raha hai, lekin jaise hi aap scale karoge, yeh problems aayengi:

### 2.1 Google Sheets Ki Limitations

Google Sheets ek spreadsheet hai, **database nahi**. Iska matlab:

**Performance:** Jab aapke paas 1000+ leads ho jayengi, toh Sheet bahut slow ho jayegi. Har read/write operation mein time lagega aur n8n workflow timeout ho sakta hai.

**Concurrent Access:** Agar 2-3 log ek saath Sheet mein changes kar rahe hain (ya n8n workflows ek saath chal rahe hain), toh data conflicts ho sakte hain. Ek workflow doosre ka data overwrite kar sakta hai.

**No Indexing:** Google Sheets mein koi indexing nahi hoti. Jab aap email se lead search karte ho, toh Sheet poori scan hoti hai. Database mein index hone se yeh milliseconds mein hota hai.

**Data Integrity:** Sheets mein koi foreign key constraints nahi hote. Iska matlab galat data bhi insert ho sakta hai bina kisi error ke.

### 2.2 Multi-User Problem

Abhi aapka system sirf **ek user** ke liye hai:

**Ek Gmail Account:** Saare emails ek hi Gmail account se jaate hain. Agar aap apni team mein 5 salespeople rakhna chahte ho, toh har ek ko apna Gmail connect karna hoga.

**No Data Isolation:** Agar multiple users ek hi Sheet use karein, toh sabko saara data dikhai dega. User A ki leads User B bhi dekh sakta hai.

**No Role Management:** Koi admin panel nahi hai jahan se aap users ko manage kar sako, unhe permissions de sako, ya unki activity track kar sako.

### 2.3 No Dashboard/Analytics

Abhi aapke paas koi visual dashboard nahi hai jahan se aap dekh sako:

- Kitni leads process hui
- Kitne emails bheje gaye
- Kitni replies aayi
- Conversion rate kya hai
- Kaunsa email template best perform kar raha hai

---

## 3. Solution: Supabase Se Sab Kuch Solve Hoga

### 3.1 Supabase Kya Hai?

Supabase ek **open-source Firebase alternative** hai. Simple bhasha mein samjho toh yeh aapko ek complete backend deta hai bina backend code likhe. Iske andar milta hai:

| Feature | Kya Karta Hai | Aapke Kaam Mein Kaise Aayega |
|---|---|---|
| **PostgreSQL Database** | Duniya ka sabse powerful open-source database | Google Sheets replace karega, fast queries, proper indexing |
| **Authentication** | User login/signup/password reset | Multi-user support ke liye |
| **Row Level Security (RLS)** | Database level par data access control | Har user sirf apni leads dekhega |
| **Realtime** | Live data updates | Dashboard mein real-time changes dikhenge |
| **Storage** | File storage (images, documents) | Email attachments, company logos store karne ke liye |
| **Auto APIs** | Har table ke liye REST aur GraphQL APIs | n8n se directly connect ho jayega |

### 3.2 Supabase Free Tier Mein Kya Milta Hai?

Bhai, Supabase ka free tier bahut generous hai:

| Resource | Free Limit |
|---|---|
| Database | 500 MB |
| Auth Users | Unlimited |
| API Requests | Unlimited |
| Realtime | 200 concurrent connections |
| Storage | 1 GB |
| Edge Functions | 500K invocations/month |

Aapke AI SDR ke liye yeh kaafi hai shuruwaat mein. Jab scale karo tab paid plan le lena.

---

## 4. Database Design: Supabase Schema (DB Suggestion)

Ab aate hain sabse important part par. Maine aapke Google Sheet ke structure ko analyze karke ek proper **relational database schema** design kiya hai. Yeh schema multi-user ready hai.

### 4.1 Entity Relationship Diagram (Samjho Kaise Tables Linked Hain)

```
users (1) ──────── (many) leads
leads (1) ──────── (many) email_sequences
leads (1) ──────── (1) lead_research
leads (1) ──────── (many) email_logs
users (1) ──────── (many) gmail_accounts
```

### 4.2 Table 1: `users` (App Ke Users)

Yeh table aapke app ke users (salespeople, admins) ke liye hai. Supabase Auth se automatically link hoti hai.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | PRIMARY KEY, DEFAULT `auth.uid()` | Supabase Auth se auto-link |
| `email` | `text` | NOT NULL, UNIQUE | User ka email |
| `full_name` | `text` | NOT NULL | User ka poora naam |
| `role` | `text` | DEFAULT 'user' | 'admin', 'user', 'viewer' |
| `company_name` | `text` | | User ki company (agar SaaS banao toh) |
| `is_active` | `boolean` | DEFAULT true | Account active hai ya nahi |
| `created_at` | `timestamptz` | DEFAULT now() | Account kab bana |
| `updated_at` | `timestamptz` | DEFAULT now() | Last update kab hua |

**SQL:**
```sql
CREATE TABLE public.users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL UNIQUE,
  full_name text NOT NULL,
  role text DEFAULT 'user' CHECK (role IN ('admin', 'user', 'viewer')),
  company_name text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

### 4.3 Table 2: `gmail_accounts` (Users Ke Gmail Accounts)

Har user apna Gmail account connect karega. Ek user ke paas multiple Gmail accounts ho sakte hain.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | PRIMARY KEY, DEFAULT `gen_random_uuid()` | Unique ID |
| `user_id` | `uuid` | REFERENCES `users(id)` | Kis user ka hai |
| `gmail_email` | `text` | NOT NULL | Gmail address |
| `oauth_token` | `text` | | Encrypted OAuth token (n8n credentials mein store karo) |
| `is_primary` | `boolean` | DEFAULT false | Primary sending account hai ya nahi |
| `daily_send_limit` | `int` | DEFAULT 50 | Daily email limit (spam se bachne ke liye) |
| `emails_sent_today` | `int` | DEFAULT 0 | Aaj kitne emails bheje |
| `created_at` | `timestamptz` | DEFAULT now() | Kab add hua |

**SQL:**
```sql
CREATE TABLE public.gmail_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  gmail_email text NOT NULL,
  oauth_token text,
  is_primary boolean DEFAULT false,
  daily_send_limit int DEFAULT 50,
  emails_sent_today int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);
```

### 4.4 Table 3: `leads` (Saari Leads Ka Master Table)

Yeh aapka sabse important table hai. Google Sheet ki jagah yeh table use hoga.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | PRIMARY KEY, DEFAULT `gen_random_uuid()` | Unique Lead ID |
| `user_id` | `uuid` | REFERENCES `users(id)` | Kis user ki lead hai |
| `full_name` | `text` | NOT NULL | Lead ka naam |
| `email` | `text` | NOT NULL | Lead ka email |
| `company_name` | `text` | | Company ka naam |
| `company_website` | `text` | | Company ki website |
| `job_title` | `text` | | Lead ka designation |
| `linkedin_url` | `text` | | LinkedIn profile URL |
| `pain_points` | `text` | | Lead ke challenges |
| `lead_source` | `text` | | Kahan se aaya (LinkedIn, Website, Referral, etc.) |
| `email_verified` | `boolean` | DEFAULT false | Email verify hua ya nahi |
| `email_verification_status` | `text` | | 'valid', 'invalid', 'risky', 'unknown' |
| `stage` | `int` | DEFAULT 0 | 0=New, 1=1st Email Sent, 2=2nd Email Sent, 3=3rd Email Sent, 4=Converted, 5=Lost |
| `reply_status` | `text` | DEFAULT 'no_reply' | 'no_reply', 'replied', 'bounced', 'unsubscribed' |
| `latest_thread_id` | `text` | | Gmail thread ID for tracking |
| `last_email_sent_at` | `timestamptz` | | Aakhri email kab bheja |
| `conversion_probability` | `text` | | AI-predicted conversion chance |
| `tags` | `text[]` | | Custom tags (array) |
| `notes` | `text` | | Manual notes |
| `created_at` | `timestamptz` | DEFAULT now() | Lead kab create hui |
| `updated_at` | `timestamptz` | DEFAULT now() | Last update |

**SQL:**
```sql
CREATE TABLE public.leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  email text NOT NULL,
  company_name text,
  company_website text,
  job_title text,
  linkedin_url text,
  pain_points text,
  lead_source text,
  email_verified boolean DEFAULT false,
  email_verification_status text,
  stage int DEFAULT 0 CHECK (stage >= 0 AND stage <= 5),
  reply_status text DEFAULT 'no_reply' CHECK (reply_status IN ('no_reply', 'replied', 'bounced', 'unsubscribed')),
  latest_thread_id text,
  last_email_sent_at timestamptz,
  conversion_probability text,
  tags text[],
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Important indexes for fast queries
CREATE INDEX idx_leads_user_id ON public.leads(user_id);
CREATE INDEX idx_leads_email ON public.leads(email);
CREATE INDEX idx_leads_stage ON public.leads(stage);
CREATE INDEX idx_leads_reply_status ON public.leads(reply_status);
CREATE INDEX idx_leads_user_stage ON public.leads(user_id, stage);
```

### 4.5 Table 4: `lead_research` (AI-Generated Company Research)

Yeh table lead ki company ke baare mein AI research store karega. Isse `leads` table chhota aur fast rahega.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | PRIMARY KEY, DEFAULT `gen_random_uuid()` | Unique ID |
| `lead_id` | `uuid` | REFERENCES `leads(id)`, UNIQUE | Kis lead ka research hai |
| `company_scrape_data` | `jsonb` | | Apify se aaya raw scraped data |
| `linkedin_profile_data` | `jsonb` | | LinkedIn profile ka data |
| `linkedin_posts_data` | `jsonb` | | LinkedIn posts ka data |
| `website_analysis` | `text` | | AI-generated website analysis |
| `final_company_summary` | `text` | | Final compiled company research |
| `behavior_analysis` | `jsonb` | | Lead Behavior Analyzer ka output |
| `created_at` | `timestamptz` | DEFAULT now() | Kab create hua |

**SQL:**
```sql
CREATE TABLE public.lead_research (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id uuid NOT NULL UNIQUE REFERENCES public.leads(id) ON DELETE CASCADE,
  company_scrape_data jsonb,
  linkedin_profile_data jsonb,
  linkedin_posts_data jsonb,
  website_analysis text,
  final_company_summary text,
  behavior_analysis jsonb,
  created_at timestamptz DEFAULT now()
);
```

> **Pro Tip:** `jsonb` data type use kiya hai kyunki Apify aur AI models ka output structured JSON hota hai. PostgreSQL mein aap `jsonb` ke andar bhi query kar sakte ho, jaise `behavior_analysis->>'journey_stage'`.

### 4.6 Table 5: `email_sequences` (Generated Email Sequences)

Har lead ke liye 3 emails generate hote hain. Yeh table un emails ko store karega.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | PRIMARY KEY, DEFAULT `gen_random_uuid()` | Unique ID |
| `lead_id` | `uuid` | REFERENCES `leads(id)` | Kis lead ka email hai |
| `email_number` | `int` | NOT NULL, CHECK (1-3) | 1st, 2nd, ya 3rd email |
| `subject_lines` | `text[]` | | 3 subject line options (array) |
| `selected_subject` | `text` | | Jo subject line actually use hui |
| `content_raw` | `text` | | Raw AI-generated content |
| `content_html` | `text` | | HTML formatted email |
| `cta` | `text` | | Call to Action |
| `psychological_trigger` | `text` | | Kaunsa trigger use hua |
| `purpose` | `text` | | Email ka purpose |
| `status` | `text` | DEFAULT 'draft' | 'draft', 'sent', 'failed' |
| `sent_at` | `timestamptz` | | Kab bheja gaya |
| `created_at` | `timestamptz` | DEFAULT now() | Kab generate hua |

**SQL:**
```sql
CREATE TABLE public.email_sequences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id uuid NOT NULL REFERENCES public.leads(id) ON DELETE CASCADE,
  email_number int NOT NULL CHECK (email_number >= 1 AND email_number <= 3),
  subject_lines text[],
  selected_subject text,
  content_raw text,
  content_html text,
  cta text,
  psychological_trigger text,
  purpose text,
  status text DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'failed')),
  sent_at timestamptz,
  created_at timestamptz DEFAULT now(),
  UNIQUE(lead_id, email_number)
);

CREATE INDEX idx_email_seq_lead ON public.email_sequences(lead_id);
```

### 4.7 Table 6: `email_logs` (Email Activity Tracking)

Yeh table har email activity ko log karega. Isse aapko analytics milegi.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | PRIMARY KEY, DEFAULT `gen_random_uuid()` | Unique ID |
| `lead_id` | `uuid` | REFERENCES `leads(id)` | Kis lead ko bheja |
| `user_id` | `uuid` | REFERENCES `users(id)` | Kis user ne bheja |
| `gmail_account_id` | `uuid` | REFERENCES `gmail_accounts(id)` | Kis Gmail se bheja |
| `email_sequence_id` | `uuid` | REFERENCES `email_sequences(id)` | Kaunsa email bheja |
| `thread_id` | `text` | | Gmail thread ID |
| `message_id` | `text` | | Gmail message ID |
| `action` | `text` | NOT NULL | 'sent', 'replied', 'bounced', 'opened', 'clicked' |
| `subject` | `text` | | Email ka subject |
| `metadata` | `jsonb` | | Extra data (error messages, etc.) |
| `created_at` | `timestamptz` | DEFAULT now() | Kab hua |

**SQL:**
```sql
CREATE TABLE public.email_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id uuid NOT NULL REFERENCES public.leads(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.users(id),
  gmail_account_id uuid REFERENCES public.gmail_accounts(id),
  email_sequence_id uuid REFERENCES public.email_sequences(id),
  thread_id text,
  message_id text,
  action text NOT NULL CHECK (action IN ('sent', 'replied', 'bounced', 'opened', 'clicked')),
  subject text,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_email_logs_lead ON public.email_logs(lead_id);
CREATE INDEX idx_email_logs_user ON public.email_logs(user_id);
CREATE INDEX idx_email_logs_action ON public.email_logs(action);
```

---

## 5. Row Level Security (RLS): Multi-User Data Isolation

Yeh section bahut important hai. RLS se hum ensure karenge ki **har user sirf apna data dekhe**.

### 5.1 RLS Kaise Kaam Karta Hai?

Socho ki aapke database mein 3 users hain: Anurag, Priya, aur Rahul. Bina RLS ke, agar Anurag `leads` table query kare, toh usse saari 1000 leads dikhengi. Lekin RLS enable karne ke baad, Anurag ko sirf apni 300 leads dikhengi, Priya ko apni 400, aur Rahul ko apni 300.

Yeh sab **database level** par hota hai, matlab aapke application code mein kuch extra karne ki zaroorat nahi. Supabase automatically filter kar deta hai.

### 5.2 RLS Policies

```sql
-- ========================================
-- LEADS TABLE RLS
-- ========================================
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;

-- Users apni leads dekh sakte hain
CREATE POLICY "Users can view own leads"
ON public.leads FOR SELECT
USING (auth.uid() = user_id);

-- Users apni leads insert kar sakte hain
CREATE POLICY "Users can insert own leads"
ON public.leads FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users apni leads update kar sakte hain
CREATE POLICY "Users can update own leads"
ON public.leads FOR UPDATE
USING (auth.uid() = user_id);

-- Users apni leads delete kar sakte hain
CREATE POLICY "Users can delete own leads"
ON public.leads FOR DELETE
USING (auth.uid() = user_id);

-- ========================================
-- EMAIL_SEQUENCES TABLE RLS
-- ========================================
ALTER TABLE public.email_sequences ENABLE ROW LEVEL SECURITY;

-- Users apni leads ke email sequences dekh sakte hain
CREATE POLICY "Users can view own email sequences"
ON public.email_sequences FOR SELECT
USING (
  lead_id IN (SELECT id FROM public.leads WHERE user_id = auth.uid())
);

-- Users apni leads ke liye email sequences insert kar sakte hain
CREATE POLICY "Users can insert own email sequences"
ON public.email_sequences FOR INSERT
WITH CHECK (
  lead_id IN (SELECT id FROM public.leads WHERE user_id = auth.uid())
);

-- ========================================
-- LEAD_RESEARCH TABLE RLS
-- ========================================
ALTER TABLE public.lead_research ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own lead research"
ON public.lead_research FOR SELECT
USING (
  lead_id IN (SELECT id FROM public.leads WHERE user_id = auth.uid())
);

-- ========================================
-- EMAIL_LOGS TABLE RLS
-- ========================================
ALTER TABLE public.email_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own email logs"
ON public.email_logs FOR SELECT
USING (auth.uid() = user_id);

-- ========================================
-- GMAIL_ACCOUNTS TABLE RLS
-- ========================================
ALTER TABLE public.gmail_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own gmail accounts"
ON public.gmail_accounts FOR ALL
USING (auth.uid() = user_id);
```

> **Important Note:** n8n workflows ke liye aapko **Supabase Service Role Key** use karna hoga, jo RLS bypass karta hai. Yeh isliye kyunki n8n backend se kaam karta hai aur usse saare users ka data access karna padta hai. Service Role Key ko hamesha secret rakhna.

---

## 6. n8n Workflow Mein Kya Changes Karne Hain

### 6.1 Google Sheets Nodes Ko Supabase Se Replace Karna

Yeh ek mapping hai ki kaunsa Google Sheets node kaunse Supabase operation se replace hoga:

| Current (Google Sheets) | New (Supabase) | Operation |
|---|---|---|
| `Get row(s) in sheet` (new leads) | Supabase Node | SELECT from `leads` WHERE `stage = 0` AND `user_id = ?` |
| `Get row(s) in sheet` (by email) | Supabase Node | SELECT from `leads` WHERE `email = ?` |
| `Get row(s) in sheet1` (replied leads) | Supabase Node | SELECT from `leads` WHERE `reply_status = 'replied'` AND `stage < 3` |
| `Append or update row in sheet` | Supabase Node | UPSERT into `leads` + INSERT into `email_sequences` |
| `Update row in sheet` | Supabase Node | UPDATE `leads` SET `stage = ?`, `reply_status = ?` |

### 6.2 n8n Mein Supabase Node Kaise Use Karna Hai

n8n mein Supabase ka built-in integration hai. Aapko bas:

1. n8n mein **Credentials** section mein jaao
2. **Supabase API** credential add karo
3. Aapko chahiye: **Supabase URL** (project settings se milega) aur **Service Role Key** (API settings se milega)
4. Ab workflow mein **Supabase** node drag karo aur operation select karo (Get Row, Insert Row, Update Row, etc.)

### 6.3 Workflow Architecture Change

```
PEHLE (Current):
Google Sheet → n8n → Google Sheet (update)

BAAD MEIN (New):
Supabase → n8n → Supabase (update)
Website → Supabase (lead add) → n8n trigger → Process → Supabase (update)
```

**Key Change:** Ab leads sirf Google Sheet se nahi, balki **website form** se bhi aa sakti hain directly Supabase mein. Aur n8n ko Supabase ka **Database Webhook** ya **Realtime** feature trigger kar sakta hai jab naya lead aaye.

---

## 7. Multi-User Handle Karne Ka Tarika

### 7.1 User Onboarding Flow

```
1. User website par signup karta hai (Supabase Auth)
2. `users` table mein entry banti hai
3. User apna Gmail account connect karta hai (OAuth flow)
4. `gmail_accounts` table mein entry banti hai
5. User leads upload karta hai (CSV ya manual)
6. `leads` table mein entries banti hain (user_id ke saath)
7. n8n workflow trigger hota hai
8. Processing hoti hai, results Supabase mein save hote hain
```

### 7.2 Multi-User n8n Workflow Design

Abhi aapka workflow ek specific Gmail account se hardcoded hai. Multi-user ke liye aapko yeh changes karne honge:

**Option A: Single n8n Instance, Dynamic Credentials**

Ek hi n8n workflow sabke liye chalega, lekin dynamically user ka Gmail credential use karega. Yeh thoda complex hai lekin cost-effective hai.

**Option B: Per-User Workflow Copies (Simple but Not Scalable)**

Har user ke liye alag workflow copy banana. Yeh simple hai lekin 50+ users ke liye manage karna mushkil hai.

**Option C (Recommended): Webhook-Based Architecture**

Website se Supabase mein lead aaye → Supabase Database Webhook fire ho → n8n webhook receive kare → Workflow process kare with user's credentials → Results Supabase mein save ho.

### 7.3 User Roles Aur Permissions

| Role | Kya Kar Sakta Hai |
|---|---|
| **Admin** | Saare users dekh sakta hai, settings change kar sakta hai, analytics dekh sakta hai |
| **User** | Apni leads manage kar sakta hai, emails bhej sakta hai, apni analytics dekh sakta hai |
| **Viewer** | Sirf data dekh sakta hai, kuch change nahi kar sakta |

---

## 8. Database Functions Aur Triggers (Automation at DB Level)

Supabase mein aap PostgreSQL functions aur triggers likh sakte ho jo automatically kaam karein.

### 8.1 Auto-Update `updated_at` Column

```sql
-- Yeh function har update par automatically updated_at set karega
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Leads table par trigger
CREATE TRIGGER update_leads_updated_at
BEFORE UPDATE ON public.leads
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### 8.2 Daily Email Counter Reset

```sql
-- Har raat 12 baje gmail_accounts ka emails_sent_today reset karo
-- Yeh Supabase Edge Function ya pg_cron se schedule kar sakte ho
CREATE OR REPLACE FUNCTION reset_daily_email_counts()
RETURNS void AS $$
BEGIN
  UPDATE public.gmail_accounts SET emails_sent_today = 0;
END;
$$ LANGUAGE plpgsql;
```

### 8.3 Useful Database Views (Analytics Ke Liye)

```sql
-- User-wise lead statistics
CREATE VIEW public.user_lead_stats AS
SELECT
  u.id as user_id,
  u.full_name,
  COUNT(l.id) as total_leads,
  COUNT(CASE WHEN l.stage = 0 THEN 1 END) as new_leads,
  COUNT(CASE WHEN l.stage = 1 THEN 1 END) as stage_1,
  COUNT(CASE WHEN l.stage = 2 THEN 1 END) as stage_2,
  COUNT(CASE WHEN l.stage = 3 THEN 1 END) as stage_3,
  COUNT(CASE WHEN l.reply_status = 'replied' THEN 1 END) as replied_leads,
  COUNT(CASE WHEN l.stage = 4 THEN 1 END) as converted_leads
FROM public.users u
LEFT JOIN public.leads l ON u.id = l.user_id
GROUP BY u.id, u.full_name;
```

---

## 9. Migration Plan: Google Sheets Se Supabase

### Step 1: Supabase Project Create Karo
- [supabase.com](https://supabase.com) par jaao
- "Start your project" par click karo
- Free plan select karo
- Project name do: `ai-sdr`
- Database password set karo (yaad rakhna!)
- Region select karo: Mumbai (ap-south-1) - India ke liye sabse fast

### Step 2: Tables Create Karo
- Supabase Dashboard → SQL Editor
- Upar diye gaye saare CREATE TABLE statements ek ek karke run karo
- Pehle `users`, phir `gmail_accounts`, phir `leads`, phir `lead_research`, phir `email_sequences`, phir `email_logs`

### Step 3: RLS Enable Karo
- SQL Editor mein saari RLS policies run karo
- Dashboard → Authentication → Policies se verify karo ki policies lag gayi hain

### Step 4: Existing Data Migrate Karo
- Google Sheet ko CSV mein export karo
- Supabase Dashboard → Table Editor → leads table → Insert → Import CSV
- Ya phir ek chhota Python script likho:

```python
import csv
from supabase import create_client

supabase = create_client("YOUR_SUPABASE_URL", "YOUR_SERVICE_ROLE_KEY")

with open('leads.csv', 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        supabase.table('leads').insert({
            'user_id': 'YOUR_USER_UUID',
            'full_name': row['Full Name'],
            'email': row['Email'],
            'company_name': row['Company Name'],
            'company_website': row['Company Website'],
            'job_title': row['Job Title'],
            'pain_points': row['Pain Points'],
            'lead_source': row['Lead Source'],
            'stage': int(row.get('Stage', 0)),
            'reply_status': row.get('Lead Reply Status', 'no_reply'),
        }).execute()
```

### Step 5: n8n Credentials Update Karo
- n8n → Settings → Credentials → Add New → Supabase API
- Supabase URL aur Service Role Key daalo
- Test connection karo

### Step 6: Workflow Nodes Replace Karo
- Ek ek karke Google Sheets nodes ko Supabase nodes se replace karo
- Pehle test environment mein try karo, phir production mein deploy karo

---

## 10. Future Website Ka Architecture (Jab Website Banao)

Jab aap website banane ka socho, tab yeh architecture follow karo:

```
┌─────────────────────────────────────────────┐
│                 FRONTEND                     │
│         React + Vite + TailwindCSS           │
│                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │  Login   │ │Dashboard │ │  Leads   │    │
│  │  Page    │ │  Page    │ │  Page    │    │
│  └──────────┘ └──────────┘ └──────────┘    │
└──────────────────┬──────────────────────────┘
                   │
                   │ Supabase JS Client
                   │
┌──────────────────▼──────────────────────────┐
│               SUPABASE                       │
│                                              │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────────┐  │
│  │ Auth │ │  DB  │ │ RLS  │ │ Realtime │  │
│  └──────┘ └──────┘ └──────┘ └──────────┘  │
└──────────────────┬──────────────────────────┘
                   │
                   │ Database Webhook / API
                   │
┌──────────────────▼──────────────────────────┐
│                 n8n                           │
│                                              │
│  ┌──────────────────────────────────────┐   │
│  │  Lead Processing Workflow            │   │
│  │  (Email Verify → Research → AI →     │   │
│  │   Email Generate → Send → Update)    │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

---

## 11. Complete Roadmap Timeline

| Phase | Kya Karna Hai | Estimated Time | Priority |
|---|---|---|---|
| **Phase 1** | Supabase project setup + Tables create + RLS policies | 1-2 din | HIGH |
| **Phase 2** | Google Sheets se data migrate karo | 1 din | HIGH |
| **Phase 3** | n8n workflow mein Supabase nodes replace karo | 2-3 din | HIGH |
| **Phase 4** | Test karo - saare flows check karo | 1-2 din | HIGH |
| **Phase 5** | Basic website banao (Login + Dashboard + Leads list) | 1-2 weeks | MEDIUM |
| **Phase 6** | Multi-user Gmail OAuth integration | 1 week | MEDIUM |
| **Phase 7** | Analytics dashboard add karo | 1 week | LOW |
| **Phase 8** | Advanced features (bulk import, templates, A/B testing) | 2-3 weeks | LOW |

---

## 12. Important Tips Aur Best Practices

**Tip 1: Service Role Key Kabhi Frontend Mein Mat Daalo.** Yeh key RLS bypass karti hai. Isse sirf n8n (backend) mein use karo. Frontend mein sirf `anon` key use karo.

**Tip 2: Indexes Zaroor Banao.** Maine upar SQL mein indexes diye hain. Yeh queries ko 10x-100x fast bana dete hain. Bina index ke, jaise jaise data badhega, queries slow hoti jaayengi.

**Tip 3: JSONB Ka Faayda Uthao.** Apify aur AI models ka output structured JSON hota hai. Isse `jsonb` column mein store karo. Baad mein aap iske andar bhi search kar sakte ho.

**Tip 4: Supabase Realtime Use Karo.** Jab website banao, toh Supabase Realtime enable karo. Isse jab n8n koi lead update kare, toh website par turant dikhai dega bina page refresh kiye.

**Tip 5: Email Sending Limits Ka Dhyan Rakho.** Gmail ka daily sending limit 500 emails hai (regular account) aur 2000 (Google Workspace). `gmail_accounts` table mein `daily_send_limit` column isliye rakha hai taaki aap track kar sako aur limit cross na ho.

**Tip 6: Backup Regularly.** Supabase mein daily automatic backups hote hain (paid plan mein). Free plan mein aap manually `pg_dump` se backup le sakte ho.

---

## 13. Conclusion

Bhai, aapka current AI SDR system bahut accha hai. Bas usse Google Sheets se Supabase par shift karna hai, aur aapka system production-ready ho jayega. Sabse pehle **Phase 1 se 4** complete karo (DB setup + migration + n8n update). Yeh 1 week mein ho jayega. Uske baad dheere dheere website aur multi-user features add karte jaao.

Agar koi bhi step mein help chahiye, toh pooch lena. Main aapke liye SQL queries, n8n workflow changes, ya website code - kuch bhi bana ke de sakta hoon.

All the best!

---

## References

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Row Level Security Guide](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [n8n Supabase Integration](https://n8n.io/integrations/supabase/)
- [Supabase Multi-Tenancy Pattern](https://roughlywritten.substack.com/p/supabase-multi-tenancy-simple-and)
- [PostgreSQL JSONB Documentation](https://www.postgresql.org/docs/current/datatype-json.html)
