# FocusFlow 專案檔案架構

## 📁 完整檔案結構

```
FocusFlow/
│
├── 📱 FocusFlow.xcodeproj
│
├── 📂 FocusFlow/
│   │
│   ├── 📂 App/
│   │   ├── 📄 FocusFlowApp.swift                 # App 進入點 @main
│   │   ├── 📄 Info.plist                         # App 設定
│   │   └── 📄 AppDelegate.swift                  # App 生命週期（如需要）
│   │
│   ├── 📂 Core/                                  # 🎯 核心系統（成員 A 負責）
│   │   ├── 📂 Coordinator/
│   │   │   ├── 📄 ModuleCoordinator.swift        # 模組協調器
│   │   │   ├── 📄 ModuleProtocol.swift           # 模組協定
│   │   │   └── 📄 FlowEvents.swift               # 事件定義
│   │   │
│   │   ├── 📂 Services/
│   │   │   ├── 📄 SharedTimerService.swift       # 共用計時器
│   │   │   ├── 📄 SharedAudioService.swift       # 共用音效
│   │   │   ├── 📄 SharedHapticService.swift      # 共用震動
│   │   │   ├── 📄 SharedNotificationService.swift # 共用通知
│   │   │   ├── 📄 SharedSettingsService.swift    # 共用設定
│   │   │   └── 📄 SharedDataService.swift        # 共用資料服務
│   │   │
│   │   └── 📂 State/
│   │       ├── 📄 AppState.swift                 # 全域狀態
│   │       └── 📄 DailyProgress.swift            # 每日進度
│   │
│   ├── 📂 Models/                                # 📊 資料模型
│   │   ├── 📄 RunningRecord.swift                # 跑步記錄
│   │   ├── 📄 PomodoroRecord.swift               # 番茄記錄
│   │   ├── 📄 GameRecord.swift                   # 遊戲記錄
│   │   ├── 📄 DailyStats.swift                   # 每日統計
│   │   └── 📄 Achievement.swift                  # 成就資料
│   │
│   ├── 📂 DesignSystem/                          # 🎨 設計系統（成員 A 負責）
│   │   ├── 📄 Theme.swift                        # 主題定義
│   │   ├── 📄 Colors.swift                       # 顏色系統
│   │   ├── 📄 Typography.swift                   # 字體系統
│   │   ├── 📄 Spacing.swift                      # 間距系統
│   │   ├── 📄 Animations.swift                   # 動畫系統
│   │   └── 📄 Shadows.swift                      # 陰影系統
│   │
│   ├── 📂 Components/                            # 🧩 共用元件
│   │   ├── 📂 Base/
│   │   │   ├── 📄 GlassCard.swift               # 玻璃卡片
│   │   │   ├── 📄 PrimaryButton.swift           # 主要按鈕
│   │   │   ├── 📄 SecondaryButton.swift         # 次要按鈕
│   │   │   └── 📄 IconButton.swift              # 圖標按鈕
│   │   │
│   │   ├── 📂 Progress/
│   │   │   ├── 📄 CircularProgress.swift        # 圓形進度
│   │   │   ├── 📄 LinearProgress.swift          # 線性進度
│   │   │   └── 📄 AnimatedProgress.swift        # 動畫進度
│   │   │
│   │   ├── 📂 Stats/
│   │   │   ├── 📄 StatPill.swift                # 統計藥丸
│   │   │   ├── 📄 StatCard.swift                # 統計卡片
│   │   │   ├── 📄 WeeklyChart.swift             # 週圖表
│   │   │   └── 📄 ModuleStatusPill.swift        # 模組狀態藥丸
│   │   │
│   │   └── 📂 Navigation/
│   │       ├── 📄 CustomTabBar.swift            # 自訂標籤列
│   │       ├── 📄 IntegratedTabBar.swift        # 整合標籤列
│   │       └── 📄 TabBarButton.swift            # 標籤按鈕
│   │
│   ├── 📂 Modules/                               # 📱 功能模組
│   │   │
│   │   ├── 📂 Running/                          # 🏃 跑步模組（成員 A）
│   │   │   ├── 📄 RunningModule.swift           # 模組主體
│   │   │   ├── 📄 RunningModuleView.swift       # 主視圖
│   │   │   ├── 📄 RunningConfiguration.swift    # 設定
│   │   │   ├── 📂 Views/
│   │   │   │   ├── 📄 RunningTimerView.swift    # 計時器視圖
│   │   │   │   ├── 📄 RunningProgressRing.swift # 進度環
│   │   │   │   ├── 📄 RunningStatsView.swift    # 統計視圖
│   │   │   │   └── 📄 BPMIndicator.swift        # BPM 指示器
│   │   │   └── 📂 ViewModels/
│   │   │       └── 📄 RunningViewModel.swift     # 視圖模型
│   │   │
│   │   ├── 📂 Focus/                            # 🍅 專注模組（成員 B）
│   │   │   ├── 📄 FocusModule.swift             # 模組主體
│   │   │   ├── 📄 FocusModuleView.swift         # 主視圖
│   │   │   ├── 📄 FocusConfiguration.swift      # 設定
│   │   │   ├── 📂 Views/
│   │   │   │   ├── 📄 PomodoroTimerView.swift   # 番茄計時器
│   │   │   │   ├── 📄 PhaseIndicator.swift      # 階段指示器
│   │   │   │   ├── 📄 FocusHistoryView.swift    # 歷史記錄
│   │   │   │   └── 📄 BreakReminderView.swift   # 休息提醒
│   │   │   └── 📂 ViewModels/
│   │   │       ├── 📄 PomodoroViewModel.swift    # 視圖模型
│   │   │       └── 📄 PomodoroManager.swift      # 番茄管理器
│   │   │
│   │   └── 📂 Game/                             # 🎮 遊戲模組（成員 C）
│   │       ├── 📄 GameModule.swift              # 模組主體
│   │       ├── 📄 GameModuleView.swift          # 主視圖
│   │       ├── 📄 GameConfiguration.swift       # 設定
│   │       ├── 📂 Views/
│   │       │   ├── 📄 Game2048View.swift        # 2048 主遊戲
│   │       │   ├── 📄 GameBoardView.swift       # 遊戲板
│   │       │   ├── 📄 GameTileView.swift        # 遊戲方塊
│   │       │   ├── 📄 GameScoreView.swift       # 分數顯示
│   │       │   ├── 📄 EnergyDisplay.swift       # 能量顯示
│   │       │   └── 📄 LeaderboardView.swift     # 排行榜
│   │       ├── 📂 ViewModels/
│   │       │   └── 📄 Game2048ViewModel.swift    # 遊戲邏輯
│   │       └── 📂 Models/
│   │           ├── 📄 GameBoard.swift           # 遊戲板模型
│   │           └── 📄 GameTile.swift            # 方塊模型
│   │
│   ├── 📂 Views/                                 # 📱 主要視圖
│   │   ├── 📄 ContentView.swift                  # 原始內容視圖
│   │   ├── 📄 IntegratedContentView.swift        # 整合內容視圖
│   │   ├── 📄 OnboardingView.swift               # 引導頁面
│   │   ├── 📄 SplashScreenView.swift             # 啟動畫面
│   │   │
│   │   ├── 📂 Shared/
│   │   │   ├── 📄 GlobalStatusBar.swift         # 全域狀態列
│   │   │   ├── 📄 DailyProgressCard.swift       # 每日進度卡
│   │   │   ├── 📄 ModuleContainer.swift         # 模組容器
│   │   │   └── 📄 BackgroundView.swift          # 背景視圖
│   │   │
│   │   └── 📂 Settings/
│   │       ├── 📄 SettingsView.swift            # 設定主視圖
│   │       ├── 📄 SettingsModuleView.swift      # 設定模組視圖
│   │       ├── 📄 AudioSettingsView.swift       # 音效設定
│   │       ├── 📄 GoalSettingsView.swift        # 目標設定
│   │       ├── 📄 NotificationSettingsView.swift # 通知設定
│   │       └── 📄 AboutView.swift               # 關於頁面
│   │
│   ├── 📂 Extensions/                            # 🔧 擴充功能
│   │   ├── 📄 Color+Extensions.swift             # 顏色擴充
│   │   ├── 📄 View+Extensions.swift              # 視圖擴充
│   │   ├── 📄 Date+Extensions.swift              # 日期擴充
│   │   └── 📄 Double+Extensions.swift            # 數字擴充
│   │
│   ├── 📂 Utilities/                             # 🛠️ 工具類
│   │   ├── 📄 Constants.swift                    # 常數定義
│   │   ├── 📄 Helpers.swift                      # 輔助函數
│   │   └── 📄 Logger.swift                       # 日誌工具
│   │
│   └── 📂 Resources/                             # 📦 資源檔案
│       ├── 📂 Assets.xcassets/
│       │   ├── 📂 AppIcon.appiconset/           # App 圖標
│       │   ├── 📂 Colors/                       # 顏色資源
│       │   ├── 📂 Images/                       # 圖片資源
│       │   └── 📂 Icons/                        # 圖標資源
│       │
│       ├── 📂 Sounds/                           # 音效檔案
│       │   ├── 🎵 running_music.mp3             # 跑步音樂
│       │   ├── 🎵 focus_music.mp3               # 專注音樂
│       │   ├── 🎵 game_music.mp3                # 遊戲音樂
│       │   ├── 🔊 complete.mp3                  # 完成音效
│       │   ├── 🔊 success.mp3                   # 成功音效
│       │   ├── 🔊 warning.mp3                   # 警告音效
│       │   └── 🔊 click.mp3                     # 點擊音效
│       │
│       ├── 📂 Fonts/                            # 字體檔案
│       │   └── 📝 SF-Pro-Display.ttf            # 自訂字體
│       │
│       └── 📂 Localizations/                    # 本地化
│           ├── 📄 Localizable.strings (zh-Hant)  # 繁體中文
│           └── 📄 Localizable.strings (en)       # 英文
│
├── 📂 FocusFlowTests/                            # 單元測試
│   ├── 📂 Core/
│   │   ├── 📄 ModuleCoordinatorTests.swift
│   │   └── 📄 SharedServicesTests.swift
│   ├── 📂 Modules/
│   │   ├── 📄 RunningModuleTests.swift
│   │   ├── 📄 FocusModuleTests.swift
│   │   └── 📄 GameModuleTests.swift
│   └── 📄 FocusFlowTests.swift
│
└── 📂 FocusFlowUITests/                          # UI 測試
    ├── 📄 FocusFlowUITests.swift
    └── 📄 FocusFlowUITestsLaunchTests.swift
```

