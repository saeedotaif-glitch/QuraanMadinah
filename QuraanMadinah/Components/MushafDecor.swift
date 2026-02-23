import SwiftUI

// ══════════════════════════════════════════════════════════════
// MARK: - خلفية الورق
// ══════════════════════════════════════════════════════════════

struct ParchmentBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Theme.page,     location: 0.0),
                    .init(color: Theme.pageMid,  location: 0.5),
                    .init(color: Theme.pageDeep, location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing
            )
            // ألياف الورق الدقيقة
            PaperFiber()
        }
        .ignoresSafeArea()
    }
}

private struct PaperFiber: View {
    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRandom(seed: 42)
            var y: CGFloat = 0
            while y < size.height {
                let x0: CGFloat = rng.next() * size.width * 0.1
                let x1: CGFloat = size.width - rng.next() * size.width * 0.1
                let dy: CGFloat = rng.next() * 1.8 - 0.9
                let opacity = rng.next() * 0.018 + 0.006
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: x0, y: y))
                    p.addCurve(
                        to: CGPoint(x: x1, y: y + dy),
                        control1: CGPoint(x: size.width * 0.3, y: y + dy * 0.4),
                        control2: CGPoint(x: size.width * 0.7, y: y - dy * 0.3)
                    )
                }, with: .color(Color(red:0.52, green:0.40, blue:0.22).opacity(opacity)),
                   lineWidth: 0.4)
                y += rng.next() * 3.5 + 1.8
            }
        }
    }
}

// خوارزمية random ثابتة (لا تتغير بين الـ renders)
private struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> CGFloat {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17
        return CGFloat(state & 0xFFFF) / CGFloat(0xFFFF)
    }
}

// ══════════════════════════════════════════════════════════════
// MARK: - إطار صفحة المصحف الاحترافي
// محاكاة دقيقة لإطار مصحف المدينة المنورة
// ══════════════════════════════════════════════════════════════

struct MushafPageFrame: View {
    let cornerRadius: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack {
                MadinahBorderSystem(size: geo.size, cr: cornerRadius)
            }
            .drawingGroup()
            .accessibilityHidden(true)
        }
    }
}

// ── نظام الحدود المتعدد الطبقات ───────────────────────────────

private struct MadinahBorderSystem: View {
    let size: CGSize
    let cr: CGFloat

    var body: some View {
        Canvas { ctx, sz in
            // ─── الطبقة 1: الخط الذهبي الخارجي ─────────────────
            strokeRect(ctx, sz, inset: 1.5, radius: cr,
                       color: Theme.gold, width: 1.8)

            // ─── الطبقة 2: الشريط الزخرفي (النمط الهندسي المتكرر)
            drawDecorativeBand(ctx: ctx, sz: sz,
                               outerInset: 6.0, bandWidth: 14.0, cr: cr - 4)

            // ─── الطبقة 3: خط ذهبي داخلي ─────────────────────────
            strokeRect(ctx, sz, inset: 21.5, radius: cr - 14,
                       color: Theme.gold.opacity(0.85), width: 1.2)

            // ─── الطبقة 4: خط أخضر داخلي ────────────────────────
            strokeRect(ctx, sz, inset: 25.5, radius: cr - 18,
                       color: Theme.green.opacity(0.72), width: 0.85)

            // ─── الطبقة 5: خط ذهبي خافت أعمق ────────────────────
            strokeRect(ctx, sz, inset: 28.5, radius: cr - 21,
                       color: Theme.gold.opacity(0.35), width: 0.6)

            // ─── زخارف الزوايا الكبيرة ───────────────────────────
            drawAllCornerMedallions(ctx: ctx, sz: sz)
        }
    }

    // ── رسم مستطيل بإطار ─────────────────────────────

    private func strokeRect(_ ctx: GraphicsContext, _ sz: CGSize,
                             inset i: CGFloat, radius r: CGFloat,
                             color: Color, width: CGFloat) {
        let rect = CGRect(x: i, y: i, width: sz.width - i*2, height: sz.height - i*2)
        let path = Path(roundedRect: rect, cornerRadius: max(r, 1), style: .continuous)
        ctx.stroke(path, with: .color(color), lineWidth: width)
    }

