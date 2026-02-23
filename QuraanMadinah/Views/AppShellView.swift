import SwiftUI

struct AppShellView: View {
    @StateObject private var store     = QuranDataStore.shared
    @StateObject private var bookmarks = BookmarkStore()

    @AppStorage("last_page_v1") private var lastPage: Int  = 1
    @State private var selectedTab: Tab = .home

    enum Tab: Hashable { case home, mushaf, search, index }

    var body: some View {
        TabView(selection: $selectedTab) {
            // ── Home ─────────────────────────────────────────────
            NavigationStack {
                HomeView(store: store) { page in
                    lastPage    = page
                    selectedTab = .mushaf
                }
            }
            .tag(Tab.home)
            .tabItem {
                Label("الرئيسية", systemImage: selectedTab == .home ? "house.fill" : "house")
            }

            // ── Mushaf ───────────────────────────────────────────
            QuranReaderView(store: store)
                .environmentObject(bookmarks)
                .tag(Tab.mushaf)
                .tabItem {
                    Label("المصحف", systemImage: selectedTab == .mushaf ? "book.fill" : "book")
                }

            // ── Search ───────────────────────────────────────────
            SearchView { record in
                lastPage    = record.page
                selectedTab = .mushaf
                NotificationCenter.default.post(name: .jumpToPage, object: record.page)
            }
            .tag(Tab.search)
            .tabItem {
                Label("بحث", systemImage: "magnifyingglass")
            }

            // ── Index ────────────────────────────────────────────
            SurahListView(surahs: store.surahs) { page in
                lastPage    = page
                selectedTab = .mushaf
                NotificationCenter.default.post(name: .jumpToPage, object: page)
            }
            .tag(Tab.index)
            .tabItem {
                Label("الفهرس", systemImage: "list.bullet.rectangle")
            }
        }
        .tint(Theme.green)
        .onAppear {
            // Premium parchment tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0.975, green: 0.966, blue: 0.943, alpha: 0.97)

            // Gold hairline separator
            appearance.shadowColor = UIColor(
                red: 0.758, green: 0.608, blue: 0.255, alpha: 0.30
            )

            // Unselected item appearance
            let unselectedAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor(red: 0.50, green: 0.46, blue: 0.40, alpha: 1)
            ]
            let selectedAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor(red: 0.030, green: 0.230, blue: 0.160, alpha: 1)
            ]
            appearance.stackedLayoutAppearance.normal.titleTextAttributes  = unselectedAttrs
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs
            appearance.stackedLayoutAppearance.normal.iconColor   = UIColor(red: 0.50, green: 0.46, blue: 0.40, alpha: 1)
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.030, green: 0.230, blue: 0.160, alpha: 1)

            UITabBar.appearance().standardAppearance   = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

extension Notification.Name {
    static let jumpToPage = Notification.Name("jump_to_page_v1")
}
