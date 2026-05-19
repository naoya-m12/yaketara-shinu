create table if not exists public.app_data (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.app_data enable row level security;

drop policy if exists "app_data_read" on public.app_data;
drop policy if exists "app_data_insert" on public.app_data;
drop policy if exists "app_data_update" on public.app_data;
drop policy if exists "app_data_delete" on public.app_data;

drop function if exists public.get_app_data(text);
drop function if exists public.upsert_app_data(text, jsonb);

revoke all on public.app_data from anon;

create or replace function public.get_app_data(p_id text)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select data
  from public.app_data
  where id = p_id
  limit 1;
$$;

create or replace function public.upsert_app_data(p_id text, p_data jsonb)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.app_data (id, data, updated_at)
  values (p_id, p_data, now())
  on conflict (id)
  do update set
    data = excluded.data,
    updated_at = excluded.updated_at;
$$;

grant execute on function public.get_app_data(text) to anon;
grant execute on function public.upsert_app_data(text, jsonb) to anon;
