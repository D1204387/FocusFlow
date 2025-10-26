import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var taskName: String = ""
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    var onComplete: (TaskModel) -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            NavigationStack {
                VStack(spacing: 24) {
                        // 時間選擇器
                    HStack {
                        Picker("分鐘", selection: $minutes) {
                            ForEach(0..<60) { Text(String(format: "%02d", $0)) }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        Text(":")
                        Picker("秒", selection: $seconds) {
                            ForEach(0..<60) { Text(String(format: "%02d", $0)) }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                    }
                    .frame(height: 120)
                    .clipped()
                    
                        // 快速選擇時間按鈕（移到任務名稱輸入框上方）
                    HStack(spacing: 16) {
                        Button(action: { minutes = 5; seconds = 0 }) {
                            Text("5 分鐘")
                                .foregroundStyle(Theme.Focus.solid)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .overlay(
                                    Capsule()
                                        .stroke(Theme.Focus.solid, lineWidth: 2)
                                )
                                .clipShape(Capsule())
                        }
                        Button(action: { minutes = 10; seconds = 0 }) {
                            Text("10 分鐘")
                                .foregroundStyle(Theme.Focus.solid)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .overlay(
                                    Capsule()
                                        .stroke(Theme.Focus.solid, lineWidth: 2)
                                )
                                .clipShape(Capsule())
                        }
                        Button(action: { minutes = 25; seconds = 0 }) {
                            Text("25 分鐘")
                                .foregroundStyle(Theme.Focus.solid)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .overlay(
                                    Capsule()
                                        .stroke(Theme.Focus.solid, lineWidth: 2)
                                )
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.bottom, 4)
                    
                        // 任務名稱輸入框
                    TextField("請輸入任務名稱", text: $taskName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    Spacer()
                    // 新增：本次設定區塊，顯示目前選擇的時間
                    Text("本次設定：\(minutes) 分 \(seconds) 秒")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)
                    Text("預設：\(AppSettings.shared.focusMinutes) 分鐘")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Button("完成") {
                        let model = TaskModel(name: taskName, minutes: minutes, seconds: seconds)
                        onComplete(model)
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle(.primary(Theme.Focus.solid)))
                    .disabled(taskName.trimmingCharacters(in: .whitespaces).isEmpty || (minutes == 0 && seconds == 0))
                }
                .padding()
                .navigationTitle("新增任務")
            }
                // 下拉橫桿指示器（放在最上方，navigationTitle 之上）
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
        }
    }
}
