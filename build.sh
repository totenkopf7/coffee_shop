#!/bin/bash
set -e

# Install Flutter SDK if not present
FLUTTER_SDK_PATH="$HOME/flutter"
if [ ! -d "$FLUTTER_SDK_PATH" ]; then
  echo "Cloning Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 $FLUTTER_SDK_PATH
fi

# Add Flutter to PATH for THIS shell session
export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

# Verify Flutter is available
flutter --version

# Get dependencies and build
flutter pub get
flutter build web --release