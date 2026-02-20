---
name: ios-design-guidelines
description: Apple Human Interface Guidelines for iPhone. Use when building, reviewing, or refactoring SwiftUI/UIKit interfaces for iOS. Triggers on tasks involving iPhone UI, iOS components, accessibility, Dynamic Type, Dark Mode, or HIG compliance.
license: MIT
metadata:
  author: platform-design-skills
  version: "1.0.0"
---

# iOS Design Guidelines for iPhone

Comprehensive rules derived from Apple's Human Interface Guidelines. Apply these when building, reviewing, or refactoring any iPhone app interface.

---

## 1. Layout & Safe Areas
**Impact:** CRITICAL

### Rule 1.1: Minimum 44pt Touch Targets
All interactive elements must have a minimum tap target of 44x44 points. This includes buttons, links, toggles, and custom controls.

**Correct:**
```swift
Button("Save") { save() }
    .frame(minWidth: 44, minHeight: 44)
```

**Incorrect:**
```swift
// 20pt icon with no padding — too small to tap reliably
Button(action: save) {
    Image(systemName: "checkmark")
        .font(.system(size: 20))
}
// Missing .frame(minWidth: 44, minHeight: 44)
```

### Rule 1.2: Respect Safe Areas
Never place interactive or essential content under the status bar, Dynamic Island, or home indicator. Use SwiftUI's automatic safe area handling or UIKit's `safeAreaLayoutGuide`.

**Correct:**
```swift
struct ContentView: View {
    var body: some View {
        VStack {
            Text("Content")
        }
        // SwiftUI respects safe areas by default
    }
}
```

**Incorrect:**
```swift
struct ContentView: View {
    var body: some View {
        VStack {
            Text("Content")
        }
        .ignoresSafeArea() // Content will be clipped under notch/Dynamic Island
    }
}
```

Use `.ignoresSafeArea()` only for background fills, images, or decorative elements — never for text or interactive controls.

### Rule 1.3: Primary Actions in the Thumb Zone
Place primary actions at the bottom of the screen where the user's thumb naturally rests. Secondary actions and navigation belong at the top.

**Correct:**
```swift
VStack {
    ScrollView { /* content */ }
    Button("Continue") { next() }
        .buttonStyle(.borderedProminent)
        .padding()
}
```

**Incorrect:**
```swift
VStack {
    Button("Continue") { next() } // Top of screen — hard to reach one-handed
        .buttonStyle(.borderedProminent)
        .padding()
    ScrollView { /* content */ }
}
```

### Rule 1.4: Support All iPhone Screen Sizes
Design for iPhone SE (375pt wide) through iPhone Pro Max (430pt wide). Use flexible layouts, avoid hardcoded widths.

**Correct:**
```swift
HStack(spacing: 12) {
    ForEach(items) { item in
        CardView(item: item)
            .frame(maxWidth: .infinity) // Adapts to screen width
    }
}
```

**Incorrect:**
```swift
HStack(spacing: 12) {
    ForEach(items) { item in
        CardView(item: item)
            .frame(width: 180) // Breaks on SE, wastes space on Pro Max
    }
}
```

### Rule 1.5: 8pt Grid Alignment
Align spacing, padding, and element sizes to multiples of 8 points (8, 16, 24, 32, 40, 48). Use 4pt for fine adjustments.

### Rule 1.6: Landscape Support
Support landscape orientation unless the app is task-specific (e.g., camera). Use `ViewThatFits` or `GeometryReader` for adaptive layouts.

---

## 2. Navigation
**Impact:** CRITICAL

### Rule 2.1: Tab Bar for Top-Level Sections
Use a tab bar at the bottom of the screen for 3 to 5 top-level sections. Each tab should represent a distinct category of content or functionality.

**Correct:**
```swift
TabView {
    HomeView()
        .tabItem {
            Label("Home", systemImage: "house")
        }
    SearchView()
        .tabItem {
            Label("Search", systemImage: "magnifyingglass")
        }
    ProfileView()
        .tabItem {
            Label("Profile", systemImage: "person")
        }
}
```

**Incorrect:**
```swift
// Hamburger menu hidden behind three lines — discoverability is near zero
NavigationView {
    Button(action: { showMenu.toggle() }) {
        Image(systemName: "line.horizontal.3")
    }
}
```

### Rule 2.2: Never Use Hamburger Menus
Hamburger (drawer) menus hide navigation, reduce discoverability, and violate iOS conventions. Use a tab bar instead. If you have more than 5 sections, consolidate or use a "More" tab.

### Rule 2.3: Large Titles in Primary Views
Use `.navigationBarTitleDisplayMode(.large)` for top-level views. Titles transition to inline (`.inline`) when the user scrolls.

**Correct:**
```swift
NavigationStack {
    List(items) { item in
        ItemRow(item: item)
    }
    .navigationTitle("Messages")
    .navigationBarTitleDisplayMode(.large)
}
```

### Rule 2.4: Never Override Back Swipe
The swipe-from-left-edge gesture for back navigation is a system-level expectation. Never attach custom gesture recognizers that interfere with it.

**Incorrect:**
```swift
.gesture(
    DragGesture()
        .onChanged { /* custom drawer */ } // Conflicts with system back swipe
)
```

### Rule 2.5: Use NavigationStack for Hierarchical Content
Use `NavigationStack` (not the deprecated `NavigationView`) for drill-down content. Use `NavigationPath` for programmatic navigation.

