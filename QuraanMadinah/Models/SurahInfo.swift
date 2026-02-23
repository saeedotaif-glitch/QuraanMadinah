import Foundation

struct SurahInfo: Identifiable, Hashable {
    var id: Int { suraNo }
    let suraNo: Int
    let nameAr: String
    let nameEn: String
    let firstPage: Int
}
