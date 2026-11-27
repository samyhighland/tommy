-- TOMMY WEARS database schema (Supabase / PostgreSQL)
-- Run once in a new project's SQL Editor. Safe to re-run for the objects below.

create extension if not exists pgcrypto;

create table if not exists public.store_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text not null default '',
  price numeric(12,2) not null default 0 check (price >= 0),
  compare_at_price numeric(12,2) check (compare_at_price is null or compare_at_price >= 0),
  category text not null default 'Uncategorized',
  gender text not null default 'Unisex' check (gender in ('Men','Women','Unisex')),
  sizes text[] not null default '{}',
  colours text[] not null default '{}',
  stock integer not null default 0 check (stock >= 0),
  images text[] not null default '{}',
  featured boolean not null default false,
  is_new boolean not null default false,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_requests (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  phone text not null,
  delivery_city text not null default '',
  delivery_address text not null default '',
  items jsonb not null default '[]'::jsonb,
  subtotal numeric(12,2) not null default 0 check (subtotal >= 0),
  customer_note text not null default '',
  status text not null default 'new' check (status in ('new','contacted','confirmed','fulfilled','cancelled')),
  created_at timestamptz not null default now(),
  constraint order_requests_customer_name_length check (char_length(trim(customer_name)) between 2 and 120),
  constraint order_requests_phone_length check (char_length(trim(phone)) between 7 and 30),
  constraint order_requests_items_array check (jsonb_typeof(items) = 'array')
);

create index if not exists products_active_sort_idx on public.products(is_active, featured desc, sort_order, created_at desc);
create index if not exists products_category_idx on public.products(category);
create index if not exists products_gender_idx on public.products(gender);

create or replace function public.tommy_set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists tommy_products_updated_at on public.products;
create trigger tommy_products_updated_at
before update on public.products
for each row execute function public.tommy_set_updated_at();

alter table public.products enable row level security;
alter table public.store_admins enable row level security;
alter table public.order_requests enable row level security;

-- Least-privilege table grants. Row-level policies below still decide which rows are visible.
revoke all on table public.products from anon, authenticated;
grant select on table public.products to anon, authenticated;
grant insert, update, delete on table public.products to authenticated;

revoke all on table public.store_admins from anon, authenticated;
grant select on table public.store_admins to authenticated;

revoke all on table public.order_requests from anon, authenticated;
grant insert on table public.order_requests to anon, authenticated;
grant select, update on table public.order_requests to authenticated;

-- Product visibility: visitors see active products; an admin can also see hidden products.
drop policy if exists "Admins can view all products" on public.products;
drop policy if exists "Public can view active products" on public.products;
drop policy if exists "Storefront and admins can view products" on public.products;
create policy "Storefront and admins can view products" on public.products
for select to anon, authenticated
using (
  is_active = true
  or exists (select 1 from public.store_admins a where a.user_id = (select auth.uid()))
);

drop policy if exists "Admins can insert products" on public.products;
create policy "Admins can insert products" on public.products
for insert to authenticated
with check (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));

drop policy if exists "Admins can update products" on public.products;
create policy "Admins can update products" on public.products
for update to authenticated
using (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())))
with check (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));

drop policy if exists "Admins can delete products" on public.products;
create policy "Admins can delete products" on public.products
for delete to authenticated
using (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));

drop policy if exists "Admins can read own admin record" on public.store_admins;
create policy "Admins can read own admin record" on public.store_admins
for select to authenticated using (user_id = (select auth.uid()));

-- Order requests can be submitted by a shopper, but only an admin can read or update them.
drop policy if exists "Public can submit order requests" on public.order_requests;
create policy "Public can submit order requests" on public.order_requests
for insert to anon, authenticated
with check (
  char_length(trim(customer_name)) between 2 and 120
  and char_length(trim(phone)) between 7 and 30
  and jsonb_typeof(items) = 'array'
);
drop policy if exists "Admins can view order requests" on public.order_requests;
create policy "Admins can view order requests" on public.order_requests
for select to authenticated
using (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));
drop policy if exists "Admins can update order requests" on public.order_requests;
create policy "Admins can update order requests" on public.order_requests
for update to authenticated
using (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())))
with check (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('product-images','product-images',true,10485760,array['image/jpeg','image/png','image/webp','image/avif'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can view product images" on storage.objects;
create policy "Public can view product images" on storage.objects
for select to anon, authenticated using (bucket_id = 'product-images');

drop policy if exists "Admins can upload product images" on storage.objects;
create policy "Admins can upload product images" on storage.objects
for insert to authenticated
with check (bucket_id = 'product-images' and exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));

drop policy if exists "Admins can update product images" on storage.objects;
create policy "Admins can update product images" on storage.objects
for update to authenticated
using (bucket_id = 'product-images' and exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())))
with check (bucket_id = 'product-images' and exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));

drop policy if exists "Admins can delete product images" on storage.objects;
create policy "Admins can delete product images" on storage.objects
for delete to authenticated
using (bucket_id = 'product-images' and exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));
