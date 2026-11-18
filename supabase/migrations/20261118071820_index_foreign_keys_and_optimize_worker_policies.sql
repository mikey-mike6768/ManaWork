create index if not exists booking_events_actor_id_idx on public.booking_events(actor_id);
create index if not exists bookings_category_id_idx on public.bookings(category_id);
create index if not exists bookings_skill_id_idx on public.bookings(skill_id);
create index if not exists reviews_reviewer_id_idx on public.reviews(reviewer_id);
create index if not exists worker_skills_skill_id_idx on public.worker_skills(skill_id);

drop policy if exists worker_skills_manage_own on public.worker_skills;
create policy worker_skills_insert_own on public.worker_skills for insert to authenticated with check(worker_id=(select auth.uid()));
create policy worker_skills_update_own on public.worker_skills for update to authenticated using(worker_id=(select auth.uid())) with check(worker_id=(select auth.uid()));
create policy worker_skills_delete_own on public.worker_skills for delete to authenticated using(worker_id=(select auth.uid()));

drop policy if exists worker_areas_manage_own on public.worker_service_areas;
create policy worker_areas_insert_own on public.worker_service_areas for insert to authenticated with check(worker_id=(select auth.uid()));
create policy worker_areas_update_own on public.worker_service_areas for update to authenticated using(worker_id=(select auth.uid())) with check(worker_id=(select auth.uid()));
create policy worker_areas_delete_own on public.worker_service_areas for delete to authenticated using(worker_id=(select auth.uid()));

drop policy if exists worker_availability_manage_own on public.worker_availability;
create policy worker_availability_insert_own on public.worker_availability for insert to authenticated with check(worker_id=(select auth.uid()));
create policy worker_availability_update_own on public.worker_availability for update to authenticated using(worker_id=(select auth.uid())) with check(worker_id=(select auth.uid()));
create policy worker_availability_delete_own on public.worker_availability for delete to authenticated using(worker_id=(select auth.uid()));
