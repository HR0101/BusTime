import Foundation
import Combine

// このクラスが、アプリの状態とロジックを管理します。
// ObservableObjectなので、SwiftUIのView（画面）はこのクラスのプロパティの変更を監視できます。
class BusTimetableViewModel: ObservableObject {
    
    // MARK: - UIの状態を管理するプロパティ
    
    // @Publishedを付けると、このプロパティの値が変更されたときに、自動的にUIが更新されます。
    @Published var selectedRoute: Route = .mansionToStation      // 選択中のルート
    @Published var searchType: SearchType = .departure          // 選択中の検索方法（出発 or 到着）
    @Published var departureTime: Date = Date()                 // 選択中の出発時刻
    @Published var arrivalTime: Date = Date()                   // 選択中の到着希望時刻
    @Published var searchResults: [Bus] = []                    // 検索結果のバスリスト
    @Published var searchCriteriaDescription: String = "検索条件: まだ検索されていません" // 検索条件の説明テキスト
    @Published var holidayMessage: String? = nil                // 土日・祝日の場合のエラーメッセージ
    
    @Published var countdownMessages: [String: String] = [:]    // カウントダウン表示用

    // MARK: - 内部でだけ使うプロパティ
    
    private var allTimetables: [Route: [Bus]] = [:] // 全ルートの時刻表データ
    private let publicHolidays = [                  // 祝日リスト
        "2025-01-01", "2025-01-13", "2025-02-11", "2025-02-23", "2025-03-20",
        "2025-04-29", "2025-05-03", "2025-05-04", "2025-05-05", "2025-07-21",
        "2025-08-11", "2025-09-15", "2025-09-23", "2025-10-13", "2025-11-03",
        "2025-11-23", "2025-12-23"
    ]
    private var timer: AnyCancellable?              // カウントダウン用のタイマー

    // MARK: - 選択肢を管理するための列挙型
    
    // ルートの種類を定義します。CaseIterableに準拠すると、全てのケースを簡単にリストアップできます。
    enum Route: String, CaseIterable {
        case mansionToStation = "コロンブスシティ → 海浜幕張駅"
        case stationToMansion = "海浜幕張駅 → コロンブスシティ"
    }
    
    // 検索方法の種類を定義します。
    enum SearchType: String {
        case departure = "出発時刻"
        case arrival = "到着希望時刻"
    }
    
    // MARK: - 初期化処理
    
    // このクラスのインスタンスが作成されたときに一度だけ呼ばれます。
    init() {
        setupTimetables() // 時刻表データを準備する
        checkHoliday()    // 休日かどうかをチェックする
        startTimer()      // カウントダウン用のタイマーを開始する
    }
    
