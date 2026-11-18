-- ManaWork initial marketplace schema
create extension if not exists pgcrypto;
create extension if not exists postgis with schema extensions;

create type public.account_mode as enum ('customer', 'worker');
create type public.worker_verification_status as enum ('pending', 'submitted', 'verified', 'rejected', 'suspended');
create type public.booking_status as enum ('requested', 'quoted', 'accepted', 'in_progress', 'completed', 'cancelled', 'disputed');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text, phone text,
  preferred_language text not null default 'en' check (preferred_language in ('en','te','hi')),
  active_mode public.account_mode not null default 'customer',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.customer_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  default_address text, created_at timestamptz not null default now()
);
create table public.worker_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  bio text, verification_status public.worker_verification_status not null default 'pending',
  years_experience smallint check (years_experience between 0 and 60),
  service_location extensions.geography(point,4326),
  is_available boolean not null default false,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index worker_profiles_location_gix on public.worker_profiles using gist(service_location);
create index worker_profiles_available_idx on public.worker_profiles(is_available, verification_status);

create table public.service_categories (
  id uuid primary key default gen_random_uuid(), name text not null unique, slug text not null unique,
  description text, icon_key text, is_active boolean not null default true,
  sort_order integer not null default 0, created_at timestamptz not null default now()
);
create table public.skills (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.service_categories(id) on delete restrict,
  name text not null, slug text not null unique, is_active boolean not null default true,
  unique(category_id,name)
);
create table public.worker_skills (
  worker_id uuid not null references public.worker_profiles(user_id) on delete cascade,
  skill_id uuid not null references public.skills(id) on delete restrict,
  created_at timestamptz not null default now(), primary key(worker_id,skill_id)
);
create table public.worker_service_areas (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references public.worker_profiles(user_id) on delete cascade,
  area_name text not null, center extensions.geography(point,4326),
  radius_km numeric(5,2) not null default 5 check(radius_km > 0 and radius_km <= 100),
  created_at timestamptz not null default now(), unique(worker_id,area_name)
);
create index worker_service_areas_center_gix on public.worker_service_areas using gist(center);
create table public.worker_availability (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references public.worker_profiles(user_id) on delete cascade,
  weekday smallint not null check(weekday between 0 and 6),
  start_time time not null, end_time time not null, is_active boolean not null default true,
  check(end_time > start_time), unique(worker_id,weekday,start_time,end_time)
);
create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customer_profiles(user_id) on delete restrict,
  worker_id uuid references public.worker_profiles(user_id) on delete set null,
  category_id uuid not null references public.service_categories(id) on delete restrict,
  skill_id uuid references public.skills(id) on delete set null,
  title text not null, description text, service_address text not null,
  service_location extensions.geography(point,4326), scheduled_at timestamptz,
  quoted_amount numeric(12,2) check(quoted_amount is null or quoted_amount >= 0),
  final_amount numeric(12,2) check(final_amount is null or final_amount >= 0),
  status public.booking_status not null default 'requested',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index bookings_customer_created_idx on public.bookings(customer_id,created_at desc);
create index bookings_worker_created_idx on public.bookings(worker_id,created_at desc);
create index bookings_status_idx on public.bookings(status);
create index bookings_location_gix on public.bookings using gist(service_location);

create table public.booking_events (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  old_status public.booking_status, new_status public.booking_status, note text,
  created_at timestamptz not null default now()
);
create index booking_events_booking_created_idx on public.booking_events(booking_id,created_at);
create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete cascade,
  reviewer_id uuid not null references public.profiles(id) on delete restrict,
  worker_id uuid not null references public.worker_profiles(user_id) on delete restrict,
  rating smallint not null check(rating between 1 and 5), comment text,
  created_at timestamptz not null default now()
);
create index reviews_worker_created_idx on public.reviews(worker_id,created_at desc);

create or replace function public.handle_new_user()
returns trigger language plpgsql security invoker set search_path = ''
as $$
begin
  insert into public.profiles(id,full_name,phone)
  values(new.id,nullif(new.raw_user_meta_data->>'full_name',''),nullif(new.phone,''));
  insert into public.customer_profiles(user_id) values(new.id);
  return new;
end;
$$;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.customer_profiles enable row level security;
alter table public.worker_profiles enable row level security;
alter table public.service_categories enable row level security;
alter table public.skills enable row level security;
alter table public.worker_skills enable row level security;
alter table public.worker_service_areas enable row level security;
alter table public.worker_availability enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_events enable row level security;
alter table public.reviews enable row level security;

