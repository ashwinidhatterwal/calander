# Android Build Guide

## Recommended route: GitHub Actions

1. Create a GitHub repository.
2. Put the contents of this checkpoint at the repository root.
3. Push to the `main` branch.
4. Open **Actions → Android QA build**.
5. Run the workflow if it did not start automatically.
6. After success, open the workflow run's **Artifacts** section.
7. Download `hindu-calendar-1.0.0-build19-qa-apk`.
8. Extract and install `app-release.apk` on an Android test device.

## Current Android identity

```text
App label: हिन्दू कैलेंडर
Package ID: in.hinducalendar.hindu_calendar
Version: 1.0.0+19
```

Keep the existing package ID and upload signing key for updates.

## Store release later

For Google Play, do not use the CI template's development signing identity. Before production release:

- finalize package ID;
- create/store the production upload keystore securely;
- configure release signing through GitHub secrets or a trusted local build machine;
- build a signed `.aab` with `flutter build appbundle --release`;
- preserve the signing credentials for all future updates.
