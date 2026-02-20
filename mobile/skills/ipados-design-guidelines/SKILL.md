---
name: ipados-design-guidelines
description: Apple Human Interface Guidelines for iPad. Use when building iPad-optimized interfaces, implementing multitasking, pointer support, keyboard shortcuts, or responsive layouts. Triggers on tasks involving iPad, Split View, Stage Manager, sidebar navigation, or trackpad support.
license: MIT
metadata:
  author: platform-design-skills
  version: "1.0.0"
---

# iPadOS Design Guidelines

Comprehensive rules for building iPad-native apps following Apple's Human Interface Guidelines. iPad is not a big iPhone -- it demands adaptive layouts, multitasking support, pointer interactions, keyboard shortcuts, and inter-app drag and drop. These rules extend iOS patterns for the larger, more capable canvas.

---

## 1. Responsive Layout (CRITICAL)

### 1.1 Use Adaptive Size Classes

iPad presents two horizontal size classes: **regular** (full screen, large splits) and **compact** (Slide Over, narrow splits). Design for both. Never hardcode dimensions.

```swift
struct AdaptiveView: View {
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        if sizeClass == .regular {
            TwoColumnLayout()
        } else {
            StackedLayout()
        }
    }
}
```

### 1.2 Don't Scale Up iPhone UI

iPad layouts must be purpose-built. Stretching an iPhone layout across a 13" display wastes space and feels wrong. Use multi-column layouts, master-detail patterns, and increased information density in regular width.

### 1.3 Support All iPad Screen Sizes

Design for the full range: iPad Mini (8.3"), iPad (10.9"), iPad Air (11"/13"), and iPad Pro (11"/13"). Use flexible layouts that redistribute content rather than simply scaling.

### 1.4 Column-Based Layouts for Regular Width

In regular width, organize content into columns. Two-column is the most common (sidebar + detail). Three-column works for deep hierarchies (sidebar + list + detail). Avoid single-column full-width layouts on large screens.

```swift
struct ThreeColumnLayout: View {
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } content: {
            ContentListView()
        } detail: {
            DetailView()
        }
    }
}
```

### 1.5 Respect Safe Areas

iPad safe areas differ from iPhone. Older iPads have no home indicator. iPads in landscape have different insets than portrait. Always use `safeAreaInset` and never hardcode padding for notches or indicators.

### 1.6 Support Both Orientations

iPad apps must work well in both portrait and landscape. Landscape is the dominant orientation for productivity. Portrait is common for reading. Adapt column counts and layout density to orientation.

---

## 2. Multitasking (CRITICAL)

### 2.1 Support Split View

Your app must function correctly at 1/3, 1/2, and 2/3 screen widths in Split View. At 1/3 width, your app receives compact horizontal size class. Content must remain usable at every split ratio.

### 2.2 Support Slide Over

Slide Over presents your app as a compact-width overlay on the right edge. It behaves like an iPhone-width app. Ensure all functionality remains accessible in this narrow mode.

### 2.3 Handle Stage Manager

