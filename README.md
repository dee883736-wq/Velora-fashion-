# VÉLORA — Live Store + Admin

This package contains the storefront, secure admin panel, Supabase configuration, and SQL setup.

## Files
- `index.html` — customer storefront
- `admin.html` — admin dashboard/login
- `config.js` — Supabase project URL + publishable key
- `supabase.sql` — database, RLS, storage bucket and tracking function

## Supabase setup
1. Open Supabase SQL Editor.
2. Run **all** of `supabase.sql`.
3. In Supabase Authentication, create an admin user with email/password.
4. Copy that user's UUID from Authentication and run:
   `insert into public.admin_users(user_id) values ('YOUR_USER_UUID');`
5. The admin can then log in at `/admin.html`.

The frontend uses the Supabase **publishable/anon** key only. Never put a `service_role` key in this project.

## GitHub + Netlify
1. Create a GitHub repository.
2. Upload all four files.
3. In Netlify choose **Add new site → Import an existing project → GitHub**.
4. Select the repository.
5. Build command: leave empty.
6. Publish directory: `/` (root).
7. Deploy.

Your customer website will open at the Netlify site root and the admin panel at `/admin.html`.

## Live features
- Products load from Supabase.
- Admin can add products and upload up to 5 images each.
- Product deletion.
- Customer cart with local persistence.
- Customer checkout creates live orders in Supabase.
- Admin sees live orders and can update status.
- Customer can track an order by order ID.
- Customer feedback/rating submission.
- Realtime admin refresh for products/orders.
