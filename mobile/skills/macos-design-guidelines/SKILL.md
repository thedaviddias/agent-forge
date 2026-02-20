---
name: macos-design-guidelines
description: Apple Human Interface Guidelines for Mac. Use when building macOS apps with SwiftUI or AppKit, implementing menu bars, toolbars, window management, or keyboard shortcuts. Triggers on tasks involving Mac UI, desktop apps, or Mac Catalyst.
license: MIT
metadata:
  author: platform-design-skills
  version: "1.0.0"
---

# macOS Human Interface Guidelines

Mac apps serve power users who expect deep keyboard control, persistent menu bars, resizable multi-window layouts, and tight system integration. These guidelines codify Apple's HIG into actionable rules with SwiftUI and AppKit examples.

---

## 1. Menu Bar (CRITICAL)

Every Mac app must have a menu bar. It is the primary discovery mechanism for commands. Users who cannot find a feature will look in the menu bar before anywhere else.

### Rule 1.1 — Provide Standard Menus

Every app must include at minimum: **App**, **File**, **Edit**, **View**, **Window**, **Help**. Omit File only if the app is not document-based. Add app-specific menus between Edit and View or between View and Window.

```swift
// SwiftUI — Standard menu structure
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            // Adds to existing standard menus
            CommandGroup(after: .newItem) {
                Button("New from Template...") { newFromTemplate() }
                    .keyboardShortcut("T", modifiers: [.command, .shift])
            }
            CommandMenu("Canvas") {
                Button("Zoom to Fit") { zoomToFit() }
                    .keyboardShortcut("0", modifiers: .command)
                Divider()
                Button("Add Artboard") { addArtboard() }
                    .keyboardShortcut("A", modifiers: [.command, .shift])
            }
        }
    }
}
```

```swift
// AppKit — Building menus programmatically
let editMenu = NSMenu(title: "Edit")
let undoItem = NSMenuItem(title: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z")
let redoItem = NSMenuItem(title: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "Z")
editMenu.addItem(undoItem)
editMenu.addItem(redoItem)
editMenu.addItem(.separator())
```

### Rule 1.2 — Keyboard Shortcuts for All Menu Items

Every menu item that performs an action must have a keyboard shortcut. Use standard shortcuts for standard actions (Cmd+C, Cmd+V, Cmd+Z, etc.). Custom shortcuts should use Cmd plus a letter. Reserve Cmd+Shift, Cmd+Option, and Cmd+Ctrl combos for secondary actions.

**Standard Shortcut Reference:**

| Action | Shortcut |
|--------|----------|
| New | Cmd+N |
| Open | Cmd+O |
| Close | Cmd+W |
| Save | Cmd+S |
| Save As | Cmd+Shift+S |
| Print | Cmd+P |
| Undo | Cmd+Z |
| Redo | Cmd+Shift+Z |
| Cut | Cmd+X |
| Copy | Cmd+C |
| Paste | Cmd+V |
| Select All | Cmd+A |
| Find | Cmd+F |
| Find Next | Cmd+G |
| Preferences/Settings | Cmd+, |
| Hide App | Cmd+H |
| Quit | Cmd+Q |
| Minimize | Cmd+M |
| Fullscreen | Cmd+Ctrl+F |

### Rule 1.3 — Dynamic Menu Updates

Menu items must reflect current state. Disable items that are not applicable. Update titles to match context (e.g., "Undo Typing" not just "Undo"). Toggle checkmarks for on/off states.

```swift
// SwiftUI — Dynamic menu state
CommandGroup(replacing: .toolbar) {
    Button(showingSidebar ? "Hide Sidebar" : "Show Sidebar") {
        showingSidebar.toggle()
    }
    .keyboardShortcut("S", modifiers: [.command, .control])
}
```

```swift
// AppKit — Validate menu items
override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    if menuItem.action == #selector(delete(_:)) {
        menuItem.title = selectedItems.count > 1 ? "Delete \(selectedItems.count) Items" : "Delete"
        return !selectedItems.isEmpty
    }
    return super.validateMenuItem(menuItem)
}
```

### Rule 1.4 — Contextual Menus

Provide right-click context menus on all interactive elements. Context menus should contain the most relevant subset of menu bar actions for the clicked element, plus element-specific actions.