    // ── الشريط الزخرفي (تسلسل من نمط المعين والزهرة) ────────────

    private func drawDecorativeBand(ctx: GraphicsContext, sz: CGSize,
                                     outerInset oi: CGFloat, bandWidth bw: CGFloat,
                                     cr: CGFloat) {
        let midInset = oi + bw / 2
        let step: CGFloat = 10.0

        // الخط المحوري للشريط (خط رفيع وسط الشريط)
        strokeRect(ctx, sz, inset: oi, radius: cr + bw/2,
                   color: Theme.goldDark.opacity(0.40), width: 0.5)
        strokeRect(ctx, sz, inset: oi + bw, radius: cr - bw/2,
                   color: Theme.goldDark.opacity(0.40), width: 0.5)

        // حواف الشريط العلوية والسفلية والجانبية
        let top   = midInset
        let bot   = sz.height - midInset
        let left  = midInset
        let right = sz.width  - midInset

        // الحافة العلوية
        drawBandRow(ctx: ctx, from: CGPoint(x: oi + bw * 2, y: top),
                    to: CGPoint(x: sz.width - oi - bw * 2, y: top),
                    step: step, vertical: false)

        // الحافة السفلية
        drawBandRow(ctx: ctx, from: CGPoint(x: oi + bw * 2, y: bot),
                    to: CGPoint(x: sz.width - oi - bw * 2, y: bot),
                    step: step, vertical: false)

        // الحافة اليمنى
        drawBandRow(ctx: ctx, from: CGPoint(x: right, y: oi + bw * 2),
                    to: CGPoint(x: right, y: sz.height - oi - bw * 2),
                    step: step, vertical: true)

        // الحافة اليسرى
        drawBandRow(ctx: ctx, from: CGPoint(x: left, y: oi + bw * 2),
                    to: CGPoint(x: left, y: sz.height - oi - bw * 2),
                    step: step, vertical: true)
    }

