# iOS design reference (accessibility, components, patterns, privacy, system integration)

See [SKILL.md](../SKILL.md) for layout and safe areas, navigation, typography, and color & dark mode.

## 5. Accessibility
**Impact:** CRITICAL

### Rule 5.1: VoiceOver Labels on All Interactive Elements
Every button, control, and interactive element must have a meaningful accessibility label.

**Correct:**
```swift
Button(action: addToCart) {
    Image(systemName: "cart.badge.plus")
}
.accessibilityLabel("Add to cart")
```

**Incorrect:**
```swift
Button(action: addToCart) {
    Image(systemName: "cart.badge.plus")
}
// VoiceOver reads "cart.badge.plus" — meaningless to users
```

### Rule 5.2: Logical VoiceOver Navigation Order
Ensure VoiceOver reads elements in a logical order. Use `.accessibilitySortPriority()` to adjust when the visual layout doesn't match the reading order.

```swift
VStack {
    Text("Price: $29.99")
        .accessibilitySortPriority(1) // Read first
    Text("Product Name")
        .accessibilitySortPriority(2) // Read second
}
```

### Rule 5.3: Support Bold Text
When the user enables Bold Text in Settings, use the `.bold` dynamic type variants. SwiftUI text styles handle this automatically. Custom text must respond to `UIAccessibility.isBoldTextEnabled`.

### Rule 5.4: Support Reduce Motion
Disable decorative animations and parallax when Reduce Motion is enabled. Use `@Environment(\.accessibilityReduceMotion)`.

