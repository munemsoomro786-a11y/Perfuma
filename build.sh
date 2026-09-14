#!/bin/bash
# Install Flutter and build the web app for Vercel
echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter config --enable-web
flutter build web
