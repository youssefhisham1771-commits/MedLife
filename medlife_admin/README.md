# MedLife Admin Panel

Independent Flutter administration app for MedLife.

## Development setup

This app is intentionally isolated under `medlife_admin/`; it does not replace the customer app at the repository root.

From this directory:

```powershell
flutter create . --platforms=web,windows,android,ios
flutter pub get
flutter run -d chrome
```

The Firebase options are copied from the existing MedLife app and point to the existing Firebase project. Do not deploy modified Firestore rules as part of this setup.

## Current milestone

- Independent Flutter app scaffold.
- Existing Firebase project configuration reused.
- Admin sign-in gate checks the signed-in user's `users/{uid}.role == admin`.
- Modern Premium responsive shell and initial live dashboard.
- Remaining modules will be implemented and validated incrementally.
