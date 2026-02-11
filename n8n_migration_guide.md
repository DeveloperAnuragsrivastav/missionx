
# n8n Migration Guide: Google Sheets/Gmail → Supabase/SendGrid

Bhai, yeh guide aapko apne n8n workflows ko upgrade karne mein help karegi. Hum Google Sheets ko Supabase se aur Gmail ko SendGrid se replace karenge. Isse aapka system scalable, multi-user ready, aur powerful ban jayega.

**Fayde (Benefits):**
- **Scalability:** Supabase hazaron leads handle kar sakta hai, Sheets ki tarah slow nahi hoga.
- **Multi-User:** Har user apna SendGrid account aur leads manage kar payega.
- **Data Integrity:** Proper database relations se data clean aur organized rahega.
- **Advanced Features:** SendGrid webhooks se real-time reply tracking possible hai.

---

## Part 1: Credentials Setup in n8n

Sabse pehle, n8n ko Supabase aur SendGrid se connect karna hoga.

### 1.1 Supabase Credentials

1.  n8n mein, left panel se **Credentials** > **Add credential** par jao.
2.  Search karo "Supabase" aur select karo.
3.  Aapko **Project URL** aur **Supabase API Key** daalni hai.
    -   Yeh aapko Supabase Dashboard → Project → Settings → API mein milega.
    -   **Important:** Yahan par `service_role` key use karna, `anon` key nahi. `service_role` key RLS policies ko bypass kar sakti hai, jo n8n jaise backend automation ke liye zaroori hai.
4.  Credential ko ek naam do (e.g., "My Supabase") aur save karo.

### 1.2 SendGrid Credentials

1.  n8n mein, **Credentials** > **Add credential** par jao.
2.  Search karo "SendGrid" aur select karo.
3.  Aapko **API Key** daalni hai.
    -   Yeh aapko SendGrid Dashboard → Settings → API Keys mein milega. "Create API Key" par click karke ek new key banao with "Full Access".
4.  Credential ko naam do (e.g., "My SendGrid") aur save karo.

---

## Part 2: Workflow 1 - New Lead Processing (Manual Trigger)

Yeh workflow naye leads ko process karta hai, research karta hai, aur pehla email bhejta hai.

**Old Flow:** `Google Sheets (Get Rows)` -> `Reoon` -> `Apify` -> `OpenAI` -> `Gmail (Send)` -> `Google Sheets (Update)`

**New Flow:** `Manual Trigger` -> `Supabase (Select)` -> `Reoon` -> `Apify` -> `OpenAI` -> `SendGrid (Send)` -> `Supabase (Update)`

### Node-by-Node Changes:

| Old Node (Google Sheets) | New Node (Supabase) | Details |
| :--- | :--- | :--- |
| **1. Get Rows** | **1. Supabase (Select)** | Manual trigger ke baad, `Supabase` node use karo to get leads. **Resource:** `leads`, **Operation:** `Select`. **Filters** mein `stage` ko `0` (new lead) se filter karo. |
| **11. Update Sheet** | **11. Supabase (Update)** | Workflow ke end mein, `Supabase` node use karo. **Resource:** `leads`. **Operation:** `Update`. **Match Column** mein `id` use karo. Saare research data (company summary, pain points) aur generated email content ko corresponding columns mein map karo. `stage` ko `1` set karo. |

| Old Node (Gmail) | New Node (SendGrid) | Details |
| :--- | :--- | :--- |
| **10. Send Email** | **10. SendGrid (Send)** | `Gmail` node ko `SendGrid` node se replace karo. **From Email** mein `esp_accounts` se `sender_email` use karo. **To Email** mein `leads` table se `email` use karo. Subject aur Body ko `email_sequences` table se map karo. |

**Important:** SendGrid se email bhejte waqt, aapko ek `Custom Header` set karna hoga taaki aap replies ko track kar sako. 
- **Header Name:** `X-Manus-Lead-ID`
- **Header Value:** `{{ $json["id"] }}` (lead ka ID)

Yeh header har outgoing email mein chala jayega. Jab reply aayega, SendGrid yeh header hume wapas dega, jisse hume pata chalega ki kis lead ne reply kiya hai.

---

