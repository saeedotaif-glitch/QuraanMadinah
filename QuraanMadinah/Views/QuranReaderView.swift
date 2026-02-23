import SwiftUI

// ══════════════════════════════════════════════════════════════
// MARK: - QuranReaderView  (واجهة القراءة)
// ══════════════════════════════════════════════════════════════

struct QuranReaderView: View {
    @ObservedObject var store: QuranDataStore
    @EnvironmentObject private var bookmarks: BookmarkStore
    @AppStorage("last_page_v1")         private var lastPage:   Int    = 1
    @AppStorage("mushaf_font_scale_v1") private var fontScale:  Double = 1.18

    @State private var currentPage   = 1
    @State private var chromeVisible = true
    @State private var showSurahs    = false
    @State private var showSearch    = false
    @State private var showFontSize  = false

    var body: some View {
        ZStack {
            // ─ الصفحات ──────────────────────────────────────────
            TabView(selection: $currentPage) {
                ForEach(1...604, id: \.self) { page in
                    MushafPageView(
                        pageNumber: page,
                        records:    store.records(forPage: page)
                    )
                    .tag(page)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.20)) {
                            chromeVisible.toggle()
                            if showFontSize { showFontSize = false }
                        }
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .environment(\.layoutDirection, .rightToLeft)
            .ignoresSafeArea()
            .onAppear { currentPage = min(max(lastPage, 1), 604) }
            .onChange(of: currentPage) { _, v in lastPage = v }
            .onReceive(NotificationCenter.default.publisher(for: .jumpToPage)) { note in
                if let t = note.object as? Int { currentPage = min(max(t, 1), 604) }
            }

            // ─ شريط الأدوات ────────────────────────────────────
            if chromeVisible {
                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    if showFontSize {
                        fontPanel
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    bottomBar
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.20), value: chromeVisible)
                .animation(.spring(response: 0.33, dampingFraction: 0.82), value: showFontSize)
            }
        }
        .sheet(isPresented: $showSurahs) {
            SurahListView(surahs: store.surahs) { page in
                currentPage = page; showSurahs = false
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchView { record in
                currentPage = record.page; showSearch = false
            }
        }
    }

    // ── الشريط العلوي ─────────────────────────────────────────────

    private func arabicNumerals(_ n: Int) -> String {
        let d = ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]
        return String(n).map { c -> String in
            if let v = c.wholeNumberValue, v < d.count { return d[v] }
            return String(c)
        }.joined()
    }

    private var topBar: some View {
        let info = store.pageInfo(page: currentPage)
        return HStack(spacing: 12) {
            chromeBtn("magnifyingglass") { showSearch = true }
            Spacer()
            VStack(spacing: 2) {
                Text(info.title)
                    .font(.system(size: 14.5, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.green)
                    .lineLimit(1)
                Text(info.subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.mutedInk)
                    .lineLimit(1)
            }
            Spacer()
            chromeBtn("list.bullet") { showSurahs = true }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 9)
        .background(chromeBarBg(edge: .top))
        .ignoresSafeArea(edges: .top)
    }

    private func chromeBtn(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Theme.pageMid.opacity(0.92))
                    .overlay(Circle().stroke(Theme.goldStroke.opacity(0.50), lineWidth: 1))
                    .shadow(color: .black.opacity(0.08), radius: 5, y: 2)
                Image(systemName: icon)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(Theme.green)
            }
            .frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)
    }

    // ── لوحة حجم الخط ────────────────────────────────────────────

    private var fontPanel: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                fontStepBtn(icon: "textformat.size.smaller", step: -0.04, label: "أصغر")

                VStack(spacing: 5) {
                    Slider(value: $fontScale, in: 0.80...1.50, step: 0.02)
                        .tint(Theme.green)
                        .onChange(of: fontScale) { _, _ in PageComposer.shared.clearCache() }
                    Text("بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ")
                        .font(.hafsSmart(max(13, 21 * CGFloat(fontScale))))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .environment(\.layoutDirection, .rightToLeft)
                }
                .padding(.horizontal, 10)

                fontStepBtn(icon: "textformat.size.larger", step: +0.04, label: "أكبر")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Theme.page.opacity(0.82)
                VStack {
                    Rectangle().fill(Theme.gold.opacity(0.22)).frame(height: 0.7)
                    Spacer()
                }
            }
        )
    }

    private func fontStepBtn(icon: String, step: Double, label: String) -> some View {
        Button {
            fontScale = min(max(fontScale + step, 0.80), 1.50)
            PageComposer.shared.clearCache()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.green)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Theme.mutedInk)
            }
            .frame(width: 50)
        }
        .buttonStyle(.plain)
    }

    // ── الشريط السفلي ─────────────────────────────────────────────

    private var bottomBar: some View {
        HStack(spacing: 0) {
            bottomBtn("الفهرس",  icon: "list.bullet.rectangle.portrait", active: false)
                { showSurahs = true }
            bottomBtn("بحث",     icon: "magnifyingglass", active: false)
                { showSearch = true }
            bottomBtn("علامة",   icon: bookmarks.isBookmarked(currentPage) ? "bookmark.fill" : "bookmark",
                      active: bookmarks.isBookmarked(currentPage))
                { bookmarks.toggle(currentPage) }
            bottomBtn("الخط",    icon: "textformat.size", active: showFontSize) {
                withAnimation(.spring(response: 0.33, dampingFraction: 0.82)) {
                    showFontSize.toggle()
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 22)
        .background(chromeBarBg(edge: .bottom))
        .ignoresSafeArea(edges: .bottom)
    }

    private func bottomBtn(_ title: String, icon: String, active: Bool,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16.5, weight: active ? .bold : .semibold))
                    .foregroundStyle(active ? Theme.goldBright : Theme.green)
                Text(title)
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(active ? Theme.goldBright : Theme.mutedInk)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
    }

    // ── خلفية الأشرطة ────────────────────────────────────────────

    private func chromeBarBg(edge: Edge) -> some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            LinearGradient(
                colors: edge == .top
                    ? [Theme.page.opacity(0.92), Theme.page.opacity(0.78)]
                    : [Theme.page.opacity(0.78), Theme.page.opacity(0.94)],
                startPoint: .top, endPoint: .bottom
            )
            VStack {
                if edge == .bottom {
                    Rectangle().fill(Theme.gold.opacity(0.22)).frame(height: 0.7)
                }
                Spacer()
                if edge == .top {
                    Rectangle().fill(Theme.gold.opacity(0.22)).frame(height: 0.7)
                }
            }
        }
    }
}
