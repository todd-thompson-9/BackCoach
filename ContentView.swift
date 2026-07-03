import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var store = LogStore()
    @State private var selectedTab = 0
    @State private var selectedDate = Date()
    @State private var exportURL: URL?
    @State private var showingShare = false

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(store: store, date: selectedDate)
                .tabItem { Label("Today", systemImage: "checkmark.circle") }
                .tag(0)

            PainSleepView(store: store, date: selectedDate)
                .tabItem { Label("Log", systemImage: "heart.text.square") }
                .tag(1)

            HistoryView(store: store, exportAction: exportCSV)
                .tabItem { Label("History", systemImage: "calendar") }
                .tag(2)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(3)
        }
        .tint(.blue)
        .sheet(isPresented: $showingShare) {
            if let exportURL { ShareSheet(items: [exportURL]) }
        }
    }

    private func exportCSV() {
        do {
            exportURL = try store.exportURL()
            showingShare = true
        } catch {
            print("Export failed: \(error)")
        }
    }
}

struct TodayView: View {
    @ObservedObject var store: LogStore
    let date: Date

    var exercises: [Exercise] { ExercisePlan.exercises(for: date) }
    var daily: [Exercise] { ExercisePlan.daily }
    var strength: [Exercise] { ExercisePlan.isStrengthDay(date) ? ExercisePlan.strength : [] }
    var routineTitle: String {
        let f = DateFormatter(); f.dateFormat = "EEEE"
        return "\(f.string(from: date)) Routine"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ProgressCard(store: store, date: date, title: routineTitle)
                    ExerciseSection(title: "Daily", exercises: daily, store: store, date: date)
                    if !strength.isEmpty {
                        ExerciseSection(title: "3-Day Strength", exercises: strength, store: store, date: date)
                    }
                    WalkingCard(store: store, date: date)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Back Coach")
        }
    }
}

struct ProgressCard: View {
    @ObservedObject var store: LogStore
    let date: Date
    let title: String

    var body: some View {
        let c = store.completion(for: date)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.title2.bold())
                    Text(ExercisePlan.isStrengthDay(date) ? "Daily exercises + strength routine." : "Daily exercises only.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(c.done) of \(c.total)")
                    .font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.blue.opacity(0.12), in: Capsule())
                    .foregroundStyle(.blue)
            }
            ProgressView(value: Double(c.done), total: Double(max(c.total, 1)))
            HStack { Text("Completion").foregroundStyle(.secondary); Spacer(); Text("\(c.percent)%").bold().foregroundStyle(.green) }
                .font(.subheadline)
        }
        .cardStyle()
    }
}

struct ExerciseSection: View {
    let title: String
    let exercises: [Exercise]
    @ObservedObject var store: LogStore
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.title3.bold()).padding(.bottom, 8)
            ForEach(exercises) { exercise in
                ExerciseRow(exercise: exercise, done: store.log(for: date).completedExerciseIDs.contains(exercise.id)) {
                    store.toggleExercise(exercise.id, for: date)
                }
                Divider()
            }
        }
        .cardStyle()
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    let done: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).stroke(done ? Color.green : Color.gray.opacity(0.45), lineWidth: 2)
                        .frame(width: 32, height: 32)
                        .background(done ? Color.green : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                    if done { Image(systemName: "checkmark").font(.headline.bold()).foregroundStyle(.white) }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name).font(.body.bold()).foregroundStyle(.primary)
                    Text(exercise.dose).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct WalkingCard: View {
    @ObservedObject var store: LogStore
    let date: Date
    var body: some View {
        let log = store.log(for: date)
        VStack(alignment: .leading, spacing: 12) {
            Text("Walking").font(.title3.bold())
            HStack(spacing: 10) {
                InfoBox(label: "Goal", value: "30–45", detail: "minutes")
                InfoBox(label: "Substitute", value: "3,000", detail: "purposeful steps")
            }
            Toggle("Completed walk or step substitute", isOn: Binding(
                get: { log.walkCompleted },
                set: { store.setWalk($0, for: date) }
            ))
            .font(.subheadline.bold())
        }.cardStyle()
    }
}

struct PainSleepView: View {
    @ObservedObject var store: LogStore
    let date: Date
    var body: some View {
        let log = store.log(for: date)
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Morning Pain").font(.title3.bold())
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            PainStepper(title: "Neck", value: log.neckPain) { store.setPain(\.neckPain, value: $0, for: date) }
                            PainStepper(title: "Mid Back", value: log.midBackPain) { store.setPain(\.midBackPain, value: $0, for: date) }
                            PainStepper(title: "Low Back", value: log.lowBackPain) { store.setPain(\.lowBackPain, value: $0, for: date) }
                            PainStepper(title: "Sciatica", value: log.sciaticaPain) { store.setPain(\.sciaticaPain, value: $0, for: date) }
                        }
                        Text("No extra tracking fields. This mirrors the tracker and keeps daily entry quick.")
                            .font(.caption).foregroundStyle(.orange).padding().background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                    }.cardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sleep / Walking").font(.title3.bold())
                        HStack(spacing: 10) {
                            NumberStepperBox(label: "Oura Score", value: log.ouraScore, range: 0...100) { store.setOura($0, for: date) }
                            InfoBox(label: "Walk", value: log.walkCompleted ? "✓" : "—", detail: "or step substitute")
                        }
                    }.cardStyle()
                }.padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Pain / Sleep")
        }
    }
}

struct PainStepper: View {
    let title: String
    let value: Int
    let set: (Int) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased()).font(.caption.bold()).foregroundStyle(.secondary)
            Text("\(value)").font(.largeTitle.bold())
            HStack {
                Button("−") { set(value - 1) }.buttonStyle(.bordered)
                Button("+") { set(value + 1) }.buttonStyle(.bordered)
            }
        }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct NumberStepperBox: View {
    let label: String
    let value: Int
    let range: ClosedRange<Int>
    let set: (Int) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased()).font(.caption.bold()).foregroundStyle(.secondary)
            Text("\(value)").font(.largeTitle.bold())
            Stepper("", value: Binding(get: { value }, set: { set(min(range.upperBound, max(range.lowerBound, $0))) }), in: range).labelsHidden()
        }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct HistoryView: View {
    @ObservedObject var store: LogStore
    let exportAction: () -> Void
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Export CSV", action: exportAction)
                } footer: {
                    Text("Export creates a CSV you can upload to ChatGPT for review.")
                }
                Section("History") {
                    ForEach(store.sortedLogs()) { log in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(log.dateKey).font(.headline)
                                Text("Neck \(log.neckPain) · Mid \(log.midBackPain) · Low \(log.lowBackPain) · Sciatica \(log.sciaticaPain)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            let c = store.completion(for: dateFromKey(log.dateKey) ?? Date())
                            Text("\(c.percent)%").bold()
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }
    private func dateFromKey(_ key: String) -> Date? {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"; return f.date(from: key)
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Storage") {
                    Text("Your data is saved locally on this iPhone using app storage.")
                    Text("Use Export CSV from History for backup or to send your progress for review.")
                }
                Section("Schedule") {
                    Text("Daily exercises appear every day.")
                    Text("Strength exercises appear Monday, Wednesday, and Friday.")
                }
            }.navigationTitle("Settings")
        }
    }
}

struct InfoBox: View {
    let label: String
    let value: String
    let detail: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased()).font(.caption.bold()).foregroundStyle(.secondary)
            Text(value).font(.largeTitle.bold()).minimumScaleFactor(0.7).lineLimit(1)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension View {
    func cardStyle() -> some View {
        self.padding().background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20)).shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}
