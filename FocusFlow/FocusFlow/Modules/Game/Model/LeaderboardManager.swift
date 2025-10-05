import Foundation
import Observation

@Observable
final class LeaderboardManager {
    var leaderboard: [(name: String, score: Int)] = []
    let maxEntries = 10
    let key = "2048Leaderboard"
    
    init() {
        load()
    }
    
    func save() {
        let data = leaderboard.map { ["name": $0.name, "score": $0.score] }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    func load() {
        guard let data = UserDefaults.standard.array(forKey: key) as? [[String: Any]] else { return }
        leaderboard = data.compactMap {
            guard let name = $0["name"] as? String,
                  let score = $0["score"] as? Int else { return nil }
            return (name, score)
        }
    }
    
    func addScore(_ score: Int, name: String = "玩家") {
        leaderboard.append((name, score))
        leaderboard.sort { $0.score > $1.score }
        if leaderboard.count > maxEntries {
            leaderboard = Array(leaderboard.prefix(maxEntries))
        }
        save()
    }
}


