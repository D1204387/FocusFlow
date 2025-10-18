import SwiftUI
import WidgetKit

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("設定")
                .font(.largeTitle)
                .bold()
                .padding(.top, 32)
            Spacer()
            Button(action: {
                WidgetCenter.shared.reloadAllTimelines()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.title2)
                    Text("刷新桌面小工具")
                        .font(.title3)
                        .bold()
                }
                .padding()
                .foregroundColor(.accentColor)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            Spacer()
        }
        .padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
