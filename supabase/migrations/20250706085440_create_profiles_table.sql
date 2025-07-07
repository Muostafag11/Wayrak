-- Creates the profiles table and all related helper functions/triggers

-- 1. Create the profiles table
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  updated_at timestamp with time zone,
  full_name text,
  user_type text not null,
  phone_number text,
  avatar_url text
);

-- 2. Set up Row Level Security (RLS) for profiles
alter table public.profiles enable row level security;

create policy "Users can view their own profile."
on public.profiles for select
using ( auth.uid() = id );

create policy "Users can update their own profile."
on public.profiles for update
using ( auth.uid() = id );

-- 3. Create a function to handle new user sign-ups
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, user_type)
  values (new.id, new.raw_user_meta_data->>'user_type');
  return new;
end;
$$;

-- 4. Create a trigger to call the function when a new user signs up
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 5. Create a helper function to get user claims from their JWT
create function public.get_my_claim(claim text)
returns jsonb
language sql stable
as $$
  select nullif(current_setting('request.jwt.claims', true), '')::jsonb -> claim;
$$;