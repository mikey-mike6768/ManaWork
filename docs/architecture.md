# ManaWork — Initial Architecture

## Product model

ManaWork is a Hyderabad-focused local-services marketplace. A single account can act as a customer, a worker, or both. Customer and Worker are modes attached to one identity, not mutually exclusive account types.

## Applications

- `apps/mobile`: Flutter application with Customer and Worker modes.
- `apps/admin`: future web-based operations and safety portal.
- `apps/api`: optional supporting API services where Edge Functions are not sufficient.

## Backend

Supabase provides:

- Auth for sign-in and session management.
- PostgreSQL for application data.
- Row Level Security (RLS) for data access enforcement.
- Storage for private verification documents and service media.
- Realtime for selected live booking and messaging updates.
- Edge Functions for trusted server-side workflows.
- PostGIS for proximity and service-area queries.

## Domain boundaries

- **Identity:** user accounts, customer profiles, worker profiles, and mode preferences.
- **Catalogue:** service categories, skills, service packages, and service areas.
- **Supply:** worker onboarding, verification status, availability, and location.
- **Booking:** service requests, assignments, quotes, booking events, and photos.
- **Money:** payment intents, payment records, commissions, and payouts.
- **Trust:** reviews, disputes, reports, and audit events.
- **Communication:** conversations, messages, and notifications.

## Security requirements

1. Enable RLS on every table exposed through the Supabase API.
2. Derive the acting user from the authenticated session; never trust a client-supplied user ID for authorization.
3. Store identity and verification documents in private buckets with narrowly scoped access.
4. Keep service-role keys and payment secrets exclusively in trusted server environments.
5. Verify payment-provider webhook signatures and make webhook processing idempotent.
6. Record sensitive administrative actions in an audit trail.

## Mobile application structure

Use feature-first Flutter modules, with shared design tokens, reusable widgets, localization, and typed data models. Initial languages: English, Telugu, and Hindi.

## Initial delivery milestone

- Flutter app foundation and navigation.
- Supabase client configuration.
- Database migrations and RLS policies.
- Authentication and profile bootstrap.
- Customer/Worker mode selection.
- Starter dashboards for both modes.
