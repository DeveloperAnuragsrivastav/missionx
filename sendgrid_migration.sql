-- =============================================
-- AI SDR DATABASE SCHEMA - SENDGRID MIGRATION
-- =============================================

-- Step 1: Drop the old gmail_accounts table and related objects if they exist
DROP TABLE IF EXISTS public.gmail_accounts CASCADE;

-- Step 2: Create a new, more generic esp_accounts table
CREATE TABLE public.esp_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  provider text NOT NULL DEFAULT 'sendgrid' CHECK (provider IN ('sendgrid', 'gmail', 'custom')), -- For future expansion
  account_name text NOT NULL, -- e.g., "Anurag's SendGrid"
  api_key text NOT NULL, -- To store the SendGrid API key
  sender_email text NOT NULL, -- The verified email address in SendGrid
  is_primary boolean DEFAULT false,
  daily_send_limit int DEFAULT 500,
  emails_sent_today int DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, sender_email)
);

-- Step 3: Add a new column to the leads table to store the last message ID from the ESP
ALTER TABLE public.leads
ADD COLUMN last_message_id text;

-- Step 4: Update the email_logs table to use the new esp_accounts table
-- First, drop the old foreign key constraint if it exists
ALTER TABLE public.email_logs DROP CONSTRAINT IF EXISTS email_logs_gmail_account_id_fkey;
-- Then, rename the column and add the new constraint
ALTER TABLE public.email_logs RENAME COLUMN gmail_account_id TO esp_account_id;
ALTER TABLE public.email_logs
ADD CONSTRAINT email_logs_esp_account_id_fkey
FOREIGN KEY (esp_account_id) REFERENCES public.esp_accounts(id) ON DELETE SET NULL;

-- Step 5: Re-create RLS policies for the new esp_accounts table
ALTER TABLE public.esp_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own ESP accounts"
ON public.esp_accounts FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Step 6: Update the function to reset email counts for the new table
CREATE OR REPLACE FUNCTION reset_daily_email_counts()
RETURNS void AS $$
BEGIN
  UPDATE public.esp_accounts SET emails_sent_today = 0;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- MIGRATION COMPLETE
-- =============================================
