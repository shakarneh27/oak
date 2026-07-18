# 🌳 السنديانة الرقمية (Digital Oak)

Adaptive STEAM learning platform for elementary students — Flutter (Web +
Mobile) frontend on a Supabase (PostgreSQL / Auth / Realtime) backend.

## Architecture

| Layer | Technology |
| --- | --- |
| Frontend | Flutter (Dart), Material 3, RTL Arabic UI |
| State management | Riverpod |
| Routing | go_router (role-based redirects) |
| Backend | Supabase — Postgres + Row Level Security, Auth, Realtime |
| Realtime | Supabase Realtime Channels (replaces the original Socket.io event list) |
| AI hints | Supabase Edge Function (`ai-get-hint`) with a local fallback |
| Hosting | Vercel (`flutter build web`) |

See `supabase/migrations/` for the full schema (`users` → `profiles`,
`student_progress`, `game_sessions`, `remedial_events`, `realtime_logs`,
`units`, `games_catalog`) and RLS policies, and
`supabase/functions/ai-get-hint/` for the AI assistant edge function stub.

### Screens (`lib/screens/`)

Splash → Login → Diagnostic test → Student dashboard → Progress tree →
Units → Games → AI assistant → Teacher dashboard → Parent dashboard →
Achievements → Settings — one folder per screen, matching the original
spec's 12-screen flow.

### Adaptive games engine (`lib/screens/games/`)

Every game in `lib/data/games_matrix_data.dart` (mirrors
`supabase/migrations/0002_seed_catalog.sql`) is built on one of three
generic, reusable mechanics (`lib/screens/games/widgets/`):

- **match** — tap emoji ↔ label pairs, then validate the whole round
- **sequence** — drag items into the correct order, then validate
- **mcq** — timed multiple choice, one question at a time

Content per game/level lives in `lib/data/game_interactions_data.dart`.
Difficulty across weak/medium/advanced is expressed by item count and
distractor complexity, per the spreadsheet's original level descriptions.

### Remedial engine (`lib/services/remedial_engine.dart`)

Implements the four automated rules from the spec:

1. 3 consecutive fails at the same level → pause + log a skill gap
2. 2 fails at Medium/Advanced → downgrade one level + visual hints
3. Continued failure on the easier/remediation game → alert teacher + parent in realtime
4. Clearing the remediation game 100% → "شارة المحاولة الشجاعة" badge, tree growth, and a fresh scenario back on the original game

## Getting started

### 1. Supabase project

```bash
# In the Supabase SQL editor, or via the CLI:
supabase link --project-ref <your-project-ref>
supabase db push   # applies supabase/migrations/0001_init.sql and 0002_seed_catalog.sql
supabase functions deploy ai-get-hint
supabase secrets set ANTHROPIC_API_KEY=sk-... # optional, enables real AI hints
```

### 2. Run the app

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```

### 3. Deploy to Vercel

`vercel.json` clones the Flutter SDK during the build (Vercel's build
image doesn't ship it) and runs `flutter build web`. In the Vercel
project settings, set the environment variables `SUPABASE_URL` and
`SUPABASE_ANON_KEY` — the build command forwards them as `--dart-define`
flags.

## Tests

```bash
flutter analyze
flutter test
```
