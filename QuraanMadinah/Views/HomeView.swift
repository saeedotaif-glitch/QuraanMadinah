import SwiftUI

// ══════════════════════════════════════════════════════════════
// MARK: - HomeView  (الشاشة الرئيسية — غلاف المصحف)
// ══════════════════════════════════════════════════════════════

struct HomeView: View {
    @ObservedObject var store: QuranDataStore
    @AppStorage("last_page_v1") private var lastPage: Int = 1
    let openReader: (Int) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                coverSection
                    .padding(.bottom, 22)

                VStack(spacing: 13) {
                    continueCard
                    quickActionsRow
                    dailyAyahCard
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 34)
            }
        }
        .background(ParchmentBackground())
        .navigationBarHidden(true)
    }

    private func toArabicNums(_ n: Int) -> String {
        let d = ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]
        return String(n).map { c -> String in
            if let v = c.wholeNumberValue, v < d.count { return d[v] }
            return String(c)
        }.joined()
    }

    // ══════════════════════════════════════════════════════
    // MARK: - غلاف المصحف
    // ══════════════════════════════════════════════════════

    private var coverSection: some View {
        ZStack {
            // خلفية خضراء إسلامية
            LinearGradient(
                stops: [
                    .init(color: Color(red:0.012, green:0.120, blue:0.082), location: 0.0),
                    .init(color: Color(red:0.022, green:0.178, blue:0.122), location: 0.40),
                    .init(color: Color(red:0.018, green:0.155, blue:0.105), location: 0.75),
                    .init(color: Color(red:0.008, green:0.095, blue:0.062), location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // نمط الأرابيسك
            CoverGeometricPattern().opacity(0.065)

            // حقل النجوم
            CoverStarfield().opacity(0.22)

            // الإطار الذهبي الداخلي
            CoverInnerFrame()

            // المحتوى
            VStack(spacing: 0) {
                Spacer().frame(height: 46)

                // الماندالا
                IslamicMandala(size: 148)

                Spacer().frame(height: 18)

                // فاصل ذهبي علوي
                CoverDivider()
                    .padding(.horizontal, 48)
                    .padding(.bottom, 14)

                // البسملة
                Text("بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ")
                    .font(.hafsSmart(21))
                    .foregroundStyle(Color.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .environment(\.layoutDirection, .rightToLeft)
                    .padding(.bottom, 14)

                // فاصل ذهبي سفلي
                CoverDivider()
                    .padding(.horizontal, 48)
                    .padding(.bottom, 16)

                // العنوان الرئيسي
                Text("المصحف الشريف")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.goldLight,
                                Theme.goldBright,
                                Color(red:0.95, green:0.82, blue:0.50),
                                Theme.goldBright,
                                Theme.goldLight
                            ],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 6, y: 2)
                    .padding(.bottom, 8)

                // التفاصيل
                HStack(spacing: 0) {
                    coverDetailPill("رواية حفص")
                    coverSep
                    coverDetailPill("عن عاصم")
                    coverSep
                    coverDetailPill("الكوفي")
                }
                .padding(.bottom, 6)

                HStack(spacing: 0) {
                    coverDetailPill("تلاوة")
                    coverSep
                    coverDetailPill("حفظ")
                    coverSep
                    coverDetailPill("بحث")
                }
                .padding(.bottom, 36)
            }
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 34,
                bottomTrailingRadius: 34, topTrailingRadius: 0
            )
        )
        .shadow(color: .black.opacity(0.28), radius: 30, y: 15)
    }

    private func coverDetailPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11.5, weight: .semibold))
            .foregroundStyle(Theme.goldPale.opacity(0.88))
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .overlay(
                Capsule().stroke(Theme.gold.opacity(0.30), lineWidth: 0.8)
            )
    }

    private var coverSep: some View {
        Rectangle()
            .fill(Theme.gold.opacity(0.28))
            .frame(width: 1, height: 16)
    }

    // ══════════════════════════════════════════════════════
    // MARK: - بطاقة متابعة القراءة
    // ══════════════════════════════════════════════════════

    private var continueCard: some View {
        let info = store.pageInfo(page: lastPage)
        return Button { openReader(lastPage) } label: {
            HStack(spacing: 14) {
                // أيقونة الصفحة
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.greenGlass)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.greenStroke, lineWidth: 1))
                    VStack(spacing: 2) {
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.green)
                        Text(toArabicNums(lastPage))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.green)
                    }
                }
                .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 3) {
                    Text("متابعة القراءة")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.mutedInk)
                    Text(info.title)
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text(info.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.subtleInk)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [Theme.greenMedium, Theme.green],
                                          startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 36, height: 36)
                .shadow(color: Theme.green.opacity(0.38), radius: 8, y: 4)
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    colors: [Theme.gold.opacity(0.48), Theme.gold.opacity(0.20),
                                             Theme.gold.opacity(0.48)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    )
            )
            .shadow(color: .black.opacity(0.07), radius: 14, y: 5)
        }
        .buttonStyle(.plain)
    }

    // ══════════════════════════════════════════════════════
    // MARK: - أزرار الإجراءات السريعة
    // ══════════════════════════════════════════════════════

    private var quickActionsRow: some View {
        HStack(spacing: 10) {
            QuickTile(
                title: "الفهرس", subtitle: "١١٤ سورة",
                icon: "list.bullet.rectangle.portrait.fill",
                tint: Theme.green
            ) { openReader(lastPage) }

            QuickTile(
                title: "البحث", subtitle: "في الآيات",
                icon: "magnifyingglass",
                tint: Color(red:0.40, green:0.20, blue:0.04)
            ) { openReader(lastPage) }

            QuickTile(
                title: "العلامات", subtitle: "المحفوظة",
                icon: "bookmark.fill",
                tint: Color(red:0.10, green:0.26, blue:0.48)
            ) { openReader(lastPage) }
        }
    }

    // ══════════════════════════════════════════════════════
    // MARK: - بطاقة آية اليوم
    // ══════════════════════════════════════════════════════

    private var dailyAyahCard: some View {
        VStack(spacing: 0) {
            HStack {
                Label("من آيات القرآن الكريم", systemImage: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.mutedInk)
                    .labelStyle(.titleAndIcon)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 13)
            .padding(.bottom, 9)

            OrnamentalDivider()
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            Text("وَلَقَدۡ يَسَّرۡنَا ٱلۡقُرۡءَانَ لِلذِّكۡرِ فَهَلۡ مِن مُّدَّكِرٍ")
                .font(.hafsSmart(20))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .environment(\.layoutDirection, .rightToLeft)
                .padding(.horizontal, 18)
                .padding(.bottom, 8)

            OrnamentalDivider()
                .padding(.horizontal, 16)
                .padding(.top, 2)
                .padding(.bottom, 9)

            Text("سورة القمر  •  الآية ١٧")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.mutedInk)
                .padding(.bottom, 13)
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [Theme.gold.opacity(0.42), Theme.gold.opacity(0.18),
                                         Theme.gold.opacity(0.42)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

// ══════════════════════════════════════════════════════════════
// MARK: - بلاطة إجراء سريع
// ══════════════════════════════════════════════════════════════

private struct QuickTile: View {
    let title:    String
    let subtitle: String
    let icon:     String
    let tint:     Color
    let action:   () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 9) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.11))
                        .overlay(Circle().stroke(tint.opacity(0.22), lineWidth: 1))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint)
                }
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.subtleInk)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.card)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.stroke, lineWidth: 1))
            )
            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// ══════════════════════════════════════════════════════════════
