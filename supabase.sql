-- VÉLORA / Supabase setup
-- Run this in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(select 1 from public.admin_users where user_id = auth.uid());
$$;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text,
  price numeric not null default 0,
  discount numeric not null default 0,
  image text,
  images jsonb not null default '[]'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_code text unique not null,
  customer_name text not null,
  phone text not null,
  address text not null,
  pincode text not null,
  payment_method text not null,
  total numeric not null default 0,
  status text not null default 'placed',
  items jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references public.products(id) on delete cascade,
  customer_name text not null default 'Customer',
  rating integer not null check (rating between 1 and 5),
  review_text text default '',
  created_at timestamptz not null default now()
);

alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.reviews enable row level security;
alter table public.admin_users enable row level security;

-- Public storefront: active products only.
drop policy if exists "public read active products" on public.products;
create policy "public read active products" on public.products
for select to anon, authenticated using (active = true or public.is_admin());

-- Admin product management.
drop policy if exists "admins manage products" on public.products;
create policy "admins manage products" on public.products
for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Customers can place orders; only admins can read/update them directly.
drop policy if exists "public create orders" on public.orders;
create policy "public create orders" on public.orders
for insert to anon, authenticated with check (true);

drop policy if exists "admins manage orders" on public.orders;
create policy "admins manage orders" on public.orders
for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Customers can submit feedback; admins can read/manage reviews.
drop policy if exists "public create reviews" on public.reviews;
create policy "public create reviews" on public.reviews
for insert to anon, authenticated with check (rating between 1 and 5);

drop policy if exists "admins manage reviews" on public.reviews;
create policy "admins manage reviews" on public.reviews
for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Safe public order tracking: returns only tracking fields.
create or replace function public.track_order(p_order_code text)
returns table(order_code text, status text, customer_name text)
language sql
security definer
set search_path = public
as $$
  select o.order_code, o.status, o.customer_name
  from public.orders o
  where o.order_code = p_order_code
  limit 1;
$$;

grant execute on function public.track_order(text) to anon, authenticated;

-- Storage bucket for product images.
insert into storage.buckets (id, name, public)
values ('product-images','product-images',true)
on conflict (id) do update set public=true;

drop policy if exists "public view product images" on storage.objects;
create policy "public view product images" on storage.objects
for select to anon, authenticated using (bucket_id='product-images');

drop policy if exists "admins upload product images" on storage.objects;
create policy "admins upload product images" on storage.objects
for insert to authenticated with check (bucket_id='product-images' and public.is_admin());

drop policy if exists "admins update product images" on storage.objects;
create policy "admins update product images" on storage.objects
for update to authenticated using (bucket_id='product-images' and public.is_admin()) with check (bucket_id='product-images' and public.is_admin());

drop policy if exists "admins delete product images" on storage.objects;
create policy "admins delete product images" on storage.objects
for delete to authenticated using (bucket_id='product-images' and public.is_admin());

-- After creating the admin account in Supabase Authentication, replace YOUR_USER_UUID below
-- with that user's UUID and run it once:
-- insert into public.admin_users(user_id) values ('YOUR_USER_UUID');

-- Optional starter products can be added from the admin panel instead.
