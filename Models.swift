import Foundation

struct Exercise: Identifiable, Codable, Hashable {
    enum Frequency: String, Codable { case daily, strength }
    let id: String
    let name: String
    let dose: String
    let frequency: Frequency
}

struct DayLog: Codable, Identifiable {
    var id: String { dateKey }
    var dateKey: String
    var completedExerciseIDs: Set<String> = []
    var neckPain: Int = 0
    var midBackPain: Int = 0
    var lowBackPain: Int = 0
    var sciaticaPain: Int = 0
    var ouraScore: Int = 0
    var walkCompleted: Bool = false
}

enum ExercisePlan {
    static let daily: [Exercise] = [
        Exercise(id: "chin_tucks", name: "Chin Tucks", dose: "10 reps · hold 3 seconds", frequency: .daily),
        Exercise(id: "neck_rotations", name: "Neck Rotations", dose: "10 each side", frequency: .daily),
        Exercise(id: "scapula_squeezes", name: "Scapula Squeezes", dose: "3 sets · 15 reps · hold 5 seconds", frequency: .daily),
        Exercise(id: "bird_dogs", name: "Bird Dogs", dose: "2 sets · 8 per side · hold 8–10 seconds", frequency: .daily),
        Exercise(id: "open_books", name: "Open Books", dose: "2 sets · 10 per side · hold 5 seconds", frequency: .daily),
        Exercise(id: "piriformis", name: "Piriformis Stretch", dose: "10 each side", frequency: .daily),
        Exercise(id: "hamstring", name: "Hamstring Stretch", dose: "2 sets · 30 seconds each side", frequency: .daily),
        Exercise(id: "thoracic_extensions", name: "Thoracic Extensions", dose: "2 sets · 30 seconds", frequency: .daily)
    ]

    static let strength: [Exercise] = [
        Exercise(id: "band_rows", name: "Resistance Band Rows", dose: "3 sets · 15 reps · slow return", frequency: .strength),
        Exercise(id: "pull_aparts", name: "Band Pull-Aparts", dose: "3 sets · 15 reps", frequency: .strength),
        Exercise(id: "w_pulls", name: "Band “W” Pulls", dose: "2 sets · 15 reps", frequency: .strength),
        Exercise(id: "ytw", name: "Prone “YTW” Raises", dose: "3 sets · 10 reps", frequency: .strength),
        Exercise(id: "pallof", name: "Pallof Press", dose: "2 sets · 10 per side · hold 5 seconds", frequency: .strength),
        Exercise(id: "back_extensions", name: "Back Extensions", dose: "15 reps · small movement only", frequency: .strength)
    ]

    static func isStrengthDay(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 2 || weekday == 4 || weekday == 6 // Mon, Wed, Fri
    }

    static func exercises(for date: Date) -> [Exercise] {
        daily + (isStrengthDay(date) ? strength : [])
    }
}
