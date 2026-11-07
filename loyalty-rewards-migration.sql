-- Run once in Supabase Dashboard > SQL Editor before using SERA loyalty rewards.
alter table public.orders
  add column if not exists loyalty_points integer not null default 0 check (loyalty_points >= 0),
  add column if not exists loyalty_discount numeric(12,2) not null default 0 check (loyalty_discount >= 0),
  add column if not exists loyalty_credited_at timestamptz;
