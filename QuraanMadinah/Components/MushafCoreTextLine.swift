import SwiftUI
import UIKit
import CoreText

struct MushafCoreTextLine: UIViewRepresentable {
    let text: String
    let font: UIFont
    let color: UIColor

    func makeUIView(context: Context) -> CoreTextLineView {
        let v = CoreTextLineView()
        v.backgroundColor = .clear
        return v
    }

    func updateUIView(_ uiView: CoreTextLineView, context: Context) {
        uiView.text = text
        uiView.font = font
        uiView.color = color
        uiView.setNeedsDisplay()
    }
}

final class CoreTextLineView: UIView {
    var text: String = ""
    var font: UIFont = .systemFont(ofSize: 22)
    var color: UIColor = .black

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), !text.isEmpty else { return }

        ctx.saveGState()
        defer { ctx.restoreGState() }

        // Flip coordinates for CoreText
        ctx.textMatrix = .identity
        ctx.translateBy(x: 0, y: rect.height)
        ctx.scaleBy(x: 1.0, y: -1.0)

        let ctFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.baseWritingDirection = .rightToLeft
        paragraph.lineBreakMode = .byClipping

        let attrs: [NSAttributedString.Key: Any] = [
            kCTFontAttributeName as NSAttributedString.Key: ctFont,
            kCTForegroundColorAttributeName as NSAttributedString.Key: color.cgColor,
            .paragraphStyle: paragraph
        ]

        let attr = NSAttributedString(string: text, attributes: attrs)
        let line = CTLineCreateWithAttributedString(attr)

        // Center line
        let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds, .useOpticalBounds])
        let x = (rect.width - bounds.width) * 0.5 - bounds.minX
        let y = (rect.height - bounds.height) * 0.5 - bounds.minY

        ctx.textPosition = CGPoint(x: x, y: y)
        CTLineDraw(line, ctx)
    }
}