// MARK: - عناصر الغلاف الزخرفية
// ══════════════════════════════════════════════════════════════

private struct CoverDivider: View {
    var body: some View {
        HStack(spacing: 6) {
            Rectangle().fill(Theme.goldLight.opacity(0.42)).frame(height: 0.8)
            // ثلاثة معينات
            Canvas { ctx, sz in
                let cy = sz.height/2; let cx = sz.width/2
                for (dx, scale) in [(0.0, 1.0), (-9.0, 0.58), (9.0, 0.58)] {
                    let d = 3.8 * CGFloat(scale)
                    var p = Path()
                    p.move(to:    CGPoint(x: cx+CGFloat(dx), y: cy-d))
                    p.addLine(to: CGPoint(x: cx+CGFloat(dx)+d, y: cy))
                    p.addLine(to: CGPoint(x: cx+CGFloat(dx), y: cy+d))
                    p.addLine(to: CGPoint(x: cx+CGFloat(dx)-d, y: cy))
                    p.closeSubpath()
                    ctx.fill(p, with: .color(Theme.goldLight.opacity(0.88)))
                }
            }
            .frame(width: 34, height: 14)
            Rectangle().fill(Theme.goldLight.opacity(0.42)).frame(height: 0.8)
        }
    }
}

private struct CoverInnerFrame: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width; let h = geo.size.height

            Canvas { ctx, sz in
                let i1: CGFloat = 14; let i2: CGFloat = 20; let i3: CGFloat = 24

                // إطار خارجي مزدوج
                for (inset, opacity, lw) in [(i1, 0.65, 1.3), (i1+3, 0.28, 0.6)] as [(CGFloat, CGFloat, CGFloat)] {
                    let r = Path(CGRect(x: inset, y: inset,
                                       width: w - inset*2, height: h - inset*2))
                    ctx.stroke(r, with: .color(Theme.goldLight.opacity(opacity)), lineWidth: lw)
                }

                // إطار داخلي
                let r3 = Path(CGRect(x: i2, y: i2, width: w-i2*2, height: h-i2*2))
                ctx.stroke(r3, with: .color(Theme.gold.opacity(0.22)), lineWidth: 0.6)

                // نجوم في زوايا الإطار الخارجي
                let corners: [CGPoint] = [
                    CGPoint(x: i1+6, y: i1+6),
                    CGPoint(x: w-i1-6, y: i1+6),
                    CGPoint(x: i1+6, y: h-i1-6),
                    CGPoint(x: w-i1-6, y: h-i1-6)
                ]
                for c in corners {
                    for j in 0..<8 {
                        let a = Double(j) * .pi / 4
                        let px = c.x + CGFloat(cos(a)) * 5.5
                        let py = c.y + CGFloat(sin(a)) * 5.5
                        ctx.fill(Path(ellipseIn: CGRect(x: px-1.5, y: py-1.5, width: 3, height: 3)),
                                with: .color(Theme.goldLight.opacity(0.62)))
                    }
                    let cr: CGFloat = 2.5
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x-cr, y: c.y-cr, width: cr*2, height: cr*2)),
                            with: .color(Color.white.opacity(0.85)))
                }
            }
        }
    }
}

