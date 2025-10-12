import Foundation

struct TaskModel: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var minutes: Int
    var seconds: Int
    var isCompleted: Bool = false
    
    var totalSeconds: Int {
        minutes * 60 + seconds
    }
}


