import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss)     private var dismiss
    @ObservedObject private var store = QuranDataStore.shared

    @State private var query:   String      = ""
    @State private var results: [AyaRecord] = []

    let onSelect: (AyaRecord) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                ParchmentBackground()

                Group {
                    if query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
                        searchPlaceholder
                    } else if results.isEmpty {
                        noResults
                    } else {
                        resultsList
                    }
                }
            }
            .navigationTitle("البحث في القرآن")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("إغلاق") { dismiss() }
                        .foregroundStyle(Theme.green)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !results.isEmpty {
                        Text("\(results.count) نتيجة")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.mutedInk)
                    }
                }
            }
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "اكتب كلمة للبحث في الآيات"
            )
            .onChange(of: query) { _, q in
                let trimmed = q.trimmingCharacters(in: .whitespacesAndNewlines)
                results = trimmed.count >= 2
                    ? Array(store.searchEmlaey(trimmed).prefix(200))
                    : []
            }
        }
        .tint(Theme.green)
    }

    // ── Placeholder ───────────────────────────────────────────────

    private var searchPlaceholder: some View {
        VStack(spacing: 20) {
            Spacer()
            IslamicMandala(size: 100)
                .opacity(0.6)
            Text("ابحث في آيات القرآن الكريم")
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            Text("اكتب كلمة أو جزءاً من آية")
                .font(.system(size: 13))
                .foregroundStyle(Theme.mutedInk)
            Spacer()
            Spacer()
        }
    }

    // ── No Results ────────────────────────────────────────────────

    private var noResults: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Theme.gold.opacity(0.55))
            Text("لا توجد نتائج")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text("جرّب كلمة مختلفة")
                .font(.system(size: 13))
                .foregroundStyle(Theme.mutedInk)
            Spacer()
            Spacer()
        }
    }

    // ── Results List ──────────────────────────────────────────────

    private var resultsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(Array(results.enumerated()), id: \.element.id) { idx, record in
                    SearchResultRow(record: record) {
                        onSelect(record)
                    }
                    if idx < results.count - 1 {
                        OrnamentalDivider()
                            .padding(.horizontal, 18)
                            .padding(.vertical, 1)
                    }
                }
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.goldStroke.opacity(0.4), lineWidth: 1)
                    )
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
            )
        }
    }
}

// ═══════════════════════════════════════════════════════
// MARK: - Search Result Row
// ═══════════════════════════════════════════════════════

private struct SearchResultRow: View {
    let record: AyaRecord
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .trailing, spacing: 8) {
                // Header row
                HStack {
                    // Page badge
                    HStack(spacing: 4) {
                        Image(systemName: "book.pages")
                            .font(.system(size: 10, weight: .medium))
                        Text("ص \(record.page)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Theme.mutedInk)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Theme.parchmentMid)
                            .overlay(Capsule().stroke(Theme.goldStroke.opacity(0.4), lineWidth: 0.8))
                    )

                    Spacer()

                    // Surah + Aya
                    HStack(spacing: 6) {
                        Text("آية \(record.ayaNo)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.mutedInk)
                        Canvas { ctx, sz in
                            let cx = sz.width/2; let cy = sz.height/2; let d: CGFloat = 2
                            var p = Path()
                            p.move(to: CGPoint(x: cx, y: cy-d))
                            p.addLine(to: CGPoint(x: cx+d, y: cy))
                            p.addLine(to: CGPoint(x: cx, y: cy+d))
                            p.addLine(to: CGPoint(x: cx-d, y: cy))
                            p.closeSubpath()
                            ctx.fill(p, with: .color(Theme.gold.opacity(0.6)))
                        }
                        .frame(width: 6, height: 6)
                        Text(record.suraNameAr)
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundStyle(Theme.green)
                    }
                }

                // Aya text
                Text(record.ayaTextEmlaey)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.trailing)
                    .lineSpacing(4)
                    .lineLimit(3)
                    .environment(\.layoutDirection, .rightToLeft)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}