## 🎯 團隊分工對應

### **成員 A - 跑步 + 核心架構**
負責資料夾：
- ✅ `/Core/*` - 所有核心系統
- ✅ `/DesignSystem/*` - 設計系統
- ✅ `/Components/Base/*` - 基礎元件
- ✅ `/Modules/Running/*` - 跑步模組

### **成員 B - 專注模組**
負責資料夾：
- ✅ `/Modules/Focus/*` - 專注模組
- ✅ `/Components/Stats/*` - 統計元件（可選）
- ✅ `/Views/Settings/*` - 設定頁面（部分）

### **成員 C - 遊戲模組**
負責資料夾：
- ✅ `/Modules/Game/*` - 遊戲模組
- ✅ `/Components/Progress/*` - 進度元件（可選）

## 📝 檔案命名規範

### **命名規則**
```
類型           格式                     範例
----------------------------------------------------
View          [Name]View              RunningTimerView.swift
ViewModel     [Name]ViewModel         RunningViewModel.swift
Model         [Name]                  RunningRecord.swift
Service       [Name]Service           SharedTimerService.swift
Manager       [Name]Manager           PomodoroManager.swift
Extension     [Type]+Extensions       Color+Extensions.swift
Protocol      [Name]Protocol          ModuleProtocol.swift
Configuration [Name]Configuration     RunningConfiguration.swift
```

