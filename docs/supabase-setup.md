# Supabase Project Connection

ManaWork is linked to the Supabase project:

- Project: `manawork-prod`
- Project ref: `kaghdstxwhegcnsbvvdt`
- Region: Mumbai (`ap-south-1`)
- API URL: `https://kaghdstxwhegcnsbvvdt.supabase.co`
- Organization plan at setup: Free
- Project quote at creation: $0/month

## Mobile configuration

Use Flutter's `--dart-define` values or a local, untracked environment file:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

Initialize the current Supabase Flutter SDK using `publishableKey`. The publishable key is designed for client use; it does not replace authorization. Enforce access with Row Level Security.

## Secrets

Never commit service-role keys, secret API keys, database passwords, or payment-provider secrets. Keep them in trusted server environments and local secret stores.

## CLI

The project ref is recorded in `supabase/config.toml`. Authenticate the Supabase CLI locally before linking or pushing migrations. Review every migration and RLS policy before applying it to the hosted project.
