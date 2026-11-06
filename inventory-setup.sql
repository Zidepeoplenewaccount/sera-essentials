-- Run this migration once in Supabase Dashboard > SQL Editor.
-- SERA product inventory and promotion controls.
-- starting_stock is the count you enter when setting up/reconciling each product.
-- Remaining stock = starting_stock minus verified units sold.

create table if not exists public.product_inventory (
  product_id text primary key,
  product_name text not null,
  starting_stock integer not null default 0 check (starting_stock >= 0),
  low_stock_threshold integer not null default 5 check (low_stock_threshold >= 0),
  discount_price numeric(12,2),
  updated_at timestamptz not null default now(),
  check (discount_price is null or discount_price >= 0)
);

alter table public.product_inventory enable row level security;

drop policy if exists "SERA admins manage product inventory" on public.product_inventory;
create policy "SERA admins manage product inventory"
on public.product_inventory for all to authenticated
using (public.is_sera_admin())
with check (public.is_sera_admin());

drop policy if exists "Public can read product promotions" on public.product_inventory;
create policy "Public can read product promotions"
on public.product_inventory for select to anon, authenticated
using (discount_price is not null);
