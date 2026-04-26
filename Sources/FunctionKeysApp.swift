import SwiftUI

@main
struct FunctionKeysApp: App {
    @StateObject private var model = FunctionKeyState()

    var body: some Scene {
        MenuBarExtra {
            Button {
                model.setMode(standardFunctionKeys: true)
            } label: {
                ModeMenuRow(title: "F1, F2 as Standard Keys", isSelected: model.standardFunctionKeys)
            }

            Button {
                model.setMode(standardFunctionKeys: false)
            } label: {
                ModeMenuRow(title: "Media Keys", isSelected: !model.standardFunctionKeys)
            }

            Divider()

            Button {
                model.openKeyboardSettings()
            } label: {
                Label("Open Keyboard Settings", systemImage: "gearshape")
            }

            Divider()

            Button("Quit Function Keys") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(nsImage: FunctionKeyMenuIcon.image(isStandardFunctionKeys: model.standardFunctionKeys))
                .accessibilityIdentifier("com.oneill.FunctionKeys.menuBarExtra")
                .accessibilityLabel("Function Keys")
                .accessibilityValue(model.modeTitle)
        }
        .menuBarExtraStyle(.menu)
    }
}

struct ModeMenuRow: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        HStack {
            if isSelected {
                Image(systemName: "checkmark")
            }
            Text(title)
        }
    }
}

enum FunctionKeyMenuIcon {
    static func image(isStandardFunctionKeys: Bool) -> NSImage {
        let size = NSSize(width: 26, height: 18)
        let image = NSImage(size: size)

        image.lockFocus()
        defer { image.unlockFocus() }

        let text = NSString(string: "Fn")
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]

        let textSize = text.size(withAttributes: attributes)
        let textRect = NSRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect, withAttributes: attributes)

        if !isStandardFunctionKeys {
            let path = NSBezierPath()
            path.move(to: NSPoint(x: 7, y: 4))
            path.line(to: NSPoint(x: 19, y: 14))
            path.lineWidth = 2
            path.lineCapStyle = .round
            NSColor.labelColor.setStroke()
            path.stroke()
        }

        image.isTemplate = true
        return image
    }
}
