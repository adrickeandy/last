-- =============================================================================
-- CampusX — migration 003 (NON-destructive; safe to run on your live database)
-- =============================================================================
-- Run in: Supabase Dashboard -> SQL Editor -> New query -> paste -> Run.
-- Idempotent: running it twice does no harm.
--
-- What it adds
--   Post videos are now picked from the device (no more pasted links), so they
--   need somewhere to live: a public storage bucket called `post-videos`.
--   Same model as `post-images` / `attachments`: anyone holding the
--   (unguessable) link can play it, and users can only write into the folder
--   named after their own user id.
--
--   The 50 MB limit matches the limit enforced in the app. (Supabase's free
--   plan also has a project-wide upload cap; if you raise this number, check
--   Dashboard -> Storage -> Settings as well.)
--
--   No table changes: `posts.video_url` already exists and simply stores the
--   public URL of the uploaded file. Forwarding a post to a chat needs no
--   schema change either - the post snapshot travels inside `messages.content`.
-- =============================================================================

insert into storage.buckets (id, name, public, file_size_limit)
values ('post-videos', 'post-videos', true, 52428800) -- 50 MB
on conflict (id) do update set public = true, file_size_limit = 52428800;

drop policy if exists "post videos are readable" on storage.objects;
create policy "post videos are readable" on storage.objects
  for select using (bucket_id = 'post-videos');

drop policy if exists "users upload own post videos" on storage.objects;
create policy "users upload own post videos" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'post-videos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "users delete own post videos" on storage.objects;
create policy "users delete own post videos" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'post-videos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
