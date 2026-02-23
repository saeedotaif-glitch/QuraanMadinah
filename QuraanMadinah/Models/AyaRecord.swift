import Foundation

struct AyaRecord: Codable, Identifiable, Hashable {
    let id: Int
    let jozz: Int
    let suraNo: Int
    let suraNameEn: String
    let suraNameAr: String
    let page: Int
    let lineStart: Int
    let lineEnd: Int
    let ayaNo: Int
    let ayaText: String
    let ayaTextEmlaey: String

    enum CodingKeys: String, CodingKey {
        case id, jozz
        case suraNo = "sura_no"
        case suraNameEn = "sura_name_en"
        case suraNameAr = "sura_name_ar"
        case page
        case lineStart = "line_start"
        case lineEnd = "line_end"
        case ayaNo = "aya_no"
        case ayaText = "aya_text"
        case ayaTextEmlaey = "aya_text_emlaey"
    }
}