create policy profiles_select_own on public.profiles for select to authenticated using((select auth.uid())=id);
create policy profiles_insert_own on public.profiles for insert to authenticated with check((select auth.uid())=id);
create policy profiles_update_own on public.profiles for update to authenticated using((select auth.uid())=id) with check((select auth.uid())=id);
create policy customer_profiles_select_own on public.customer_profiles for select to authenticated using((select auth.uid())=user_id);
create policy customer_profiles_insert_own on public.customer_profiles for insert to authenticated with check((select auth.uid())=user_id);
create policy customer_profiles_update_own on public.customer_profiles for update to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
create policy worker_profiles_read_verified_or_own on public.worker_profiles for select to authenticated using(verification_status='verified' or (select auth.uid())=user_id);
create policy worker_profiles_insert_own on public.worker_profiles for insert to authenticated with check((select auth.uid())=user_id);
create policy worker_profiles_update_own on public.worker_profiles for update to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
create policy categories_read_active on public.service_categories for select to anon,authenticated using(is_active);
create policy skills_read_active on public.skills for select to anon,authenticated using(is_active);
create policy worker_skills_read_verified_or_own on public.worker_skills for select to authenticated using(exists(select 1 from public.worker_profiles wp where wp.user_id=worker_id and (wp.verification_status='verified' or wp.user_id=(select auth.uid()))));
create policy worker_skills_manage_own on public.worker_skills for all to authenticated using(worker_id=(select auth.uid())) with check(worker_id=(select auth.uid()));
create policy worker_areas_read_verified_or_own on public.worker_service_areas for select to authenticated using(exists(select 1 from public.worker_profiles wp where wp.user_id=worker_id and (wp.verification_status='verified' or wp.user_id=(select auth.uid()))));
create policy worker_areas_manage_own on public.worker_service_areas for all to authenticated using(worker_id=(select auth.uid())) with check(worker_id=(select auth.uid()));
create policy worker_availability_read_verified_or_own on public.worker_availability for select to authenticated using(exists(select 1 from public.worker_profiles wp where wp.user_id=worker_id and (wp.verification_status='verified' or wp.user_id=(select auth.uid()))));
create policy worker_availability_manage_own on public.worker_availability for all to authenticated using(worker_id=(select auth.uid())) with check(worker_id=(select auth.uid()));
create policy bookings_read_participants on public.bookings for select to authenticated using(customer_id=(select auth.uid()) or worker_id=(select auth.uid()));
create policy bookings_customer_create on public.bookings for insert to authenticated with check(customer_id=(select auth.uid()));
create policy bookings_customer_update_requested on public.bookings for update to authenticated using(customer_id=(select auth.uid()) and status='requested') with check(customer_id=(select auth.uid()) and status in ('requested','cancelled'));
create policy booking_events_read_participants on public.booking_events for select to authenticated using(exists(select 1 from public.bookings b where b.id=booking_id and (b.customer_id=(select auth.uid()) or b.worker_id=(select auth.uid()))));
create policy reviews_read_all_authenticated on public.reviews for select to authenticated using(true);
create policy reviews_customer_create_completed_booking on public.reviews for insert to authenticated with check(reviewer_id=(select auth.uid()) and exists(select 1 from public.bookings b where b.id=booking_id and b.customer_id=(select auth.uid()) and b.worker_id=reviews.worker_id and b.status='completed'));

grant usage on schema public to anon,authenticated;
grant select on public.service_categories,public.skills to anon,authenticated;
grant select,insert,update on public.profiles,public.customer_profiles,public.worker_profiles to authenticated;
grant select,insert,update,delete on public.worker_skills,public.worker_service_areas,public.worker_availability to authenticated;
grant select,insert,update on public.bookings to authenticated;
grant select on public.booking_events to authenticated;
grant select,insert on public.reviews to authenticated;

insert into public.service_categories(name,slug,description,icon_key,sort_order) values
('Housekeeping & Domestic Help','housekeeping','Home cleaning and domestic assistance.','home',1),
('Plumbing','plumbing','Plumbing repairs and installations.','wrench',2),
('Electrical','electrical','Electrical repairs and installations.','zap',3),
('Drivers','drivers','Local and scheduled driving services.','car',4),
('Construction Labour','construction-labour','General construction and site labour.','hard-hat',5)
on conflict(slug) do nothing;
insert into public.skills(category_id,name,slug)
select c.id,v.name,v.slug from public.service_categories c
join (values
('housekeeping','Home cleaning','home-cleaning'),
('housekeeping','Cooking assistance','cooking-assistance'),
('plumbing','Pipe repair','pipe-repair'),
('plumbing','Tap and fixture installation','tap-fixture-installation'),
('electrical','Electrical repair','electrical-repair'),
('electrical','Fan and light installation','fan-light-installation'),
('drivers','Personal driver','personal-driver'),
('drivers','Outstation driver','outstation-driver'),
('construction-labour','General labour','general-labour'),
('construction-labour','Masonry assistant','masonry-assistant')
) as v(category_slug,name,slug) on c.slug=v.category_slug
on conflict(slug) do nothing;