Stage Manager allows freely resizable windows and multiple windows simultaneously. Your app must:
- Resize fluidly to arbitrary dimensions
- Support multiple scenes (windows) showing different content
- Not assume any fixed size or aspect ratio

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Support multiple windows
        WindowGroup("Detail", for: Item.ID.self) { $itemId in
            DetailView(itemId: itemId)
        }
    }
}
```

### 2.4 Never Assume Full Screen

The app may launch directly into Split View or Stage Manager. Do not depend on full-screen dimensions during setup, onboarding, or any flow. Test your app at every possible size.

### 2.5 Handle Size Transitions Gracefully

When the user resizes via multitasking, animate layout changes smoothly. Preserve scroll position, selection state, and user context across size transitions. Never reload content on resize.

### 2.6 Support Multiple Scenes

Use `UIScene` / SwiftUI `WindowGroup` to let users open multiple instances of your app showing different content. Each scene is independent. Support `NSUserActivity` for state restoration.

---

## 3. Navigation (HIGH)

### 3.1 Sidebar for Primary Navigation

In regular width, replace the iPhone tab bar with a sidebar. The sidebar provides more room for navigation items, supports sections, and feels native on iPad.

```swift
struct AppNavigation: View {
    @State private var selection: NavigationItem? = .inbox

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Main") {
                    Label("Inbox", systemImage: "tray")
                        .tag(NavigationItem.inbox)
                    Label("Drafts", systemImage: "doc")
                        .tag(NavigationItem.drafts)
                    Label("Sent", systemImage: "paperplane")
                        .tag(NavigationItem.sent)
                }
                Section("Labels") {
                    // Dynamic sections
                }
            }
            .navigationTitle("Mail")
        } detail: {
            DetailView(for: selection)
        }
    }
}
```

### 3.2 Automatic Tab-to-Sidebar Conversion

SwiftUI `TabView` with `.sidebarAdaptable` style automatically converts to a sidebar in regular width. Use this for seamless iPhone-to-iPad adaptation.

```swift
TabView {
    Tab("Home", systemImage: "house") { HomeView() }
    Tab("Search", systemImage: "magnifyingglass") { SearchView() }
    Tab("Profile", systemImage: "person") { ProfileView() }
}
.tabViewStyle(.sidebarAdaptable)
```

### 3.3 Three-Column Layout for Complex Hierarchies

Use `NavigationSplitView` with three columns when your information architecture has three levels: category > list > detail. Examples: mail (accounts > messages > message), file managers, settings.

### 3.4 Toolbar at Top

On iPad, toolbars live at the top of the screen in the navigation bar area, not at the bottom like iPhone. Place contextual actions in `.toolbar` with appropriate placement.

```swift
.toolbar {
    ToolbarItemGroup(placement: .primaryAction) {
        Button("Compose", systemImage: "square.and.pencil") { }
    }
    ToolbarItemGroup(placement: .secondaryAction) {
        Button("Archive", systemImage: "archivebox") { }
        Button("Delete", systemImage: "trash") { }
    }
}
```

### 3.5 Detail View Should Never Be Empty

When no item is selected in a list/sidebar, show a meaningful empty state in the detail area. Use a placeholder with icon and instruction text, not a blank screen.

---

## 4. Pointer & Trackpad (HIGH)

### 4.1 Add Hover Effects to Interactive Elements

All tappable elements should respond to pointer hover. The system provides automatic hover effects for standard controls. For custom views, use `.hoverEffect()`.

```swift
Button("Action") { }
    .hoverEffect(.highlight)  // Subtle highlight on hover

// Custom hover effect
MyCustomView()
    .hoverEffect(.lift)  // Lifts and adds shadow
```

### 4.2 Pointer Magnetism on Buttons

The pointer should snap to (be attracted toward) button bounds. Standard UIKit/SwiftUI buttons get this automatically. For custom hit targets, ensure the pointer region matches the tappable area using `.contentShape()`.

### 4.3 Support Right-Click Context Menus

Right-click (secondary click) should present context menus. Use `.contextMenu` which automatically supports both long-press (touch) and right-click (pointer).

```swift
Text(item.title)
    .contextMenu {
        Button("Copy", systemImage: "doc.on.doc") { }
        Button("Share", systemImage: "square.and.arrow.up") { }
        Divider()
        Button("Delete", systemImage: "trash", role: .destructive) { }
    }
```

### 4.4 Trackpad Scroll Behaviors

Support two-finger scrolling with momentum. Pinch to zoom where appropriate. Respect scroll direction preferences. For custom scroll views, ensure trackpad gestures feel natural alongside touch gestures.

### 4.5 Customize Cursor for Content Areas

Change cursor appearance based on context. Text areas show I-beam. Links show pointer hand. Resize handles show resize cursors. Draggable items show grab cursor.

### 4.6 Pointer-Driven Drag and Drop

Pointer users expect click-and-drag for rearranging, selecting, and moving content. Combine with multi-select via Shift-click and Cmd-click.

---


## Further reference

See [references/ipados-design-reference.md](references/ipados-design-reference.md) for keyboard, Apple Pencil, drag and drop, external display, evaluation checklist, and anti-patterns.
