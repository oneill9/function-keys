import AppKit

let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

// White background rounded rect
let rect = NSRect(origin: .zero, size: size)
let path = NSBezierPath(roundedRect: rect, xRadius: 224, yRadius: 224)
NSColor.white.setFill()
path.fill()

// Draw text "Fn"
let text = "Fn" as NSString
let font = NSFont.systemFont(ofSize: 500, weight: .regular)
let attributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.black
]

let textSize = text.size(withAttributes: attributes)
let textRect = NSRect(
    x: (size.width - textSize.width) / 2,
    y: (size.height - textSize.height) / 2 - (font.ascender + font.descender) / 2 + 50,
    width: textSize.width,
    height: textSize.height
)
text.draw(in: textRect, withAttributes: attributes)

image.unlockFocus()

guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to create PNG")
}

let url = URL(fileURLWithPath: "AppBundle/icon.png")
try! pngData.write(to: url)
print("Saved to AppBundle/icon.png")
