import Foundation
import CoreText

enum FontRegistrar {
    static func registerFontIfNeeded(fontFileName: String, fileExtension: String) {
        guard let url = Bundle.main.url(forResource: fontFileName, withExtension: fileExtension) else { return }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}