```swift
// SwiftUI
Text(item.name)
    .contextMenu {
        Button("Rename...") { rename(item) }
        Button("Duplicate") { duplicate(item) }
        Divider()
        Button("Delete", role: .destructive) { delete(item) }
    }
```

### Rule 1.5 — App Menu Structure

The App menu (leftmost, bold app name) must contain: About, Preferences/Settings (Cmd+,), Services submenu, Hide App (Cmd+H), Hide Others (Cmd+Option+H), Show All, Quit (Cmd+Q). Never rename or remove these standard items.

```swift
// SwiftUI — Settings scene
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
        Settings { SettingsView() }  // Automatically wired to Cmd+,
    }
}
```

---

## 2. Windows (CRITICAL)

Mac users expect full control over window size, position, and lifecycle. An app that fights window management feels fundamentally broken on the Mac.

### Rule 2.1 — Resizable with Sensible Minimums

All main windows must be freely resizable. Set a minimum size that keeps the UI usable. Never set a maximum size unless the content truly cannot scale (rare).

```swift
// SwiftUI
WindowGroup {
    ContentView()
        .frame(minWidth: 600, minHeight: 400)
}
.defaultSize(width: 900, height: 600)
```

```swift
// AppKit
window.minSize = NSSize(width: 600, height: 400)
window.setContentSize(NSSize(width: 900, height: 600))
```

### Rule 2.2 — Support Fullscreen and Split View

Opt into native fullscreen by setting the appropriate window collection behavior. The green traffic-light button must either enter fullscreen or show the tile picker.

```swift
// AppKit
window.collectionBehavior.insert(.fullScreenPrimary)
```

SwiftUI windows get fullscreen support automatically.

### Rule 2.3 — Multiple Windows

Unless your app is a single-purpose utility, support multiple windows. Document-based apps must allow multiple documents open simultaneously. Use `WindowGroup` or `DocumentGroup` in SwiftUI.

```swift
// SwiftUI — Document-based app
@main
struct TextEditorApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: TextDocument()) { file in
            TextEditorView(document: file.$document)
        }
    }
}
```

### Rule 2.4 — Title Bar Shows Document Info

For document-based apps, the title bar must show the document name. Support proxy icon dragging. Show edited state (dot in close button). Support title bar renaming on click.

```swift
// AppKit
window.representedURL = document.fileURL
window.title = document.displayName
window.isDocumentEdited = document.hasUnsavedChanges
```

```swift
// SwiftUI — NavigationSplitView titles
NavigationSplitView {
    SidebarView()
} detail: {
    DetailView()
        .navigationTitle(document.name)
}
```

### Rule 2.5 — Remember Window State

Persist window position, size, and state across launches. Use `NSWindow.setFrameAutosaveName` or SwiftUI's built-in state restoration.

```swift
// AppKit
window.setFrameAutosaveName("MainWindow")

// SwiftUI — Automatic with WindowGroup
WindowGroup(id: "main") {
    ContentView()
}
.defaultPosition(.center)
```

### Rule 2.6 — Traffic Light Buttons

Never hide or reposition the close (red), minimize (yellow), or zoom (green) buttons. They must remain in the top-left corner. If using a custom title bar, the buttons must still be visible and functional.

```swift
// AppKit — Custom title bar that preserves traffic lights
window.titlebarAppearsTransparent = true
window.styleMask.insert(.fullSizeContentView)
// Traffic lights remain functional and visible
```

---

## 3. Toolbars (HIGH)

Toolbars are the secondary command surface after the menu bar. They provide quick access to frequent actions and should be customizable.

### Rule 3.1 — Unified Title Bar and Toolbar

Use the unified title bar + toolbar style for a modern appearance. The toolbar sits in the title bar area, saving vertical space.

```swift
// SwiftUI
WindowGroup {
    ContentView()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: compose) {
                    Label("Compose", systemImage: "square.and.pencil")
                }
            }
        }
}
.windowToolbarStyle(.unified)
```

```swift
// AppKit
window.titleVisibility = .hidden
window.toolbarStyle = .unified
```

### Rule 3.2 — User-Customizable Toolbars

Allow users to add, remove, and rearrange toolbar items. Provide a default set and a superset of available items.