    private func drawBandRow(ctx: GraphicsContext,
                              from: CGPoint, to: CGPoint,
                              step: CGFloat, vertical: Bool) {
        let len = vertical ? (to.y - from.y) : (to.x - from.x)
        guard len > 0 else { return }
        let count = Int(len / step)
        let actualStep = len / CGFloat(max(count, 1))

        for i in 0...count {
            let t = CGFloat(i) * actualStep
            let cx = vertical ? from.x : from.x + t
            let cy = vertical ? from.y + t : from.y
            let isEven = i % 2 == 0

            if isEven {
                // معين ذهبي مملوء
                let d: CGFloat = 3.6
                var p = Path()
                p.move(to:    CGPoint(x: cx,   y: cy - d))
                p.addLine(to: CGPoint(x: cx + d, y: cy))
                p.addLine(to: CGPoint(x: cx,   y: cy + d))
                p.addLine(to: CGPoint(x: cx - d, y: cy))
                p.closeSubpath()
                ctx.fill(p, with: .color(Theme.goldBright.opacity(0.80)))
                ctx.stroke(p, with: .color(Theme.goldDark.opacity(0.55)), lineWidth: 0.5)
            } else {
                // وردة صغيرة (6 بتلات)
                for j in 0..<6 {
                    let a = Double(j) * .pi / 3
                    let px = cx + CGFloat(cos(a)) * 3.0
                    let py = cy + CGFloat(sin(a)) * 3.0
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: px-1.4, y: py-1.4, width: 2.8, height: 2.8)),
                        with: .color(Theme.gold.opacity(0.60))
                    )
                }
                // نقطة مركزية
                ctx.fill(
                    Path(ellipseIn: CGRect(x: cx-1.2, y: cy-1.2, width: 2.4, height: 2.4)),
                    with: .color(Theme.goldDark.opacity(0.85))
                )
            }
        }
    }

    // ── شمسيات الزوايا الكبيرة ──────────────────────────────────

    private func drawAllCornerMedallions(ctx: GraphicsContext, sz: CGSize) {
        let r: CGFloat = 28.0
        let positions = [
            CGPoint(x: r,            y: r),
            CGPoint(x: sz.width - r, y: r),
            CGPoint(x: r,            y: sz.height - r),
            CGPoint(x: sz.width - r, y: sz.height - r)
        ]
        for pt in positions {
            drawMedallion(ctx: ctx, center: pt, outerR: r)
        }
    }

    private func drawMedallion(ctx: GraphicsContext, center: CGPoint, outerR: CGFloat) {
        // خلفية دائرية بلون الورق
        let bgRect = CGRect(x: center.x - outerR, y: center.y - outerR,
                           width: outerR * 2, height: outerR * 2)
        ctx.fill(Path(ellipseIn: bgRect), with: .color(Theme.page))

        // الحلقة الخارجية الذهبية
        ctx.stroke(Path(ellipseIn: bgRect.insetBy(dx: 0.8, dy: 0.8)),
                  with: .color(Theme.gold), lineWidth: 1.6)

        // نجمة 16 رأساً
        let starOuter = outerR * 0.82
        let starInner = outerR * 0.42
        var star = Path()
        for i in 0..<32 {
            let a = Double(i) * .pi / 16 - .pi / 2
            let rr = (i % 2 == 0) ? starOuter : starInner
            let pt = CGPoint(x: center.x + CGFloat(cos(a)) * rr,
                           y: center.y + CGFloat(sin(a)) * rr)
            if i == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
        }
        star.closeSubpath()
        ctx.fill(star,   with: .color(Theme.goldBright.opacity(0.88)))
        ctx.stroke(star, with: .color(Theme.goldDark.opacity(0.70)), lineWidth: 0.7)

        // حلقة وسطى بيضاء/ورقية
        let midR = outerR * 0.38
        let midRect = CGRect(x: center.x - midR, y: center.y - midR,
                            width: midR * 2, height: midR * 2)
        ctx.fill(Path(ellipseIn: midRect), with: .color(Theme.page))
        ctx.stroke(Path(ellipseIn: midRect.insetBy(dx: 0.5, dy: 0.5)),
                  with: .color(Theme.goldDark.opacity(0.65)), lineWidth: 0.8)

        // نقاط ذهبية حول المركز (8 نقاط)
        let dotRing = outerR * 0.22
        for i in 0..<8 {
            let a = Double(i) * .pi / 4
            let dpx = center.x + CGFloat(cos(a)) * dotRing
            let dpy = center.y + CGFloat(sin(a)) * dotRing
            let dr: CGFloat = outerR * 0.055
            ctx.fill(Path(ellipseIn: CGRect(x: dpx-dr, y: dpy-dr, width: dr*2, height: dr*2)),
                    with: .color(Theme.gold.opacity(0.90)))
        }

        // نقطة مركزية خضراء
        let cR: CGFloat = outerR * 0.13
        ctx.fill(Path(ellipseIn: CGRect(x: center.x-cR, y: center.y-cR, width: cR*2, height: cR*2)),
                with: .color(Theme.green.opacity(0.88)))
        let c2R: CGFloat = outerR * 0.055
        ctx.fill(Path(ellipseIn: CGRect(x: center.x-c2R, y: center.y-c2R, width: c2R*2, height: c2R*2)),
                with: .color(Theme.goldBright))
    }
}

// ══════════════════════════════════════════════════════════════
// MARK: - ترويسة السورة (مصحف المدينة)
// ══════════════════════════════════════════════════════════════

struct SurahOpeningBanner: View {
    let surahName: String

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // الخلفية: تدرج أخضر عميق
                LinearGradient(
                    stops: [
                        .init(color: Color(red:0.025, green:0.165, blue:0.108), location: 0),
                        .init(color: Color(red:0.038, green:0.210, blue:0.142), location: 0.45),
                        .init(color: Color(red:0.028, green:0.182, blue:0.122), location: 1)
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
                .cornerRadius(4)

                // الإطار الداخلي الذهبي
                BannerFrameCanvas(size: geo.size)

                // النمط الزخرفي الشفاف
                BannerPatternOverlay()
                    .opacity(0.10)
                    .cornerRadius(4)
                    .clipped()

                // المحتوى
                VStack(spacing: 0) {
                    // السطر العلوي: خط نقطي ذهبي
                    BannerTopLine()

                    HStack(alignment: .center, spacing: 0) {
                        // جانب أيمن: نمط زخرفي
                        BannerSideOrnament()
                        Spacer()

                        // المركز: اسم السورة
                        VStack(spacing: 3) {
                            Text(surahName)
                                .font(.system(size: 17, weight: .bold, design: .serif))
                                .foregroundStyle(Theme.goldLight)
                                .shadow(color: Color.black.opacity(0.30), radius: 2, y: 1)
                        }

                        Spacer()
                        // جانب أيسر
                        BannerSideOrnament()
                    }
                    .padding(.horizontal, 10)

                    // السطر السفلي
                    BannerTopLine()
                }
                .padding(.vertical, 6)
            }
            .frame(width: geo.size.width)
        }
        .frame(height: 46)
        .shadow(color: Color.black.opacity(0.22), radius: 6, y: 3)
    }
}

private struct BannerFrameCanvas: View {
    let size: CGSize
    var body: some View {
        Canvas { ctx, sz in
            // إطار ذهبي مزدوج
            let r1 = Path(roundedRect: CGRect(x: 1.5, y: 1.5,
                                              width: sz.width-3, height: sz.height-3),
                         cornerRadius: 4)
            ctx.stroke(r1, with: .color(Theme.gold.opacity(0.80)), lineWidth: 1.4)

            let r2 = Path(roundedRect: CGRect(x: 4.5, y: 4.5,
                                              width: sz.width-9, height: sz.height-9),
                         cornerRadius: 2.5)
            ctx.stroke(r2, with: .color(Theme.goldDark.opacity(0.50)), lineWidth: 0.7)

            // نجوم في الزوايا الأربع
            let corners = [
                CGPoint(x: 12, y: sz.height/2),
                CGPoint(x: sz.width - 12, y: sz.height/2)
            ]
            for c in corners {
                for i in 0..<8 {
                    let a = Double(i) * .pi / 4
                    let px = c.x + CGFloat(cos(a)) * 5.5
                    let py = c.y + CGFloat(sin(a)) * 5.5
                    ctx.fill(Path(ellipseIn: CGRect(x: px-1.3, y: py-1.3, width: 2.6, height: 2.6)),
                            with: .color(Theme.goldLight.opacity(0.70)))
                }
                ctx.fill(Path(ellipseIn: CGRect(x: c.x-2.2, y: c.y-2.2, width: 4.4, height: 4.4)),
                        with: .color(Theme.goldBright.opacity(0.90)))
            }
        }
    }
}

private struct BannerTopLine: View {
    var body: some View {
        Canvas { ctx, sz in
            // خط بنقاط ماسية
            let step: CGFloat = 7
            var x: CGFloat = step
            while x < sz.width - step {
                let i = Int(x / step)
                if i % 2 == 0 {
                    let d: CGFloat = 2.2
                    var p = Path()
                    p.move(to:    CGPoint(x: x,   y: sz.height/2 - d))
                    p.addLine(to: CGPoint(x: x+d, y: sz.height/2))
                    p.addLine(to: CGPoint(x: x,   y: sz.height/2 + d))
                    p.addLine(to: CGPoint(x: x-d, y: sz.height/2))
                    p.closeSubpath()
                    ctx.fill(p, with: .color(Theme.gold.opacity(0.65)))
                } else {
                    ctx.fill(Path(ellipseIn: CGRect(x: x-1, y: sz.height/2-1, width: 2, height: 2)),
                            with: .color(Theme.goldDark.opacity(0.45)))
                }
                x += step
            }
        }
        .frame(height: 7)
    }
}

private struct BannerSideOrnament: View {
    var body: some View {
        Canvas { ctx, sz in
            // ورقة/ريشة مع نقطة
            let cx = sz.width/2; let cy = sz.height/2
            // فصوص منحنية
            for i in 0..<3 {
                let ox = CGFloat(i - 1) * 7
                var p = Path()
                p.move(to:        CGPoint(x: cx+ox, y: cy - 7))
                p.addQuadCurve(to: CGPoint(x: cx+ox, y: cy + 7),
                               control: CGPoint(x: cx+ox + 5, y: cy))
                p.addQuadCurve(to: CGPoint(x: cx+ox, y: cy - 7),
                               control: CGPoint(x: cx+ox - 5, y: cy))
                ctx.fill(p, with: .color(Theme.gold.opacity(0.50 - CGFloat(abs(i-1))*0.12)))
            }
        }
        .frame(width: 26, height: 22)
    }
}

private struct BannerPatternOverlay: View {
    var body: some View {
        Canvas { ctx, sz in
            // نمط هندسي خفيف
            let step: CGFloat = 18
            var x: CGFloat = 0
            while x < sz.width {
                var y: CGFloat = 0
                while y < sz.height {
                    var p = Path()
                    for i in 0..<6 {
                        let a = Double(i) * .pi / 3
                        let pt = CGPoint(x: x + CGFloat(cos(a)) * step/2.2,
                                       y: y + CGFloat(sin(a)) * step/2.2)
                        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                    p.closeSubpath()
                    ctx.stroke(p, with: .color(Color.white), lineWidth: 0.4)
                    y += step * 0.866
                }
                x += step
            }
        }
    }
}

// ══════════════════════════════════════════════════════════════
// MARK: - الفاصل الزخرفي
// ══════════════════════════════════════════════════════════════

struct OrnamentalDivider: View {
    var color: Color = Theme.gold.opacity(0.50)

    var body: some View {
        Canvas { ctx, sz in
            let cy = sz.height / 2

            // خط أيمن
            let rightStart = sz.width / 2 + 18
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: rightStart, y: cy))
                p.addLine(to: CGPoint(x: sz.width, y: cy))
            }, with: .color(color), lineWidth: 0.7)

            // خط أيسر
            let leftEnd = sz.width / 2 - 18
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: 0, y: cy))
                p.addLine(to: CGPoint(x: leftEnd, y: cy))
            }, with: .color(color), lineWidth: 0.7)

            // الشكل المركزي: معين مع نقاط جانبية
            let cx = sz.width / 2
            // نقاط جانبية
            for dx in [-12, 12] as [CGFloat] {
                ctx.fill(Path(ellipseIn: CGRect(x: cx+dx-1.5, y: cy-1.5, width: 3, height: 3)),
                        with: .color(color.opacity(1)))
            }
            // المعين الرئيسي
            let d: CGFloat = 4.5
            var diamond = Path()
            diamond.move(to:    CGPoint(x: cx,   y: cy - d))
            diamond.addLine(to: CGPoint(x: cx+d, y: cy))
            diamond.addLine(to: CGPoint(x: cx,   y: cy + d))
            diamond.addLine(to: CGPoint(x: cx-d, y: cy))
            diamond.closeSubpath()
            ctx.fill(diamond, with: .color(color.opacity(1.2).opacity(1)))
            // معينان صغيران
            for dx in [-8, 8] as [CGFloat] {
                let sd: CGFloat = 2.5
                var sd_path = Path()
                sd_path.move(to:    CGPoint(x: cx+dx,    y: cy - sd))
                sd_path.addLine(to: CGPoint(x: cx+dx+sd, y: cy))
                sd_path.addLine(to: CGPoint(x: cx+dx,    y: cy + sd))
                sd_path.addLine(to: CGPoint(x: cx+dx-sd, y: cy))
                sd_path.closeSubpath()
                ctx.fill(sd_path, with: .color(color.opacity(0.85)))
            }
        }
        .frame(height: 10)
    }
}

// ══════════════════════════════════════════════════════════════
// MARK: - ظل تجليد الكتاب
// ══════════════════════════════════════════════════════════════

struct BookGutterShadow: View {
    let pageNumber: Int
    var body: some View {
        GeometryReader { geo in
            let isRight = (pageNumber % 2) == 1
            LinearGradient(
                colors: [Color.black.opacity(0.10), Color.clear],
                startPoint: isRight ? .leading : .trailing,
                endPoint:   isRight ? .trailing : .leading
            )
            .frame(width: 24)
            .position(x: isRight ? 12 : geo.size.width - 12, y: geo.size.height/2)
            .allowsHitTesting(false)
        }
    }
}

// ══════════════════════════════════════════════════════════════
// MARK: - الماندالا الإسلامية (للشاشة الرئيسية)
// ══════════════════════════════════════════════════════════════

struct IslamicMandala: View {
    var size: CGFloat = 200