    // 時刻表データをプログラム内に直接定義します。
    private func setupTimetables() {
        self.allTimetables[.mansionToStation] = [
            Bus(departure: "6:03", arrival: "6:11"), Bus(departure: "6:30", arrival: "6:38"),
            Bus(departure: "6:40", arrival: "6:48"), Bus(departure: "6:50", arrival: "6:58"),
            Bus(departure: "7:00", arrival: "7:08"), Bus(departure: "7:10", arrival: "7:18"),
            Bus(departure: "7:20", arrival: "7:28"), Bus(departure: "7:30", arrival: "7:38"),
            Bus(departure: "7:40", arrival: "7:48"), Bus(departure: "7:50", arrival: "7:58"),
            Bus(departure: "8:00", arrival: "8:08"), Bus(departure: "8:10", arrival: "8:18"),
            Bus(departure: "8:20", arrival: "8:28"), Bus(departure: "8:30", arrival: "8:38"),
            Bus(departure: "8:40", arrival: "8:48"), Bus(departure: "9:00", arrival: "9:08"),
            Bus(departure: "9:30", arrival: "9:38"), Bus(departure: "10:00", arrival: "10:08"),
            Bus(departure: "10:30", arrival: "10:38"), Bus(departure: "11:00", arrival: "11:08"),
            Bus(departure: "11:30", arrival: "11:38"), Bus(departure: "13:00", arrival: "13:08"),
            Bus(departure: "13:30", arrival: "13:38"), Bus(departure: "14:00", arrival: "14:08"),
            Bus(departure: "14:30", arrival: "14:38"), Bus(departure: "15:00", arrival: "15:08"),
            Bus(departure: "15:30", arrival: "15:38"), Bus(departure: "16:00", arrival: "16:08"),
            Bus(departure: "16:30", arrival: "16:38"), Bus(departure: "17:04", arrival: "17:12"),
            Bus(departure: "17:37", arrival: "17:46"), Bus(departure: "18:02", arrival: "18:11"),
            Bus(departure: "18:19", arrival: "18:28"), Bus(departure: "18:37", arrival: "18:46"),
            Bus(departure: "19:01", arrival: "19:10"), Bus(departure: "19:18", arrival: "19:27"),
            Bus(departure: "19:32", arrival: "19:41"), Bus(departure: "19:51", arrival: "20:00"),
            Bus(departure: "20:11", arrival: "20:20"), Bus(departure: "20:51", arrival: "21:00"),
            Bus(departure: "21:08", arrival: "21:17"), Bus(departure: "21:55", arrival: "22:04"),
            Bus(departure: "22:19", arrival: "22:28"), Bus(departure: "22:37", arrival: "22:46"),
            Bus(departure: "23:06", arrival: "23:15"), Bus(departure: "23:38", arrival: "23:47"),
            Bus(departure: "0:04", arrival: "0:13")
        ]
        
        self.allTimetables[.stationToMansion] = [
            Bus(departure: "6:11", arrival: "6:18"), Bus(departure: "6:38", arrival: "6:45"),
            Bus(departure: "6:48", arrival: "6:55"), Bus(departure: "6:58", arrival: "7:05"),
            Bus(departure: "7:08", arrival: "7:15"), Bus(departure: "7:18", arrival: "7:25"),
            Bus(departure: "7:28", arrival: "7:35"), Bus(departure: "7:38", arrival: "7:45"),
            Bus(departure: "7:48", arrival: "7:55"), Bus(departure: "7:58", arrival: "8:05"),
            Bus(departure: "8:08", arrival: "8:15"), Bus(departure: "8:18", arrival: "8:25"),
            Bus(departure: "8:28", arrival: "8:35"), Bus(departure: "8:48", arrival: "8:55"),
            Bus(departure: "9:38", arrival: "9:53"), Bus(departure: "10:08", arrival: "10:15"),
            Bus(departure: "10:38", arrival: "10:53"), Bus(departure: "11:08", arrival: "11:15"),
            Bus(departure: "11:38", arrival: "11:53"), Bus(departure: "13:08", arrival: "13:15"),
            Bus(departure: "13:38", arrival: "13:53"), Bus(departure: "14:08", arrival: "14:15"),
            Bus(departure: "14:38", arrival: "14:53"), Bus(departure: "15:08", arrival: "15:15"),
            Bus(departure: "15:38", arrival: "15:53"), Bus(departure: "16:08", arrival: "16:15"),
            Bus(departure: "16:38", arrival: "16:53"), Bus(departure: "17:12", arrival: "17:19"),
            Bus(departure: "17:46", arrival: "17:53"), Bus(departure: "18:11", arrival: "18:18"),
            Bus(departure: "18:28", arrival: "18:35"), Bus(departure: "18:46", arrival: "18:53"),
            Bus(departure: "19:10", arrival: "19:17"), Bus(departure: "19:27", arrival: "19:34"),
            Bus(departure: "19:41", arrival: "19:48"), Bus(departure: "20:00", arrival: "20:07"),
            Bus(departure: "20:20", arrival: "20:27"), Bus(departure: "20:43", arrival: "20:50"),
            Bus(departure: "21:00", arrival: "21:07"), Bus(departure: "21:17", arrival: "21:24"),
            Bus(departure: "21:39", arrival: "21:46"), Bus(departure: "22:04", arrival: "22:11"),
            Bus(departure: "22:28", arrival: "22:35"), Bus(departure: "22:46", arrival: "22:53"),
            Bus(departure: "23:15", arrival: "23:22"), Bus(departure: "23:47", arrival: "23:54"),
            Bus(departure: "0:13", arrival: "0:20")
        ]
    }
    
