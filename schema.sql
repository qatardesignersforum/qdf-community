-- QDF production starter schema
-- Run this in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role text not null default '',
  workplace text not null default '',
  accommodation_area text not null default '',
  whatsapp text not null default '',
  email text not null default '',
  bio text not null default '',
  freelance_available boolean not null default false,
  profile_photo_url text,
  cv_url text,
  approved boolean not null default false,
  is_admin boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.portfolio_projects (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text not null default '',
  category text not null default '',
  client_name text,
  project_year integer,
  created_at timestamptz not null default now()
);

create table if not exists public.portfolio_images (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.portfolio_projects(id) on delete cascade,
  storage_path text not null,
  image_url text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  followed_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followed_id),
  check (follower_id <> followed_id)
);

create table if not exists public.portfolio_ratings (
  id uuid primary key default gen_random_uuid(),
  portfolio_owner_id uuid not null references public.profiles(id) on delete cascade,
  rater_id uuid not null references public.profiles(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  created_at timestamptz not null default now(),
  unique (portfolio_owner_id, rater_id)
);

create table if not exists public.discussions (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  category text not null default 'General',
  created_at timestamptz not null default now()
);

create table if not exists public.discussion_replies (
  id uuid primary key default gen_random_uuid(),
  discussion_id uuid not null references public.discussions(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  event_date date,
  description text not null default '',
  created_at timestamptz not null default now()
);

-- Helper: current user's profile
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select is_admin from public.profiles where id = auth.uid()), false);
$$;

alter table public.profiles enable row level security;
alter table public.portfolio_projects enable row level security;
alter table public.portfolio_images enable row level security;
alter table public.follows enable row level security;
alter table public.portfolio_ratings enable row level security;
alter table public.discussions enable row level security;
alter table public.discussion_replies enable row level security;
alter table public.events enable row level security;

-- Profiles: approved profiles are readable to authenticated users.
create policy "approved profiles readable"
on public.profiles for select
using (approved = true or id = auth.uid() or public.is_admin());

create policy "users create own profile"
on public.profiles for insert to authenticated
with check (id = auth.uid());

create policy "users update own profile or admin"
on public.profiles for update to authenticated
using (id = auth.uid() or public.is_admin())
with check (id = auth.uid() or public.is_admin());

-- Portfolio
create policy "approved portfolio readable"
on public.portfolio_projects for select to authenticated
using (exists (select 1 from public.profiles p where p.id = profile_id and (p.approved = true or p.id = auth.uid() or public.is_admin())));

create policy "owner creates portfolio"
on public.portfolio_projects for insert to authenticated
with check (profile_id = auth.uid() or public.is_admin());

create policy "owner updates portfolio"
on public.portfolio_projects for update to authenticated
using (profile_id = auth.uid() or public.is_admin())
with check (profile_id = auth.uid() or public.is_admin());

create policy "owner deletes portfolio"
on public.portfolio_projects for delete to authenticated
using (profile_id = auth.uid() or public.is_admin());

create policy "portfolio images readable"
on public.portfolio_images for select to authenticated
using (exists (select 1 from public.portfolio_projects pp join public.profiles p on p.id = pp.profile_id where pp.id = project_id and (p.approved = true or p.id = auth.uid() or public.is_admin())));

create policy "portfolio images managed by owner"
on public.portfolio_images for all to authenticated
using (exists (select 1 from public.portfolio_projects pp where pp.id = project_id and (pp.profile_id = auth.uid() or public.is_admin())))
with check (exists (select 1 from public.portfolio_projects pp where pp.id = project_id and (pp.profile_id = auth.uid() or public.is_admin())));

-- Follows
create policy "follows readable"
on public.follows for select to authenticated using (true);
create policy "follow own account"
on public.follows for insert to authenticated with check (follower_id = auth.uid());
create policy "unfollow own account"
on public.follows for delete to authenticated using (follower_id = auth.uid());

-- Ratings
create policy "ratings readable"
on public.portfolio_ratings for select to authenticated using (true);
create policy "rate as yourself"
on public.portfolio_ratings for insert to authenticated with check (rater_id = auth.uid());
create policy "update own rating"
on public.portfolio_ratings for update to authenticated using (rater_id = auth.uid()) with check (rater_id = auth.uid());
create policy "delete own rating"
on public.portfolio_ratings for delete to authenticated using (rater_id = auth.uid());

-- Discussions
create policy "approved members read discussions"
on public.discussions for select to authenticated using (true);
create policy "members create discussions"
on public.discussions for insert to authenticated with check (author_id = auth.uid());
create policy "authors or admin update discussions"
on public.discussions for update to authenticated using (author_id = auth.uid() or public.is_admin()) with check (author_id = auth.uid() or public.is_admin());
create policy "authors or admin delete discussions"
on public.discussions for delete to authenticated using (author_id = auth.uid() or public.is_admin());

create policy "read replies"
on public.discussion_replies for select to authenticated using (true);
create policy "members create replies"
on public.discussion_replies for insert to authenticated with check (author_id = auth.uid());
create policy "authors or admin update replies"
on public.discussion_replies for update to authenticated using (author_id = auth.uid() or public.is_admin()) with check (author_id = auth.uid() or public.is_admin());
create policy "authors or admin delete replies"
on public.discussion_replies for delete to authenticated using (author_id = auth.uid() or public.is_admin());

-- Events: readable to authenticated users; admins manage.
create policy "events readable"
on public.events for select to authenticated using (true);
create policy "admins manage events"
on public.events for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Storage buckets. The dashboard can also be used to create these if needed.
insert into storage.buckets (id, name, public) values ('qdf-profiles', 'qdf-profiles', false) on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('qdf-cvs', 'qdf-cvs', false) on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('qdf-portfolio', 'qdf-portfolio', false) on conflict (id) do nothing;

-- Storage object policies: each member may manage files inside a folder named with their auth user id.
create policy "members upload own profile files"
on storage.objects for insert to authenticated
with check (bucket_id in ('qdf-profiles','qdf-cvs','qdf-portfolio') and (storage.foldername(name))[1] = auth.uid()::text);

create policy "members read own private files"
on storage.objects for select to authenticated
using (bucket_id in ('qdf-profiles','qdf-cvs','qdf-portfolio') and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

create policy "members update own files"
on storage.objects for update to authenticated
using (bucket_id in ('qdf-profiles','qdf-cvs','qdf-portfolio') and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()))
with check (bucket_id in ('qdf-profiles','qdf-cvs','qdf-portfolio') and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

create policy "members delete own files"
on storage.objects for delete to authenticated
using (bucket_id in ('qdf-profiles','qdf-cvs','qdf-portfolio') and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));
