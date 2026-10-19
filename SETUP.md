# Fresh Market

Fresh Market is a React + TypeScript + Vite storefront and admin dashboard. The storefront reads active products from Supabase when connected. Guest cash-on-delivery checkout uses a database function. Customer accounts support email/password sign-up and sign-in, profile details, and order history. Super admins can grant staff roles to existing accounts. Online payments and account password reset are not implemented.

## Run locally

1. Install Node.js 20 or newer.
2. From this folder, run `npm install`.
3. Run `npm run dev` and open the local URL Vite prints.
4. Run `npm run build` to create a production bundle.

## Connect Supabase

1. Create a Supabase project.
2. Copy `.env.example` to `.env.local`.
3. Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` from the Supabase project's API settings. `VITE_SUPABASE_ANON_KEY` is supported as a legacy fallback.
4. Restart the Vite dev server after changing `.env.local`.
5. The initial schema (001) is already applied. In Supabase **SQL Editor**, run migrations 002, 003, 004, 005, 006, and 007 in order (skip any already successfully applied).
6. To add the Bangladesh grocery catalog, run `supabase/seed_bangladesh_catalog.sql`. These products are active and marked as non-demo so checkout can use them. Check the starting stock numbers against your actual inventory before accepting orders. The optional `supabase/seed_demo.sql` is for demo-only sample items.
7. Refresh the storefront. Prices show in taka and checkout is enabled for connected, non-demo catalog products.

## Bangladesh currency and delivery

The storefront accepts delivery addresses across Bangladesh. Checkout asks for the city or district and postal code. Delivery is ৳80, with free delivery on orders of ৳2,500 or more. The same fee currently applies nationwide; confirm courier coverage and serviceability for remote addresses before dispatch. Database prices are stored in poisha (`price_cents`, 100 poisha = ৳1). The Bangladesh catalog seed sets starting quantities and prices; edit them in Admin to match your actual stock and supplier prices.

To allow consecutive orders from the same customer, run `supabase/migrations/202610190001_allow_consecutive_orders.sql` in Supabase SQL Editor. It removes the 15-minute contact-based block while retaining protection against retrying the same checkout request. Add IP rate limiting or CAPTCHA before public launch to reduce checkout spam.

## Customer accounts

Customers use the **Account** button to create an account with a Bangladesh mobile number and password. Signup sends a six-digit SMS code; the mobile number is the login ID. Existing email/password accounts can continue signing in with their email. Profiles are created automatically. Signed-in orders are linked to the account, and verified-phone accounts can claim matching guest orders and review delivered products after applying migration 202610190002.

### Enable customer mobile verification

SMS verification requires a configured SMS provider; Supabase does not send production SMS until this is set up. In Supabase Dashboard, open **Authentication → Sign In / Providers → Phone**, enable phone authentication and phone confirmation, and configure a supported SMS provider (such as Twilio) with its credentials and message template. Check the provider's Bangladesh delivery coverage and rates. Set sensible SMS rate limits and enable CAPTCHA before public launch to reduce abuse. New customers enter their number in local `01XXXXXXXXX` or international `+8801XXXXXXXXX` format; the app normalizes it to E.164 before sending.

After enabling the provider, run `supabase/migrations/202610190002_phone_verified_customer_accounts.sql` in Supabase SQL Editor after migrations 007, 009, 010, 180003, and 190001. It updates secure order, review, and customer-directory functions, and allows checkout without an email. Existing email-based users do not need to recreate their accounts.

## Enable product management in Admin

The `/admin` dashboard requires an active staff account. Create your first customer account from the storefront's **Account → Create account** flow. In Supabase **Authentication → Users**, copy that user's UUID, then run this once in **SQL Editor**, replacing the placeholder to bootstrap the first super admin:

```sql
insert into public.staff_roles (user_id, role, active)
values ('<AUTH_USER_UUID>', 'super_admin', true);
```

Open `/admin` and sign in. The super admin sees the **Staff** area, where they can grant or deactivate staff roles for existing customer accounts by email. Store managers and super admins can use the live **Customers** directory. New users first create customer accounts through the storefront. The database restricts staff management to super admins and customer directory access to store managers/super admins; catalog changes require a staff role allowed by RLS.

If a staff row shows **No email** or **Fresh Market user**, run `supabase/migrations/202610180016_staff_list_auth_details.sql` in the Supabase SQL Editor. The superadmin-only staff-list RPC then falls back to the account's Auth email and signup name when profile fields are empty.

The configured publishable key was verified against the Supabase catalog. Do not place a service-role/secret key in any `VITE_*` variable.

The migration is a foundation, not a complete production commerce backend. Before public launch, add edge-level IP rate limiting or CAPTCHA to guest checkout, then implement coupon validation/redemption, payment webhooks with signature verification, cancellation stock restoration, safe staff invitations, and exports. Expand and review RLS for each workflow. Do not create customer orders through unrestricted client table inserts.

## Environment variables

- `VITE_SUPABASE_URL` — project URL.
- `VITE_SUPABASE_PUBLISHABLE_KEY` — preferred public key.
- `VITE_SUPABASE_ANON_KEY` — legacy public key fallback.

Payment secrets, service-role credentials, email provider secrets, and webhook signing secrets belong only in server-side secret storage.

## Live admin data and inventory

The Overview and Reports screens read live orders from Supabase. Inventory stock changes are recorded transactionally. Run `supabase/migrations/202610180013_inventory_adjustment.sql` in the Supabase SQL Editor to enable staff-authorized stock adjustments. Coupon records are managed in Supabase, but checkout coupon redemption is not enabled, so created codes do not discount orders yet.



## Current demo limitations

- Storefront navigation, search, category filtering, sorting, wishlist toggles, stock-limited quantities, and local basket persistence work.
- Supabase integration reads the active product catalog. Admin product create/edit requires a signed-in account with an active staff role.
- Overview and Reports use live Supabase orders; Inventory updates require migration 013. Customer records load from Supabase after migration 007.
- Guest COD orders are created by the Supabase RPC after migration 003. Customer profiles and account order history require migration 004. Password reset, coupon redemption in checkout, review moderation, audit writes, and online payments are not connected. Staff role management requires migration 006.
- Demo product and hero images use Unsplash and need internet access.

## Store branding

To let the super admin edit the store name and upload a logo from **Admin → Settings**, run `supabase/migrations/202610180004_store_branding.sql` in the Supabase SQL Editor. This creates the public logo bucket and read policy; upload, replacement, and removal permissions are limited to super admins.

## English and Bangla product names

The storefront language switch includes English and Bangla. Run `supabase/migrations/202610180015_bengali_product_names.sql` in Supabase SQL Editor to add Bangla names to the product catalog and prefill names for the Bangladesh starter products. When adding or editing a product in Admin, fill **Product name in Bangla** to show its Bangla name when the storefront language is set to Bangla.

## Customer profile photos

Run `supabase/migrations/202610170008_customer_avatars.sql` in the Supabase SQL Editor. It creates the `customer-avatars` public image bucket, permits public image reads, and limits uploads, replacements, and deletes to each signed-in customer’s own folder. Signed-in customers can upload a JPG, PNG, WebP, or GIF up to 5 MB from Account → Profile photo. The photo is saved to Supabase Storage and shown beside the customer profile.

## Customer order history and live status

Run `supabase/migrations/202610170009_customer_order_history.sql` in the Supabase SQL Editor. The account page then reads its orders through a restricted function. It can attach old guest checkout orders to a customer only when the guest email matches that signed-in account's verified email. New orders created while signed in remain associated with the account. The account view refreshes status every 10 seconds while open.

## Order item photos

Run `supabase/migrations/202610170010_order_item_photos.sql` after migration 009. It adds saved catalog image references to the secure customer order-history response so expanded orders can display product photos.

## Manual mobile-money payments

Checkout supports cash on delivery and manual bKash, Nagad, Rocket, and Upay transfers. Customers send the order total to the configured personal number and enter the transaction ID. Orders remain pending until staff verify the transfer.

1. Run `supabase/migrations/202610170012_manual_mobile_money.sql` in the Supabase SQL Editor. It initializes the recipient number to `01811111111`, allows the storefront to read only that public setting, and creates the validated order RPC. The existing `store_settings` policy permits only superadmins to change the number.
2. Deploy the updated storefront. No aamarPay secrets are needed for manual mobile-money payments.
3. Sign into the admin dashboard as a superadmin, open **Settings**, and change the shared recipient number when needed.
4. In **Orders**, verify the submitted transaction ID in the relevant provider app, then change the payment status to **paid**. Keep it pending until verified.



## Product image uploads

Run `supabase/migrations/202610180002_product_image_storage.sql` in Supabase SQL Editor to create the public `product-images` bucket and allow authorized catalog staff to upload product images. Admin → Products → Add product accepts JPG, PNG, and WebP files up to 5 MB; the uploaded image is attached to the product record.


## Customer product reviews

Run supabase/migrations/202610180003_verified_product_reviews.sql in the Supabase SQL Editor. Customers can open a product by selecting its image, name, or rating, then submit one review per product after signing in with a verified email and a delivered order containing that product. Approved reviews update the product-card rating automatically.
