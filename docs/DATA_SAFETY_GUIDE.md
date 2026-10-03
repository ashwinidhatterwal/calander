# Google Play Data Safety Guide

This is a conservative declaration guide for the current Checkpoint 13 design. Re-check the Play Console wording at submission time.

## Core app
- Ads: No
- Required account: No
- Behavioral analytics: No
- Developer server for calendar data: No
- Personal events: stored locally on device
- Language/location preferences: stored locally on device
- Optional approximate/precise foreground coordinates: stored locally for Panchang and widgets; no developer-server upload or background tracking
- Explicit location refresh can call Android's system geocoder (potentially network-backed). The district fallback and repair of saved division labels run offline. Names stay saved locally.
- Morning reminders default on unless explicitly disabled, with Android notification permission still required. Personal-event reminders are separately optional. Optional user-granted Alarms & reminders access enables selected precise reminder times; reminder text may appear on the lock screen according to system settings.
- Android location permission is optional; manual city selection works without it

## Optional support flow
The app opens an external UPI app for a voluntary developer tip. The calendar app does not receive or store banking credentials.

## Optional handwritten note request
If the user chooses to request a physical handwritten thank-you note, the app opens their email client and the user may voluntarily send:
- Name
- Email address (inherent in their email message)
- Postal address
- Optional payment transaction reference

The app itself does not store this information. Because the flow intentionally facilitates communication to the developer, the safest Play Console approach is to disclose Name / Email address / Physical address as **optional, user-initiated developer communication** if the current Data Safety questionnaire treats this as collection through the app. Mark it not sold and not shared with third parties by the developer.

The privacy policy commits to use postal-address information only to mail the requested note and delete it within 30 days after dispatch.
