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
FocusFlow/
├─ APP/
│  ├─ Root/               # 入口與通用頁
│  │  ├─ FocusFlowApp.swift
│  │  ├─ FocusFlowRootView.swift
│  │  ├─ RecordsView.swift
│  │  └─ SettingsView.swift
│  └─ Features/
│     ├─ Running/         # 跑步
│     │  └─ RunningView.swift
│     ├─ Focus/           # 專注番茄
│     │  └─ FocusCycleView.swift
│     └─ Game/            # 2048
│        ├─ GameView.swift
│        ├─ GameModel.swift
│        └─ LeaderboardManager.swift
├─ Resources/
│  ├─ Audio/              # BGM / 節拍器 / 完成音
│  │  ├─ light_music.mp3, nature_ambient.mp3, relaxing_piano.mp3
│  │  ├─ metronome_click.wav
│  │  └─ completion_chime.m4a
│  └─ Assets.xcassets
├─ Shared/
│  ├─ Core/               # 系統層
│  │  ├─ AppSettings.swift
│  │  ├─ AudioService.swift
│  │  ├─ ModuleCoordinator.swift
│  │  └─ RewardRules.swift
│  ├─ Models/             # SwiftData 模型
│  │  ├─ RunningRecord.swift
│  │  ├─ PomodoroRecord.swift
│  │  └─ GameRecord.swift
│  ├─ Theme/              # 主題與樣式
│  │  ├─ LightTheme.swift
│  │  └─ ButtonStyles.swift
│  └─ UI/                 # 可重用元件
│     ├─ SegmentedGaugeRing.swift
│     ├─ TimeCluster.swift
│     └─ ToolbarEnergy.swift
└─ README.md

# 快速開始
使用 Xcode 15+ 開啟 FocusFlow 專案。


目標平台 iOS 17+，直接 Run 到模擬器或實機。


首次執行建議到「設定」調整 BPM 與各階段時間。


# 音訊說明
BGM 將從資源中 隨機 選一首循環播放（可在設定中關閉）。


完成跑步會播放 completion_chime.m4a，結束後自動釋放音訊資源。
# 圖片展示
<img width="402" height="874" alt="Simulator Screenshot - iPhone 17 Pro - 2025-10-14 at 01 14 05" src="https://github.com/user-attachments/assets/8a0b36e2-4e5d-4ee2-b284-89ace4cd087b" />
<img width="402" height="874" alt="Simulator Screenshot - iPhone 17 Pro - 2025-10-14 at 01 14 09" src="https://github.com/user-attachments/assets/f241c3ec-c14c-4e11-94be-21528381dd92" />
<img width="402" height="874" alt="Simulator Screenshot - iPhone 17 Pro - 2025-10-14 at 01 14 29" src="https://github.com/user-attachments/assets/9a67222b-7878-44e5-a844-d844d27fe250" />




