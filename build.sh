#!/bin/bash
set -e

FLUTTER_SDK_PATH="$HOME/flutter"

# Install Flutter (if not present)
if [ ! -d "$FLUTTER_SDK_PATH" ]; then
  git clone --branch stable https://github.com/flutter/flutter.git $FLUTTER_SDK_PATH
fi

# Key: add Flutter to PATH
export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

flutter config --enable-web
flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY