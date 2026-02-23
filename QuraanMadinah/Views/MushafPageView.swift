import SwiftUI
import UIKit

// ══════════════════════════════════════════════════════════════
// MARK: - MushafPageView  — محاكاة مصحف المدينة المنورة
// ══════════════════════════════════════════════════════════════

struct MushafPageView: View {
    let pageNumber: Int
    let records:    [AyaRecord]

    @AppStorage("mushaf_font_scale_v1") private var fontScale: Double = 1.18

    // ── ثوابت هيكلية ──────────────────────────────────────────────
    private let outerMargin : CGFloat = 11
    private let frameInset  : CGFloat = 30
    private let topPadding  : CGFloat = 13
    private let btmPadding  : CGFloat = 11

    // ── حساب عرض النص بدقة ───────────────────────────────────────
    private func textWidth(geo: GeometryProxy, outerPad: CGFloat,
                           innerPad: CGFloat, sideW: CGFloat) -> CGFloat {
        geo.size.width - (outerPad * 2) - (innerPad * 2) - (sideW * 2)
    }

    var body: some View {
        GeometryReader { geo in
            let isPad     = geo.size.width > 600
            let outerPad  = isPad ? outerMargin + 4 : outerMargin
            let innerPad  = isPad ? frameInset + 4 : frameInset
            let sideW: CGFloat = isPad ? 24 : 18

            // حجم خط موحّد لكل الصفحات
            let baseFontSize: CGFloat = isPad ? 28 : 23.5
            let fontSize = max(18, min(baseFontSize * CGFloat(fontScale), 40))

            let tW = textWidth(geo: geo, outerPad: outerPad, innerPad: innerPad, sideW: sideW)
            let uiFont = UIFont(name: "KFGQPCHafsSmart-Regular", size: fontSize)
                      ?? UIFont.systemFont(ofSize: fontSize)
            let pageLines = PageComposer.shared.compose(
                page: pageNumber, records: records, font: uiFont, maxWidth: tW
            )

            ZStack {
                ParchmentBackground()
                pageBody(geo: geo, isPad: isPad, outerPad: outerPad,
                        innerPad: innerPad, sideW: sideW,
                        fontSize: fontSize, uiFont: uiFont, pageLines: pageLines)
            }
        }
        .onChange(of: fontScale) { _, _ in PageComposer.shared.clearCache() }
    }

    // ── الجسم الكامل للصفحة ───────────────────────────────────────

