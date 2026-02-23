import SwiftUI

// ══════════════════════════════════════════════════════════════
// MARK: - SurahListView  (فهرس السور)
// ══════════════════════════════════════════════════════════════

struct SurahListView: View {
    let surahs:   [SurahInfo]
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var filtered: [SurahInfo] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return surahs }
        return surahs.filter {
            $0.nameAr.contains(q) ||
            $0.nameEn.lowercased().contains(q.lowercased()) ||
            String($0.suraNo) == q
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ParchmentBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        statsHeader
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)

                        LazyVStack(spacing: 0) {
                            ForEach(Array(filtered.enumerated()), id: \.element.id) { idx, surah in
                                SurahRow(surah: surah) { onSelect(surah.firstPage) }

                                if idx < filtered.count - 1 {
                                    Rectangle()
                                        .fill(Theme.gold.opacity(0.18))
                                        .frame(height: 0.6)
                                        .padding(.horizontal, 56)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Theme.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Theme.goldStroke.opacity(0.42), lineWidth: 1)
                                )
                                .padding(.horizontal, 14)
                        )
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 6)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("فهرس السور")
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundStyle(Theme.green)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                            Text("إغلاق")
                                .font(.system(size: 14))
                        }
                        .foregroundStyle(Theme.green)
                    }
                }
            }
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "ابحث باسم السورة أو رقمها"
            )
        }
        .tint(Theme.green)
    }

    private var statsHeader: some View {
        HStack(spacing: 0) {
            statCell("١١٤", "سورة")
            statDivider
            statCell("٦٦٠٤", "آية")
            statDivider
            statCell("٣٠", "جزءاً")
            statDivider
            statCell("٦٠٤", "صفحة")
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.goldStroke.opacity(0.38), lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private func statCell(_ val: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(val)
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundStyle(Theme.green)
            Text(label)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(Theme.mutedInk)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Theme.gold.opacity(0.30))
            .frame(width: 1, height: 28)
    }
}

// ══════════════════════════════════════════════════════════════
// MARK: - صف السورة
// ══════════════════════════════════════════════════════════════

private struct SurahRow: View {
    let surah: SurahInfo
    let onTap: () -> Void

    private let madaninSurahs = [2,3,4,5,8,9,13,22,24,33,47,48,49,55,57,58,59,60,61,62,63,64,65,66,76,98,110]

    private var isMadani: Bool { madaninSurahs.contains(surah.suraNo) }
    private var revType: String { isMadani ? "مدنية" : "مكية" }
    private var revColor: Color { isMadani ? Color(red:0.10,green:0.26,blue:0.48) : Theme.green }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 13) {
                // رقم السورة
                ZStack {
                    OctagonShape()
                        .fill(LinearGradient(
                            colors: [Theme.greenMedium.opacity(0.12), Theme.greenGlass],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    OctagonShape()
                        .stroke(Theme.greenStroke, lineWidth: 0.9)
                        .frame(width: 44, height: 44)
                    Text(toArabic(surah.suraNo))
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundStyle(Theme.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(surah.nameAr)
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    HStack(spacing: 7) {
                        Text(surah.nameEn)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.mutedInk)
                        Circle().fill(Theme.gold.opacity(0.45)).frame(width: 3, height: 3)
                        Text(revType)
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(revColor.opacity(0.82))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(revColor.opacity(0.08))
                                    .overlay(Capsule().stroke(revColor.opacity(0.20), lineWidth: 0.7))
                            )
                    }
                }

                Spacer()

                // رقم الصفحة
                Text("ص \(toArabic(surah.firstPage))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.green.opacity(0.82))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Theme.greenGlass)
                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.greenStroke, lineWidth: 0.7))
                    )

                Image(systemName: "chevron.left")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Theme.gold.opacity(0.52))
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private func toArabic(_ n: Int) -> String {
        let d = ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]
        return String(n).compactMap { c in c.wholeNumberValue.map { d[$0] } ?? String(c) }.joined()
    }
}

private struct OctagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width; let h = rect.height; let c = w * 0.22
        var p = Path()
        p.move(to:    CGPoint(x: c,   y: 0))
        p.addLine(to: CGPoint(x: w-c, y: 0))
        p.addLine(to: CGPoint(x: w,   y: c))
        p.addLine(to: CGPoint(x: w,   y: h-c))
        p.addLine(to: CGPoint(x: w-c, y: h))
        p.addLine(to: CGPoint(x: c,   y: h))
        p.addLine(to: CGPoint(x: 0,   y: h-c))
        p.addLine(to: CGPoint(x: 0,   y: c))
        p.closeSubpath()
        return p
    }
}