**Correct:**
```swift
NavigationStack(path: $path) {
    List(items) { item in
        NavigationLink(value: item) {
            ItemRow(item: item)
        }
    }
    .navigationDestination(for: Item.self) { item in
        ItemDetail(item: item)
    }
}
```

### Rule 2.6: Preserve State Across Navigation
When users navigate back and then forward, or switch tabs, restore the previous scroll position and input state. Use `@SceneStorage` or `@State` to persist view state.

---

## 3. Typography & Dynamic Type
**Impact:** HIGH

### Rule 3.1: Use Built-in Text Styles
Always use semantic text styles rather than hardcoded sizes. These scale automatically with Dynamic Type.

**Correct:**
```swift
VStack(alignment: .leading, spacing: 4) {
    Text("Section Title")
        .font(.headline)
    Text("Body content that explains the section.")
        .font(.body)
    Text("Last updated 2 hours ago")
        .font(.caption)
        .foregroundStyle(.secondary)
}
```

**Incorrect:**
```swift
VStack(alignment: .leading, spacing: 4) {
    Text("Section Title")
        .font(.system(size: 17, weight: .semibold)) // Won't scale with Dynamic Type
    Text("Body content")
        .font(.system(size: 15)) // Won't scale with Dynamic Type
}
```

### Rule 3.2: Support Dynamic Type Including Accessibility Sizes
Dynamic Type can scale text up to approximately 200% at the largest accessibility sizes. Layouts must reflow — never truncate or clip essential text.

**Correct:**
```swift
HStack {
    Image(systemName: "star")
    Text("Favorites")
        .font(.body)
}
// At accessibility sizes, consider using ViewThatFits or
// AnyLayout to switch from HStack to VStack
```

Use `@Environment(\.dynamicTypeSize)` to detect size category and adapt layouts:

```swift
@Environment(\.dynamicTypeSize) var dynamicTypeSize

var body: some View {
    if dynamicTypeSize.isAccessibilitySize {
        VStack { content }
    } else {
        HStack { content }
    }
}
```

### Rule 3.3: Custom Fonts Must Use UIFontMetrics
If you use a custom typeface, scale it with `UIFontMetrics` so it responds to Dynamic Type.

**Correct:**
```swift
extension Font {
    static func scaledCustom(size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        .custom("CustomFont-Regular", size: size, relativeTo: textStyle)
    }
}

// Usage
Text("Hello")
    .font(.scaledCustom(size: 17, relativeTo: .body))
```

### Rule 3.4: SF Pro as System Font
Use the system font (SF Pro) unless brand requirements dictate otherwise. SF Pro is optimized for legibility on Apple displays.

### Rule 3.5: Minimum 11pt Text
Never display text smaller than 11pt. Prefer 17pt for body text. Use the `caption2` style (11pt) as the absolute minimum.

### Rule 3.6: Hierarchy Through Weight and Size
Establish visual hierarchy through font weight and size. Do not rely solely on color to differentiate text levels.

---

## 4. Color & Dark Mode
**Impact:** HIGH

### Rule 4.1: Use Semantic System Colors
Use system-provided semantic colors that automatically adapt to light and dark modes.

**Correct:**
```swift
Text("Primary text")
    .foregroundStyle(.primary) // Adapts to light/dark

Text("Secondary info")
    .foregroundStyle(.secondary)

VStack { }
    .background(Color(.systemBackground)) // White in light, black in dark
```

**Incorrect:**
```swift
Text("Primary text")
    .foregroundColor(.black) // Invisible on dark backgrounds

VStack { }
    .background(.white) // Blinding in Dark Mode
```

### Rule 4.2: Provide Light and Dark Variants for Custom Colors
Define custom colors in the asset catalog with both Any Appearance and Dark Appearance variants.

```swift
// In Assets.xcassets, define "BrandBlue" with:
// Any Appearance: #0066CC
// Dark Appearance: #4DA3FF

Text("Brand text")
    .foregroundStyle(Color("BrandBlue")) // Automatically switches
```

### Rule 4.3: Never Rely on Color Alone
Always pair color with text, icons, or shapes to convey meaning. Approximately 8% of men have some form of color vision deficiency.

**Correct:**
```swift
HStack {
    Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.red)
    Text("Error: Invalid email address")
        .foregroundStyle(.red)
}
```

**Incorrect:**
```swift
// Only color indicates the error — invisible to colorblind users
TextField("Email", text: $email)
    .border(isValid ? .green : .red)
```

### Rule 4.4: 4.5:1 Contrast Ratio Minimum
All text must meet WCAG AA contrast ratios: 4.5:1 for normal text, 3:1 for large text (18pt+ or 14pt+ bold).

### Rule 4.5: Support Display P3 Wide Gamut
Use Display P3 color space for vibrant, accurate colors on modern iPhones. Define colors in the asset catalog with the Display P3 gamut.

### Rule 4.6: Background Hierarchy
Use the three-level background hierarchy for depth:
- `systemBackground` — primary surface
- `secondarySystemBackground` — grouped content, cards
- `tertiarySystemBackground` — elements within grouped content

### Rule 4.7: One Accent Color for Interactive Elements
Choose a single tint/accent color for all interactive elements (buttons, links, toggles). This creates a consistent, learnable visual language.

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.indigo) // All interactive elements use indigo
        }
    }
}
```

---


## Further reference

See [references/ios-design-reference.md](references/ios-design-reference.md) for accessibility, gestures, components, patterns, privacy, system integration, quick reference, evaluation checklist, and anti-patterns.
