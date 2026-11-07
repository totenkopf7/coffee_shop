#!/bin/bash
set -e

# Pin to a Flutter version where flutter_localizations allows web >=0.5.1
FLUTTER_VERSION="3.24.0"
FLUTTER_SDK_PATH="$HOME/flutter"

if [ ! -d "$FLUTTER_SDK_PATH" ]; then
  echo "Cloning Flutter SDK version $FLUTTER_VERSION..."
  git clone https://github.com/flutter/flutter.git -b $FLUTTER_VERSION --depth 1 $FLUTTER_SDK_PATH
fi

export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

flutter --version
flutter pub get
flutter build web --release