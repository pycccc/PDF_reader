import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'data_structure.dart';

class DataManager {
  // 確保在建立新的 DataManager 時，homeFolder 不會被重新初始化
  static final DataManager _instance = DataManager._internal(); // 私有靜態實例
  factory DataManager() {
    return _instance;
  }
  DataManager._internal() {
    // 私有的命名建構函數（只會被呼叫一次）
    homeFolder = Folder(name: "homeFolder");
    currentPath = [];
  }

  late Folder homeFolder;
  late List<String> currentPath;

  // 存入本地資料
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('file_data', json.encode(homeFolder.toJson()));
  }

  // 載入本地資料
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString('file_data');
    if (dataString != null) {
      final Map<String, dynamic> jsonData = json.decode(dataString);
      homeFolder = Folder.fromJson(jsonData);
    }
  }

  // 新增檔案
  void addFile(File fileToAdd) {
    Folder curr = homeFolder;

    for (int loc = 0; loc < currentPath.length; loc++) {
      int dest = curr.folders
          .indexWhere((folder) => folder.name.compareTo(currentPath[loc]) == 0);
      if (dest < 0) {
        print("[Error] Add file failed.");
        return;
      }
      curr = curr.folders[dest];
    }
    curr.files.add(fileToAdd);
    saveData();
  }

  // 新增資料夾
  void addFolder(Folder folderToAdd) {
    Folder curr = homeFolder;
    for (int loc = 0; loc < currentPath.length; loc++) {
      int dest =
          curr.folders.indexWhere((folder) => folder.name == currentPath[loc]);
      if (dest < 0) {
        print("[Error] Add folder failed.");
        return;
      }
      curr = curr.folders[dest];
    }
    curr.folders.add(folderToAdd);
    saveData();
  }

  // 移除所有 path 階層 (ex: home/page1/page2 --> [])
  void clearCurrPath() {
    currentPath.clear();
  }

  // 移除一個 path 階層 (ex: home/page1/page2 --> home/page1)
  void popCurrPath() {
    if (currentPath.isNotEmpty) currentPath.removeLast();
  }

  // 新增一個 path 階層 (ex: home/page1 --> home/page1/currFolderName)
  void addCurrPath(String currFolderName) {
    currentPath.add(currFolderName);
  }

  // 獲得當前路徑頁面的資料
  Folder getPageFolder() {
    Folder curr = homeFolder;
    for (int loc = 0; loc < currentPath.length; loc++) {
      int dest =
          curr.folders.indexWhere((folder) => folder.name == currentPath[loc]);
      if (dest < 0) {
        print("[Error] Get path folder failed.");
        clearCurrPath();
        return Folder(name: "error");
      }
      curr = curr.folders[dest];
    }
    return curr;
  }
}
