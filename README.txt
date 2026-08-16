VELORA FIXED LIVE PACKAGE

1. Keep index.html, admin.html, config.js, supabase.sql in the same folder.
2. Replace config.js with YOUR CURRENT Supabase URL + Publishable/anon key if needed.
3. Run supabase.sql in the NEW Supabase project's SQL Editor.
4. In Supabase Authentication > Users, create the admin email/password.
5. Copy that user's UUID and run:
   insert into public.admin_users(user_id) values ('USER-UUID-HERE') on conflict do nothing;
6. Enable Realtime for public.orders and public.products if you want instant admin updates.
7. Deploy the whole folder to Netlify/GitHub. Do not upload only config.js.

Important: index.html now blocks fake success when the order insert fails. It requires name, 10-digit phone, full address and PIN code. admin.html reads the same config.js and requires an authenticated admin account.
