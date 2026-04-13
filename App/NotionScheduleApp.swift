import SwiftUI
import WidgetKit

@main
struct NotionScheduleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var token: String = ""
    @State private var isSaved: Bool = false
    @State private var fetchMessage: String = ""
    @State private var isFetching: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Notion Connection")) {
                    SecureField("Secret Token (ntn_...)", text: $token)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button(action: saveToken) {
                        Text("Save Token")
                    }
                    .disabled(token.isEmpty)
                }

                if isSaved {
                    Section {
                        Text("Token saved securely in Keychain.")
                            .foregroundColor(.green)
                            .font(.footnote)
                    }
                    
                    Section(header: Text("Actions")) {
                        Button(action: fetchAndSyncWidget) {
                            if isFetching {
                                ProgressView()
                            } else {
                                Text("Fetch Today's Plan & Update Widget")
                            }
                        }
                        .disabled(isFetching)
                        
                        if !fetchMessage.isEmpty {
                            Text(fetchMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear(perform: loadToken)
        }
    }

    private func loadToken() {
        if let savedToken = KeychainHelper.standard.readToken(), !savedToken.isEmpty {
            self.token = savedToken
            self.isSaved = true
        }
    }

    private func saveToken() {
        KeychainHelper.standard.saveToken(token)
        isSaved = true
    }
    
    private func fetchAndSyncWidget() {
        isFetching = true
        fetchMessage = "Fetching..."
        Task {
            do {
                if let schedule = try await NotionAPIClient.shared.fetchDailySchedule(date: Date()) {
                    SharedStorage.shared.saveDailySchedule(schedule)
                    WidgetCenter.shared.reloadAllTimelines()
                    fetchMessage = "Success! Saved \(schedule.items.count) schedules. Widget updated."
                } else {
                    fetchMessage = "Done. No schedule found for today."
                    SharedStorage.shared.clearSchedule()
                    WidgetCenter.shared.reloadAllTimelines()
                }
            } catch {
                fetchMessage = "Error: \(error.localizedDescription)"
                print(error)
            }
            isFetching = false
        }
    }
}

