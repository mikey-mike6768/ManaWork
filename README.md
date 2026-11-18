# ManaWork

**Trusted help. Right around the corner.**

ManaWork is a mobile-first local-services marketplace designed to connect customers with trusted nearby service professionals in Hyderabad.

## Initial launch areas

- Gachibowli
- Madhapur
- Kondapur
- Kukatpally

## Initial service categories

- Housekeeping and domestic help
- Plumbing and electrical services
- Drivers
- Construction labour

## Product direction

A single Flutter application will support both Customer and Worker modes. One account may use both modes; the selected mode changes the experience, not the underlying identity.

## Planned technology

- Flutter for the mobile application
- Supabase Auth and PostgreSQL for identity and data
- Supabase Storage for private verification documents and service media
- Supabase Realtime and Edge Functions for live workflows and trusted server-side operations
- PostGIS for location-aware discovery
- Firebase Cloud Messaging for push notifications

## Repository structure

The repository will grow into a monorepo:

- `apps/mobile` — Flutter customer/worker application
- `apps/admin` — administration portal
- `apps/api` — supporting API services, if needed
- `supabase/migrations` — database migrations
- `supabase/functions` — Supabase Edge Functions
- `packages/` — shared design system, models, and localization
- `docs/` — architecture, product, and delivery documentation

## Security principles

- Apply Row Level Security to all exposed tables.
- Keep worker verification documents in private storage.
- Never ship Supabase service-role credentials in client applications.
- Validate sensitive operations on trusted server-side code.
- Make payment webhooks idempotent.

## Current status

Project foundation and architecture are being established. Implementation milestones and decisions will be tracked in `docs/`.
