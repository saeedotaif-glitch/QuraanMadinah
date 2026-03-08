import SwiftUI
import UserNotifications
import UIKit

struct WarrantyItem: Identifiable, Codable, Hashable {
    let id: UUID
    var productName: String
    var merchantName: String
    var purchaseDate: Date
    var warrantyMonths: Int
    var purchaseAmount: Double?
    var currencyCode: String
    var notes: String
    var receiptRawText: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        productName: String,
        merchantName: String,
        purchaseDate: Date,
        warrantyMonths: Int,
        purchaseAmount: Double?,
        currencyCode: String = Locale.current.currencyCode ?? "SAR",
        notes: String = "",
        receiptRawText: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.productName = productName
        self.merchantName = merchantName
        self.purchaseDate = purchaseDate
        self.warrantyMonths = warrantyMonths
        self.purchaseAmount = purchaseAmount
        self.currencyCode = currencyCode
        self.notes = notes
        self.receiptRawText = receiptRawText
        self.createdAt = createdAt
    }

    var expiryDate: Date {
        Calendar.current.date(byAdding: .month, value: warrantyMonths, to: purchaseDate) ?? purchaseDate
    }

    var daysRemaining: Int {
        let today = Calendar.current.startOfDay(for: .now)
        let expiry = Calendar.current.startOfDay(for: expiryDate)
        return Calendar.current.dateComponents([.day], from: today, to: expiry).day ?? 0
    }

    var status: WarrantyStatus {
        if daysRemaining < 0 { return .expired }
        if daysRemaining <= 30 { return .expiring }
        return .active
    }

    var reminderOffsets: [Int] { [60, 30, 7] }

    func reminderDate(daysBefore: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysBefore, to: expiryDate) ?? expiryDate
    }

    func claimMessage() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ar")
        dateFormatter.dateStyle = .medium

        let amountText: String = {
            guard let purchaseAmount else { return "غير مذكور" }
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale(identifier: "ar")
            formatter.currencyCode = currencyCode
            return formatter.string(from: NSNumber(value: purchaseAmount)) ?? "\(purchaseAmount)"
        }()

        return """
        السلام عليكم،

        لدي طلب فحص/مطالبة ضمان للمنتج التالي:
        • المنتج: \(productName)
        • المتجر: \(merchantName)
        • تاريخ الشراء: \(dateFormatter.string(from: purchaseDate))
        • نهاية الضمان: \(dateFormatter.string(from: expiryDate))
        • قيمة الشراء: \(amountText)

        أرجو توضيح الخطوات اللازمة لإتمام خدمة الضمان.
        شاكر تعاونكم.
        """
    }
}

enum WarrantyStatus: String, CaseIterable {
    case active
    case expiring
    case expired

    var title: String {
        switch self {
        case .active: return "نشط"
        case .expiring: return "قرب الانتهاء"
        case .expired: return "منتهي"
        }
    }

    var color: Color {
        switch self {
        case .active: return .green
        case .expiring: return .orange
        case .expired: return .red
        }
    }
}

final class WarrantyReminderScheduler {
    static let shared = WarrantyReminderScheduler()
    private let center = UNUserNotificationCenter.current()
    private let scheduledIDsKey = "warranty_scheduled_notification_ids_v1"

    func requestAuthorizationIfNeeded() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func syncReminders(for items: [WarrantyItem]) {
        let oldIDs = UserDefaults.standard.stringArray(forKey: scheduledIDsKey) ?? []
        center.removePendingNotificationRequests(withIdentifiers: oldIDs)

        var nextIDs: [String] = []
        for item in items {
            for offset in item.reminderOffsets {
                let date = item.reminderDate(daysBefore: offset)
                if date <= .now { continue }

                let id = notificationID(for: item.id, offset: offset)
                let content = UNMutableNotificationContent()
                content.title = "تذكير ضمان: \(item.productName)"
                content.body = "باقي \(offset) يوم على انتهاء ضمان \(item.productName)."
                content.sound = .default

                let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                center.add(request)
                nextIDs.append(id)
            }
        }

        UserDefaults.standard.set(nextIDs, forKey: scheduledIDsKey)
    }

