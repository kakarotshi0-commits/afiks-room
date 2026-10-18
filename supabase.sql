-- Run this once in Supabase: SQL Editor > New query > paste > Run.
-- First, replace OWNER_EMAIL below (3 places, search for it) with the email you will log in with.

create table projects (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) <= 120),
  description text default '' check (char_length(description) <= 500),
  meta text default '' check (char_length(meta) <= 60),
  link text default '#' check (char_length(link) <= 500),
  img text default '' check (char_length(img) <= 500),
  created_at timestamptz default now()
);

create table settings (
  id int primary key check (id = 1),
  email text default '' check (char_length(email) <= 200),
  whatsapp text default '' check (char_length(whatsapp) <= 40),
  github text default '' check (char_length(github) <= 300),
  linkedin text default '' check (char_length(linkedin) <= 300)
);
insert into settings (id) values (1);

create table messages (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 100),
  email text not null check (char_length(email) between 3 and 200),
  message text not null check (char_length(message) between 1 and 3000),
  created_at timestamptz default now()
);

alter table projects enable row level security;
alter table settings enable row level security;
alter table messages enable row level security;

-- Everyone can read projects and contact details. Only you can change them.
create policy "read projects" on projects for select using (true);
create policy "owner writes projects" on projects for all to authenticated
  using ((auth.jwt() ->> 'email') = 'OWNER_EMAIL')
  with check ((auth.jwt() ->> 'email') = 'OWNER_EMAIL');

create policy "read settings" on settings for select using (true);
create policy "owner writes settings" on settings for all to authenticated
  using ((auth.jwt() ->> 'email') = 'OWNER_EMAIL')
  with check ((auth.jwt() ->> 'email') = 'OWNER_EMAIL');

-- Anyone can send you a message. Only you can read or delete messages.
create policy "anyone sends message" on messages for insert to anon, authenticated with check (true);
create policy "owner reads messages" on messages for select to authenticated
  using ((auth.jwt() ->> 'email') = 'OWNER_EMAIL');
create policy "owner deletes messages" on messages for delete to authenticated
  using ((auth.jwt() ->> 'email') = 'OWNER_EMAIL');

-- Picture storage (public to view, only you can upload or delete).
insert into storage.buckets (id, name, public) values ('work', 'work', true) on conflict do nothing;
create policy "owner uploads pictures" on storage.objects for insert to authenticated
  with check (bucket_id = 'work' and (auth.jwt() ->> 'email') = 'OWNER_EMAIL');
create policy "owner deletes pictures" on storage.objects for delete to authenticated
  using (bucket_id = 'work' and (auth.jwt() ->> 'email') = 'OWNER_EMAIL');
