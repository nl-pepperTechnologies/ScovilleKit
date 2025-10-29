# ⚡ How to Use ScovilleKit

This quickstart shows how to integrate **ScovilleKit** into your iOS app.  
It is fully compatible with Swift 6.2’s strict concurrency model and the Scoville API backend.

---

## 1️⃣ Import and Configure

In your app entry point (usually `MyApp.swift` or `AppDelegate.swift`):

```swift
import ScovilleKit

@main
struct MyApp: App {
    init() {
        // Configure Scoville once at app launch
        Scoville.configure(apiKey: "YOUR_API_KEY")
        Scoville.configureAPI(url: "https://pixelwonders.nl/api") // optional override
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

When you receive your **APNs token** (e.g. inside  
`application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`):

```swift
Scoville.registerDevice(token: tokenString)
```

The token is optional — if push permissions are declined, ScovilleKit will still register
the device using its persistent UUID.

---

## 3️⃣ Track Events

### Predefined events

```swift
Scoville.track(.appOpened)
Scoville.track(.purchaseCompleted, parameters: ["amount": 5.99])
```

### Custom events

```swift
Scoville.track("custom_event_name", parameters: [
    "foo": "bar",
    "value": 123,
    "active": true
])
```

✅ All parameters must be one of: `String`, `Int`, `Double`, or `Bool`.

---

## 4️⃣ Debugging & Diagnostics

To verify configuration and API connectivity:

```swift
Scoville.debugPrintStatus()
```

You can also test your API connection:

```swift
Scoville.testHeartbeat { result in
    switch result {
    case .success:
        print("✅ Heartbeat OK")
    case .failure(let error):
        print("❌ Heartbeat failed:", error.localizedDescription)
    }
}
```

Example console output:

```
[ScovilleKit][Config] ✅ Configured for mennospijker.nl.Kenteken-Scanner — version 2.0.0 (90)
[ScovilleKit][Device] ✅ Device registered successfully
[ScovilleKit][Analytics] 📊 Event 'AppOpened' tracked successfully
```

---

## 5️⃣ Notes

- Thread-safe, actor-isolated, and 100% Sendable-compliant.  
- Works seamlessly with Swift Concurrency (`async`/`await` + `Task.detached`).  
- Logs are prefixed with `[ScovilleKit][Category]` for clarity.  
- Device registration gracefully handles missing push tokens.  
- All events are rejected by the backend if the device is not registered.

---

© 2025 Pepper Technologies — All rights reserved.
