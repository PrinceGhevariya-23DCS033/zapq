# Google Sign-In Setup Instructions

## Current Issue
Google Sign-In is showing error code 10 (DEVELOPER_ERROR) because it's not properly configured in Firebase Console.

## Steps to Fix Google Sign-In

### 1. Get Your SHA-1 Fingerprint
Run this command in your project root:
```bash
cd android
.\gradlew signingReport
```

Or use keytool directly:
```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copy the SHA-1 fingerprint from the output.

### 2. Add SHA-1 to Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `zapq-73533`
3. Go to Project Settings (gear icon)
4. Select "Your apps" tab
5. Find your Android app (`com.zappq.queue`)
6. Click "Add fingerprint"
7. Paste your SHA-1 fingerprint
8. Click "Save"

### 3. Enable Google Sign-In
1. In Firebase Console, go to "Authentication" > "Sign-in method"
2. Click on "Google"
3. Enable it by toggling the switch
4. Set your project support email
5. Click "Save"

### 4. Download New google-services.json
1. After adding SHA-1 and enabling Google Sign-In
2. Go to Project Settings > Your apps > Android app
3. Click "Download google-services.json"
4. Replace the existing file at `android/app/google-services.json`

### 5. Update Android Configuration
Add to `android/app/build.gradle.kts` (already done):
```kotlin
dependencies {
    implementation("com.google.android.gms:play-services-auth:20.7.0")
}
```

### 6. Test Google Sign-In
After completing steps 1-4:
1. Clean and rebuild: `flutter clean && flutter pub get`
2. Run the app: `flutter run`
3. Try Google Sign-In - it should work now

## Temporary Solution
For now, you can use email/password authentication which is working properly.

## Alternative: Test Account Setup
If you want to test immediately, create a test account:
- Email: test@zapq.com
- Password: test123456

The email/password registration and login are fully functional.
