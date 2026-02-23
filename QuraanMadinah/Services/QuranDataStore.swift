import Foundation
import Combine

final class QuranDataStore: ObservableObject {
    static let shared = QuranDataStore()

    @Published private(set) var allAyat: [AyaRecord] = []
    @Published private(set) var pages: [Int: [AyaRecord]] = [:]
    @Published private(set) var surahs: [SurahInfo] = []

    private init() {
        load()
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "hafs_smart_v8", withExtension: "json") else {
            assertionFailure("Missing hafs_smart_v8.json in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let records = try decoder.decode([AyaRecord].self, from: data)
            self.allAyat = records

            var byPage: [Int: [AyaRecord]] = [:]
            for r in records {
                byPage[r.page, default: []].append(r)
            }
            // stable order per page
            for (p, list) in byPage {
                byPage[p] = list.sorted { a, b in
                    if a.suraNo != b.suraNo { return a.suraNo < b.suraNo }
                    return a.ayaNo < b.ayaNo
                }
            }
            self.pages = byPage

            // build surah list
            var firstBySurah: [Int: AyaRecord] = [:]
            for r in records {
                if firstBySurah[r.suraNo] == nil || r.page < firstBySurah[r.suraNo]!.page || (r.page == firstBySurah[r.suraNo]!.page && r.ayaNo < firstBySurah[r.suraNo]!.ayaNo) {
                    firstBySurah[r.suraNo] = r
                }
            }
            self.surahs = firstBySurah.values
                .map { SurahInfo(suraNo: $0.suraNo, nameAr: $0.suraNameAr, nameEn: $0.suraNameEn, firstPage: $0.page) }
                .sorted { $0.suraNo < $1.suraNo }

        } catch {
            assertionFailure("Failed to decode hafs_smart_v8.json: \(error)")
        }
    }

    func records(forPage page: Int) -> [AyaRecord] {
        pages[page] ?? []
    }

    func searchEmlaey(_ query: String) -> [AyaRecord] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 2 else { return [] }

        // simple contains; you can later normalize Arabic if needed
        return allAyat.filter { $0.ayaTextEmlaey.contains(q) }
            .prefix(2000) // safety
            .map { $0 }
    }
}


struct PageInfo {
    let title: String
    let subtitle: String
}

extension QuranDataStore {
    func pageInfo(page: Int) -> PageInfo {
        let records = records(forPage: page)
        // السورة في أعلى الصفحة = السورة ذات أصغر رقم سطر
        let topRecord = records.min(by: { $0.lineStart < $1.lineStart })
        let title = topRecord?.suraNameAr ?? "المصحف الشريف"
        let juzNo = topRecord?.jozz ?? 1
        let subtitle = "الجزء \(toArabic(juzNo))  •  صفحة \(toArabic(page))"
        return PageInfo(title: title, subtitle: subtitle)
    }

    private func toArabic(_ n: Int) -> String {
        let d = ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]
        return String(n).map { c -> String in
            if let v = c.wholeNumberValue, v < d.count { return d[v] }
            return String(c)
        }.joined()
    }
}

