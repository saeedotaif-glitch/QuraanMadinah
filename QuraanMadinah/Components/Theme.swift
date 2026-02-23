import SwiftUI

// ══════════════════════════════════════════════════════════════
// MARK: - Theme  (مصحف المدينة المنورة)
// ══════════════════════════════════════════════════════════════

enum Theme {

    // ── ورق المصحف ────────────────────────────────────────────────
    /// لون الورقة الأساسي — كريمي دافئ
    static let page         = Color(red: 0.982, green: 0.975, blue: 0.952)
    static let pageMid      = Color(red: 0.972, green: 0.962, blue: 0.935)
    static let pageDeep     = Color(red: 0.955, green: 0.940, blue: 0.908)
    static let pageEdge     = Color(red: 0.935, green: 0.915, blue: 0.878)

    // مترادف للتوافق مع الملفات الأخرى
    static var parchment     : Color { page }
    static var parchmentMid  : Color { pageMid }
    static var parchmentDeep : Color { pageDeep }
    static var bgTop         : Color { page }
    static var bgBottom      : Color { pageDeep }
    static var card          : Color { Color(red:1,green:0.998,blue:0.990).opacity(0.82) }

    // ── الحبر ──────────────────────────────────────────────────────
    /// حبر المصحف الأسود العميق
    static let ink          = Color(red: 0.068, green: 0.058, blue: 0.042)
    static let inkSoft      = Color(red: 0.140, green: 0.125, blue: 0.095)
    static let mutedInk     = Color(red: 0.38,  green: 0.34,  blue: 0.27)
    static let subtleInk    = Color(red: 0.55,  green: 0.50,  blue: 0.42)

    // ── الذهب الأثري ───────────────────────────────────────────────
    static let gold         = Color(red: 0.748, green: 0.592, blue: 0.235)
    static let goldBright   = Color(red: 0.835, green: 0.685, blue: 0.310)
    static let goldLight    = Color(red: 0.888, green: 0.768, blue: 0.442)
    static let goldDark     = Color(red: 0.578, green: 0.452, blue: 0.135)
    static let goldPale     = Color(red: 0.918, green: 0.858, blue: 0.668)
    static let goldVibrant  = Color(red: 0.810, green: 0.655, blue: 0.275)

    // ── الأخضر الإسلامي ────────────────────────────────────────────
    static let green        = Color(red: 0.022, green: 0.218, blue: 0.148)
    static let greenMedium  = Color(red: 0.045, green: 0.298, blue: 0.205)
    static let greenDeep    = Color(red: 0.012, green: 0.155, blue: 0.102)
    static let greenSoft    = Color(red: 0.308, green: 0.528, blue: 0.408)
    static let greenGlass   = Color(red: 0.022, green: 0.218, blue: 0.148).opacity(0.10)

    // ── ألوان ترويسة السورة (مصحف المدينة) ────────────────────────
    /// خلفية البانر الرئيسية — أخضر عميق كلاسيكي
    static let bannerBg     = Color(red: 0.030, green: 0.175, blue: 0.118)
    static let bannerBorder = Color(red: 0.688, green: 0.542, blue: 0.198)

    // ── رموز الواجهة ───────────────────────────────────────────────
    static let stroke       = Color.black.opacity(0.07)
    static let goldStroke   = Color(red: 0.748, green: 0.592, blue: 0.235).opacity(0.55)
    static let greenStroke  = Color(red: 0.022, green: 0.218, blue: 0.148).opacity(0.38)
    static let goldSubtle   = Color(red: 0.798, green: 0.672, blue: 0.355)
    static let greenStroke2 = Color(red: 0.022, green: 0.218, blue: 0.148).opacity(0.25)
}
