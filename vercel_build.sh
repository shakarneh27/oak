#!/usr/bin/env bash
# Vercel build script: fetches the Flutter SDK (not present in Vercel's
# build image) and produces the release web build in build/web.
set -euo pipefail

if [ ! -d _flutter ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
fi
export PATH="$PATH:$(pwd)/_flutter/bin"

flutter pub get

# The app has working defaults baked in; forward overrides only when the
# Vercel project defines them.
DEFINES=()
[ -n "${SUPABASE_URL:-}" ] && DEFINES+=("--dart-define=SUPABASE_URL=${SUPABASE_URL}")
[ -n "${SUPABASE_ANON_KEY:-}" ] && DEFINES+=("--dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}")

# --no-web-resources-cdn bundles CanvasKit with the app instead of loading
# it from gstatic.com, so the app still works on networks that block
# Google CDNs (common in schools).
flutter build web --release --no-web-resources-cdn ${DEFINES[@]+"${DEFINES[@]}"}
