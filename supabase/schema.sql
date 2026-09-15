-- Louvor App — Supabase schema
--
-- How to use:
--   1. Create a project at https://supabase.com
--   2. Open the SQL editor and run this whole file once
--   3. Copy the Project URL and anon public key into your local `.env.json`
--      (see .env.json.example) — passed to Flutter via --dart-define-from-file
--   4. Keep "Allow new users to sign up" enabled under Authentication ->
--      Providers -> Email. The app exposes sign-up only at the hidden
--      /cadastro route (not linked from the UI). Everyone else can still
--      read the public list without an account.
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
  -- letra + cifra: ordered array of {"type": "sessao"|"letra"|"cifra"|"extras", "content": "..."},
  -- one object per line. Built from plain text by LyricsParser (Dart) when a
  -- song is saved; see lib/features/songs/domain/lyrics_parser.dart.
  lyrics       jsonb not null default '[]'::jsonb,
  -- Optional source link (YouTube, Spotify, church site, ...).
  reference_url text,
  -- Unique kebab-case identifier derived from title + authors.
  slug         text,
  created_by   uuid references auth.users (id) on delete set null default auth.uid(),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- Existing installs created before these columns existed.
alter table public.songs add column if not exists reference_url text;
alter table public.songs add column if not exists slug text;

comment on table public.songs is 'Worship songs: title, authors, original key, lyrics/chords, optional reference link and unique slug.';
comment on column public.songs.lyrics is
  'Array of {type, content} objects, one per line: type is sessao|letra|cifra|extras.';
comment on column public.songs.reference_url is
  'Optional reference link for the song (YouTube, etc.).';
comment on column public.songs.slug is
  'Unique kebab-case identifier from title + authors. Prevents duplicate songs.';

-- Migrate an existing `lyrics text` column (from an older run of this
-- script) to jsonb, preserving old content as a single "extras" line
-- instead of dropping it.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'songs'
      and column_name = 'lyrics' and data_type <> 'jsonb'
  ) then
    alter table public.songs
      alter column lyrics drop default;
    alter table public.songs
      alter column lyrics type jsonb using (
        case
          when lyrics is null or lyrics = '' then '[]'::jsonb
          else jsonb_build_array(jsonb_build_object('type', 'extras', 'content', lyrics))
        end
      );
    alter table public.songs
      alter column lyrics set default '[]'::jsonb;
  end if;
end $$;

-- ---------------------------------------------------------------------
-- Slug: kebab-case identifier from title + authors (unique)
-- ---------------------------------------------------------------------
create or replace function public.kebab_slug(input text)
returns text
language sql
immutable
as $$
  select coalesce(
    nullif(
      trim(both '-' from
        regexp_replace(
          regexp_replace(
            translate(
              lower(coalesce(input, '')),
              'áàâãäéèêëíìîïóòôõöúùûüýÿçñ',
              'aaaaaeeeeiiiiooooouuuuyycn'
            ),
            '[^a-z0-9]+', '-', 'g'
          ),
          '-{2,}', '-', 'g'
        )
      ),
      ''
    ),
    'musica'
  );
$$;

create or replace function public.song_slug(p_title text, p_authors text[])
returns text
language sql
immutable
as $$
  select public.kebab_slug(
    concat_ws(
      ' ',
      nullif(trim(coalesce(p_title, '')), ''),
      (
        select string_agg(trimmed, ' ' order by lower(trimmed))
        from (
          select trim(a) as trimmed
          from unnest(coalesce(p_authors, '{}'::text[])) as a
        ) authors
        where trimmed <> ''
      )
    )
  );
$$;

create or replace function public.songs_set_slug()
returns trigger
language plpgsql
as $$
begin
  new.slug := public.song_slug(new.title, new.authors);
  return new;
end;
$$;

drop trigger if exists songs_set_slug on public.songs;
create trigger songs_set_slug
  before insert or update of title, authors
  on public.songs
  for each row
  execute function public.songs_set_slug();

-- Backfill existing rows, then make slug required and unique.
update public.songs
set slug = public.song_slug(title, authors)
where slug is null or btrim(slug) = '';

with ranked as (
  select id, slug,
    row_number() over (partition by slug order by created_at, id) as rn
  from public.songs
  where slug is not null
)
update public.songs s
set slug = s.slug || '-' || left(replace(s.id::text, '-', ''), 8)
from ranked r
where s.id = r.id and r.rn > 1;

alter table public.songs alter column slug set not null;