    @ViewBuilder
    private func pageBody(geo: GeometryProxy, isPad: Bool,
                         outerPad: CGFloat, innerPad: CGFloat,
                         sideW: CGFloat, fontSize: CGFloat,
                         uiFont: UIFont,
                         pageLines: [String]) -> some View {
        ZStack {
            // سطح الورق
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(
                    stops: [.init(color: Theme.page.opacity(0.99), location: 0),
                            .init(color: Theme.pageMid, location: 1)],
                    startPoint: .top, endPoint: .bottom))
                .padding(.horizontal, outerPad)
                .padding(.vertical, topPadding)
                .shadow(color: .black.opacity(0.13), radius: 18, x: 0, y: 7)
                .shadow(color: .black.opacity(0.05), radius: 4,  x: 0, y: 2)

            // الإطار الزخرفي
            MushafPageFrame(cornerRadius: 14)
                .padding(.horizontal, outerPad)
                .padding(.vertical, topPadding)

            // ظل التجليد
            BookGutterShadow(pageNumber: pageNumber)
                .padding(.horizontal, outerPad)
                .padding(.vertical, topPadding)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            // ── محتوى الصفحة ─────────────────────────────────────
            VStack(spacing: 0) {
                // رأس الصفحة
                pageHeader(isPad: isPad)
                    .padding(.horizontal, outerPad + innerPad)
                    .padding(.top, isPad ? 22 : 14)
                    .padding(.bottom, 3)

                OrnamentalDivider()
                    .padding(.horizontal, outerPad + innerPad + 2)
                    .padding(.bottom, 5)

                // ─ منطقة النص ─────────────────────────────────
                GeometryReader { textGeo in
                    let banners   = buildBannerMap()
                    let bannerCnt = CGFloat(banners.count)
                    // كل ترويسة سورة تأخذ مكان 1.6 سطر
                    let bannerSlot: CGFloat = 1.6
                    let totalSlots = 15 + bannerCnt * bannerSlot
                    let slotH  = textGeo.size.height / totalSlots
                    let lineH  = slotH
                    let bannerH = slotH * bannerSlot

                    HStack(spacing: 0) {
                        // عمود أيمن (هامش الجزء)
                        rightMargin(totalH: textGeo.size.height)
                            .frame(width: sideW)

                        // نص القرآن مع الترويسات المدمجة
                        textColumn(pageLines: pageLines,
                                  banners: banners,
                                  fontSize: fontSize,
                                  uiFont: uiFont,
                                  lineH: lineH,
                                  bannerH: bannerH)
                            .frame(maxWidth: .infinity)

                        // عمود أيسر (هامش الحزب)
                        leftMargin(totalH: textGeo.size.height)
                            .frame(width: sideW)
                    }
                }
                .padding(.horizontal, outerPad + innerPad - 2)

                OrnamentalDivider()
                    .padding(.horizontal, outerPad + innerPad + 2)
                    .padding(.top, 4)

                // تذييل الصفحة
                pageFooter()
                    .padding(.horizontal, outerPad + innerPad)
                    .padding(.top, 3)
                    .padding(.bottom, isPad ? 20 : btmPadding)
            }
        }
    }

    // ══════════════════════════════════════════════════════════════
    // MARK: - رأس الصفحة (يُعرض اسم السورة في أعلى الصفحة — لا التي تبدأ)
    // ══════════════════════════════════════════════════════════════

    private func pageHeader(isPad: Bool) -> some View {
        // السورة في أعلى الصفحة = السورة ذات أصغر رقم سطر
        let topSurah = records
            .min(by: { $0.lineStart < $1.lineStart })?
            .suraNameAr ?? "المصحف الشريف"
        let juzNo = records
            .min(by: { $0.lineStart < $1.lineStart })?
            .jozz ?? 1

        return HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 3) {
                Text("جـ")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.mutedInk)
                Text(arabicNumerals(juzNo))
                    .font(.system(size: 11.5, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.green)
            }
            .frame(minWidth: 44, alignment: .leading)

            Spacer()

            headerPill(topSurah)

            Spacer()

            Text(arabicNumerals(pageNumber))
                .font(.system(size: 11.5, weight: .bold, design: .serif))
                .foregroundStyle(Theme.green)
                .frame(minWidth: 44, alignment: .trailing)
        }
    }

    private func headerPill(_ name: String) -> some View {
        HStack(spacing: 7) {
            pillOrn
            Text(name)
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundStyle(Theme.green)
                .lineLimit(1)
            pillOrn
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(
            ZStack {
                Capsule().fill(LinearGradient(
                    colors: [Theme.pageMid, Theme.pageDeep, Theme.pageMid],
                    startPoint: .leading, endPoint: .trailing))
                Capsule().stroke(Theme.goldStroke, lineWidth: 1.0)
                Capsule().stroke(Theme.gold.opacity(0.20), lineWidth: 0.5).padding(2.5)
            }
        )
    }

    private var pillOrn: some View {
        Canvas { ctx, sz in
            let cy = sz.height/2
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: 1, y: cy))
                p.addLine(to: CGPoint(x: sz.width-1, y: cy))
            }, with: .color(Theme.gold.opacity(0.55)), lineWidth: 0.8)
            ctx.fill(Path(ellipseIn: CGRect(x: sz.width-3, y: cy-1.5, width: 3, height: 3)),
                    with: .color(Theme.gold.opacity(0.80)))
            ctx.fill(Path(ellipseIn: CGRect(x: 0, y: cy-1.5, width: 3, height: 3)),
                    with: .color(Theme.gold.opacity(0.80)))
        }
        .frame(width: 16, height: 8)
    }

    // ══════════════════════════════════════════════════════════════
    // MARK: - بناء خريطة الترويسات (surahName → lineIndex قبله)
    // الترويسة تظهر مباشرة قبل سطر البسملة
    // ══════════════════════════════════════════════════════════════

    private func buildBannerMap() -> [Int: String] {
        var result: [Int: String] = [:]
        let sorted = records.sorted { $0.id < $1.id }

        for r in sorted where r.ayaNo == 1 {
            let suraNo = r.suraNo
            if suraNo == 9 { continue }          // التوبة: لا بسملة

            if suraNo == 1 {
                // الفاتحة: البسملة في idx = lineStart - 1
                let idx = max(0, min(14, r.lineStart - 1))
                result[idx] = r.suraNameAr
            } else {
                // سائر السور: البسملة في idx = lineStart - 2
                let basmalaIdx = max(0, min(14, r.lineStart - 2))
                result[basmalaIdx] = r.suraNameAr
            }
        }
        return result
    }

    // ══════════════════════════════════════════════════════════════
    // MARK: - عمود النص مع الترويسات المدمجة في موضعها الصحيح
    // ══════════════════════════════════════════════════════════════

    private func textColumn(pageLines: [String],
                            banners: [Int: String],
                            fontSize: CGFloat,
                            uiFont: UIFont,
                            lineH: CGFloat,
                            bannerH: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Array(0..<15) avoids ForEach<Range<Int>> ambiguity in Xcode 26+
            ForEach(Array(0..<15), id: \.self) { idx in
                // ترويسة السورة قبل هذا السطر (إن وُجدت)
                if let surahName = banners[idx] {
                    SurahOpeningBanner(surahName: surahName)
                        .frame(height: bannerH)
                        .padding(.vertical, 1)
                }

                // السطر نفسه
                let line = safeLine(pageLines, idx)
                if isBasmalaLine(line) {
                    BasmalaLineView(text: line, fontSize: fontSize * 0.90)
                        .frame(maxWidth: .infinity)
                        .frame(height: lineH)
                } else {
                    // CoreText with explicit RTL override renders PUA Hafs Smart
                    // characters correctly (they have neutral bidi class by default).
                    MushafCoreTextLine(
                        text: line,
                        font: uiFont,
                        color: UIColor(Theme.ink)
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: lineH)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // ══════════════════════════════════════════════════════════════
    // MARK: - الهوامش الجانبية
    // ══════════════════════════════════════════════════════════════

    private func rightMargin(totalH: CGFloat) -> some View {
        Canvas { ctx, sz in
            let cx = sz.width / 2
            // خط رفيع ذهبي
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: cx, y: 8))
                p.addLine(to: CGPoint(x: cx, y: sz.height - 8))
            }, with: .color(Theme.gold.opacity(0.22)), lineWidth: 0.6)
        }
    }

    private func leftMargin(totalH: CGFloat) -> some View {
        Canvas { ctx, sz in
            let cx = sz.width / 2
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: cx, y: 8))
                p.addLine(to: CGPoint(x: cx, y: sz.height - 8))
            }, with: .color(Theme.gold.opacity(0.22)), lineWidth: 0.6)
        }
    }

    // ══════════════════════════════════════════════════════════════
    // MARK: - تذييل الصفحة
    // ══════════════════════════════════════════════════════════════

    private func pageFooter() -> some View {
        HStack {
            Spacer()
            HStack(spacing: 6) {
                footerOrn
                Text(arabicNumerals(pageNumber))
                    .font(.system(size: 13.5, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.mutedInk)
                footerOrn
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Theme.pageDeep.opacity(0.65))
                    .overlay(Capsule().stroke(Theme.gold.opacity(0.30), lineWidth: 0.8))
            )
            Spacer()
        }
    }

    private var footerOrn: some View {
        Canvas { ctx, sz in
            let cx = sz.width/2; let cy = sz.height/2; let d: CGFloat = 2.2
            var p = Path()
            p.move(to: CGPoint(x:cx, y:cy-d)); p.addLine(to: CGPoint(x:cx+d, y:cy))
            p.addLine(to: CGPoint(x:cx, y:cy+d)); p.addLine(to: CGPoint(x:cx-d, y:cy))
            p.closeSubpath()
            ctx.fill(p, with: .color(Theme.gold.opacity(0.60)))
        }
        .frame(width: 7, height: 7)
    }

    // ══════════════════════════════════════════════════════════════
    // MARK: - مساعدات
    // ══════════════════════════════════════════════════════════════

    private func safeLine(_ lines: [String], _ idx: Int) -> String {
        guard idx >= 0, idx < lines.count else { return "" }
        return lines[idx].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isBasmalaLine(_ text: String) -> Bool {
        text.contains("بِسۡمِ") || text.contains("بِسْمِ")
    }

    /// تحويل الأرقام اللاتينية إلى عربية هندية ١٢٣
    private func arabicNumerals(_ n: Int) -> String {
        let d = ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]
        return String(n).map { c -> String in
            if let v = c.wholeNumberValue, v < d.count { return d[v] }
            return String(c)
        }.joined()
    }
}

// ══════════════════════════════════════════════════════════════
// MARK: - سطر البسملة
// ══════════════════════════════════════════════════════════════

private struct BasmalaLineView: View {
    let text: String
    let fontSize: CGFloat

    var body: some View {
        VStack(spacing: 2) {
            OrnamentalDivider(color: Theme.gold.opacity(0.40))
            Text(text)
                .font(.hafsSmart(fontSize))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .allowsTightening(false)
                .truncationMode(.tail)
                .environment(\.layoutDirection, .rightToLeft)
            OrnamentalDivider(color: Theme.gold.opacity(0.40))
        }
        .padding(.vertical, 1)
    }
}
