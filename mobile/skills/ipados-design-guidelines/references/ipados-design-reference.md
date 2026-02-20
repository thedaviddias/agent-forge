# iPadOS design reference (keyboard, Apple Pencil, drag and drop, external display, checklists)

See [SKILL.md](../SKILL.md) for responsive layout, multitasking, navigation, and pointer & trackpad.

## 5. Keyboard (HIGH)

### 5.1 Cmd+Key Shortcuts for All Major Actions

Every primary action must have a keyboard shortcut. Standard shortcuts are mandatory:

| Shortcut | Action |
|----------|--------|
| Cmd+N | New item |
| Cmd+F | Find/Search |
| Cmd+S | Save |
| Cmd+Z | Undo |
| Cmd+Shift+Z | Redo |
| Cmd+C/V/X | Copy/Paste/Cut |
| Cmd+A | Select all |
| Cmd+P | Print |
| Cmd+W | Close window/tab |
| Cmd+, | Settings/Preferences |
| Delete | Delete selected item |

```swift
Button("New Document") { createDocument() }
    .keyboardShortcut("n", modifiers: .command)
```

### 5.2 Discoverability via Cmd-Hold Overlay

When the user holds the Cmd key, iPadOS shows a shortcut overlay. Register all shortcuts using `.keyboardShortcut()` so they appear in this overlay. Group related shortcuts logically.

### 5.3 Tab Key Navigation Between Fields

Support Tab to move forward and Shift+Tab to move backward between form fields and focusable elements. Use `.focusable()` and `@FocusState` to manage keyboard focus order.

```swift
struct FormView: View {
    @FocusState private var focusedField: Field?

    var body: some View {
        Form {
            TextField("Name", text: $name)
                .focused($focusedField, equals: .name)
            TextField("Email", text: $email)
                .focused($focusedField, equals: .email)
            TextField("Phone", text: $phone)
                .focused($focusedField, equals: .phone)
        }
    }
}
```

### 5.4 Never Override System Shortcuts

Do not claim shortcuts reserved by the system: Cmd+H (Home), Cmd+Tab (App Switcher), Cmd+Space (Spotlight), Globe key combinations. These will not work and create confusion.

### 5.5 Detect Hardware Keyboard

Adapt UI when a hardware keyboard is connected. Hide the on-screen keyboard shortcut bar. Show keyboard-optimized controls. Use `GCKeyboard` or track keyboard visibility to detect state.

### 5.6 Arrow Key Navigation

Support arrow keys for navigating lists, grids, and collections. Combine with Shift for multi-selection. This is essential for productivity-focused apps.

---

## 6. Apple Pencil (MEDIUM)

### 6.1 Support Scribble

iPadOS converts handwriting to text in any standard text field automatically. Do not disable Scribble. For custom text input, adopt `UIScribbleInteraction`. Test that Scribble works in all text entry points.

### 6.2 Double-Tap Tool Switching

Apple Pencil 2 and later supports double-tap to switch tools (e.g., pen to eraser). If your app has drawing tools, implement the `UIPencilInteraction` delegate to handle double-tap.

### 6.3 Pressure and Tilt for Drawing

For drawing apps, respond to `force` (pressure) and `altitudeAngle`/`azimuthAngle` (tilt) from pencil touch events. Use these for variable line width, opacity, or shading.

### 6.4 Hover Detection (M2+ Pencil)

Apple Pencil with hover (M2 iPad Pro and later) provides position data before the pencil touches the screen. Use this for preview effects, tool size indicators, and enhanced precision.

```swift
// UIKit hover support
override func pencilHoverChanged(_ hover: UIHoverGestureRecognizer) {
    let location = hover.location(in: canvas)
    showBrushPreview(at: location)
}
```

### 6.5 PencilKit Integration

For note-taking and annotation, use `PKCanvasView` from PencilKit. It provides a full drawing experience with tool picker, undo, and ink recognition out of the box.

```swift
import PencilKit

struct DrawingView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
        canvasView.drawingPolicy = .anyInput
        return canvasView
    }
}
```

---

## 7. Drag and Drop (HIGH)

### 7.1 Inter-App Drag and Drop is Expected

iPad users expect to drag content between apps. Support dragging content out (as a source) and dropping content in (as a destination). This is a core iPad interaction.

```swift
// As drag source
Text(item.title)
    .draggable(item.title)

// As drop destination
DropTarget()
    .dropDestination(for: String.self) { items, location in
        handleDrop(items)
        return true
    }
```

### 7.2 Multi-Item Drag

Users can pick up one item, then tap additional items to add them to the drag. Support multi-item drag by providing multiple `NSItemProvider` items. Show a badge count on the drag preview.

### 7.3 Spring-Loaded Interactions

When dragging over a navigation element (folder, tab, sidebar item), pause briefly to "spring open" that destination. Implement spring-loading on navigation containers to enable deep drop targets.

### 7.4 Visual Feedback for Drag and Drop

Provide clear visual states:
- **Lift**: Item lifts with shadow when drag begins
- **Move**: Destination highlights when drag hovers over valid target
- **Drop**: Animate insertion at drop point
- **Cancel**: Item animates back to origin

### 7.5 Support Universal Control

Universal Control lets users drag between iPad and Mac. If your app supports drag and drop with standard `NSItemProvider` and UTTypes, Universal Control works automatically.

