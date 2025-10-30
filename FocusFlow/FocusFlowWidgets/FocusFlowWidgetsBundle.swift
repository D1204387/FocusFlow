import WidgetKit
import SwiftUI

@main
struct FocusFlowWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FocusFlowWidget() // 跑步專用 Widget
        PomodoroWidget() // 專注番茄鐘 Widget

    }
}
