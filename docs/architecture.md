# TokenScope Firebase Lab 3 Architecture

## Runtime boundary

```text
Screen/View
    -> ChangeNotifier ViewModel
    -> FirebaseLab3Controller / AuthController
    -> Firebase service adapter
    -> Firebase SDK
```

Firebase service SDK imports are restricted to `lib/services/`; the only
bootstrap exception is `main.dart`, which initializes `firebase_core`. Screens
use `FirebaseLab3Controller` for Lab 3 operations and `AuthController` for the
session state.

## Firebase ownership

| Capability | Service adapter | ViewModel boundary |
| --- | --- | --- |
| Authentication | `FirebaseAuthService` | `AuthController` |
| Storage | `FirebaseStorageService` | `FirebaseLab3Controller` |
| Messaging | `FirebaseMessagingService` | `FirebaseLab3Controller` |
| Analytics | `FirebaseAnalyticsService` | `FirebaseLab3Controller` |
| Crashlytics | `FirebaseCrashlyticsService` | `FirebaseLab3Controller` |
| Remote Config | `FirebaseRemoteConfigService` | `FirebaseLab3Controller` |

## State rules

- Authentication exposes `unknown`, `authenticating`, `authenticated`, and
  `unauthenticated` through `AuthController`.
- Usage and dashboard controllers expose loading, data, empty, and error
  states.
- Firebase failures are returned to the ViewModel as explicit failure values
  or exceptions; no simulated cloud success is returned to the UI.

## Notification routing

`FirebaseMessagingService` stores received messages locally and emits a
navigation intent. `TokenScopeApp` owns the `NavigatorKey` and maps intents to
named routes, keeping route handling outside the Firebase adapter.
