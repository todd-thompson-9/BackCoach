import Foundation
import SwiftUI

final class LogStore: ObservableObject {
    @Published private(set) var logs: [String: DayLog] = [:] {
        didSet { save() }
    }

    private let storageKey = "BackCoach.logs.v1"

    init() { load() }

    static func key(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func log(for date: Date) -> DayLog {
        let key = Self.key(for: date)
        return logs[key] ?? DayLog(dateKey: key)
    }

    func update(_ log: DayLog) {
        logs[log.dateKey] = log
    }

    func toggleExercise(_ exerciseID: String, for date: Date) {
        var log = log(for: date)
        if log.completedExerciseIDs.contains(exerciseID) {
            log.completedExerciseIDs.remove(exerciseID)
        } else {
            log.completedExerciseIDs.insert(exerciseID)
        }
        update(log)
    }

    func setPain(_ keyPath: WritableKeyPath<DayLog, Int>, value: Int, for date: Date) {
        var log = log(for: date)
        log[keyPath: keyPath] = min(10, max(0, value))
        update(log)
    }

    func setOura(_ value: Int, for date: Date) {
        var log = log(for: date)
        log.ouraScore = min(100, max(0, value))
        update(log)
    }

    func setWalk(_ completed: Bool, for date: Date) {
        var log = log(for: date)
        log.walkCompleted = completed
        update(log)
    }

    func completion(for date: Date) -> (done: Int, total: Int, percent: Int) {
        let list = ExercisePlan.exercises(for: date)
        let log = log(for: date)
        let done = list.filter { log.completedExerciseIDs.contains($0.id) }.count
        let percent = list.isEmpty ? 0 : Int(round(Double(done) / Double(list.count) * 100))
        return (done, list.count, percent)
    }

    func sortedLogs() -> [DayLog] {
        logs.values.sorted { $0.dateKey > $1.dateKey }
    }

    func csvData() -> Data {
        var rows = ["Date,Neck,Mid Back,Low Back,Sciatica,Oura Sleep,Walk Completed,Exercises Completed,Total Exercises,Completion Percent"]
        for log in sortedLogs().reversed() {
            let date = dateFromKey(log.dateKey) ?? Date()
            let c = completion(for: date)
            rows.append("\(log.dateKey),\(log.neckPain),\(log.midBackPain),\(log.lowBackPain),\(log.sciaticaPain),\(log.ouraScore),\(log.walkCompleted ? \"Yes\" : \"No\"),\(c.done),\(c.total),\(c.percent)")
        }
        return rows.joined(separator: "\n").data(using: .utf8) ?? Data()
    }

    func exportURL() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("BackCoach-Export.csv")
        try csvData().write(to: url, options: .atomic)
        return url
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: DayLog].self, from: data) else { return }
        logs = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(logs) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func dateFromKey(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }
}
