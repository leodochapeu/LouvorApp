-- Louvor App — Supabase schema
--
-- How to use:
--   1. Create a project at https://supabase.com
--   2. Open the SQL editor and run this whole file once
--   3. Copy the Project URL and anon public key into your local `.env`
--      (see .env.example)
--   4. Create user accounts manually under Authentication -> Users.
--      There is no public sign-up flow: only people you add there can log
--      in and edit songs. Everyone else can still read the public list.
--
-- Safe to re-run: every statement uses IF NOT EXISTS / OR REPLACE / DROP
-- POLICY IF EXISTS where applicable.

-- ---------------------------------------------------------------------
-- Table
-- ---------------------------------------------------------------------
create table if not exists public.songs (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  authors      text[] not null default '{}'::text[],
  original_key text not null,              -- "Tom original", e.g. "C"
  current_key  text,                       -- "Tom alterado", nullable
  lyrics       text not null default '',   -- letra + cifra (plain text)
  created_by   uuid references auth.users (id) on delete set null default auth.uid(),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

comment on table public.songs is 'Worship songs: title, authors, key(s) and lyrics/chords.';

-- ---------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------
create index if not exists songs_title_lower_idx on public.songs (lower(title));
create index if not exists songs_authors_gin_idx on public.songs using gin (authors);

-- ---------------------------------------------------------------------
-- Keep updated_at fresh on every UPDATE
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists songs_set_updated_at on public.songs;
create trigger songs_set_updated_at
  before update on public.songs
  for each row
  execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- Row Level Security
--   - Anyone (including anonymous visitors) can read songs.
--   - Only authenticated users can create/update/delete songs.
-- ---------------------------------------------------------------------
alter table public.songs enable row level security;

drop policy if exists "Songs are publicly readable" on public.songs;
create policy "Songs are publicly readable"
  on public.songs for select
  to anon, authenticated
  using (true);

drop policy if exists "Authenticated users can insert songs" on public.songs;
create policy "Authenticated users can insert songs"
  on public.songs for insert
  to authenticated
  with check (true);

drop policy if exists "Authenticated users can update songs" on public.songs;
create policy "Authenticated users can update songs"
  on public.songs for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists "Authenticated users can delete songs" on public.songs;
create policy "Authenticated users can delete songs"
  on public.songs for delete
  to authenticated
  using (true);

-- ---------------------------------------------------------------------
-- Realtime: let the app stream live changes to the songs list
-- ---------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'songs'
  ) then
    alter publication supabase_realtime add table public.songs;
  end if;
end $$;
