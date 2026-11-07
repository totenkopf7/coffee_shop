#!/bin/bash
set -e

# Clone a specific Flutter version instead of "stable"
# 3.13.2 is your local version. 
# If 3.13.2 fails, try 3.16.0 or 3.19.0.
FLUTTER_VERSION="3.13.2"
FLUTTER_SDK_PATH="$HOME/flutter"

if [ ! -d "$FLUTTER_SDK_PATH" ]; then
  echo "Cloning Flutter SDK version $FLUTTER_VERSION..."
  git clone https://github.com/flutter/flutter.git -b $FLUTTER_VERSION --depth 1 $FLUTTER_SDK_PATH
fi

export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

flutter --version
flutter pub get
flutter build web --release