    var body: some View {
        Canvas { ctx, sz in
            let cx = sz.width/2; let cy = sz.height/2
            let R = sz.width/2 * 0.95

            // حلقات متحدة المركز
            for (r, op) in [(R, 0.22), (R*0.78, 0.18), (R*0.55, 0.16), (R*0.32, 0.15)] {
                ctx.stroke(
                    Path(ellipseIn: CGRect(x: cx-CGFloat(r), y: cy-CGFloat(r),
                                          width: CGFloat(r)*2, height: CGFloat(r)*2)),
                    with: .color(Theme.goldLight.opacity(CGFloat(op))), lineWidth: 0.8)
            }
            // حلقة من 16 وردة
            petalRing(ctx, cx: cx, cy: cy, ring: R*0.86, n: 16, pr: R*0.09,
                     color: Theme.gold.opacity(0.30))
            // حلقة من 12 نجمة صغيرة
            starRing(ctx, cx: cx, cy: cy, ring: R*0.64, n: 12, outerR: R*0.09,
                    innerR: R*0.042, color: Theme.gold.opacity(0.50))
            // حلقة من 8 نجوم أكبر
            starRing(ctx, cx: cx, cy: cy, ring: R*0.40, n: 8, outerR: R*0.10,
                    innerR: R*0.048, color: Theme.gold.opacity(0.68))
            // النجمة المركزية الكبيرة (16 رأساً)
            star(ctx, cx: cx, cy: cy, outerR: R*0.25, innerR: R*0.115, pts: 16,
                fill: Theme.goldVibrant.opacity(0.92))
            star(ctx, cx: cx, cy: cy, outerR: R*0.25, innerR: R*0.115, pts: 16,
                stroke: Theme.goldDark.opacity(0.65), lw: 0.7)
            // النقطة المركزية
            let dr = R*0.08
            ctx.fill(Path(ellipseIn: CGRect(x: cx-dr, y: cy-dr, width: dr*2, height: dr*2)),
                    with: .color(Theme.green.opacity(0.90)))
            let dr2 = R*0.035
            ctx.fill(Path(ellipseIn: CGRect(x: cx-dr2, y: cy-dr2, width: dr2*2, height: dr2*2)),
                    with: .color(Theme.goldBright))
        }
        .frame(width: size, height: size)
    }

    private func petalRing(_ ctx: GraphicsContext, cx: CGFloat, cy: CGFloat,
                            ring: CGFloat, n: Int, pr: CGFloat, color: Color) {
        for i in 0..<n {
            let a = Double(i) * 2 * .pi / Double(n)
            let px = cx + CGFloat(cos(a)) * ring
            let py = cy + CGFloat(sin(a)) * ring
            ctx.fill(Path(ellipseIn: CGRect(x: px-pr, y: py-pr, width: pr*2, height: pr*2)),
                    with: .color(color))
        }
    }

    private func starRing(_ ctx: GraphicsContext, cx: CGFloat, cy: CGFloat,
                           ring: CGFloat, n: Int, outerR: CGFloat, innerR: CGFloat, color: Color) {
        for i in 0..<n {
            let a = Double(i) * 2 * .pi / Double(n)
            let px = cx + CGFloat(cos(a)) * ring
            let py = cy + CGFloat(sin(a)) * ring
            var p = Path()
            for j in 0..<12 {
                let sa = Double(j) * .pi / 6 - .pi/2
                let r = (j % 2 == 0) ? outerR : innerR
                let pt = CGPoint(x: px + CGFloat(cos(sa))*r, y: py + CGFloat(sin(sa))*r)
                if j == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
        }
    }

    private func star(_ ctx: GraphicsContext, cx: CGFloat, cy: CGFloat,
                      outerR: CGFloat, innerR: CGFloat, pts: Int,
                      fill: Color? = nil, stroke: Color? = nil, lw: CGFloat = 1) {
        var p = Path()
        for i in 0..<(pts * 2) {
            let a = Double(i) * .pi / Double(pts) - .pi/2
            let r = (i % 2 == 0) ? outerR : innerR
            let pt = CGPoint(x: cx + CGFloat(cos(a))*r, y: cy + CGFloat(sin(a))*r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        if let f = fill   { ctx.fill(p, with: .color(f)) }
        if let s = stroke { ctx.stroke(p, with: .color(s), lineWidth: lw) }
    }
}
