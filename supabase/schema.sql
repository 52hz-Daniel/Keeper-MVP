-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Create families table
create table public.families (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  invite_code text unique not null
);

-- Create profiles table (extends auth.users)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  family_id uuid references public.families(id),
  role text check (role in ('Mom', 'Dad', 'Partner', 'Guardian')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create logs table
create table public.logs (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  family_id uuid references public.families(id) not null,
  creator_id uuid references public.profiles(id) not null,
  event_type text check (event_type in ('sleep', 'feed', 'diaper', 'medication', 'note', 'growth')) not null,
  raw_text text,
  structured_data jsonb,
  is_confirmed boolean default false,
  client_updated_at timestamp with time zone,
  last_modified_by uuid references public.profiles(id)
);

-- RLS Policies
alter table public.families enable row level security;
alter table public.profiles enable row level security;
alter table public.logs enable row level security;

-- Profiles policies
create policy "Users can view their own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Families policies
create policy "Users can view their family"
  on public.families for select
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
      and profiles.family_id = families.id
    )
  );

-- Logs policies
create policy "Users can view logs from their family"
  on public.logs for select
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
      and profiles.family_id = logs.family_id
    )
  );

create policy "Users can insert logs for their family"
  on public.logs for insert
  with check (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
      and profiles.family_id = logs.family_id
    )
  );

create policy "Users can update logs for their family"
  on public.logs for update
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
      and profiles.family_id = logs.family_id
    )
  );

-- Create storage bucket for raw audio
insert into storage.buckets (id, name, public) values ('raw_audio', 'raw_audio', false);

create policy "Family members can upload audio"
  on storage.objects for insert
  with check (
    bucket_id = 'raw_audio' and
    auth.role() = 'authenticated'
  );

create policy "Family members can read audio"
  on storage.objects for select
  using (
    bucket_id = 'raw_audio' and
    auth.role() = 'authenticated'
  );
