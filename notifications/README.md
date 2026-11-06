# SERA order email notifications (free Gmail setup)

This setup sends an email to **enibeedboss@gmail.com** whenever a new row is inserted into `public.orders` in Supabase.

It uses Google Apps Script and Gmail's included sending quota. No paid email service, Supabase service-role key, or storefront secret is required. Google account and Apps Script quotas apply, so this is suitable for normal small-store order volumes rather than bulk email.

## 1. Create the Google Apps Script

1. Sign in to the Google account that should send the notifications.
2. Open [script.google.com](https://script.google.com/) and choose **New project**.
3. Replace the editor contents with the code in `notifications/sera-order-email.gs`.
4. Open **Project Settings** (gear icon).
5. Under **Script Properties**, add:
   - Property: `SERA_WEBHOOK_SECRET`
   - Value: create a long random secret (at least 32 characters). Keep it private; do not put it in GitHub or the website.
6. Save the project. Give it a name such as **SERA Order Notifications**.

## 2. Deploy the script as a web app

1. Select **Deploy → New deployment**.
2. Choose type **Web app**.
3. Set **Execute as** to **Me**.
4. Set **Who has access** to **Anyone** so Supabase can reach the endpoint. The long secret in the URL is checked by the script.
5. Deploy and approve Google's permission prompt to send email from your account.
6. Copy the Web app URL ending in `/exec`. Do not paste the secret into the script code.

## 3. Add the Supabase Database Webhook

1. Open the SERA Supabase project.
2. Go to **Database → Webhooks** (the menu may appear under Database).
3. Create a webhook:
   - Name: `sera-new-order-email`
   - Table: `public.orders`
   - Events: **INSERT only**
   - Type/method: **HTTP POST**
   - URL: your Apps Script `/exec` URL followed by `?key=` and the exact secret you saved in Script Properties.
   - Header, if the form asks for one: `Content-Type: application/json`
4. Save the webhook.

The webhook must listen only for **INSERT**. Do not enable UPDATE, otherwise every order status change could send another new-order email.

## 4. Test it

Place a low-value test order through the real SERA checkout using the normal process. Confirm:
- An email arrives at **enibeedboss@gmail.com**.
- The email includes the order number, customer details, delivery address, items, quantities, variants, subtotal, delivery fee and total.
- The email clearly says payment is still awaiting verification.

The email is only an alert. It does **not** verify a bank transfer or change an order's status. Continue verifying payments in the SERA admin dashboard.

## Important security notes

- Never put the secret or a Supabase service-role key in frontend JavaScript or a public repository.
- If the webhook URL/secret is exposed, generate a new secret in Apps Script Properties and update the Supabase webhook URL.
- This sends order details to the specified Gmail inbox. Restrict access to that inbox.
- Apps Script and Gmail have sending quotas and Google can change them. This is free within the account's current quota, not an unlimited email service.
