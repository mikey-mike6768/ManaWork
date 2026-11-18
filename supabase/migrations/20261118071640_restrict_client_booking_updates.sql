-- Booking transitions will be performed by trusted server-side workflows.
revoke update on public.bookings from authenticated;
