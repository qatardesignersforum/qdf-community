# Qatar Designers Forum (QDF) Community Website

GitHub-ready starter for the QDF community website.

## Current package
- `index.html` — current QDF visual prototype and community pages
- `supabase/schema.sql` — database tables, Row Level Security policies and storage buckets for the production backend
- `supabase/config.example.js` — frontend Supabase configuration placeholder
- `js/supabase.js` — small Supabase client loader; replace the values in `supabase/config.js`
- `.gitignore` — prevents local secrets from being committed

## Important
The included `index.html` is still the visual/demo prototype. Its demo login and sample data are not secure authentication. The next step is to connect Supabase Auth + Database + Storage and replace the demo data/functions.

## Supabase setup
1. Create a Supabase project.
2. Open SQL Editor and run `supabase/schema.sql`.
3. Copy `supabase/config.example.js` to `supabase/config.js`.
4. Put your Supabase Project URL and publishable/anon key in `supabase/config.js`.
5. Never put a `service_role` key in the website.
6. The production website should use Supabase Auth and RLS for member/admin permissions.

## GitHub Pages / Cloudflare
This package is plain HTML/CSS/JavaScript, so it can be hosted from GitHub Pages or Cloudflare Pages. Supabase remains the backend.
