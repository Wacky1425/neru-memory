# Neru Memory - Firebase setup

1. Install Firebase CLI (if not installed) and login: `firebase login`
2. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
3. From this project root run: `flutterfire configure`
   - Select/create the Firebase project for Neru Memory.
   - Select Android and Web.
   - This replaces `lib/firebase_options.dart` with real project values.
4. Firebase Console > Authentication > Sign-in method > enable Google.
5. For Android Google Sign-In, register the app SHA-1 in Firebase project settings. You can get it with `cd android && .\\gradlew signingReport` on Windows.
6. Firebase Console > Firestore Database > Create database.
7. Deploy the included owner-only rules with Firebase CLI, or paste `firestore.rules` into the Firestore Rules editor and publish.
8. Run `flutter pub get`, `flutter analyze`, `flutter test`, then `flutter run`.

Data is stored at `users/{uid}/app/state`. Local SharedPreferences remains as a local cache. When signed in for the first time, local data is uploaded if the cloud state does not exist; otherwise cloud data wins on sign-in.
