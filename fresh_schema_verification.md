# Fresh SendGrid Schema Verification

## ✅ Successfully Created Tables:

1. **users** - User profiles and authentication
2. **esp_accounts** - SendGrid API keys and email service providers (replaces gmail_accounts)
3. **leads** - Master leads table with SendGrid tracking fields
4. **lead_research** - AI-generated research data (JSONB)
5. **email_sequences** - 3-email sequences per lead
6. **email_logs** - Activity tracking and analytics
7. **user_lead_stats** - Analytics view (UNRESTRICTED)

## ❌ Removed Tables:

- **gmail_accounts** - Replaced by `esp_accounts`

## Key Changes for SendGrid:

### esp_accounts table:
- `provider` - Supports 'sendgrid', 'gmail', 'custom'
- `api_key` - Stores SendGrid API key
- `sender_email` - Verified sender email
- `sender_name` - Display name for emails
- `daily_send_limit` - Rate limiting (default: 500)
- `emails_sent_today` - Current day counter

### leads table additions:
- `last_message_id` - Track SendGrid message IDs
- `latest_thread_id` - Track email threads
- `reply_status` - 'no_reply', 'replied', 'bounced', 'unsubscribed'

### email_logs table:
- `esp_account_id` - Links to SendGrid account used
- `message_id` - SendGrid message ID
- `thread_id` - Email thread tracking
- `action` - 'sent', 'replied', 'bounced', 'opened', 'clicked', 'unsubscribed'
- `metadata` - JSONB for webhook data

## Next Steps:

1. Add your SendGrid API key to `esp_accounts` table
2. Update n8n workflows as per migration guide
3. Setup SendGrid Inbound Parse webhook
4. Test email sending and reply tracking