    private func notificationID(for itemID: UUID, offset: Int) -> String {
        "warranty-\(itemID.uuidString)-\(offset)"
    }
}

final class WarrantyStore: ObservableObject {
    @Published private(set) var items: [WarrantyItem] = []

    private static let storageKey = "warranty_items_storage_v1"
    private let reminderScheduler: WarrantyReminderScheduler

    init(reminderScheduler: WarrantyReminderScheduler = .shared) {
        self.reminderScheduler = reminderScheduler
        load()
        reminderScheduler.syncReminders(for: items)
    }

    var sortedItems: [WarrantyItem] {
        items.sorted {
            if $0.status == $1.status {
                return $0.daysRemaining < $1.daysRemaining
            }
            return statusRank($0.status) < statusRank($1.status)
        }
    }

    var statusSummary: [WarrantyStatus: Int] {
        var summary: [WarrantyStatus: Int] = [.active: 0, .expiring: 0, .expired: 0]
        for item in items {
            summary[item.status, default: 0] += 1
        }
        return summary
    }

    var potentialSavings: Double {
        items.compactMap(\.purchaseAmount).reduce(0, +)
    }

    func add(_ item: WarrantyItem) {
        items.append(item)
        persist()
    }

    func delete(id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    private func statusRank(_ status: WarrantyStatus) -> Int {
        switch status {
        case .expiring: return 0
        case .active: return 1
        case .expired: return 2
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
            reminderScheduler.syncReminders(for: items)
        } catch {
            assertionFailure("Failed to persist warranty items: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else { return }
        do {
            items = try JSONDecoder().decode([WarrantyItem].self, from: data)
        } catch {
            items = []
        }
    }
}

struct AppShellView: View {
    @StateObject private var store = WarrantyStore()
    @State private var showingAddSheet = false

    var body: some View {
        TabView {
            NavigationStack {
                WarrantyHomeView(store: store, showingAddSheet: $showingAddSheet)
            }
            .tabItem { Label("الضمانات", systemImage: "doc.text.image") }

            NavigationStack {
                WarrantyInsightsView(store: store)
            }
            .tabItem { Label("الإحصائيات", systemImage: "chart.bar") }
        }
        .onAppear {
            WarrantyReminderScheduler.shared.requestAuthorizationIfNeeded()
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                AddWarrantyView(store: store)
            }
        }
    }
}

struct WarrantyHomeView: View {
    @ObservedObject var store: WarrantyStore
    @Binding var showingAddSheet: Bool
    @State private var query = ""

    var filteredItems: [WarrantyItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return store.sortedItems }
        return store.sortedItems.filter {
            $0.productName.localizedCaseInsensitiveContains(q) ||
            $0.merchantName.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 10) {
                    StatCard(title: "نشط", value: store.statusSummary[.active, default: 0], color: .green)
                    StatCard(title: "قرب الانتهاء", value: store.statusSummary[.expiring, default: 0], color: .orange)
                    StatCard(title: "منتهي", value: store.statusSummary[.expired, default: 0], color: .red)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }

            Section("كل الضمانات") {
                if filteredItems.isEmpty {
                    ContentUnavailableView(
                        "لا توجد عناصر",
                        systemImage: "tray",
                        description: Text("أضف أول فاتورة/ضمان للبدء.")
                    )
                } else {
                    ForEach(filteredItems) { item in
                        NavigationLink(value: item) {
                            WarrantyRowView(item: item)
                        }
                    }
                }
            }
        }
        .navigationTitle("ضمان الفاتورة")
        .navigationDestination(for: WarrantyItem.self) { item in
            WarrantyDetailView(store: store, itemID: item.id)
        }
        .searchable(text: $query, prompt: "ابحث بالمنتج أو المتجر")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("إضافة", systemImage: "plus.circle.fill")
                }
            }
        }
    }
}