## Part 3: Workflow 2 - Reply Detection (Webhook Trigger)

Yeh sabse bada change hai. Hum Gmail trigger ko SendGrid Inbound Parse Webhook se replace karenge. Isse real-time reply tracking hogi.

### 3.1 SendGrid Setup: Inbound Parse

1.  SendGrid Dashboard mein **Settings** > **Inbound Parse** par jao.
2.  **Add Host & URL** par click karo.
3.  **Receiving Domain** mein ek subdomain set karo, jaise `replies.yourdomain.com`.
4.  **Destination URL** mein aapko n8n webhook URL daalna hai. Yeh URL aapko n8n mein `Webhook` trigger node se milega.
5.  SendGrid aapko DNS records (MX record) dega. Yeh records aapko apne domain provider (e.g., GoDaddy, Cloudflare) mein add karne honge. Isse `replies.yourdomain.com` par aane waale saare emails SendGrid receive karega.

### 3.2 New n8n Workflow: "Reply Handler"

Ek naya workflow banao.

**Flow:** `Webhook Trigger` -> `Supabase (Select Lead)` -> `Supabase (Update Lead)` -> `Supabase (Insert Log)` -> `(Optional) OpenAI`

1.  **Trigger: Webhook**
    -   Ek `Webhook` node add karo. Yeh aapko ek URL dega. Isko SendGrid Inbound Parse ke Destination URL mein daalo.
    -   SendGrid se ek test email bhejo `test@replies.yourdomain.com` par. Webhook node test data capture kar lega.

2.  **Node: Supabase (Select Lead)**
    -   SendGrid ke webhook data mein `headers` field hoga. Usme se `X-Manus-Lead-ID` nikalo.
    -   Expression: `{{ $json.body.headers["X-Manus-Lead-ID"] }}`
    -   `Supabase` node use karke `leads` table se woh lead select karo jiska `id` is header value se match karta hai.

3.  **Node: Supabase (Update Lead)**
    -   Agar lead mil jaata hai, toh `Supabase` node (Update) se `reply_status` ko `'replied'` set karo.
    -   SendGrid se aaye `subject` aur `text` ko `notes` column mein append kar sakte ho.

4.  **Node: Supabase (Insert Log)**
    -   `email_logs` table mein ek new entry daalo. `action` ko `'replied'` set karo. `lead_id`, `user_id`, aur `metadata` (JSON of the webhook body) store karo.

---

## Part 4: Workflow 3 - Scheduled Follow-Up (Daily Trigger)

Yeh workflow un leads ko follow-up emails bhejta hai jinhone reply nahi kiya.

**Old Flow:** `Schedule Trigger` -> `Google Sheets (Get Rows)` -> `Code` -> `Gmail (Send)` -> `Google Sheets (Update)`

**New Flow:** `Schedule Trigger` -> `Supabase (Select)` -> `Loop` -> `SendGrid (Send)` -> `Supabase (Update)`

### Node-by-Node Changes:

| Old Node (Google Sheets) | New Node (Supabase) | Details |
| :--- | :--- | :--- |
| **2. Get Rows** | **2. Supabase (Select)** | `Schedule Trigger` ke baad, `Supabase` node use karo. **Resource:** `leads`. **Operation:** `Select`. **Filters** mein yeh conditions lagao:
  - `reply_status` **equals** `no_reply`
  - `last_email_sent_at` **is older than** `4 days` (n8n expression use karke)
  - `stage` **is less than** `3` |
| **5. Update Sheet** | **5. Supabase (Update)** | Loop ke end mein, `Supabase` node (Update) use karo. `stage` ko `stage + 1` se update karo aur `last_email_sent_at` ko current time se update karo. |

| Old Node (Gmail) | New Node (SendGrid) | Details |
| :--- | :--- | :--- |
| **4. Send Email** | **4. SendGrid (Send)** | Loop ke andar, `SendGrid` node use karo. `email_sequences` table se next email (Email 2 ya Email 3) ka content fetch karke bhejo. Yahan bhi `X-Manus-Lead-ID` custom header zaroor bhejna. |

---

Yeh changes karne ke baad, aapka AI SDR system poori tarah se Supabase aur SendGrid par chalega. Isse aapko behtar performance, scalability, aur control milega.