## 🔧 Xcode 專案設定

### **建立群組（Groups）**
1. 在 Xcode 中建立對應的群組結構
2. 確保「Create folder references」選項
3. 群組顏色建議：
   - 🔴 Core (紅色)
   - 🟢 Modules (綠色)
   - 🔵 Components (藍色)
   - 🟡 DesignSystem (黃色)
   - 🟣 Models (紫色)

### **Target 設定**
```
Target: FocusFlow
├── Deployment Target: iOS 18.0
├── Device Orientation: Portrait
├── Status Bar Style: Light Content
└── Capabilities:
    ├── Background Modes (Audio)
    ├── Push Notifications
    └── HealthKit (optional)
```

## 📦 套件管理 (Swift Package Manager)

### **Package.swift**
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FocusFlow",
    platforms: [
        .iOS(.v18)
    ],
    dependencies: [
        // 如需第三方套件，在此加入
        // .package(url: "https://github.com/...", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "FocusFlow",
            dependencies: []
        ),
        .testTarget(
            name: "FocusFlowTests",
            dependencies: ["FocusFlow"]
        )
    ]
)
```

## 🚀 快速開始

### **1. 建立專案**
```bash
# 在 Xcode 中
File → New → Project → iOS → App
Product Name: FocusFlow
Interface: SwiftUI
Language: Swift
Use Core Data: No (我們用 SwiftData)
Include Tests: Yes
```

### **2. 建立資料夾結構**
```bash
# 在專案根目錄執行
mkdir -p FocusFlow/{App,Core/{Coordinator,Services,State},Models,DesignSystem}
mkdir -p FocusFlow/Components/{Base,Progress,Stats,Navigation}
mkdir -p FocusFlow/Modules/{Running,Focus,Game}/{Views,ViewModels}
mkdir -p FocusFlow/Views/{Shared,Settings}
mkdir -p FocusFlow/{Extensions,Utilities,Resources/{Sounds,Fonts}}
```

### **3. Git 設定**
**.gitignore**
```gitignore
# Xcode
*.xcodeproj/xcuserdata/
*.xcworkspace/xcuserdata/
*.xcodeproj/project.xcworkspace/xcuserdata/
DerivedData/
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