**Correct:**
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    CardView()
        .animation(reduceMotion ? nil : .spring(), value: isExpanded)
}
```

### Rule 5.5: Support Increase Contrast
When the user enables Increase Contrast, ensure custom colors have higher-contrast variants. Use `@Environment(\.colorSchemeContrast)` to detect.

### Rule 5.6: Don't Convey Info Only by Color, Shape, or Position
Information must be available through multiple channels. Pair visual indicators with text or accessibility descriptions.

### Rule 5.7: Alternative Interactions for All Gestures
Every custom gesture must have an equivalent tap-based or menu-based alternative for users who cannot perform complex gestures.

### Rule 5.8: Support Switch Control and Full Keyboard Access
Ensure all interactions work with Switch Control (external switches) and Full Keyboard Access (Bluetooth keyboards). Test navigation order and focus behavior.

---

## 6. Gestures & Input
**Impact:** HIGH

### Rule 6.1: Use Standard Gestures
Use the standard iOS gesture vocabulary: tap, long press, swipe, pinch, rotate. Users already understand these.

| Gesture | Standard Use |
|---------|-------------|
| Tap | Primary action, selection |
| Long press | Context menu, preview |
| Swipe horizontal | Delete, archive, navigate back |
| Swipe vertical | Scroll, dismiss sheet |
| Pinch | Zoom in/out |
| Two-finger rotate | Rotate content |

### Rule 6.2: Never Override System Gestures
These gestures are reserved by the system and must not be intercepted:
- Swipe from left edge (back navigation)
- Swipe down from top-left (Notification Center)
- Swipe down from top-right (Control Center)
- Swipe up from bottom (home / app switcher)

### Rule 6.3: Custom Gestures Must Be Discoverable
If you add a custom gesture, provide visual hints (e.g., a grabber handle) and ensure the action is also available through a visible button or menu item.

### Rule 6.4: Support All Input Methods
Design for touch first, but also support:
- Hardware keyboards (iPad keyboard accessories, Bluetooth keyboards)
- Assistive devices (Switch Control, head tracking)
- Pointer input (assistive touch)

---

## 7. Components
**Impact:** HIGH

### Rule 7.1: Button Styles
Use the built-in button styles appropriately:
- `.borderedProminent` — primary call-to-action
- `.bordered` — secondary actions
- `.borderless` — tertiary or inline actions
- `.destructive` role — red tint for delete/remove

**Correct:**
```swift
VStack(spacing: 16) {
    Button("Purchase") { buy() }
        .buttonStyle(.borderedProminent)

    Button("Add to Wishlist") { wishlist() }
        .buttonStyle(.bordered)

    Button("Delete", role: .destructive) { delete() }
}
```

### Rule 7.2: Alerts — Critical Info Only
Use alerts sparingly for critical information that requires a decision. Prefer 2 buttons; maximum 3. The destructive option should use `.destructive` role.

**Correct:**
```swift
.alert("Delete Photo?", isPresented: $showAlert) {
    Button("Delete", role: .destructive) { deletePhoto() }
    Button("Cancel", role: .cancel) { }
} message: {
    Text("This photo will be permanently removed.")
}
```

**Incorrect:**
```swift
// Alert for non-critical info — should be a banner or toast
.alert("Tip", isPresented: $showTip) {
    Button("OK") { }
} message: {
    Text("Swipe left to delete items.")
}
```

### Rule 7.3: Sheets for Scoped Tasks
Present sheets for self-contained tasks. Always provide a way to dismiss (close button or swipe down). Use `.presentationDetents()` for half-height sheets.

```swift
.sheet(isPresented: $showCompose) {
    NavigationStack {
        ComposeView()
            .navigationTitle("New Message")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCompose = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") { send() }
                }
            }
    }
    .presentationDetents([.medium, .large])
}
```

### Rule 7.4: Lists — Inset Grouped Default
Use the `.insetGrouped` list style as the default. Support swipe actions for common operations. Minimum row height is 44pt.

**Correct:**
```swift
List {
    Section("Recent") {
        ForEach(recentItems) { item in
            ItemRow(item: item)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { delete(item) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button { archive(item) } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .tint(.blue)
                }
        }
    }
}
.listStyle(.insetGrouped)
```

### Rule 7.5: Tab Bar Behavior
- Use SF Symbols for tab icons — filled variant for the selected tab, outline for unselected
- Never hide the tab bar when navigating deeper within a tab
- Badge important counts with `.badge()`

```swift
TabView {
    MessagesView()
        .tabItem {
            Label("Messages", systemImage: "message")
        }
        .badge(unreadCount)
}
```

### Rule 7.6: Search
Place search using `.searchable()`. Provide search suggestions and support recent searches.

```swift
NavigationStack {
    List(filteredItems) { item in
        ItemRow(item: item)
    }
    .searchable(text: $searchText, prompt: "Search items")
    .searchSuggestions {
        ForEach(suggestions) { suggestion in
            Text(suggestion.title)
                .searchCompletion(suggestion.title)
        }
    }
}
```

### Rule 7.7: Context Menus
Use context menus (long press) for secondary actions. Never use a context menu as the only way to access an action.

```swift
PhotoView(photo: photo)
    .contextMenu {
        Button { share(photo) } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        Button { favorite(photo) } label: {
            Label("Favorite", systemImage: "heart")
        }
        Button(role: .destructive) { delete(photo) } label: {
            Label("Delete", systemImage: "trash")
        }
    }
