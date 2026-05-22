# Habibi — 功能・收費・機制總覽

> 最後更新:2026-05-22
> 本文件用中文敘述,專有名詞(habit、challenge、Pro、Free 等)維持英文。
> 內容分成兩大類:**✅ 已實作**(程式裡已經有)與 **📝 設計中**(已討論定案,但還沒寫進程式)。

---

## 0. 這是什麼 App

Habibi 是一個極簡的習慣養成 App,DSAP 課程的學校專案。

- **技術**:Flutter
- **本機儲存**:Hive(資料目前都存在使用者自己的手機上,沒有伺服器)
- **狀態管理**:Provider
- **架構特色**:資料層採用「可抽換 repository」設計(`AuthRepository`、`SocialRepository`),未來要接 Firebase 時,UI 與 provider 完全不用動。
- **目標平台**:以 App Store(iOS)為主。

App 主畫面有 **3 個 tab**:`Habits`、`Challenges`、`Account`(內含 friends)。

---

## 1. ✅ 已實作的功能

### 1.1 Habit(個人習慣)
- 建立 / 編輯 / 刪除 habit。
- 每個 habit 有:名稱、描述、顏色、icon。
- 每天可以「打卡」(check-in),完成的日期存成一組日期集合(date keys,格式 `yyyy-MM-dd`)。
- 自動計算 **streak(連續天數)**:從今天往回數連續完成的天數。
- 也能算 **longest streak(史上最長連續)**。
- 視覺:habit card、點陣圖(dot grid)、月曆(month calendar)、habit 詳細頁。

### 1.2 Challenge(好友挑戰)
- challenge = 「和朋友一起做的 habit」。
- 每位參與者(participant)各自有自己的打卡紀錄。
- **mutual streak(共同連續天數)**:用 **set intersection(集合交集)** 算出「所有人都有打卡的日子」,再對這些日子算 streak。也就是說,**只要有一個人某天沒打卡,那天就不算共同達成**。
- 建立 challenge 的前提:要先 sign in,而且至少要有一位 friend。
- **目前 UI 只支援「2 人」challenge**(我 + 一位朋友);不過底層的 `participantIds` 已經是一個 list,天生支援多人,之後擴充不用改資料結構。
- 視覺:challenge card、challenge 詳細頁。

### 1.3 Friends(朋友)與帳號
- `Account` tab 提供一個 **demo 版 sign in**(按鈕寫「Continue with Google」,但目前是本機假登入,不需要真的 Google 帳號)。
- 可手動新增 / 刪除 friend(也有「Add demo friend」一鍵新增測試用朋友)。
- friend 的 id 會被當成 challenge 裡的 participant id 使用。
- 可登出;登出後 friends 與 challenges 仍留在這台裝置上。

### 1.4 外觀與設定
- **主題**:Light / Dark / System(跟隨系統)三選一,主色為紫色。
- `Settings` 頁:主題切換、About、版本資訊。

### 1.5 其他
- 已加入 `.gitattributes`,統一換行字元為 LF,消除 Windows 上的 CRLF 警告。

---

## 2. 📝 收費機制(Monetization)— 設計中,尚未實作

### 2.1 方案比較

| 功能 | **Free** | **Pro** |
|---|---|---|
| habits 數量 | 最多 **3 個** | **無限** |
| challenges | **無限**(但每個至少要 2 人) | 無限 |
| widgets | basic widgets | 全部 widgets |
| restore archived habits(還原被封存的 habit) | ✗ | ✓ |
| charts & statistics(圖表統計) | ✗ | ✓ |
| import & export data(匯入 / 匯出資料) | ✗ | ✓ |

### 2.2 定價

| 方案 | 價格 | 備註 |
|---|---|---|
| Monthly | **NT$30 / 月** | |
| Annual | **NT$300 / 年** | 約等於月繳省 17% |
| Lifetime | **NT$690 一次買斷** | 約等於 23 個月月費 |

> ⚠️ **Lifetime 的長期考量**:目前 App 是 local-first(資料在手機、幾乎沒有持續成本),賣 Lifetime 沒問題。但**未來若接上 Firebase**(雲端同步、即時 challenge),Lifetime 用戶會變成「永久持續花你錢」的負擔,屆時建議把 Lifetime 改成限時 / 早鳥限定。

### 2.3 收費點的設計原則
- **限制只放在「個人 habit 數量」**(免費 3 個),以及未來的周邊功能(charts、widgets、import/export)。
- **challenges 不收費、不設上限**,因為 challenge 是社交功能,對單人收費會傷到無辜的朋友(collateral damage)。把錢收在「只屬於你自己、鎖了不傷別人」的東西上。