```swift
// SwiftUI — Customizable toolbar
.toolbar(id: "main") {
    ToolbarItem(id: "compose", placement: .primaryAction) {
        Button(action: compose) {
            Label("Compose", systemImage: "square.and.pencil")
        }
    }
    ToolbarItem(id: "filter", placement: .secondaryAction) {
        Button(action: toggleFilter) {
            Label("Filter", systemImage: "line.3.horizontal.decrease")
        }
    }
}
.toolbarRole(.editor)
```

### Rule 3.3 — Segmented Controls for View Switching

Use a segmented control or picker in the toolbar for switching between content views (e.g., List/Grid/Column). This is a toolbar pattern, not a tab bar.

```swift
// SwiftUI
ToolbarItem(placement: .principal) {
    Picker("View Mode", selection: $viewMode) {
        Label("List", systemImage: "list.bullet").tag(ViewMode.list)
        Label("Grid", systemImage: "square.grid.2x2").tag(ViewMode.grid)
        Label("Column", systemImage: "rectangle.split.3x1").tag(ViewMode.column)
    }
    .pickerStyle(.segmented)
}
```

### Rule 3.4 — Search Field in Toolbar

Place the search field in the trailing area of the toolbar. Use `.searchable()` in SwiftUI for standard search behavior with suggestions and tokens.

```swift
// SwiftUI
NavigationSplitView {
    SidebarView()
} detail: {
    ContentListView()
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search items")
        .searchSuggestions {
            ForEach(suggestions) { suggestion in
                Text(suggestion.title).searchCompletion(suggestion.title)
            }
        }
}
```

### Rule 3.5 — Toolbar Labels and Icons

Toolbar items should have both an icon (SF Symbol) and a text label. In compact mode, show icons only. Prefer labeled icons for discoverability. Use `Label` to supply both.

---

## 4. Sidebars (HIGH)

Sidebars are the primary navigation surface for Mac apps. They appear on the leading edge and provide persistent access to top-level sections and content libraries.

### Rule 4.1 — Leading Edge, Collapsible

Place the sidebar on the left (leading) edge. Make it collapsible via the toolbar button or Cmd+Ctrl+S. Persist collapsed state.

```swift
// SwiftUI
NavigationSplitView(columnVisibility: $columnVisibility) {
    List(selection: $selection) {
        Section("Library") {
            Label("All Items", systemImage: "tray.full")
            Label("Favorites", systemImage: "star")
            Label("Recent", systemImage: "clock")
        }
        Section("Tags") {
            ForEach(tags) { tag in
                Label(tag.name, systemImage: "tag")
            }
        }
    }
    .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 320)
} detail: {
    DetailView(selection: selection)
}
.navigationSplitViewStyle(.prominentDetail)
```

### Rule 4.2 — Source List Style

Use the source list style (`.listStyle(.sidebar)`) for content-library navigation. Source lists have a translucent background that shows the desktop or window behind them with vibrancy effects.

```swift
// SwiftUI
List(selection: $selection) {
    ForEach(sections) { section in
        Section(section.name) {
            ForEach(section.items) { item in
                NavigationLink(value: item) {
                    Label(item.name, systemImage: item.icon)
                }
            }
        }
    }
}
.listStyle(.sidebar)
```

### Rule 4.3 — Outline Views for Hierarchies

When content is hierarchical (e.g., folder trees, project structures), use disclosure groups or outline views to let users expand and collapse levels.

```swift
// SwiftUI — Recursive outline
List(selection: $selection) {
    OutlineGroup(rootNodes, children: \.children) { node in
        Label(node.name, systemImage: node.icon)
    }
}
```

### Rule 4.4 — Drag to Reorder

Sidebar items that can be reordered (bookmarks, favorites, custom sections) must support drag-to-reorder. Implement `onMove` or `NSOutlineView` drag delegates.

```swift
// SwiftUI
ForEach(favorites) { item in
    Label(item.name, systemImage: item.icon)
}
.onMove { source, destination in
    favorites.move(fromOffsets: source, toOffset: destination)
}
```

### Rule 4.5 — Badge Counts

Show badge counts on sidebar items for unread counts, pending items, or notifications. Use the `.badge()` modifier.

```swift
// SwiftUI
Label("Inbox", systemImage: "tray")
    .badge(unreadCount)
```

---


## Further reference

See [references/macos-design-reference.md](references/macos-design-reference.md) for keyboard, pointer and mouse, notifications, system integration, visual design, quick reference, evaluation checklist, and anti-patterns.