-- ---------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------
create index if not exists songs_title_lower_idx on public.songs (lower(title));
create index if not exists songs_authors_gin_idx on public.songs using gin (authors);
create index if not exists songs_lyrics_gin_idx on public.songs using gin (lyrics);
create unique index if not exists songs_slug_uidx on public.songs (slug);

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

-- ---------------------------------------------------------------------
-- Cultos (worship services): a dated setlist of already-registered songs
-- ---------------------------------------------------------------------
create table if not exists public.cultos (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  service_date date not null,
  -- Ordered list of song ids (songs.id). Order is the setlist order.
  song_ids     uuid[] not null default '{}'::uuid[],
  created_by   uuid references auth.users (id) on delete set null default auth.uid(),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

comment on table public.cultos is 'Worship services (cultos): title, date and ordered song setlist.';
comment on column public.cultos.song_ids is
  'Ordered array of songs.id. The app resolves full songs from the songs table.';

-- Tom alterado is per culto (each service can play the same song in a
-- different key), not a property of the catalog song.
alter table public.cultos
  add column if not exists song_keys jsonb not null default '{}'::jsonb;

comment on column public.cultos.song_keys is
  'Map of songs.id -> tom alterado for this culto. Songs without an entry use their original_key.';

-- Unique kebab-case identifier from title + service_date, used in share URLs.
alter table public.cultos add column if not exists slug text;

drop function if exists public.culto_slug(text, date);

create or replace function public.culto_slug(p_title text, p_service_date date, p_id uuid)
returns text
language sql
immutable
as $$
  select concat_ws(
    '-',
    coalesce(
      nullif(
        trim(both '-' from
          regexp_replace(
            regexp_replace(
              translate(
                lower(coalesce(p_title, '')),
                'áàâãäéèêëíìîïóòôõöúùûüýÿçñ',
                'aaaaaeeeeiiiiooooouuuuyycn'
              ),
              '[^a-z0-9]+', '-', 'g'
            ),
            '-{2,}', '-', 'g'
          )
        ),
        ''
      ),
      'culto'
    ),
    to_char(p_service_date, 'DD-MM'),
    p_id::text
  );
$$;

create or replace function public.cultos_set_slug()
returns trigger
language plpgsql
as $$
begin
  new.slug := public.culto_slug(new.title, new.service_date, new.id);
  return new;
end;
$$;

drop trigger if exists cultos_set_slug on public.cultos;
create trigger cultos_set_slug
  before insert or update of title, service_date
  on public.cultos
  for each row
  execute function public.cultos_set_slug();

update public.cultos
set slug = public.culto_slug(title, service_date, id);

alter table public.cultos alter column slug set not null;
create unique index if not exists cultos_slug_uidx on public.cultos (slug);

comment on column public.cultos.slug is
  'Share URL identifier: kebab(title)-DD-MM-<uuid>.';

-- Existing installs stored the play key on songs.current_key. Copy it onto
-- every culto that already lists those songs, then drop the catalog column.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'songs'
      and column_name = 'current_key'
  ) then
    update public.cultos c
    set song_keys = coalesce((
      select jsonb_object_agg(s.id::text, s.current_key)
      from unnest(c.song_ids) as sid
      join public.songs s on s.id = sid
      where s.current_key is not null and btrim(s.current_key) <> ''
    ), '{}'::jsonb)
    where coalesce(c.song_keys, '{}'::jsonb) = '{}'::jsonb;

    alter table public.songs drop column current_key;
  end if;
end $$;

create index if not exists cultos_service_date_idx on public.cultos (service_date desc);
create index if not exists cultos_title_lower_idx on public.cultos (lower(title));

drop trigger if exists cultos_set_updated_at on public.cultos;
create trigger cultos_set_updated_at
  before update on public.cultos
  for each row
  execute function public.set_updated_at();

-- Row Level Security: anyone can read, only authenticated users write.
alter table public.cultos enable row level security;

drop policy if exists "Cultos are publicly readable" on public.cultos;
create policy "Cultos are publicly readable"
  on public.cultos for select
  to anon, authenticated
  using (true);

drop policy if exists "Authenticated users can insert cultos" on public.cultos;
create policy "Authenticated users can insert cultos"
  on public.cultos for insert
  to authenticated
  with check (true);

drop policy if exists "Authenticated users can update cultos" on public.cultos;
create policy "Authenticated users can update cultos"
  on public.cultos for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists "Authenticated users can delete cultos" on public.cultos;
create policy "Authenticated users can delete cultos"
  on public.cultos for delete
  to authenticated
  using (true);

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'cultos'
  ) then
    alter publication supabase_realtime add table public.cultos;
  end if;
end $$;