struct WarrantyRowView: View {
    let item: WarrantyItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.productName).font(.headline)
                Spacer()
                Text(item.status.title)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.status.color.opacity(0.15))
                    .foregroundStyle(item.status.color)
                    .clipShape(Capsule())
            }
            Text(item.merchantName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Label("ينتهي \(item.expiryDate.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                Spacer()
                Text(item.daysRemaining >= 0 ? "باقي \(item.daysRemaining) يوم" : "انتهى منذ \(-item.daysRemaining) يوم")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(item.status.color)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

struct AddWarrantyView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: WarrantyStore

    @State private var productName = ""
    @State private var merchantName = ""
    @State private var purchaseDate = Date()
    @State private var warrantyMonths = 24
    @State private var amount = ""
    @State private var currencyCode = Locale.current.currencyCode ?? "SAR"
    @State private var notes = ""
    @State private var receiptText = ""

    private var canSave: Bool {
        !productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !merchantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        warrantyMonths > 0
    }

    var body: some View {
        Form {
            Section("بيانات المنتج") {
                TextField("اسم المنتج", text: $productName)
                TextField("اسم المتجر", text: $merchantName)
                DatePicker("تاريخ الشراء", selection: $purchaseDate, displayedComponents: .date)
                Stepper("مدة الضمان: \(warrantyMonths) شهر", value: $warrantyMonths, in: 1...60)
            }

            Section("بيانات الفاتورة") {
                TextField("السعر (اختياري)", text: $amount)
                    .keyboardType(.decimalPad)
                TextField("العملة (مثل SAR أو USD)", text: $currencyCode)
                    .textInputAutocapitalization(.characters)
                TextField("ملاحظات", text: $notes, axis: .vertical)
            }

            Section("نص الفاتورة (اختياري)") {
                TextEditor(text: $receiptText)
                    .frame(minHeight: 90)
                Button("استخراج تاريخ/سعر من النص") {
                    applyReceiptHints()
                }
                .disabled(receiptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("إضافة ضمان")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("إلغاء") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("حفظ") {
                    let amountValue = Double(amount.replacingOccurrences(of: ",", with: "."))
                    let item = WarrantyItem(
                        productName: productName.trimmingCharacters(in: .whitespacesAndNewlines),
                        merchantName: merchantName.trimmingCharacters(in: .whitespacesAndNewlines),
                        purchaseDate: purchaseDate,
                        warrantyMonths: warrantyMonths,
                        purchaseAmount: amountValue,
                        currencyCode: currencyCode.uppercased(),
                        notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                        receiptRawText: receiptText
                    )
                    store.add(item)
                    dismiss()
                }
                .disabled(!canSave)
            }
        }
    }

    private func applyReceiptHints() {
        if let inferredDate = ReceiptParser.firstDate(in: receiptText) {
            purchaseDate = inferredDate
        }
        if amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let inferredAmount = ReceiptParser.firstAmount(in: receiptText) {
            amount = inferredAmount
        }
    }
}

struct WarrantyDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: WarrantyStore
    let itemID: UUID
    @State private var showingShare = false

    private var item: WarrantyItem? { store.items.first { $0.id == itemID } }

    var body: some View {
        Group {
            if let item {
                List {
                    Section("الحالة") {
                        HStack {
                            Text("وضع الضمان")
                            Spacer()
                            Text(item.status.title)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(item.status.color.opacity(0.15))
                                .foregroundStyle(item.status.color)
                                .clipShape(Capsule())
                        }
                        Label("ينتهي \(item.expiryDate.formatted(date: .complete, time: .omitted))", systemImage: "calendar")
                        Text(item.daysRemaining >= 0 ? "باقي \(item.daysRemaining) يوم" : "انتهى منذ \(-item.daysRemaining) يوم")
                    }

                    Section("تفاصيل") {
                        LabeledContent("المنتج", value: item.productName)
                        LabeledContent("المتجر", value: item.merchantName)
                        LabeledContent("مدة الضمان", value: "\(item.warrantyMonths) شهر")
                        if let price = item.purchaseAmount {
                            LabeledContent("السعر", value: formattedCurrency(price, code: item.currencyCode))
                        }
                        if !item.notes.isEmpty {
                            Text(item.notes)
                        }
                    }

                    Section("نص مطالبة الضمان") {
                        Text(item.claimMessage())
                            .textSelection(.enabled)
                        Button {
                            UIPasteboard.general.string = item.claimMessage()
                        } label: {
                            Label("نسخ النص", systemImage: "doc.on.doc")
                        }
                        Button {
                            showingShare = true
                        } label: {
                            Label("مشاركة", systemImage: "square.and.arrow.up")
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            store.delete(id: item.id)
                            dismiss()
                        } label: {
                            Label("حذف العنصر", systemImage: "trash")
                        }
                    }
                }
                .navigationTitle("تفاصيل الضمان")
                .sheet(isPresented: $showingShare) {
                    ShareSheet(items: [item.claimMessage()])
                }
            } else {
                ContentUnavailableView("العنصر غير موجود", systemImage: "exclamationmark.triangle")
            }
        }
    }

    private func formattedCurrency(_ value: Double, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ar")
        formatter.currencyCode = code
        return formatter.string(from: NSNumber(value: value)) ?? "\(value) \(code)"
    }
}

struct WarrantyInsightsView: View {
    @ObservedObject var store: WarrantyStore

    var body: some View {
        List {
            Section("ملخص سريع") {
                LabeledContent("إجمالي الضمانات", value: "\(store.items.count)")
                LabeledContent("إجمالي قيمة المشتريات", value: formattedCurrency(store.potentialSavings))
                LabeledContent("قرب الانتهاء خلال 30 يوم", value: "\(store.statusSummary[.expiring, default: 0])")
            }

            Section("فرص الاستفادة") {
                Text("قبل انتهاء الضمان، جهّز مطالبة واحدة على الأقل لكل منتج به عطل أو ضعف أداء.")
                Text("التطبيق يولّد رسالة مطالبة جاهزة للمشاركة عبر البريد أو واتساب.")
            }
        }
        .navigationTitle("الإحصائيات")
    }

    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ar")
        formatter.currencyCode = Locale.current.currencyCode ?? "SAR"
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

struct StatCard: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

enum ReceiptParser {
    static func firstDate(in text: String) -> Date? {
        let datePatterns = [
            #"\b\d{1,2}/\d{1,2}/\d{4}\b"#,
            #"\b\d{1,2}-\d{1,2}-\d{4}\b"#,
            #"\b\d{4}-\d{1,2}-\d{1,2}\b"#
        ]

        for pattern in datePatterns {
            guard let match = firstMatch(in: text, pattern: pattern) else { continue }
            let formatters = ["d/M/yyyy", "d-M-yyyy", "yyyy-M-d", "dd/MM/yyyy", "dd-MM-yyyy", "yyyy-MM-dd"]
            for format in formatters {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = format
                if let date = formatter.date(from: match) {
                    return date
                }
            }
        }
        return nil
    }

    static func firstAmount(in text: String) -> String? {
        let pattern = #"\b\d+([.,]\d{1,2})?\b"#
        guard let match = firstMatch(in: text, pattern: pattern) else { return nil }
        return match.replacingOccurrences(of: ",", with: ".")
    }

    private static func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let swiftRange = Range(match.range, in: text) else { return nil }
        return String(text[swiftRange])
    }
}

extension Notification.Name {
    static let jumpToPage = Notification.Name("jump_to_page_v1")
}
