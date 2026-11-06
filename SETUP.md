# SERA ESSENTIALS order system setup

The storefront and admin interface are in this repository. Order storage and receipt uploads use Supabase because GitHub Pages is static hosting and must not be used to store private customer information.

## 1. Create the free Supabase project
1. Create a project at https://supabase.com/ and choose the Free plan.
2. In Project Settings > API, copy the Project URL and anon/publishable key.
3. Replace the two placeholders in `supabase-config.js`. The anon/publishable key is intended for browser use; never put a service-role key in this repository.
4. In SQL Editor, run all of `supabase-setup.sql`.

## 2. Create the admin login
1. In Authentication > Users, add an admin user using an email address and a strong password.
2. Copy that user's UUID.
3. In SQL Editor, run: `insert into public.admin_users (user_id) values ('PASTE-ADMIN-UUID');`
4. Do not add ordinary customers to `admin_users`. The admin page requires Supabase authentication and an admin row.

## 3. Add bank transfer details
Edit `PAYMENT_DETAILS` in `supabase-config.js` with SERA's bank name, account name and account number. These are public checkout instructions, not secrets. Confirm the account is a business account you control.

## 4. Publish
Commit/push the repository. Enable GitHub Pages from Settings > Pages > Deploy from a branch > main > /(root). The admin URL will be `/admin/`.

## Order flow
- Customer selects products, enters delivery details, uploads a receipt and submits.
- Receipt goes to a private Supabase Storage bucket. The order is stored with `pending_verification`.
- Admin signs in at `/admin/`, views the receipt through a short-lived signed URL, checks the bank account, and updates the status.
- Admin can open WhatsApp with a pre-filled message to the customer.
- Admin can export order records to CSV.

## Important safeguards and current limitations
- A receipt upload is **not** proof of payment. Verify funds in the bank account before choosing Payment verified.
- Delivery fee is currently recorded as zero and shown as to-be-confirmed. Set the fee with the customer before taking payment, or extend checkout to calculate delivery by location before launch.
- This first version does not automatically message WhatsApp; the admin clicks the WhatsApp button and sends the prepared message.
- GitHub Pages is static hosting. Supabase provides authentication, database and private receipt storage.
- The SQL policies permit anonymous order creation and receipt upload, but only authenticated IDs listed in `admin_users` can read orders and receipts.
- The store does not yet include a payment gateway or automatic bank reconciliation.
