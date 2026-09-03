# App Review Notes

SecondClock is a full-screen clock app with Home Screen and Lock Screen widgets. No account or sign-in is required.

Main features:
- Launching the app immediately shows the clock.
- Tap the gear button in the upper-right corner to open customization settings.
- The app supports portrait and landscape orientations.
- To select a photo background, open Settings > Background > Photo. The system Photos picker only returns the image explicitly selected by the user.

In-App Purchase:
- Product ID: `com.irochi.SecondClock.pro.lifetime`
- Type: Non-Consumable
- Access: Launch app > gear button > SecondClock Pro
- Restore: “購入を復元” on the same paywall
- No subscription is used.

Widgets:
- Add SecondClock from the system widget gallery after opening the app once.
- Seconds are rendered with the public SwiftUI timer text mechanism. iOS may reduce updates while Always-On display is dimmed or Low Power Mode is active.

Privacy:
- No analytics, ads, account system, tracking, or developer-operated server is used.
- Settings and the user-selected background image remain in the local App Group container.
- Purchases are processed with StoreKit 2.

Support: `https://secondclock-support.ariken.chatgpt.site/support`
Privacy policy: `https://secondclock-support.ariken.chatgpt.site/privacy`

