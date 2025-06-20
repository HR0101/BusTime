import Foundation

// 1つのバスの便を表す構造体です。
// SwiftUIのリストで各項目をユニークに識別するためにIdentifiableプロトコルに準拠させます。
struct Bus: Identifiable {
    var departure: String // 出発時刻
    var arrival: String   // 到着時刻
    
    // Identifiableプロトコルに必須のプロパティ。
    // ここでは出発時刻を各バスのユニークなIDとして使用します。
    var id: String { departure }
}
