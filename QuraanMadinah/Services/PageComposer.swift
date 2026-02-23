import Foundation
import UIKit
import Combine

final class PageComposer {
    static let shared = PageComposer()

    // Standard Uthmani Basmala (injected for every new surah except At-Tawbah)
    static let basmalaText = "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ"

    private let cache = NSCache<NSString, NSArray>()

    private init() {
        cache.countLimit = 300 // page x fontScale/width variants
    }

    /// Clears the layout cache — call when font scale changes.
    func clearCache() { cache.removeAllObjects() }

    /// Compose a mushaf page into exactly 15 visible lines.
    /// Injects a Basmala line at the correct visual line (just before aya 1)
    /// for every new surah except Al-Fatiha (already in dataset) and At-Tawbah.
    func compose(page: Int, records: [AyaRecord], font: UIFont, maxWidth: CGFloat) -> [String] {
        // Cache key must include width to avoid stale line breaks on rotation/split-view.
        let key = "\(page)_\(Int(font.pointSize * 10))_\(Int(maxWidth.rounded()))" as NSString

        if let cached = cache.object(forKey: key) as? [String] {
            return cached
        }

        let sortedRecords = records.sorted { $0.id < $1.id }

        // Find ALL surah starts on this page (a page can contain multiple new surahs)
        let surahStartRecords = sortedRecords.filter { $0.ayaNo == 1 }

        // Inject an explicit Basmala for surahs 2-114 except At-Tawbah (9)
        // Surah 1 (Al-Fatiha) aya 1 IS the Basmala — dataset handles it naturally.
        let injectedBasmalaStarts = surahStartRecords.filter { r in
            r.suraNo != 1 && r.suraNo != 9
        }

        // For Al-Fatiha: detect basmala embedded in dataset and place it on its line.
        // (Keep this as an array for consistency in case of malformed/duplicated data.)
        let datasetBasmalaRecords: [AyaRecord] = surahStartRecords.filter { r in
            guard r.suraNo != 9 else { return false }
            guard r.ayaNo == 1   else { return false }
            let t = r.ayaText.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.hasPrefix("\u{0628}\u{0650}\u{0633}\u{0652}\u{0645}") || t.hasPrefix("\u{0628}\u{0633}\u{0645}")
        }

        var lines = Array(repeating: "", count: 15)

        // Place injected Basmala(s) on their real page line(s): one line before aya 1.
        for r in injectedBasmalaStarts {
            let basmalaIndex = max(0, min(14, r.lineStart - 2))
            if lines[basmalaIndex].isEmpty {
                lines[basmalaIndex] = PageComposer.basmalaText
            }
        }

        // Place dataset Basmala(s) (Al-Fatiha) on recorded line(s).
        for b in datasetBasmalaRecords {
            let idx = max(0, min(14, b.lineStart - 1))
            if lines[idx].isEmpty {
                lines[idx] = b.ayaText
            }
        }

        // Body records: exclude dataset-basmala records if already placed as their own lines.
        let datasetBasmalaIDs = Set(datasetBasmalaRecords.map { $0.id })
        let bodyRecords: [AyaRecord] = datasetBasmalaIDs.isEmpty
            ? sortedRecords
            : sortedRecords.filter { !datasetBasmalaIDs.contains($0.id) }

        for r in bodyRecords {
            let startIndex = max(0, min(14, r.lineStart - 1))
            let endIndex = max(startIndex, min(14, r.lineEnd - 1))
            let needed = endIndex - startIndex + 1

            let parts: [String] = (needed <= 1)
                ? [r.ayaText]
                : LineBreaker.split(text: r.ayaText, lines: needed, font: font, maxWidth: maxWidth)

            for (offset, part) in parts.enumerated() {
                let idx = startIndex + offset
                guard idx < lines.count else { continue }
                lines[idx] = lines[idx].isEmpty ? part : (lines[idx] + " " + part)
            }
        }

        cache.setObject(lines as NSArray, forKey: key)
        return lines
    }
}
