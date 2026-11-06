-- Run this entire file in Supabase Dashboard > SQL Editor.
-- Creates private order records and private payment receipt storage.
create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;

-- Check admin membership without exposing the admin_users table to customers.
create or replace function public.is_sera_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $
  select exists (
    select 1 from public.admin_users
    where user_id = auth.uid()
  );
$;
revoke all on function public.is_sera_admin() from public;
grant execute on function public.is_sera_admin() to authenticated;

create table if not exists public.orders (
  id uuid primary key,
  order_number text not null unique,
  customer_name text not null,
  phone text not null,
  email text,
  delivery_address text not null,
  items jsonb not null,
  subtotal numeric(12,2) not null check (subtotal >= 0),
  delivery_fee numeric(12,2) not null default 0 check (delivery_fee >= 0),
  total numeric(12,2) not null check (total >= 0),
  receipt_path text not null,
  status text not null default 'pending_verification'
    check (status in ('pending_verification','payment_verified','payment_rejected','processing','ordered_from_supplier','dispatched','out_for_delivery','delivered')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.orders enable row level security;

create policy "Public can submit pending orders"
on public.orders for insert to anon, authenticated
with check (status = 'pending_verification' and receipt_path <> '');

create policy "SERA admins can view orders"
on public.orders for select to authenticated
using (public.is_sera_admin());

create policy "SERA admins can update orders"
on public.orders for update to authenticated
using (public.is_sera_admin())
with check (public.is_sera_admin());

-- Create a PRIVATE bucket. Customers can upload a receipt but cannot read receipts.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('payment-receipts', 'payment-receipts', false, 5242880,
  array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict (id) do update set public = false, file_size_limit = 5242880,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "Anyone can upload payment receipt"
on storage.objects for insert to anon, authenticated
with check (bucket_id = 'payment-receipts');

create policy "Only SERA admins can read payment receipts"
on storage.objects for select to authenticated
using (bucket_id = 'payment-receipts' and public.is_sera_admin());

create policy "Only SERA admins can delete payment receipts"
on storage.objects for delete to authenticated
using (bucket_id = 'payment-receipts' and public.is_sera_admin());

-- After creating your admin user in Authentication > Users, copy its UUID
-- and run this once (replace the value; do not share a service-role key):
-- insert into public.admin_users (user_id) values ('YOUR-AUTH-USER-UUID');
