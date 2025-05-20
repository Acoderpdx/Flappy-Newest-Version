#!/bin/bash

echo "Cleaning Flutter project..."
flutter clean

echo "Removing Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

echo "Removing Flutter pub cache..."
flutter pub cache repair

echo "Re-getting dependencies..."
flutter pub get

echo "Updating Podfiles..."
cd ios
pod deintegrate
pod update
pod install --repo-update
cd ..

echo "Building for iOS..."
flutter build ios --debug

echo "Clean and rebuild complete. Now try running in Xcode."
