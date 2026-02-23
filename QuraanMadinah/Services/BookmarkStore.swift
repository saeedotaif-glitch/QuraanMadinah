import Foundation
import SwiftUI
import Combine

final class BookmarkStore: ObservableObject {
    @Published private(set) var pages: Set<Int> = []

    private let key = "bookmark_pages_v1"

    init() {
        load()
    }

    func isBookmarked(_ page: Int) -> Bool {
        pages.contains(page)
    }

    func toggle(_ page: Int) {
        if pages.contains(page) {
            pages.remove(page)
        } else {
            pages.insert(page)
        }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        if let decoded = try? JSONDecoder().decode([Int].self, from: data) {
            pages = Set(decoded)
        }
    }

    private func save() {
        let arr = Array(pages).sorted()
        guard let data = try? JSONEncoder().encode(arr) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
