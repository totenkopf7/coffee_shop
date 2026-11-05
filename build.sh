#!/bin/bash
set -e

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "ERROR: SUPABASE_URL or SUPABASE_ANON_KEY is missing."
  exit 1
fi

FLUTTER_SDK_PATH="$HOME/flutter"

if [ ! -d "$FLUTTER_SDK_PATH" ]; then
  git clone --branch stable --depth 1 https://github.com/flutter/flutter.git $FLUTTER_SDK_PATH
fi

export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

flutter config --enable-web
flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY