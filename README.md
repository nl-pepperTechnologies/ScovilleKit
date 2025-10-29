# 📊 ScovilleKit — Developer README

ScovilleKit is a lightweight analytics SDK for iOS apps by Pepper Technologies.
It offers **event tracking**, **device registration**, and **simple API configuration** for the Scoville backend.

---

## 🔧 Installation

### Swift Package Manager (recommended)
1. In Xcode: **File → Add Packages…**
2. Enter the repo URL (or add the local package).
3. Add **ScovilleKit** to your app target.

### Manual
Drag the `ScovilleKit` sources into your app target.

---

## 🚀 Quick Start

Initialize once at launch (e.g., in your `@main` App init or `application(_:didFinishLaunchingWithOptions:)`).

```swift
import ScovilleKit

@main
struct MyApp: App {
    init() {
        Scoville.configure(apiKey: "YOUR_API_KEY")
        Scoville.configureAPI(url: "https://your-api-endpoint.com")
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

### Register the device (when you receive your APNs token)
```swift
Scoville.registerDevice(token: apnsTokenString)
```

### Track events
```swift
// Predefined event
Scoville.track(.appOpened)

// Custom event
Scoville.track("CustomEvent", parameters: [
    "foo": "bar",
    "value": 123,
    "premium": true,
    "ratio": 0.42
])
```

**Supported parameter types:** `String`, `Int`, `Double`, `Bool` (via `AnalyticsValue`).

---

## 🧩 Project Structure (Files Overview)

- **Scoville.swift** — Public API. Holds configuration (API key, bundle ID, version/build, persistent UUID), event tracking, device registration, and debug logging. Runs network calls via `ScovilleNetwork` using Swift Concurrency friendly patterns.
- **ScovilleKit.swift** — Module entry file (export surface).
- **ScovilleNetwork.swift** — Thin HTTP client with configurable base URL. Provides `post(endpoint:apiKey:body:completion:)` used by tracking + registration. Configure via `Scoville.configureAPI(url:)`.
- **ScovilleLogger.swift** — Minimal console logger (debug-level printing).
- **EventPayload.swift** — `Codable & Sendable` payload for `/v2/analytics/track`. Includes `uuid`, `eventName`, `parameters`, `bundleId`, `version`, and `build`.
- **DevicePayload.swift** — `Codable & Sendable` payload for `/v2/devices/register`. Includes `uuid`, `token`, `platform`, `version`, `build`, `bundleId`.
- **AnalyticsValue.swift** — Type-safe wrapper for parameter values (string, int, double, bool). Fully `Codable & Sendable`.
- **AnalyticsEventName.swift** — Enum of common event names. You can add your own cases or pass raw strings via `Scoville.track(_ eventName:String, ...)`.
- **Bundle+Info.swift** — Helper to extract `bundleId`, `version`, `build` from `Bundle.main`.

> If you previously used `AnyCodable`, the SDK now uses `AnalyticsValue` for **strict Sendable safety** under Swift 6 / strict concurrency.

---

## 🌐 Networking

- **Base URL**: configure at launch with `Scoville.configureAPI(url:)`.
- **Endpoints**:
  - `POST /v2/analytics/track` — body: `EventPayload`
  - `POST /v2/devices/register` — body: `DevicePayload`
- **Auth**: Uses your `apiKey` via `Authorization: Bearer <key>` or as implemented in `ScovilleNetwork`.

> Calls are asynchronous and log success/failure through `ScovilleLogger`.

---

## 🧠 Concurrency & Sendable

- The SDK is safe to use with Swift Concurrency.
- `EventPayload`, `DevicePayload`, and `AnalyticsValue` conform to `Sendable`.
- Public API methods that hop across threads use `Task {}` but log on the main actor for UI-friendly output.

---

## 🧪 Testing Tips

Example unit tests (pseudo):
```swift
func testConfigurationStoresApiKey() {
    Scoville.configure(apiKey: "TEST_KEY")
    // If no crash and no missing config warnings, OK
    XCTAssertTrue(true)
}

func testTrackEventDoesNotCrash() {
    Scoville.configure(apiKey: "TEST_KEY")
    Scoville.track("TestEvent", parameters: ["foo": "bar", "n": 1])
    XCTAssertTrue(true)
}
```
Consider stubbing `ScovilleNetwork` for deterministic tests.

---

## 🗺️ Usage Patterns & Best Practices

- **Initialize early** (on app start).
- **Register device** whenever the push token changes.
- **Use enums** for common events (`AnalyticsEventName`) and freeform strings for ad-hoc analytics.
- **Keep parameters primitive** (String/Int/Double/Bool). If you need arrays or nested objects later, extend `AnalyticsValue` accordingly.
- **Avoid UI work in callbacks** — the SDK already marshals logging to the MainActor.

---

## 🔁 Migration (from `AnyCodable` to `AnalyticsValue`)

Before:
```swift
Scoville.track("MyEvent", parameters: ["any": AnyCodable(something)])
```
After (compile-time safe):
```swift
Scoville.track("MyEvent", parameters: ["flag": true, "name": "abc", "count": 3])
```

---

## 🧰 Troubleshooting

- **“Scoville not configured yet”** → Ensure `Scoville.configure(apiKey:)` is called before any tracking or registration.
- **Network errors** → Check `configureAPI(url:)`, connectivity, and API key validity.
- **Missing events on server** → Confirm endpoint paths (`/v2/analytics/track`, `/v2/devices/register`) and inspect logs from `ScovilleLogger`.

---

## 📝 License

© 2025 Pepper Technologies. All rights reserved. (Replace with your preferred license.)

---

## 👤 Maintainer

Built by **Menno Spijker** · Pepper Technologies
