# 🔥 ScovilleKit
**Lightweight analytics & device registration framework for Pepper Technologies apps**

## 🌶 Overview
ScovilleKit is a Swift package developed by **Pepper Technologies** for unified app analytics and device management across multiple iOS and Android apps.
It provides automatic app metadata, event tracking, and secure device registration with your Laravel-based backend (https://pixelwonders.nl/api).

## ✨ Features
- ✅ Persistent device UUID per app
- ✅ Automatic app version / build / bundle ID tracking
- ✅ One-line analytics tracking (`Scoville.track("AppOpened")`)
- ✅ Secure event transport via X-App-Key
- ✅ Device registration with push token (for notifications)
- ✅ Works both locally and in production
- ✅ Extensible architecture for future features (batching, sessions, offline queue)

## 🧱 Installation
### Swift Package Manager
1. In Xcode, go to **File → Add Packages**
2. Enter repository URL:
   ```
   git@github.com:nl-pepperTechnologies/ScovilleKit.git
   ```
3. Choose **Exact Version** and select the latest tag (e.g., `1.0.0`)
4. Import:
   ```swift
   import ScovilleKit
   ```

## 🚀 Quick Start
### 1. Configure Scoville at app launch
```swift
import SwiftUI
import ScovilleKit

@main
struct KentekenScannerApp: App {
    init() {
        Scoville.configure(apiKey: "YOUR_APP_API_KEY")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```
Automatically:
- Stores persistent UUID
- Captures bundle ID, app version & build
- Sends first launch event (`AppOpened`)

### 2. Track custom events
```swift
Scoville.track("LicensePlateSearch", parameters: [
    "query": "KZ-123-X",
    "success": true
])
```

### 3. Register device for push notifications
```swift
func application(_ application: UIApplication,
                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Scoville.registerDevice(pushToken: deviceToken)
}
```

## 🧠 Architecture Overview
1. **App Launch →** `Scoville.configure()`
2. **User Actions →** `Scoville.track(event)`
3. **Push Token Granted →** `Scoville.registerDevice()`
4. **Admin App →** Reads data from `/v2/analytics/...`

## 🧩 Backend Endpoints
| Endpoint | Purpose | Method | Auth |
|-----------|----------|--------|------|
| `/api/v2/analytics/track` | Send events | POST | X-App-Key |
| `/api/v2/devices/register` | Register device | POST | X-App-Key |

## ⚠️ Notes
- Call `Scoville.configure()` before any tracking.
- API key authenticates your app to the backend.
- Local builds use your LAN IP.
- Only anonymized data is collected.

## 🧑‍💻 Maintained by
**Pepper Technologies**
🇳🇱 Eindhoven, The Netherlands
https://peppertechnologies.nl
