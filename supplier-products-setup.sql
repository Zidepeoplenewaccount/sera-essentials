-- Run once in Supabase SQL Editor to add SERA's supplier product draft workflow.
create table if not exists public.supplier_product_drafts (
  id uuid primary key default gen_random_uuid(),
  supplier text not null check (supplier in ('AliExpress','Temu')),
  supplier_url text not null,
  supplier_product_id text,
  title text not null,
  description text,
  image_urls jsonb not null default '[]'::jsonb,
  supplier_price numeric(12,2),
  supplier_currency text,
  rating numeric(3,2),
  review_count integer,
  sold_count integer,
  shipping_info jsonb not null default '{}'::jsonb,
  selling_price numeric(12,2),
  status text not null default 'draft' check (status in ('draft','approved','rejected')),
  source_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (supplier, supplier_product_id)
);
alter table public.supplier_product_drafts enable row level security;
drop policy if exists "SERA admins manage supplier drafts" on public.supplier_product_drafts;
create policy "SERA admins manage supplier drafts"
on public.supplier_product_drafts for all to authenticated
using (public.is_sera_admin())
with check (public.is_sera_admin());
