-- =============================================
-- AI SDR DATABASE SCHEMA - TABLE 1: USERS
-- =============================================

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

-- =============================================
-- TABLE 2: GMAIL ACCOUNTS
-- =============================================

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

-- =============================================
-- TABLE 3: LEADS (Main Table)
-- =============================================

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

-- =============================================
-- TABLE 4: LEAD RESEARCH
-- =============================================

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

-- =============================================
-- TABLE 5: EMAIL SEQUENCES
-- =============================================

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

-- =============================================
-- TABLE 6: EMAIL LOGS
-- =============================================

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

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

CREATE INDEX idx_leads_user_id ON public.leads(user_id);
CREATE INDEX idx_leads_email ON public.leads(email);
CREATE INDEX idx_leads_stage ON public.leads(stage);
CREATE INDEX idx_leads_reply_status ON public.leads(reply_status);
CREATE INDEX idx_leads_user_stage ON public.leads(user_id, stage);
CREATE INDEX idx_email_seq_lead ON public.email_sequences(lead_id);
CREATE INDEX idx_email_logs_lead ON public.email_logs(lead_id);
CREATE INDEX idx_email_logs_user ON public.email_logs(user_id);
CREATE INDEX idx_email_logs_action ON public.email_logs(action);
CREATE INDEX idx_gmail_accounts_user ON public.gmail_accounts(user_id);

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================

-- USERS TABLE RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
ON public.users FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
ON public.users FOR UPDATE
USING (auth.uid() = id);

-- GMAIL ACCOUNTS TABLE RLS
ALTER TABLE public.gmail_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own gmail accounts"
ON public.gmail_accounts FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own gmail accounts"
ON public.gmail_accounts FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own gmail accounts"
ON public.gmail_accounts FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own gmail accounts"
ON public.gmail_accounts FOR DELETE
USING (auth.uid() = user_id);

-- LEADS TABLE RLS
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own leads"
ON public.leads FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own leads"
ON public.leads FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own leads"
ON public.leads FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own leads"
ON public.leads FOR DELETE
USING (auth.uid() = user_id);

-- LEAD RESEARCH TABLE RLS
ALTER TABLE public.lead_research ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own lead research"
ON public.lead_research FOR SELECT
USING (lead_id IN (SELECT id FROM public.leads WHERE user_id = auth.uid()));

CREATE POLICY "Users can insert own lead research"
ON public.lead_research FOR INSERT
WITH CHECK (lead_id IN (SELECT id FROM public.leads WHERE user_id = auth.uid()));

CREATE POLICY "Users can update own lead research"
ON public.lead_research FOR UPDATE
USING (lead_id IN (SELECT id FROM public.leads WHERE user_id = auth.uid()));

-- EMAIL SEQUENCES TABLE RLS
ALTER TABLE public.email_sequences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own email sequences"
ON public.email_sequences FOR SELECT
USING (lead_id IN (SELECT id FROM public.leads WHERE user_id = auth.uid()));

CREATE POLICY "Users can insert own email sequences"
ON public.email_sequences FOR INSERT
WITH CHECK (lead_id IN (SELECT id FROM public.leads WHERE user_id = auth.uid()));

CREATE POLICY "Users can update own email sequences"
ON public.email_sequences FOR UPDATE
USING (lead_id IN (SELECT id FROM public.leads WHERE user_id = auth.uid()));

-- EMAIL LOGS TABLE RLS
ALTER TABLE public.email_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own email logs"
ON public.email_logs FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own email logs"
ON public.email_logs FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- =============================================
-- FUNCTIONS & TRIGGERS
-- =============================================

-- Auto-update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for leads table
CREATE TRIGGER update_leads_updated_at
BEFORE UPDATE ON public.leads
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for users table
CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Reset daily email counter function
CREATE OR REPLACE FUNCTION reset_daily_email_counts()
RETURNS void AS $$
BEGIN
  UPDATE public.gmail_accounts SET emails_sent_today = 0;
END;
$$ LANGUAGE plpgsql;

-- Auto-create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: when new user signs up, auto-create profile
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================
-- ANALYTICS VIEW
-- =============================================

CREATE VIEW public.user_lead_stats AS
SELECT
  u.id as user_id,
  u.full_name,
  COUNT(l.id) as total_leads,
  COUNT(CASE WHEN l.stage = 0 THEN 1 END) as new_leads,
  COUNT(CASE WHEN l.stage = 1 THEN 1 END) as stage_1,
  COUNT(CASE WHEN l.stage = 2 THEN 1 END) as stage_2,
  COUNT(CASE WHEN l.stage = 3 THEN 1 END) as stage_3,
  COUNT(CASE WHEN l.stage = 4 THEN 1 END) as converted,
  COUNT(CASE WHEN l.reply_status = 'replied' THEN 1 END) as replied_leads
FROM public.users u
LEFT JOIN public.leads l ON u.id = l.user_id
GROUP BY u.id, u.full_name;
