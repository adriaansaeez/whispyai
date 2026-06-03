import SwiftUI

/// WhispyAI logo as a SwiftUI Shape.
/// Pixel-art "W" with eyes, based on the original 16×16 SVG.
struct LogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 16 // scale factor (16-unit grid)
        func r(_ x: Int, _ y: Int, _ w: Int = 1, _ h: Int = 1) -> CGRect {
            CGRect(x: CGFloat(x) * s + rect.minX,
                   y: CGFloat(y) * s + rect.minY,
                   width: CGFloat(w) * s,
                   height: CGFloat(h) * s)
        }

        var path = Path()

        // Top bar
        path.addRect(r(6, 3, 6, 1))
        // Right column
        path.addRect(r(12, 3, 1, 7))
        path.addRect(r(13, 4, 1, 6))
        path.addRect(r(14, 9, 1, 2))
        path.addRect(r(15, 10, 1, 1))
        // Left column
        path.addRect(r(1, 6, 1, 2))
        path.addRect(r(2, 5, 1, 4))
        path.addRect(r(5, 4, 1, 1))
        path.addRect(r(6, 3, 1, 1))
        // Bottom center bar
        path.addRect(r(6, 8, 1, 3))
        path.addRect(r(7, 8, 1, 6))
        // Feet
        path.addRect(r(7, 11, 2, 3))
        path.addRect(r(10, 11, 2, 3))
        // Eyes (white, will be cut out)
        path.addRect(r(6, 4, 1, 2))
        path.addRect(r(9, 4, 1, 2))

        return path
    }
}

/// Monochrome version for menubar template images.
struct LogoTemplateShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 16
        func r(_ x: Int, _ y: Int, _ w: Int = 1, _ h: Int = 1) -> CGRect {
            CGRect(x: CGFloat(x) * s + rect.minX,
                   y: CGFloat(y) * s + rect.minY,
                   width: CGFloat(w) * s,
                   height: CGFloat(h) * s)
        }

        var path = Path()

        // All filled pixels (blue body + feet, no eyes)
        path.addRect(r(6, 3, 6, 1))
        path.addRect(r(12, 3, 1, 7))
        path.addRect(r(13, 4, 1, 6))
        path.addRect(r(14, 9, 1, 2))
        path.addRect(r(15, 10, 1, 1))
        path.addRect(r(1, 6, 1, 2))
        path.addRect(r(2, 5, 1, 4))
        path.addRect(r(5, 4, 1, 1))
        path.addRect(r(6, 3, 1, 1))
        path.addRect(r(6, 8, 1, 3))
        path.addRect(r(7, 8, 1, 6))
        path.addRect(r(7, 11, 2, 3))
        path.addRect(r(10, 11, 2, 3))

        return path
    }
}

// MARK: - NSImage helper for menubar

extension LogoTemplateShape {
    /// Loads the menubar icon PNG from the resource bundle.
    /// Falls back to a programmatic render if the bundle resource is missing.
    static func menuBarImage(pointSize: CGFloat = 18) -> NSImage {
        if let url = Bundle.module.url(forResource: "menubar-icon", withExtension: "png"),
           let nsImage = NSImage(contentsOf: url) {
            let resized = NSImage(size: NSSize(width: pointSize, height: pointSize))
            resized.lockFocus()
            NSGraphicsContext.current?.imageInterpolation = .high
            nsImage.draw(
                in: NSRect(x: 0, y: 0, width: pointSize, height: pointSize),
                from: .zero,
                operation: .copy,
                fraction: 1.0
            )
            resized.unlockFocus()
            resized.isTemplate = true
            return resized
        }
        // Fallback: render from shape
        let size = NSSize(width: pointSize, height: pointSize)
        let image = NSImage(size: size, flipped: false) { rect in
            let shape = LogoTemplateShape()
            let path = shape.path(in: rect)
            NSColor.black.set()
            _ = path.fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}
