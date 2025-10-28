
# ⚡ How to Use ScovilleKit

This quickstart shows how to integrate ScovilleKit into your iOS app.

---

## 1️⃣ Import and Configure

In your app entry point (usually `MyApp.swift` or `AppDelegate.swift`):

```swift
import ScovilleKit

@main
struct MyApp: App {
    init() {
        Scoville.configure(apiKey: "YOUR_API_KEY")
        Scoville.configureAPI(url: "https://your-api-endpoint.com")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## 2️⃣ Register Device

When you receive your APNs token (e.g. in `didRegisterForRemoteNotificationsWithDeviceToken`):

```swift
Scoville.registerDevice(token: tokenString)
```

This links the device to your backend for analytics and notifications.

---

## 3️⃣ Track Events

Track predefined events:

```swift
Scoville.track(.appOpened)
Scoville.track(.purchaseCompleted, parameters: ["amount": 5.99])
```

Or custom events:

```swift
Scoville.track("custom_event_name", parameters: [
    "foo": "bar",
    "value": 123,
    "active": true
])
```

All parameters must be one of: `String`, `Int`, `Double`, or `Bool`.

---

## 4️⃣ Debugging

Use this to confirm your setup:

```swift
Scoville.debugPrintStatus()
```

Console output example:
```
✅ Scoville configured for nl.pepper.kentekenscanner — version 1.3.0 (87)
📡 Device registered successfully.
📊 Event 'app_opened' tracked successfully.
```

---

## 5️⃣ Ready for Production

- No extra setup needed — events are sent asynchronously.
- Works with Swift Concurrency and strict `Sendable` mode.
- Automatically includes UUID, bundle, version, and build metadata.

---

© 2025 Pepper Technologies
