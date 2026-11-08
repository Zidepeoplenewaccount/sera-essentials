-- SERA guest Play & Earn rewards.
-- Run once in Supabase Dashboard > SQL Editor.
-- Guest IDs are generated in the visitor's browser; no customer profile is required.

create table if not exists public.sera_guest_reward_plays (
  guest_id uuid not null,
  play_date date not null,
  points integer not null default 1 check (points = 1),
  played_at timestamptz not null default now(),
  primary key (guest_id, play_date)
);

alter table public.sera_guest_reward_plays enable row level security;
revoke all on public.sera_guest_reward_plays from public, anon, authenticated;

create or replace function public.sera_guest_reward_status(p_guest_id uuid)
returns table(total_points bigint, played_today boolean)
language sql
security definer
set search_path = public, pg_temp
as $$
  select
    (select count(*) from public.sera_guest_reward_plays p where p.guest_id = p_guest_id)::bigint,
    exists (
      select 1 from public.sera_guest_reward_plays p
      where p.guest_id = p_guest_id
        and p.play_date = (now() at time zone 'Africa/Lagos')::date
    );
$$;

create or replace function public.sera_play_daily_reward(p_guest_id uuid)
returns table(total_points bigint, played_today boolean, points_awarded integer)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_today date := (now() at time zone 'Africa/Lagos')::date;
  v_inserted integer := 0;
  v_total bigint := 0;
begin
  if p_guest_id is null then
    raise exception 'A valid guest rewards ID is required';
  end if;

  insert into public.sera_guest_reward_plays (guest_id, play_date, points)
  values (p_guest_id, v_today, 1)
  on conflict (guest_id, play_date) do nothing;

  get diagnostics v_inserted = row_count;

  select count(*) into v_total
  from public.sera_guest_reward_plays
  where guest_id = p_guest_id;

  return query select v_total, true, v_inserted;
end;
$$;

revoke all on function public.sera_guest_reward_status(uuid) from public;
revoke all on function public.sera_play_daily_reward(uuid) from public;
grant execute on function public.sera_guest_reward_status(uuid) to anon, authenticated;
grant execute on function public.sera_play_daily_reward(uuid) to anon, authenticated;