### 2.4 Paywall(付費牆)
- 當 free 使用者想建立第 4 個 habit 時,跳出 paywall。
- paywall 顯示 Free vs Pro 功能對照 + 三種定價,讓使用者選擇後購買。

### 2.5 ⚠️ App Store 的重要前提(真實上架時)
- Apple 規定:App 內解鎖數位功能**必須走 Apple In-App Purchase (IAP)**,不能用自己的金流。
- Apple 抽成 15%(小型開發者)~ 30%。
- 需要 Apple Developer 帳號(US$99/年)。
- IAP **只能在真機 / sandbox 測試**,無法在 Chrome 或 Windows 上測。
- 因此目前策略:**先做「模擬付款」版本**(假付款、用本機旗標模擬 Pro 狀態),把整套 UX 跑起來;真正的 IAP 之後在 Mac 上,用 `in_app_purchase` 或 RevenueCat 套件,藏在同一個可抽換的 billing 介面後面再接上。

---

## 3. 📝 Challenge 生命週期機制 — 設計中,尚未實作

這是 Habibi 最特別的機制:challenge 不是永遠存在,而是「需要大家持續投入才能活著」。

### 3.1 人數
- 每個 challenge **至少 2 人、最多 10 人**。

### 3.2 打卡計時(7 天)
- **每一位** participant 各自有一個 7 天計時器。
- 每個人都必須在自己的每 7 天內**至少打卡一次**。

### 3.3 有人沒打卡時會怎樣
- **目前人數 > 2 時**:某位 participant 連續 7 天沒打卡 → **那個人被踢出(dropped)**,其餘的人**繼續**。人數就這樣慢慢變少。
- **人數剩下 2 人時**:其中一人連續 7 天沒打卡 → **整個 challenge 結束(state = `ended`)**(因為剩 1 人就不算「和朋友一起」)。
- 不論是被踢出還是 ended,紀錄都**永久保存、不能 restore(復活)**。

### 3.4 天數的處理
- **天數不回溯更動**:過去已經達成的共同天數保留不動。有人被踢出後,**往後**只看「還在的人」重新計算交集。

### 3.5 被踢出的人會看到什麼
- 「自己堅持了幾天」。
- 「這個 challenge 最後總共活了幾天」。
- 如果這個 challenge **還在繼續**(其他人還在),被踢出的人可以在 **墓園(graveyard)** 看到它**目前的現況**(像去探望一樣)。

### 3.6 墓園(Graveyard)
- 所有已 `ended` 的 challenge,以及自己被踢出的 challenge,都會保存在墓園裡,**隨時都能回去看**(可看、不可改、不可復活)。

### 3.7 死前警告
- 在「踢人 / ended」發生前,一定要有**警告 + 推播提醒**(例如:「小明已經 5 天沒打卡,再 2 天你們的 challenge 就會結束!」)。
- 這同時是公平機制(避免使用者莫名其妙失去),也是很強的回流(re-engagement)機制。

---

## 4. 實作進度(Implementation Status)

| 項目 | 狀態 |
|---|---|
| Habit 建立 / 打卡 / streak | ✅ 已實作 |
| Challenge(2 人)+ mutual streak | ✅ 已實作 |
| Friends + demo sign in | ✅ 已實作 |
| Light / Dark / System 主題 | ✅ 已實作 |
| `.gitattributes`(換行統一) | ✅ 已實作 |
| **Stage 1**:模擬 billing + paywall + 3 個 habit 上限 gate | ✅ 已實作(模擬付款) |
| **Stage 2**:超額 habit 封存(archive)+ Pro 還原(restore) | ✅ 已實作 |
| **Stage 3**:Challenge 生命週期(踢人 / ended / 墓園 / 警告) | ✅ 已實作(含 demo 時間控制 + 單元測試) |
| Charts & statistics | 📝 待做 |
| 多種 widgets | 📝 待做 |
| Import & export data | 📝 待做 |
| 真實 Apple IAP(需 Mac + Apple 帳號) | 📝 待做 |
| Firebase(雲端同步、真實好友) | 📝 待做(架構已預留) |

---

## 5. 給未來的技術備註
- **模擬付款 → 真實 IAP**:billing 會做成可抽換介面(`BillingRepository`),`LocalBillingRepository`(模擬)現在用,`StoreBillingRepository`(真實)之後接,只改 `main.dart` 一行,UI 不動 —— 與現有的 `AuthRepository` / `SocialRepository` 同一套模式。
- **平台限制**:開發機是 Windows;iOS build 與 IAP 測試需要 Mac。模擬版可直接在 Chrome 上跑、展示。
- **Firebase 遷移**:接上 Firebase 後等於有了「伺服器 + 雲端資料庫」,屆時可重新評估是否要支援消耗型(consumable)購買、以及 Lifetime 方案的成本。