private struct CoverGeometricPattern: View {
    var body: some View {
        Canvas { ctx, sz in
            let step: CGFloat = 34
            var row = 0
            var y: CGFloat = 0
            while y < sz.height {
                let xOff: CGFloat = (row % 2 == 0) ? 0 : step/2
                var x: CGFloat = xOff
                while x < sz.width {
                    // نجمة 8 رؤوس صغيرة
                    let r1: CGFloat = step * 0.40
                    let r2: CGFloat = step * 0.18
                    var star = Path()
                    for i in 0..<16 {
                        let a = Double(i) * .pi / 8 - .pi/8
                        let r = (i % 2 == 0) ? r1 : r2
                        let pt = CGPoint(x: x + CGFloat(cos(a))*r, y: y + CGFloat(sin(a))*r)
                        if i == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
                    }
                    star.closeSubpath()
                    ctx.stroke(star, with: .color(Color.white), lineWidth: 0.45)
                    x += step
                }
                y += step * 0.866
                row += 1
            }
        }
    }
}

private struct CoverStarfield: View {
    private let positions: [(CGFloat, CGFloat, CGFloat)] = [
        (0.08,0.06,1.4),(0.22,0.13,0.9),(0.62,0.04,1.2),(0.87,0.10,0.8),
        (0.44,0.18,0.7),(0.76,0.21,1.1),(0.14,0.30,0.9),(0.52,0.28,1.3),
        (0.91,0.35,0.7),(0.30,0.42,1.0),(0.68,0.46,0.8),(0.06,0.52,0.9),
        (0.46,0.55,1.2),(0.80,0.58,0.7),(0.20,0.65,0.8),(0.58,0.70,1.0),
        (0.12,0.78,0.9),(0.72,0.80,0.8),(0.36,0.86,1.1),(0.90,0.90,0.7),
        (0.25,0.95,0.8),(0.65,0.92,0.9),(0.48,0.98,0.7)
    ]

    var body: some View {
        Canvas { ctx, sz in
            for (rx, ry, s) in positions {
                let x = rx * sz.width; let y = ry * sz.height
                ctx.fill(Path(ellipseIn: CGRect(x: x-s/2, y: y-s/2, width: s, height: s)),
                        with: .color(Color.white.opacity(0.78)))
            }
        }
    }
}