### 7.6 Drop Delegates for Custom Behavior

Use `DropDelegate` for fine-grained control over drop behavior: validating drop content, reordering within lists, and handling drop position.

```swift
struct ReorderDropDelegate: DropDelegate {
    let item: Item
    @Binding var items: [Item]
    @Binding var draggedItem: Item?

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem,
              let fromIndex = items.firstIndex(of: draggedItem),
              let toIndex = items.firstIndex(of: item) else { return }
        withAnimation {
            items.move(fromOffsets: IndexSet(integer: fromIndex),
                      toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }
}
```

---

## 8. External Display (MEDIUM)

### 8.1 Provide Extended Content, Not Just Mirroring

When connected to an external display, show complementary content rather than duplicating the iPad screen. Presentations, reference material, or expanded views belong on the external display while controls stay on iPad.

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Additional scene for external display
        WindowGroup(id: "presentation") {
            PresentationView()
        }
    }
}
```

### 8.2 Handle Display Connection and Disconnection

Listen for `UIScreen.didConnectNotification` and `UIScreen.didDisconnectNotification`. Transition gracefully -- if the external display disconnects mid-presentation, bring content back to the iPad screen without data loss.

### 8.3 Support Full External Display Resolution

Use the full resolution and aspect ratio of the external display. Do not letterbox or pillarbox your content. Query `UIScreen.bounds` and `UIScreen.scale` for the connected display.

---

## Evaluation Checklist

Use this checklist to verify iPad-readiness:

### Layout & Multitasking
- [ ] App uses adaptive layout with `horizontalSizeClass`
- [ ] Tested at all Split View ratios (1/3, 1/2, 2/3)
- [ ] Tested in Slide Over (compact width)
- [ ] Stage Manager: resizes fluidly to arbitrary dimensions
- [ ] Multiple scenes/windows supported
- [ ] Both orientations (portrait and landscape) work correctly
- [ ] No content clipped at any size
- [ ] Safe areas respected on all iPad models

### Navigation
- [ ] Sidebar visible in regular width
- [ ] Tab bar used in compact width
- [ ] Detail view shows placeholder when no selection
- [ ] Toolbar items placed at top, not bottom
- [ ] Three-column layout used where appropriate

### Pointer & Trackpad
- [ ] Hover effects on all interactive elements
- [ ] Right-click context menus available
- [ ] Pointer cursor adapts to content (I-beam for text, etc.)
- [ ] Click-and-drag works for reordering

### Keyboard
- [ ] Cmd+key shortcuts for all major actions
- [ ] Shortcuts appear in Cmd-hold overlay
- [ ] Tab key navigates between form fields
- [ ] No system shortcut conflicts
- [ ] Arrow keys navigate lists and grids
- [ ] Return/Enter activates default action

### Apple Pencil
- [ ] Scribble works in all text fields
- [ ] Drawing apps support pressure and tilt
- [ ] Double-tap interaction handled (if applicable)

### Drag and Drop
- [ ] Content can be dragged out to other apps
- [ ] Content can be dropped in from other apps
- [ ] Multi-item drag supported
- [ ] Visual feedback for all drag states

### External Display
- [ ] Extended content shown (not just mirror)
- [ ] Graceful handling of connect/disconnect

---

## Anti-Patterns

### DO NOT: Scale Up iPhone Layouts
Stretching a single-column iPhone UI to fill an iPad screen wastes space, looks lazy, and provides a poor experience. Always redesign for the larger canvas.

### DO NOT: Disable Multitasking
Never opt out of multitasking support. Users expect every app to work in Split View and Slide Over. Requiring full screen is hostile to iPad workflows.

### DO NOT: Ignore the Keyboard
Many iPad users have Magic Keyboard or Smart Keyboard. An app with no keyboard shortcuts forces them to reach for the screen constantly. Provide shortcuts for all frequent actions.

### DO NOT: Use iPhone-Style Bottom Tab Bars in Regular Width
Tab bars at the bottom waste vertical space on iPad and look out of place. Convert to sidebar navigation in regular width. SwiftUI does this automatically with `.sidebarAdaptable`.

### DO NOT: Show Popovers as Full-Screen Sheets
On iPad, popovers should anchor to their source element as floating panels. Only use full-screen sheets for immersive content or flows that genuinely need the full screen. Avoid the iPhone pattern of everything being a sheet.

### DO NOT: Ignore Pointer Hover States
Missing hover effects make the app feel broken when using a trackpad. Users cannot tell what is interactive. Always add hover feedback to custom interactive elements.

### DO NOT: Hardcode Dimensions
Never hardcode widths, heights, or positions based on a specific iPad model. Use Auto Layout constraints, SwiftUI flexible frames, and `GeometryReader` for dynamic sizing.

### DO NOT: Forget Drag and Drop
On iPad, drag and drop between apps is a core workflow. Not supporting it makes your app a dead end for content. At minimum, support dragging text, images, and URLs in and out.

### DO NOT: Override System Keyboard Shortcuts
Claiming Cmd+H, Cmd+Tab, Cmd+Space, or Globe shortcuts will not work and confuses users who expect system behavior. Check Apple's reserved shortcuts list before assigning.

### DO NOT: Present Dense Content Without Scrolling
Large iPad screens tempt designers to show everything at once. Content should still scroll when it exceeds the visible area. Never truncate content to avoid scrolling.
