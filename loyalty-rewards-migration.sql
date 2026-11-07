-- Run once in Supabase Dashboard > SQL Editor before using SERA loyalty rewards.
alter table public.orders
  add column if not exists loyalty_points integer not null default 0 check (loyalty_points >= 0),
  add column if not exists loyalty_discount numeric(12,2) not null default 0 check (loyalty_discount >= 0),
  add column if not exists loyalty_credited_at timestamptz;

-- Discount codes are issued by SERA admins and tied to the customer's WhatsApp number.
alter table public.orders
  add column if not exists discount_code text,
  add column if not exists discount_amount numeric(12,2) not null default 0 check (discount_amount >= 0);

create table if not exists public.sera_discount_codes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  phone_digits text not null,
  points integer not null check (points >= 6 and points % 6 = 0),
  discount_amount numeric(12,2) not null check (discount_amount > 0),
  status text not null default 'issued' check (status in ('issued','reserved','redeemed','expired')),
  order_id uuid references public.orders(id) on delete set null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '90 days'),
  redeemed_at timestamptz
);
alter table public.sera_discount_codes enable row level security;
revoke all on public.sera_discount_codes from anon, authenticated;

create or replace function public.sera_phone_digits(p_phone text)
returns text language sql immutable as $$
 select regexp_replace(coalesce(p_phone,''),'[^0-9]','','g')
$$;

create or replace function public.sera_issue_discount_code(p_phone text,p_points integer)
returns table(code text,discount_amount numeric,points integer,expires_at timestamptz)
language plpgsql security definer set search_path=public,pg_temp as $$
declare v_phone text; v_balance integer; v_code text;
begin
 if not public.is_sera_admin() then raise exception 'Admin access required'; end if;
 v_phone:=public.sera_phone_digits(p_phone);
 if length(v_phone)<10 then raise exception 'Enter a valid customer phone number'; end if;
 if p_points is null or p_points<6 or p_points%6<>0 then raise exception 'Redeem points in multiples of 6'; end if;
 select coalesce(sum(o.loyalty_points),0)::integer into v_balance from public.orders o
 where public.sera_phone_digits(o.phone)=v_phone and o.loyalty_credited_at is not null
 and o.status in ('payment_verified','processing','ordered_from_supplier','dispatched','out_for_delivery','delivered');
 v_balance:=v_balance-coalesce((select sum(c.points)::integer from public.sera_discount_codes c where c.phone_digits=v_phone and c.status in ('issued','reserved','redeemed')),0);
 if p_points>v_balance then raise exception 'Customer only has % unredeemed points available',greatest(v_balance,0); end if;
 v_code:='SERA-'||upper(substr(encode(gen_random_bytes(5),'hex'),1,8));
 insert into public.sera_discount_codes(code,phone_digits,points,discount_amount)
 values(v_code,v_phone,p_points,(p_points/6)*100);
 return query select v_code,(p_points/6)*100::numeric,p_points,now()+interval '90 days';
end $$;

create or replace function public.sera_validate_discount_code(p_code text,p_phone text)
returns table(discount_amount numeric,points integer)
language sql security definer set search_path=public,pg_temp as $$
 select c.discount_amount,c.points from public.sera_discount_codes c
 where upper(c.code)=upper(trim(p_code)) and c.phone_digits=public.sera_phone_digits(p_phone)
 and c.status='issued' and c.expires_at>now()
$$;

create or replace function public.sera_reserve_discount_code(p_code text,p_phone text,p_order_id uuid)
returns table(discount_amount numeric,points integer)
language plpgsql security definer set search_path=public,pg_temp as $$
begin
 return query update public.sera_discount_codes c set status='reserved',order_id=p_order_id
 where upper(c.code)=upper(trim(p_code)) and c.phone_digits=public.sera_phone_digits(p_phone)
 and c.status='issued' and c.expires_at>now()
 returning c.discount_amount,c.points;
end $$;

create or replace function public.sera_release_discount_code(p_code text,p_order_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
begin
 update public.sera_discount_codes set status='issued',order_id=null
 where upper(code)=upper(trim(p_code)) and order_id=p_order_id and status='reserved';
 return found;
end $$;

create or replace function public.sera_update_discount_code_for_order(p_order_id uuid,p_new_status text)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if not public.is_sera_admin() then raise exception 'Admin access required'; end if;
 if p_new_status in ('payment_verified','processing','ordered_from_supplier','dispatched','out_for_delivery','delivered') then
  update public.sera_discount_codes set status='redeemed',redeemed_at=coalesce(redeemed_at,now()) where order_id=p_order_id and status='reserved';
 elsif p_new_status='payment_rejected' then
  update public.sera_discount_codes set status='issued',order_id=null where order_id=p_order_id and status='reserved';
 end if;
 return found;
end $$;

revoke all on function public.sera_issue_discount_code(text,integer) from public,anon;
revoke all on function public.sera_update_discount_code_for_order(uuid,text) from public,anon;
grant execute on function public.sera_issue_discount_code(text,integer) to authenticated;
grant execute on function public.sera_update_discount_code_for_order(uuid,text) to authenticated;
revoke all on function public.sera_validate_discount_code(text,text) from public;
grant execute on function public.sera_validate_discount_code(text,text) to anon,authenticated;
revoke all on function public.sera_reserve_discount_code(text,text,uuid) from public;
grant execute on function public.sera_reserve_discount_code(text,text,uuid) to anon,authenticated;
revoke all on function public.sera_release_discount_code(text,uuid) from public;
grant execute on function public.sera_release_discount_code(text,uuid) to anon,authenticated;