```

### Rule 7.8: Progress Indicators
- Determinate (`ProgressView(value:total:)`) for operations with known duration
- Indeterminate (`ProgressView()`) for unknown duration
- Never block the entire screen with a spinner

---

## 8. Patterns
**Impact:** MEDIUM

### Rule 8.1: Onboarding — Max 3 Pages, Skippable
Keep onboarding to 3 or fewer pages. Always provide a skip option. Defer sign-in until the user needs authenticated features.

```swift
TabView {
    OnboardingPage(
        image: "wand.and.stars",
        title: "Smart Suggestions",
        subtitle: "Get personalized recommendations based on your preferences."
    )
    OnboardingPage(
        image: "bell.badge",
        title: "Stay Updated",
        subtitle: "Receive notifications for things that matter to you."
    )
    OnboardingPage(
        image: "checkmark.shield",
        title: "Private & Secure",
        subtitle: "Your data stays on your device."
    )
}
.tabViewStyle(.page)
.overlay(alignment: .topTrailing) {
    Button("Skip") { completeOnboarding() }
        .padding()
}
```

### Rule 8.2: Loading — Skeleton Views, No Blocking Spinners
Use skeleton/placeholder views that match the layout of the content being loaded. Never show a full-screen blocking spinner.

**Correct:**
```swift
if isLoading {
    ForEach(0..<5) { _ in
        SkeletonRow() // Placeholder matching final row layout
            .redacted(reason: .placeholder)
    }
} else {
    ForEach(items) { item in
        ItemRow(item: item)
    }
}
```

**Incorrect:**
```swift
if isLoading {
    ProgressView("Loading...") // Blocks the entire view
} else {
    List(items) { item in ItemRow(item: item) }
}
```

### Rule 8.3: Launch Screen — Match First Screen
The launch storyboard must visually match the initial screen of the app. No splash logos, no branding screens. This creates the perception of instant launch.

### Rule 8.4: Modality — Use Sparingly
Present modal views only when the user must complete or abandon a focused task. Always provide a clear dismiss action. Never stack modals on top of modals.

### Rule 8.5: Notifications — High Value Only
Only send notifications for content the user genuinely cares about. Support actionable notifications. Categorize notifications so users can control them granularly.

### Rule 8.6: Settings Placement
- **Frequent settings:** In-app settings screen accessible from a profile or gear icon
- **Privacy/permission settings:** Defer to the system Settings app via URL scheme
- Never duplicate system-level controls in-app

### Rule 8.7: Feedback — Visual + Haptic
Provide immediate feedback for every user action:
- Visual state change (button highlight, animation)
- Haptic feedback for significant actions using `UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator`, or `UISelectionFeedbackGenerator`

```swift
Button("Complete") {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)
    completeTask()
}
```

---

## 9. Privacy & Permissions
**Impact:** HIGH

### Rule 9.1: Request Permissions in Context
Request a permission at the moment the user takes an action that needs it — never at app launch.

**Correct:**
```swift
Button("Take Photo") {
    // Request camera permission only when the user taps this button
    AVCaptureDevice.requestAccess(for: .video) { granted in
        if granted { showCamera = true }
    }
}
```

**Incorrect:**
```swift
// In AppDelegate.didFinishLaunching — too early, no context
func application(_ application: UIApplication, didFinishLaunchingWithOptions ...) {
    AVCaptureDevice.requestAccess(for: .video) { _ in }
    CLLocationManager().requestWhenInUseAuthorization()
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
}
```

### Rule 9.2: Explain Before System Prompt
Show a custom explanation screen before triggering the system permission dialog. The system dialog only appears once — if the user denies, the app must direct them to Settings.

```swift
struct LocationExplanation: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.fill")
                .font(.largeTitle)
            Text("Find Nearby Stores")
                .font(.headline)
            Text("We use your location to show stores within walking distance. Your location is never shared or stored.")
                .font(.body)
                .multilineTextAlignment(.center)
            Button("Enable Location") {
                locationManager.requestWhenInUseAuthorization()
            }
            .buttonStyle(.borderedProminent)
            Button("Not Now") { dismiss() }
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
```

### Rule 9.3: Support Sign in with Apple
If the app offers any third-party sign-in (Google, Facebook), it must also offer Sign in with Apple. Present it as the first option.

### Rule 9.4: Don't Require Accounts Unless Necessary
Let users explore the app before requiring sign-in. Gate only features that genuinely need authentication (purchases, sync, social features).

### Rule 9.5: App Tracking Transparency
If you track users across apps or websites, display the ATT prompt. Respect denial — do not degrade the experience for users who opt out.

### Rule 9.6: Location Button for One-Time Access
Use `LocationButton` for actions that need location once without requesting ongoing permission.

```swift
LocationButton(.currentLocation) {
    fetchNearbyStores()
}
.labelStyle(.titleAndIcon)
```

---

## 10. System Integration
**Impact:** MEDIUM

### Rule 10.1: Widgets for Glanceable Data
Provide widgets using WidgetKit for information users check frequently. Widgets are not interactive (beyond tapping to open the app), so show the most useful snapshot.

### Rule 10.2: App Shortcuts for Key Actions
Define App Shortcuts so users can trigger key actions from Siri, Spotlight, and the Shortcuts app.

```swift
struct MyAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartWorkoutIntent(),
            phrases: ["Start a workout in \(.applicationName)"],
            shortTitle: "Start Workout",
            systemImageName: "figure.run"
        )
    }
}
```

### Rule 10.3: Spotlight Indexing
Index app content with `CSSearchableItem` so users can find it from Spotlight search.

### Rule 10.4: Share Sheet Integration
Support the system share sheet for content that users might want to send elsewhere. Implement `UIActivityItemSource` or use `ShareLink` in SwiftUI.

```swift
ShareLink(item: article.url) {
    Label("Share", systemImage: "square.and.arrow.up")
}
```

### Rule 10.5: Live Activities
Use Live Activities and the Dynamic Island for real-time, time-bound events (delivery tracking, sports scores, workouts).

### Rule 10.6: Handle Interruptions Gracefully
Save state and pause gracefully when interrupted by:
- Phone calls
- Siri invocations
- Notifications
- App switcher
- FaceTime SharePlay

Use `scenePhase` to detect transitions:

```swift
@Environment(\.scenePhase) var scenePhase

