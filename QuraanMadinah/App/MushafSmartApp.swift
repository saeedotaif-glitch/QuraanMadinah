import SwiftUI

@main
struct MushafSmartApp: App {
    init() {
        FontRegistrar.registerFontIfNeeded(fontFileName: "HafsSmart_08", fileExtension: "ttf")
    }

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environment(\.layoutDirection, .rightToLeft)
        }
    }
}
