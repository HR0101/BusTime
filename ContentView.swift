import SwiftUI

struct ContentView: View {
    
    // @StateObject を付けることで、このView専用のViewModelのインスタンスを作成・管理します。
    @StateObject private var viewModel = BusTimetableViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    Section(header: Text("ステップ1: ルートを選択").font(.headline)) {
                        Picker("ルート選択", selection: $viewModel.selectedRoute) {
                            ForEach(BusTimetableViewModel.Route.allCases, id: \.self) { route in
                                Text(route.rawValue).tag(route)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Section(header: Text("ステップ2: 検索方法を選択").font(.headline)) {
                        Picker("検索方法", selection: $viewModel.searchType) {
                            Text("出発時刻").tag(BusTimetableViewModel.SearchType.departure)
                            Text("到着希望時刻").tag(BusTimetableViewModel.SearchType.arrival)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Section(header: Text("ステップ3: 時刻を設定").font(.headline)) {
                        if viewModel.searchType == .departure {
                            DatePicker("出発時刻", selection: $viewModel.departureTime, displayedComponents: .hourAndMinute)
                        } else {
                            DatePicker("到着希望時刻", selection: $viewModel.arrivalTime, displayedComponents: .hourAndMinute)
                        }
                    }
                    .datePickerStyle(.graphical)
                    
                    VStack(spacing: 10) {
                        if viewModel.searchType == .departure {
                            Button(action: { viewModel.setSearchToCurrentTime() }) {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                    Text("現在時刻で検索")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                // ★★★ ダークモード対応 → 固定色に変更 ★★★
                                .background(Color(white: 0.9)) // 明るいグレー
                                .foregroundColor(Color.black) // 文字は黒
                                .cornerRadius(10)
                            }
                        }
                        
                        Button(action: { viewModel.performSearch() }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("選択した条件で検索")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            // ★★★ ダークモード対応 → 固定色に変更 ★★★
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    
                    Section(header: Text("検索結果").font(.title2).bold()) {
                        if let message = viewModel.holidayMessage {
                            Text(message)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.15))
                                .cornerRadius(8)
                        } else {
                            Text(viewModel.searchCriteriaDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if viewModel.searchResults.isEmpty {
                                Text("条件に合うバスは見つかりませんでした。")
                                    .padding(.top, 5)
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(viewModel.searchResults) { bus in
                                    HStack {
                                        Text("推奨バス:").fontWeight(.bold)
                                        Text("\(bus.departure) → \(bus.arrival)")
                                        Spacer()
                                        
                                        Text(viewModel.countdownMessages[bus.id] ?? "")
                                            .font(.caption.bold())
                                            .foregroundColor(.red)
                                    }
                                    .padding()
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("時刻一覧 (全便)").font(.title2).bold()) {
                        ForEach(viewModel.currentFullTimetable) { bus in
                            HStack {
                                Text(bus.departure)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(bus.arrival)
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(viewModel.searchResults.contains(where: { $0.id == bus.id }) ? Color.green.opacity(0.2) : Color.clear)
                        }
                    }
                    
                }
                .padding()
            }
            .navigationTitle("バス時刻検索 ")
            .onAppear {
                viewModel.performSearch()
            }
            // ★★★ ダークモード対応 → 全体をライトモードで固定 ★★★
            .preferredColorScheme(.light)
        }
    }
}

// Xcodeプレビュー用のコードです。アプリの動作には影響しません。
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
