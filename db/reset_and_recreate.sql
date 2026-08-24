-- =============================================================================
-- CampusX — FULL DATABASE RESET
-- =============================================================================
-- !! WARNING — THIS IS DESTRUCTIVE AND IRREVERSIBLE !!
-- This drops every table in the `public` schema and every row in them, then
-- recreates the schema from scratch to match what the Flutter app's
-- services/models actually query (lib/services/*.dart, lib/models/*.dart).
--
-- It does NOT touch `auth.users` — your Supabase auth accounts are untouched.
-- Signing in again will re-trigger profile creation via the trigger below.
--
-- Run this in: Supabase Dashboard -> SQL Editor -> New query -> paste -> Run.
-- Take a backup first if you have any data you care about (Dashboard ->
-- Database -> Backups, or `pg_dump` if you're on a paid plan with direct
-- Postgres access).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0. Wipe everything currently in the public schema
-- -----------------------------------------------------------------------------
drop schema if exists public cascade;
create schema public;
grant usage on schema public to postgres, anon, authenticated, service_role;

create extension if not exists "pgcrypto"; -- for gen_random_uuid()

-- -----------------------------------------------------------------------------
-- 1. profiles  (one row per auth.users row)
-- -----------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text unique not null,
  full_name text,
  avatar_url text,
  cover_url text,
  bio text,
  campus text,
  course text,
  year_of_study int,
  is_admin boolean not null default false,
  is_verified boolean not null default false,
  is_banned boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Auto-create a profile row whenever someone signs up (auth_service.dart
-- passes `username` in the signUp `data` payload).
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, username, full_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'username', split_part(new.email, '@', 1)),
    new.raw_user_meta_data ->> 'full_name'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- -----------------------------------------------------------------------------
-- 2. clubs / club_members
-- -----------------------------------------------------------------------------
create table public.clubs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  description text,
  cover_url text,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.club_members (
  club_id uuid not null references public.clubs (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null default 'member',
  joined_at timestamptz not null default now(),
  primary key (club_id, user_id)
);

-- -----------------------------------------------------------------------------
-- 3. posts / comments / likes
-- -----------------------------------------------------------------------------
create table public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id) on delete cascade,
  content text,
  image_urls text[] not null default '{}',
  video_url text,
  is_confession boolean not null default false,
  club_id uuid references public.clubs (id) on delete set null,
  like_count int not null default 0,
  comment_count int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now()
);

create table public.likes (
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

-- Keep posts.like_count / comment_count in sync automatically.
create function public.handle_like_count()
returns trigger language plpgsql as $$
begin
  if (tg_op = 'INSERT') then
    update public.posts set like_count = like_count + 1 where id = new.post_id;
    return new;
  elsif (tg_op = 'DELETE') then
    update public.posts set like_count = greatest(like_count - 1, 0) where id = old.post_id;
    return old;
  end if;
  return null;
end;
$$;

create trigger on_like_change
  after insert or delete on public.likes
  for each row execute function public.handle_like_count();

create function public.handle_comment_count()
returns trigger language plpgsql as $$
begin
  if (tg_op = 'INSERT') then
    update public.posts set comment_count = comment_count + 1 where id = new.post_id;
    return new;
  elsif (tg_op = 'DELETE') then
    update public.posts set comment_count = greatest(comment_count - 1, 0) where id = old.post_id;
    return old;
  end if;
  return null;
end;
$$;

create trigger on_comment_change
  after insert or delete on public.comments
  for each row execute function public.handle_comment_count();

-- -----------------------------------------------------------------------------
-- 4. events / event_rsvps
-- -----------------------------------------------------------------------------
create table public.events (
  id uuid primary key default gen_random_uuid(),
  club_id uuid references public.clubs (id) on delete set null,
  host_id uuid references public.profiles (id) on delete set null,
  title text not null,
  description text,
  location text,
  cover_url text,
  starts_at timestamptz not null,
  ends_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.event_rsvps (
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'going',
  created_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

-- -----------------------------------------------------------------------------
-- 5. marketplace
-- -----------------------------------------------------------------------------
create table public.marketplace_items (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  description text,
  price numeric(12, 2) not null,
  currency text not null default 'UGX',
  image_urls text[] not null default '{}',
  category text,
  status text not null default 'available', -- available | reserved | sold
  created_at timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- 6. conversations / conversation_members / messages
-- -----------------------------------------------------------------------------
create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  is_group boolean not null default false,
  title text,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.conversation_members (
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  content text not null,
  read_by uuid[] not null default '{}',
  created_at timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- 7. notifications
-- -----------------------------------------------------------------------------
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  actor_id uuid references public.profiles (id) on delete set null,
  type text not null, -- like | comment | follow | message | club_invite | event | poll | mention
  entity_id text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- 8. polls / poll_votes
-- -----------------------------------------------------------------------------
create table public.polls (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id) on delete cascade,
  question text not null,
  options text[] not null,
  closes_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.poll_votes (
  poll_id uuid not null references public.polls (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  option_index int not null,
  created_at timestamptz not null default now(),
  primary key (poll_id, user_id)
);

-- -----------------------------------------------------------------------------
-- 9. follows
-- -----------------------------------------------------------------------------
create table public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  following_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

-- -----------------------------------------------------------------------------
-- 10. reports (moderation)
-- -----------------------------------------------------------------------------
-- NOTE: admin_service.dart's fetchReports() embeds `posts(*)`, so target_id is
-- modelled as an FK to posts for post reports. User/comment reports can still
-- be filed with target_type set accordingly; the posts embed is simply null
-- for those rows.
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  target_type text not null, -- 'post' | 'user' | 'comment'
  target_id uuid references public.posts (id) on delete cascade,
  reason text not null,
  status text not null default 'pending', -- pending | resolved | dismissed
  created_at timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- 11. feature_flags / admin_logs
-- -----------------------------------------------------------------------------
create table public.feature_flags (
  key text primary key,
  enabled boolean not null default false,
  description text,
  updated_by uuid references public.profiles (id) on delete set null,
  updated_at timestamptz not null default now()
);

create table public.admin_logs (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references public.profiles (id) on delete set null,
  action text not null,
  target_type text,
  target_id text,
  meta jsonb not null default '{}',
  created_at timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- 12. ai_messages (Pegasus conversation history)
-- -----------------------------------------------------------------------------
create table public.ai_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null, -- 'user' | 'assistant'
  content text not null,
  created_at timestamptz not null default now()
);

-- =============================================================================
-- 13. Indexes for the query patterns the app actually uses
-- =============================================================================
create index idx_posts_feed on public.posts (is_confession, created_at desc);
create index idx_posts_author on public.posts (author_id);
create index idx_comments_post on public.comments (post_id);
create index idx_events_starts_at on public.events (starts_at);
create index idx_marketplace_category on public.marketplace_items (category);
create index idx_messages_conversation on public.messages (conversation_id, created_at);
create index idx_notifications_recipient on public.notifications (recipient_id, created_at desc);
create index idx_ai_messages_user on public.ai_messages (user_id, created_at);

-- =============================================================================
-- 14. Row Level Security — locked down by default, then opened deliberately
-- =============================================================================
alter table public.profiles enable row level security;
alter table public.clubs enable row level security;
alter table public.club_members enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;
alter table public.likes enable row level security;
alter table public.events enable row level security;
alter table public.event_rsvps enable row level security;
alter table public.marketplace_items enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.polls enable row level security;
alter table public.poll_votes enable row level security;
alter table public.follows enable row level security;
alter table public.reports enable row level security;
alter table public.feature_flags enable row level security;
alter table public.admin_logs enable row level security;
alter table public.ai_messages enable row level security;

-- Helper: is the current user an admin?
create function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select is_admin from public.profiles where id = auth.uid()), false);
$$;

-- profiles: readable by any signed-in user, editable only by the owner
create policy "profiles are readable by authenticated users" on public.profiles
  for select using (auth.role() = 'authenticated');
create policy "users update own profile" on public.profiles
  for update using (auth.uid() = id);
create policy "admins manage profiles" on public.profiles
  for all using (public.is_admin());

-- clubs
create policy "clubs are readable by authenticated users" on public.clubs
  for select using (auth.role() = 'authenticated');
create policy "authenticated users create clubs" on public.clubs
  for insert with check (auth.uid() = created_by);
create policy "creator updates own club" on public.clubs
  for update using (auth.uid() = created_by);

create policy "club members readable" on public.club_members
  for select using (auth.role() = 'authenticated');
create policy "users manage own membership" on public.club_members
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- posts: feed + confessions readable by anyone signed in; only the author writes
create policy "posts readable by authenticated users" on public.posts
  for select using (auth.role() = 'authenticated');
create policy "author creates posts" on public.posts
  for insert with check (auth.uid() = author_id);
create policy "author updates own posts" on public.posts
  for update using (auth.uid() = author_id);
create policy "author deletes own posts" on public.posts
  for delete using (auth.uid() = author_id or public.is_admin());

create policy "comments readable by authenticated users" on public.comments
  for select using (auth.role() = 'authenticated');
create policy "author creates comments" on public.comments
  for insert with check (auth.uid() = author_id);
create policy "author deletes own comments" on public.comments
  for delete using (auth.uid() = author_id or public.is_admin());

create policy "likes readable by authenticated users" on public.likes
  for select using (auth.role() = 'authenticated');
create policy "users manage own likes" on public.likes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- events
create policy "events readable by authenticated users" on public.events
  for select using (auth.role() = 'authenticated');
create policy "host creates events" on public.events
  for insert with check (auth.uid() = host_id);
create policy "host updates own events" on public.events
  for update using (auth.uid() = host_id);

create policy "rsvps readable by authenticated users" on public.event_rsvps
  for select using (auth.role() = 'authenticated');
create policy "users manage own rsvp" on public.event_rsvps
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- marketplace
create policy "listings readable by authenticated users" on public.marketplace_items
  for select using (auth.role() = 'authenticated');
create policy "seller creates listings" on public.marketplace_items
  for insert with check (auth.uid() = seller_id);
create policy "seller updates own listings" on public.marketplace_items
  for update using (auth.uid() = seller_id);

-- messaging: strictly participants only
create policy "members see their conversations" on public.conversations
  for select using (
    exists (
      select 1 from public.conversation_members cm
      where cm.conversation_id = conversations.id and cm.user_id = auth.uid()
    )
  );
create policy "authenticated users start conversations" on public.conversations
  for insert with check (auth.uid() = created_by);

create policy "members see membership rows for their conversations" on public.conversation_members
  for select using (
    exists (
      select 1 from public.conversation_members cm2
      where cm2.conversation_id = conversation_members.conversation_id
        and cm2.user_id = auth.uid()
    )
  );
create policy "users add themselves or are added when starting a conversation" on public.conversation_members
  for insert with check (auth.uid() is not null);

create policy "participants read messages" on public.messages
  for select using (
    exists (
      select 1 from public.conversation_members cm
      where cm.conversation_id = messages.conversation_id and cm.user_id = auth.uid()
    )
  );
create policy "participants send messages" on public.messages
  for insert with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.conversation_members cm
      where cm.conversation_id = messages.conversation_id and cm.user_id = auth.uid()
    )
  );

-- notifications: recipient only
create policy "recipient reads own notifications" on public.notifications
  for select using (auth.uid() = recipient_id);
create policy "recipient updates own notifications" on public.notifications
  for update using (auth.uid() = recipient_id);
create policy "authenticated users create notifications" on public.notifications
  for insert with check (auth.role() = 'authenticated');

-- polls
create policy "polls readable by authenticated users" on public.polls
  for select using (auth.role() = 'authenticated');
create policy "author creates polls" on public.polls
  for insert with check (auth.uid() = author_id);

create policy "poll votes readable by authenticated users" on public.poll_votes
  for select using (auth.role() = 'authenticated');
create policy "users manage own poll vote" on public.poll_votes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- follows
create policy "follows readable by authenticated users" on public.follows
  for select using (auth.role() = 'authenticated');
create policy "users manage own follows" on public.follows
  for all using (auth.uid() = follower_id) with check (auth.uid() = follower_id);

-- reports / feature_flags / admin_logs: admin-only, plus reporters can file
create policy "authenticated users file reports" on public.reports
  for insert with check (auth.uid() = reporter_id);
create policy "admins manage reports" on public.reports
  for select using (public.is_admin());
create policy "admins resolve reports" on public.reports
  for update using (public.is_admin());

create policy "admins manage feature flags" on public.feature_flags
  for all using (public.is_admin());

create policy "admins read logs" on public.admin_logs
  for select using (public.is_admin());
create policy "admins write logs" on public.admin_logs
  for insert with check (public.is_admin());

-- ai_messages (Pegasus): strictly private to the owner
create policy "own ai messages" on public.ai_messages
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- =============================================================================
-- Done. Grant baseline table privileges (RLS policies above still apply on
-- top of these — grants alone do not bypass RLS).
-- =============================================================================
grant select, insert, update, delete on all tables in schema public to authenticated;
grant select on public.profiles, public.posts, public.comments, public.clubs,
  public.events, public.marketplace_items, public.polls to anon;
