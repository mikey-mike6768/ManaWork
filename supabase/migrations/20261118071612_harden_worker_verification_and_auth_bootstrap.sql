-- Prevent workers from self-assigning a privileged verification status.
revoke insert, update on public.worker_profiles from authenticated;
grant insert (user_id,bio,years_experience,service_location,is_available) on public.worker_profiles to authenticated;
grant update (bio,years_experience,service_location,is_available,updated_at) on public.worker_profiles to authenticated;

-- Booking state transitions will be handled by trusted server-side workflows.
revoke update on public.bookings from authenticated;

-- Allow the Auth service role to execute the profile bootstrap trigger writes.
grant usage on schema public to supabase_auth_admin;
grant insert on public.profiles,public.customer_profiles to supabase_auth_admin;