.onChange(of: scenePhase) { _, newPhase in
    switch newPhase {
    case .active: resumeActivity()
    case .inactive: pauseActivity()
    case .background: saveState()
    @unknown default: break
    }
}
```

---

## Quick Reference

| Need | Component | Notes |
|------|-----------|-------|
| Top-level sections (3-5) | `TabView` with `.tabItem` | Bottom tab bar, SF Symbols |
| Hierarchical drill-down | `NavigationStack` | Large title on root, inline on children |
| Self-contained task | `.sheet` | Swipe to dismiss, cancel/done buttons |
| Critical decision | `.alert` | 2 buttons preferred, max 3 |
| Secondary actions | `.contextMenu` | Long press; must also be accessible elsewhere |
| Scrolling content | `List` with `.insetGrouped` | 44pt min row, swipe actions |
| Text input | `TextField` / `TextEditor` | Label above, validation below |
| Selection (few options) | `Picker` | Segmented for 2-5, wheel for many |
| Selection (on/off) | `Toggle` | Aligned right in a list row |
| Search | `.searchable` | Suggestions, recent searches |
| Progress (known) | `ProgressView(value:total:)` | Show percentage or time remaining |
| Progress (unknown) | `ProgressView()` | Inline, never full-screen blocking |
| One-time location | `LocationButton` | No persistent permission needed |
| Sharing content | `ShareLink` | System share sheet |
| Haptic feedback | `UIImpactFeedbackGenerator` | `.light`, `.medium`, `.heavy` |
| Destructive action | `Button(role: .destructive)` | Red tint, confirm via alert |

---

## Evaluation Checklist

Use this checklist to audit an iPhone app for HIG compliance:

### Layout & Safe Areas
- [ ] All touch targets are at least 44x44pt
- [ ] No content is clipped under status bar, Dynamic Island, or home indicator
- [ ] Primary actions are in the bottom half of the screen (thumb zone)
- [ ] Layout adapts from iPhone SE to Pro Max without breaking
- [ ] Spacing aligns to the 8pt grid

### Navigation
- [ ] Tab bar is used for 3-5 top-level sections
- [ ] No hamburger/drawer menus
- [ ] Primary views use large titles
- [ ] Swipe-from-left-edge back navigation works throughout
- [ ] State is preserved when switching tabs

### Typography
- [ ] All text uses built-in text styles or `UIFontMetrics`-scaled custom fonts
- [ ] Dynamic Type is supported up to accessibility sizes
- [ ] Layouts reflow at large text sizes (no truncation of essential text)
- [ ] Minimum text size is 11pt

### Color & Dark Mode
- [ ] App uses semantic system colors or provides light/dark asset variants
- [ ] Dark Mode looks intentional (not just inverted)
- [ ] No information conveyed by color alone
- [ ] Text contrast meets 4.5:1 (normal) or 3:1 (large)
- [ ] Single accent color for interactive elements

### Accessibility
- [ ] VoiceOver reads all screens logically with meaningful labels
- [ ] Bold Text preference is respected
- [ ] Reduce Motion disables decorative animations
- [ ] Increase Contrast variant exists for custom colors
- [ ] All gestures have alternative access paths

### Components
- [ ] Alerts are used only for critical decisions
- [ ] Sheets have a dismiss path (button and/or swipe)
- [ ] List rows are at least 44pt tall
- [ ] Tab bar is never hidden during navigation
- [ ] Destructive buttons use the `.destructive` role

### Privacy
- [ ] Permissions are requested in context, not at launch
- [ ] Custom explanation shown before each system permission dialog
- [ ] Sign in with Apple offered alongside other providers
- [ ] App is usable without an account for basic features
- [ ] ATT prompt is shown if tracking, and denial is respected

### System Integration
- [ ] Widgets show glanceable, up-to-date information
- [ ] App content is indexed for Spotlight
- [ ] Share Sheet is available for shareable content
- [ ] App handles interruptions (calls, background, Siri) gracefully

---

## Anti-Patterns

These are common mistakes that violate the iOS Human Interface Guidelines. Never do these:

1. **Hamburger menus** — Use a tab bar. Hamburger menus hide navigation and reduce feature discoverability by up to 50%.

2. **Custom back buttons that break swipe-back** — If you replace the back button, ensure the swipe-from-left-edge gesture still works via `NavigationStack`.

3. **Full-screen blocking spinners** — Use skeleton views or inline progress indicators. Blocking spinners make the app feel frozen.

4. **Splash screens with logos** — The launch screen must mirror the first screen of the app. Branding delays feel artificial.

5. **Requesting all permissions at launch** — Asking for camera, location, notifications, and contacts on first launch guarantees most will be denied.

6. **Hardcoded font sizes** — Use text styles. Hardcoded sizes ignore Dynamic Type and accessibility preferences, breaking the app for millions of users.

7. **Using only color to indicate state** — Red/green for valid/invalid excludes colorblind users. Always pair with icons or text.

8. **Alerts for non-critical information** — Alerts interrupt flow and require dismissal. Use banners, toasts, or inline messages for tips and non-critical information.

9. **Hiding the tab bar on push** — Tab bars should remain visible throughout navigation within a tab. Hiding them disorients users.

10. **Ignoring safe areas** — Using `.ignoresSafeArea()` on content views causes text and buttons to disappear under the notch, Dynamic Island, or home indicator.

11. **Non-dismissable modals** — Every modal must have a clear dismiss path (close button, cancel, swipe down). Trapping users in a modal is hostile.

12. **Custom gestures without alternatives** — A three-finger swipe for undo is unusable for many people. Provide a visible button or menu item as well.

13. **Tiny touch targets** — Buttons and links smaller than 44pt cause mis-taps, especially in lists and toolbars.

14. **Stacked modals** — Presenting a sheet on top of a sheet on top of a sheet creates navigation confusion. Use navigation within a single modal instead.

15. **Dark Mode as an afterthought** — Using hardcoded colors means the app is either broken in Dark Mode or light mode. Always use semantic colors.
