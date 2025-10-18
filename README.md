# FocusFlow
以「跑步 × 專注 × 小遊戲」打造的日常自律 App。完成跑步或一顆番茄可獲得能量，用能量解鎖 2048 小遊戲；所有紀錄會以圖表回顧。
# 主要功能
慢跑：計時、節拍器（BPM 可調）、可選背景音樂、到時播放完成音。


專注番茄：專注 / 短休 / 長休循環，支援自動續播與回合計數。


遊戲：2048（能量 > 0 才可開始，結束後會存分數到排行榜）。


記錄：近 7/30 天跑步分鐘數、番茄分鐘數、遊戲局數統計。


設定：音樂、節拍器、BPM、各階段分鐘數與長休間隔等。


# 能量規則
跑步：完成一次 +1 能量


番茄：完成一顆 +1 能量


遊戲：需要 能量 > 0 才能開始（遊戲本身不再額外給能量）
# 技術棧
iOS 17+ / Xcode 15+


SwiftUI（UI）、Observation（@Observable / @Environment 注入）


SwiftData（RunningRecord, PomodoroRecord, GameRecord）


AVFoundation（BGM、節拍器、完成音）
# 專案結構
```
FocusFlow/
├─ APP/                            # 主應用層（主要頁面與功能模組）
│  ├─ Root/                        # 應用入口與共用頁面
│  │  ├─ FocusFlowApp.swift        # App 主入口（@main）
│  │  ├─ FocusFlowRootView.swift   # 根視圖，負責導航與容器管理
│  │  ├─ RecordsView.swift         # 專注與跑步紀錄列表
│  │  └─ SettingsView.swift        # 設定頁
│  └─ Features/                    # 功能模組（Feature Modules）
│     ├─ Running/                  # 慢跑模組
│     │  └─ RunningView.swift      # 跑步紀錄畫面與邏輯
│     ├─ Focus/                    # 番茄專注模組
│     │  ├─ FocusCycleView.swift   # 專注循環計時主畫面
│     │  ├─ AddTaskView.swift      # 新增任務頁面
│     │  └─ TaskModel.swift        # 任務資料模型
│     └─ Game/                     # 2048 遊戲模組
│        ├─ GameView.swift         # 遊戲主畫面
│        ├─ GameModel.swift        # 遊戲邏輯
│        └─ LeaderboardManager.swift # 排行榜管理
│
├─ Resources/                      # 資源檔案（音效與素材）
│  ├─ Audio/                       # 音效資源
│  │  ├─ light_music.mp3           # 輕音樂背景
│  │  ├─ nature_ambient.mp3        # 自然環境聲
│  │  ├─ relaxing_piano.mp3        # 鋼琴放鬆音樂
│  │  ├─ metronome_click.wav       # 節拍器點音
│  │  └─ completion_chime.m4a      # 完成提示音
│  └─ Assets.xcassets              # App 圖示與主題顏色資產
│
├─ Shared/                         # 共用邏輯層（可跨模組共用）
│  ├─ Core/                        # 核心邏輯
│  │  ├─ AppSettings.swift         # 全域設定與偏好管理
│  │  ├─ AudioService.swift        # 音效播放控制
│  │  ├─ ModuleCoordinator.swift   # 模組切換協調器
│  │  └─ RewardRules.swift         # 獎勵機制與分數規則
│  ├─ Models/                      # SwiftData 資料模型
│  │  ├─ RunningRecord.swift       # 跑步紀錄資料模型
│  │  ├─ PomodoroRecord.swift      # 番茄紀錄資料模型
│  │  └─ GameRecord.swift          # 遊戲紀錄資料模型
│  ├─ Stores/                      # 資料存取層
│  │  └─ RecordsStore.swift        # 統一管理紀錄資料的存取
│  ├─ Theme/                       # 主題與樣式
│  │  ├─ LightTheme.swift          # App 色彩主題設定
│  │  └─ ButtonStyles.swift        # 按鈕樣式統一定義
│  └─ UI/                          # 可重用 UI 元件
│     ├─ SegmentedGaugeRing.swift  # 圓環進度元件
│     ├─ TimeCluster.swift         # 時間區塊顯示
│     ├─ ToolbarEnergy.swift       # 工具列能量指示
│     └─ StatusCard.swift          # 狀態資訊卡片
│
├─ Widgets/                        # 小工具 (Widget Extension)
│  ├─ FocusFlowWidget.swift        # 主 Widget 入口
│  ├─ PomodoroWidget.swift         # 番茄時鐘 Widget
│  ├─ RefreshWidgetIntent.swift    # 資料手動刷新 Intent
│  ├─ ManualRecordIntent.swift     # 手動新增紀錄 Intent
│  ├─ FocusFlowWidgetsBundle.swift # Widget 組合管理
│  └─ Info.plist                   # Widget 組態檔
│
├─ Config/                         # 設定檔與權限
│  ├─ FocusFlow-iOS-Info.plist     # 主應用的 Info 設定
│  └─ FocusFlowWidgetsExtension.entitlements # Widget 權限設定
│
└─ README.md                       # 專案說明文件

```

# 快速開始
使用 Xcode 15+ 開啟 FocusFlow 專案。


目標平台 iOS 17+，直接 Run 到模擬器或實機。


首次執行建議到「設定」調整 BPM 與各階段時間。


# 音訊說明
BGM 將從資源中 隨機 選一首循環播放（可在設定中關閉）。


完成跑步會播放 completion_chime.m4a，結束後自動釋放音訊資源。
# 圖片展示
<img width="268" height="583" alt="Simulator Screenshot - iPhone 17 Pro - 2025-10-14 at 01 14 05" src="https://github.com/user-attachments/assets/8a0b36e2-4e5d-4ee2-b284-89ace4cd087b" />
<img width="268" height="583" alt="Simulator Screenshot - iPhone 17 Pro - 2025-10-14 at 01 14 09" src="https://github.com/user-attachments/assets/f241c3ec-c14c-4e11-94be-21528381dd92" />
<img width="268" height="583" alt="Simulator Screenshot - iPhone 17 Pro - 2025-10-14 at 01 14 29" src="https://github.com/user-attachments/assets/9a67222b-7878-44e5-a844-d844d27fe250" />




