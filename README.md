# PDF_reader

## 環境準備

先 clone 程式碼，環境需求: gradle 8.5, jdk 21, android 34  

### 安裝 flutter:  
* 安裝:  
  兩種方法:  
  - 終端機輸入: `git clone -b stable https://github.com/flutter/flutter.git`  
  - 到 https://flutter.dev/docs/development/tools/sdk/releases 下載最新版 flutter sdk 解壓縮到C槽
* 檢查:
  - 在終端機輸入 `flutter doctor`，會寫那些還沒裝好
  - <img width="622" alt="image" src="https://github.com/user-attachments/assets/466107cc-6130-4297-9a7e-5a5c496c46df">
  
### 安裝 Android Studio:  
* 下載:  
  到官網: https://developer.android.com/studio?hl=zh-tw#downloads 下載最新版本
* 安裝 SDK:  
  開啟 Android Studio --> More Actions --> SDK Manager  
  - 上面的 Android SDK Location 可以填自己的  
    C 槽空間不夠的推薦放 D 槽: `D:\Android\SDKs`  
  - SDK platform 中選 API level 34 (含)以上的
  - SDK tools 我是勾圖片中的這些:  
      <img width="428" alt="image" src="https://github.com/user-attachments/assets/bfad9e52-0dc2-45cd-b7de-72299e4b8a98">  
  - SDK Update Sites 不用動  
  結束記得 apply 再離開  
* 安裝 Virtual Device:  
  開啟 Android Studio --> More Actions --> Virtual Device Manager  
  - 左上角 + 新增  
  - Choose a device definition:  
    選擇 "phone" --> "small phone" (足夠了) --> next  
  - Select a system image:  Recommended --> UpSideDownCake (API level = 34, Android 14.0)  
  - 幫裝置取名 --> 左下有 Show Advance Setting 可以裝置調整記憶體大小 --> finish  
    
  
### 確認 Android Studio 的 SDK 資料夾中包含最新的 "cmdline-tools":  
* 目錄 `D:\Android\SDKs\cmdline-tools\` 中有 `latest` 資料夾  
  
### 設定使用者環境變數:  
1. JAVA_HOME: `C:\Program Files\Java\jdk-21` or where your JDK is.
2. GRADLE_HOME: `C:\Gradle\gradle-8.5` or where your gradle is.
3. ANDROID_HOME: `D:\Android\SDKs`or where your SDKs is put.
  
### 設定系統環境變數:  
* Path:  
  <img width="208" alt="image" src="https://github.com/user-attachments/assets/00e93d0f-c314-4436-b143-c5a7bb221285">
  
  
 
## 程式運行  
兩種方式:  
* 在終端機輸入 `flutter run`  
* 使用 VScode 的 emulator extension  