    // 1秒ごとにカウントダウンを更新するためのタイマーを開始します。
    private func startTimer() {
        // [weak self] は、メモリリークを防ぐためのおまじないです。
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            self?.updateCountdown()
        }
    }

    // MARK: - ロジック（処理）に関するメソッド群
    
    // 現在時刻をDate型で取得します。
    private func now() -> Date {
        return Date()
    }
    
    // "HH:mm"形式の文字列を、日付情報を持たない純粋な「時刻」のDateオブジェクトに変換します。
    private func timeStringToDate(_ timeString: String) -> Date? {
        let calendar = Calendar.current
        let components = timeString.split(separator: ":").map { Int($0) ?? 0 }
        guard components.count == 2 else { return nil }
        return calendar.date(from: DateComponents(hour: components[0], minute: components[1]))
    }
    
    // Dateオブジェクトから、その日の0時からの経過分数を計算します。(例: 1:30 -> 90)
    private func timeToMinutes(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    // 「現在時刻で検索」ボタンのためのメソッド
    func setSearchToCurrentTime() {
        // 検索タイプを「出発」に強制的に変更します。
        self.searchType = .departure
        
        // 出発時刻を現在の時刻に設定します。
        self.departureTime = now()
        
        // そのまま検索を実行します。
        performSearch()
    }

    // 検索を実行するメインのメソッドです。
    func performSearch() {
        checkHoliday() // まず休日かチェック
        // もし休日なら、運休メッセージを表示して処理を中断します。
        guard holidayMessage == nil else {
            searchResults = []
            searchCriteriaDescription = "検索条件: 本日は運休です。"
            return
        }
        
        // 選択されているルートの時刻表を取得します。
        guard let currentTimetable = allTimetables[selectedRoute] else { return }
        
        // 検索方法に応じて処理を分岐します。
        if searchType == .arrival {
            let results = findNextBusesByArrival(timetable: currentTimetable, arrivalTargetTime: arrivalTime)
            self.searchResults = results
        } else {
            let results = findNextBusesByDeparture(timetable: currentTimetable, departureRefTime: departureTime)
            self.searchResults = results
        }
        updateSearchCriteriaDescription() // 検索条件の表示を更新します。
    }

    // 「出発時刻」でバスを探すロジックです。
    private func findNextBusesByDeparture(timetable: [Bus], departureRefTime: Date) -> [Bus] {
        let departureRefMinutes = timeToMinutes(departureRefTime)
        let upcomingBuses = timetable.compactMap { bus -> (bus: Bus, sortKey: Int)? in
            guard let busDepartureDate = timeStringToDate(bus.departure) else { return nil }
            var busDepartureMinutes = timeToMinutes(busDepartureDate)
            
            // 日付をまたぐ深夜便の考慮 (基準が21時以降で、バスが4時より前の場合)
            if departureRefMinutes > 21 * 60 && busDepartureMinutes < 4 * 60 {
                busDepartureMinutes += 24 * 60 // 24時間分を加算して、大小関係を正しくする
            }
            // 指定された出発時刻以降のバスのみを候補とします。
            if busDepartureMinutes >= departureRefMinutes {
                return (bus, busDepartureMinutes)
            }
            return nil
        }
        // 候補のバスを、出発が早い順に並び替え、最初の2件を取得します。
        return upcomingBuses.sorted { $0.sortKey < $1.sortKey }.map { $0.bus }.prefix(2).map{$0}
    }

    // 「到着希望時刻」でバスを探すロジックです。現在時刻に依存しないシンプルなロジックに修正しました。
    private func findNextBusesByArrival(timetable: [Bus], arrivalTargetTime: Date) -> [Bus] {
        let arrivalTargetMinutes = timeToMinutes(arrivalTargetTime)

        let candidateBuses = timetable.compactMap { bus -> (bus: Bus, arrival: Int)? in
            guard let busArrivalDate = timeStringToDate(bus.arrival) else { return nil }

            let busArrivalMinutes = timeToMinutes(busArrivalDate)
            
            // 純粋に、バスの到着時刻が指定された到着希望時刻以前であるかだけをチェックします。
            if busArrivalMinutes <= arrivalTargetMinutes {
                return (bus, busArrivalMinutes)
            }
            return nil
        }

        // 候補のバスを、到着が遅い順（＝希望時刻に近い順）に並び替え、最初の2件を取得します。
        return candidateBuses.sorted { $0.arrival > $1.arrival }.map { $0.bus }.prefix(2).map{$0}
    }
    
    // UIに表示する検索条件の説明文を更新します。
    func updateSearchCriteriaDescription() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if searchType == .arrival {
            searchCriteriaDescription = "検索条件: 到着希望 \(formatter.string(from: arrivalTime))"
        } else {
            searchCriteriaDescription = "検索条件: 出発目安 \(formatter.string(from: departureTime))"
        }
    }
    
    // 今日が土日・祝日かどうかをチェックし、メッセージを設定します。
    private func checkHoliday() {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today) // 1が日曜, 7が土曜
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: today)
        if weekday == 1 || weekday == 7 {
            self.holidayMessage = "本日は土日のため運休です。"
        } else if publicHolidays.contains(todayString) {
            self.holidayMessage = "本日は祝日のため運休です。"
        } else {
            self.holidayMessage = nil
        }
    }
    
    // カウントダウン表示を更新します。
    private func updateCountdown() {
        // 検索結果がなければ何もしません。
        guard !searchResults.isEmpty else {
            countdownMessages = [:] // メッセージを空にする
            return
        }
        
        var newMessages: [String: String] = [:]
        
        for bus in searchResults {
            guard let busDate = timeStringToDate(bus.departure) else { continue }
            
            let now = Date()
            let calendar = Calendar.current
            // 今日の日付とバスの時刻を組み合わせた、完全なDateオブジェクトを作成します。
            var busComponents = calendar.dateComponents([.hour, .minute], from: busDate)
            busComponents.year = calendar.component(.year, from: now)
            busComponents.month = calendar.component(.month, from: now)
            busComponents.day = calendar.component(.day, from: now)
            guard var targetDate = calendar.date(from: busComponents) else { continue }
            
            // もし計算した出発時刻が現在より前の場合、それは明日の便とみなして日付を1日進めます。
            if targetDate < now {
                targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate)!
            }
            
            // 現在時刻とバスの出発時刻の差を計算します。(時間と分を取得)
            let diff = calendar.dateComponents([.hour, .minute], from: now, to: targetDate)
            
            if let hours = diff.hour, let minutes = diff.minute {
                if hours < 0 || (hours == 0 && minutes < 0) {
                    newMessages[bus.id] = "出発済み"
                } else if hours > 0 {
                    newMessages[bus.id] = String(format: "あと%d時間%d分", hours, minutes)
                } else if minutes > 0 {
                    newMessages[bus.id] = String(format: "あと%d分", minutes)
                } else {
                    newMessages[bus.id] = "まもなく出発"
                }
            }
        }
        
        // 計算が終わった後、UIに反映させる
        self.countdownMessages = newMessages
    }
    
    // 現在選択されているルートの全時刻表を返します。
    var currentFullTimetable: [Bus] {
        return allTimetables[selectedRoute] ?? []
    }
}
