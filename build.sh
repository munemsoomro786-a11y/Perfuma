#!/bin/bash
# Install Flutter and build the web app for Vercel

echo "Checking Flutter installation..."
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
else
  echo "Flutter directory already exists."
fi

export PATH="$PATH:`pwd`/flutter/bin"
flutter config --enable-web

# Generate firebase_config.dart if environment variables exist
if [ -n "$FIREBASE_API_KEY" ]; then
  echo "Generating Firebase config from environment variables..."
  cat > lib/firebase_config.dart << EOF
import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static const FirebaseOptions options = FirebaseOptions(
    apiKey: '${FIREBASE_API_KEY}',
    authDomain: '${FIREBASE_AUTH_DOMAIN}',
    projectId: '${FIREBASE_PROJECT_ID}',
    storageBucket: '${FIREBASE_STORAGE_BUCKET}',
    messagingSenderId: '${FIREBASE_MESSAGING_SENDER_ID}',
    appId: '${FIREBASE_APP_ID}',
  );
}
EOF
else
  echo "Using default firebase_config.dart..."
fi

flutter build web --release
