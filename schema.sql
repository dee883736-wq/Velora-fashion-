-- VÉLORA E-COMMERCE: Supabase setup / repair
-- Run this whole script in Supabase SQL Editor.

create extension if not exists pgcrypto;

-- PRODUCTS
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

alter table public.products add column if not exists image text;
alter table public.products add column if not exists images jsonb not null default '[]'::jsonb;
alter table public.products add column if not exists discount numeric not null default 0;
alter table public.products add column if not exists active boolean not null default true;
alter table public.products add column if not exists created_at timestamptz not null default now();

-- ORDERS
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_code text unique not null,
  customer_name text not null,
  phone text not null,
  address text not null,
  pincode text not null,
  payment_method text not null default 'cod',
  total numeric not null default 0,
  status text not null default 'placed',
  items jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.orders add column if not exists order_code text;
alter table public.orders add column if not exists customer_name text;
alter table public.orders add column if not exists phone text;
alter table public.orders add column if not exists address text;
alter table public.orders add column if not exists pincode text;
alter table public.orders add column if not exists payment_method text default 'cod';
alter table public.orders add column if not exists total numeric default 0;
alter table public.orders add column if not exists status text default 'placed';
alter table public.orders add column if not exists items jsonb default '[]'::jsonb;
alter table public.orders add column if not exists created_at timestamptz default now();

create unique index if not exists orders_order_code_uidx
on public.orders(order_code);

-- RLS
alter table public.products enable row level security;
alter table public.orders enable row level security;

-- Clean up policies created by earlier versions.
drop policy if exists "products_public_read" on public.products;
drop policy if exists "products_admin_all" on public.products;
drop policy if exists "orders_public_insert" on public.orders;
drop policy if exists "orders_admin_all" on public.orders;

-- Customers can read active products.
create policy "products_public_read"
on public.products
for select
to anon, authenticated
using (active = true);

-- Logged-in admin can manage products.
create policy "products_admin_all"
on public.products
for all
to authenticated
using (true)
with check (true);

-- Customers may create an order.
-- IMPORTANT: this does NOT allow customers to read all orders.
create policy "orders_public_insert"
on public.orders
for insert
to anon, authenticated
with check (
  length(trim(customer_name)) between 2 and 100
  and length(trim(phone)) between 7 and 20
  and length(trim(address)) between 5 and 500
  and length(trim(pincode)) between 4 and 10
  and payment_method in ('cod','online')
  and status = 'placed'
  and total >= 0
);

-- Only authenticated admin can read/change orders.
create policy "orders_admin_all"
on public.orders
for all
to authenticated
using (true)
with check (true);

-- STORAGE
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do update set public = true;

drop policy if exists "product_images_public_read" on storage.objects;
drop policy if exists "product_images_admin_insert" on storage.objects;
drop policy if exists "product_images_admin_update" on storage.objects;
drop policy if exists "product_images_admin_delete" on storage.objects;

create policy "product_images_public_read"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'product-images');

create policy "product_images_admin_insert"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'product-images');

create policy "product_images_admin_update"
on storage.objects
for update
to authenticated
using (bucket_id = 'product-images')
with check (bucket_id = 'product-images');

create policy "product_images_admin_delete"
on storage.objects
for delete
to authenticated
using (bucket_id = 'product-images');

-- Optional: enable realtime for admin live updates.
-- If already added, these are harmless.
do $$
begin
  alter publication supabase_realtime add table public.orders;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.products;
exception when duplicate_object then null;
end $$;
