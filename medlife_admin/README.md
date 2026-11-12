# MedLife Admin Command Center

The admin application is a separate Flutter app in this folder. It reuses the existing Firebase project and existing MedLife collections; it does not create a replacement store database.

## Run locally

```powershell
cd medlife_admin
flutter pub get
dart format lib
flutter analyze
flutter run -d chrome
```

For Android/iOS, select the connected device after confirming Firebase platform configuration.

## Included sections

- Overview and live business metrics
- Searchable orders, sorting, order details, and status updates
- Product CRUD
- Customers
- Finance summary and advanced operational reports
- Staff directory (read-only)
- Live-data assistant (rule-based summaries, not generative AI)
- Automation rule management
- Activity log
- Inventory quantity tracking
- Marketing: promo codes and homepage banners
- Delivery fee management
- Notifications center
- System/account settings
- Existing legacy admin tools

## Important implementation notes

- Firebase Auth is used, with an admin check at `users/{uid}.role == admin`.
- Google popup sign-in is enabled only on web; email/password remains available on other configured platforms.
- Inventory uses the `quantity` field. Existing products without it remain untracked until a quantity is set.
- Finance figures are gross delivered order totals, not net profit.
- The assistant calculates summaries from Firestore; no external AI provider is connected.
- Staff role editing is intentionally disabled. Role changes need a trusted server-side authorization workflow.
- Automation event handlers require Cloud Functions deployment before they run.
- No Firebase deployment, production data migration, or live database mutation is performed by these changes.
- Review Firestore rules and run local/Emulator tests before any deployment.