# Swift Package Manager
.build/
.swiftpm/

# CocoaPods (if used)
Pods/

# macOS
.DS_Store

# AppCode
.idea/
```

## 📋 檔案模板

### **Module Template**
```swift
// Modules/[Name]/[Name]Module.swift
import SwiftUI

struct [Name]Module: FlowModule {
    @ObservedObject var coordinator = ModuleCoordinator.shared
    
    typealias Configuration = [Name]Configuration
    var configuration = [Name]Configuration()
    
    var body: some View {
        [Name]ModuleView()
            .environmentObject(coordinator)
    }
    
    func onStart() {
        // 啟動邏輯
    }
    
    func onStop() {
        // 停止邏輯
    }
    
    func onPause() {
        // 暫停邏輯
    }
    
    func onResume() {
        // 繼續邏輯
    }
    
    func getProgress() -> ModuleProgress {
        // 回傳進度
    }
}
```

### **View Template**
```swift
// Views/[Name]View.swift
import SwiftUI

struct [Name]View: View {
    @EnvironmentObject var coordinator: ModuleCoordinator
    
    var body: some View {
        VStack {
            // UI 內容
        }
    }
}

#Preview {
    [Name]View()
        .environmentObject(ModuleCoordinator.shared)
}
```

## 📱 Import 順序規範

```swift
// 1. System frameworks
import SwiftUI
import SwiftData
import Combine

// 2. Third-party frameworks
// import [ThirdParty]

// 3. Local modules
import FocusFlowCore
import FocusFlowUI

// 4. File content
struct MyView: View {
    // ...
}
```

## ✅ 檔案檢查清單

確保每個模組都有：
- [ ] Module 主檔案
- [ ] ModuleView 視圖
- [ ] Configuration 設定
- [ ] ViewModel（如需要）
- [ ] 相關子視圖
- [ ] 單元測試

## 🎯 最佳實踐

1. **一個檔案一個類型**：每個 struct/class 獨立一個檔案
2. **資料夾對應功能**：檔案位置反映其功能
3. **命名一致性**：遵循命名規範
4. **註解清晰**：檔案頭部加入用途說明
5. **版本控制**：定期提交，寫清楚 commit message

---
**團隊合作愉快！** 🚀