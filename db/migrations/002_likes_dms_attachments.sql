-- =============================================================================
-- CampusX — migration 002 (NON-destructive; safe to run on your live database)
-- =============================================================================
-- Run in: Supabase Dashboard -> SQL Editor -> New query -> paste -> Run.
-- It is idempotent: running it twice does no harm.
--
-- What it fixes / adds
--   1. Likes + comment counters now update for EVERYONE (not just the author).
--   2. Direct messages: removes two Row-Level-Security traps that make
--      "start chat" fail (needed by Contact Seller / Message on profile).
--   3. File attachments on messages and comments (new columns + a public
--      storage bucket called `attachments`).
--   Profile cover photos need no schema change (profiles.cover_url exists).
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. LIKE / COMMENT COUNTERS
-- -----------------------------------------------------------------------------
-- Why likes looked like "one switch for everybody":
-- the triggers below update public.posts, but the posts UPDATE policy only lets
-- the AUTHOR update a post. The trigger ran with the permissions of whoever
-- clicked "like", so for anyone except the author the counter update was
-- silently blocked by RLS. `security definer` makes the trigger run as the
-- table owner, so the counter always moves.
create or replace function public.handle_like_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
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

create or replace function public.handle_comment_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
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

-- Make sure the triggers exist (no-op if they already do).
drop trigger if exists on_like_change on public.likes;
create trigger on_like_change
  after insert or delete on public.likes
  for each row execute function public.handle_like_count();

drop trigger if exists on_comment_change on public.comments;
create trigger on_comment_change
  after insert or delete on public.comments
  for each row execute function public.handle_comment_count();

-- Repair counters that drifted while the triggers were being blocked.
update public.posts p
set like_count = coalesce((select count(*) from public.likes l where l.post_id = p.id), 0),
    comment_count = coalesce((select count(*) from public.comments c where c.post_id = p.id), 0);


-- -----------------------------------------------------------------------------
-- 2. DIRECT-MESSAGE RLS FIXES
-- -----------------------------------------------------------------------------
-- (a) The old "members see membership rows" policy selected from the very table
--     it protects, which Postgres rejects as "infinite recursion in policy".
--     A security-definer helper breaks the loop.
create or replace function public.is_conversation_member(conv_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.conversation_members
    where conversation_id = conv_id and user_id = auth.uid()
  );
$$;

-- (b) Creating a chat does `insert into conversations ... returning *`. The
--     returned row must pass the SELECT policy, but you are not a member yet at
--     that instant, so the insert was rejected. Letting the creator see their own
--     conversation fixes that.
drop policy if exists "members see their conversations" on public.conversations;
create policy "members see their conversations" on public.conversations
  for select using (
    created_by = auth.uid() or public.is_conversation_member(id)
  );

drop policy if exists "members see membership rows for their conversations" on public.conversation_members;
create policy "members see membership rows for their conversations" on public.conversation_members
  for select using (
    user_id = auth.uid() or public.is_conversation_member(conversation_id)
  );

drop policy if exists "participants read messages" on public.messages;
create policy "participants read messages" on public.messages
  for select using (public.is_conversation_member(conversation_id));

drop policy if exists "participants send messages" on public.messages;
create policy "participants send messages" on public.messages
  for insert with check (
    auth.uid() = sender_id and public.is_conversation_member(conversation_id)
  );


-- -----------------------------------------------------------------------------
-- 3. ATTACHMENTS (messages + comments)
-- -----------------------------------------------------------------------------
alter table public.messages
  add column if not exists attachment_url  text,
  add column if not exists attachment_name text,
  add column if not exists attachment_type text,   -- MIME type, e.g. image/png
  add column if not exists attachment_size bigint; -- bytes

alter table public.comments
  add column if not exists attachment_url  text,
  add column if not exists attachment_name text,
  add column if not exists attachment_type text,
  add column if not exists attachment_size bigint;

-- A message/comment may be "file only", so empty text must be allowed.
alter table public.messages alter column content set default '';
alter table public.comments alter column content set default '';

-- Storage bucket. Public = anyone holding the (unguessable) link can open it,
-- same model as your existing post-images / marketplace-images buckets.
insert into storage.buckets (id, name, public, file_size_limit)
values ('attachments', 'attachments', true, 10485760) -- 10 MB
on conflict (id) do update set public = true, file_size_limit = 10485760;

drop policy if exists "attachments are readable" on storage.objects;
create policy "attachments are readable" on storage.objects
  for select using (bucket_id = 'attachments');

-- Users may only upload into a folder named after their own user id.
drop policy if exists "users upload own attachments" on storage.objects;
create policy "users upload own attachments" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'attachments'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "users delete own attachments" on storage.objects;
create policy "users delete own attachments" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'attachments'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
