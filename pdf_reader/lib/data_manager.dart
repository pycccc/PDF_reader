import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import 'data_structure.dart';
import 'dart:io';
import 'dart:ui';

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
  void addFile(Document fileToAdd) {
    getPageFolder().files.add(fileToAdd);
    saveData();
  }

  // 刪除檔案
  Future<void> deleteFile(Document fileToDelete) async {
    final file = File(fileToDelete.path);

    if (await file.exists()) {
      await file.delete();
      getPageFolder()
          .files
          .removeWhere((item) => item.name == fileToDelete.name);
      print("已刪除檔案: " + file.path);
      saveData();
    } else {
      print("檔案不存在: " + file.path);
    }
  }

  // 重新命名檔案
  Future<void> renameFile(Document fileToRename, String newName) async {
    final file = File(fileToRename.path);

    newName = newName + '.pdf';
    String newPath = file.parent.path + '/' + newName;
    if (await file.exists()) {
      final renamedFile = await file.rename(newPath);

      Folder curr = getPageFolder();
      int fileToRenameIdx =
          curr.files.indexWhere((file) => file.name == fileToRename.name);
      curr.files[fileToRenameIdx].name = newName;
      curr.files[fileToRenameIdx].path = newPath;

      print('檔案已重新命名為: ${renamedFile.path}');
    } else {
      print('原檔案不存在: ${fileToRename.path}');
    }

    saveData();
  }

  // 新增資料夾
  Future<void> addFolder(Folder folderToAdd) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    String wholeDir = '${appDocDir.path}/pdf_reader';
    List<String> currDirs = currentPath;
    for (var currDir in currDirs) {
      wholeDir += '/';
      wholeDir += currDir;
    }
    wholeDir += '/';
    wholeDir += folderToAdd.name;

    final Directory folderDir = Directory(wholeDir);
    if (!await folderDir.exists()) {
      await folderDir.create(recursive: true); // 遞迴建立資料夾
      print('資料夾建立: ${folderDir.path}');

      getPageFolder().folders.add(folderToAdd);
      saveData();
    } else {
      print('資料夾已存在: ${folderDir.path}');
      // TODO
      // if("getPageFolder().folders 裡面有依樣名字的")
      getPageFolder().folders.add(folderToAdd);
      saveData();
    }
  }

  // 移除資料夾下的檔案
  void deleteFolderInRecursive(Folder folderToDel) {
    if (folderToDel.folders.isNotEmpty) {
      for (var folder in folderToDel.folders) {
        deleteFolderInRecursive(folder);
      }
    }
    if (folderToDel.files.isNotEmpty) {
      for (var file in folderToDel.files) {
        deleteFile(file);
      }
    }
    folderToDel.folders
        .removeWhere((folder) => folder.name == folderToDel.name);
  }

  // 移除資料夾
  void deleteFolder(Folder folderToDel) {
    Folder curr = getPageFolder();

    int folderToDelIdx =
        curr.folders.indexWhere((folder) => folder.name == folderToDel.name);
    deleteFolderInRecursive(curr.folders[folderToDelIdx]);
    curr.folders.removeAt(folderToDelIdx);

    saveData();
  }

  // 重新命名資料夾下的檔案
  void renameFolderInRecursive(Folder folderToRename, String newPath) {
    for (var folder in folderToRename.folders) {
      String folerPath = newPath + '/' + folder.name;
      renameFolderInRecursive(folder, folerPath);
    }
    for (var file in folderToRename.files) {
      file.path = newPath + '/' + file.name;
    }
  }

  // 重新命名資料夾
  Future<void> renameFolder(Folder folderToRename, String newName) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    String wholeDir = '${appDocDir.path}/pdf_reader';
    List<String> currDirs = currentPath;
    for (var currDir in currDirs) {
      wholeDir += '/';
      wholeDir += currDir;
    }

    String oldPath = wholeDir + '/' + folderToRename.name;
    String newPath = wholeDir + '/' + newName;

    final Directory directory = Directory(oldPath);
    if (await directory.exists()) {
      final renamedDirectory = await directory.rename(newPath);

      Folder curr = getPageFolder();
      int folderToRenameIdx = curr.folders
          .indexWhere((folder) => folder.name == folderToRename.name);

      renameFolderInRecursive(curr.folders[folderToRenameIdx], newPath);
      curr.folders[folderToRenameIdx].name = newName;

      print('資料夾已重新命名為: ${renamedDirectory.path}');
      saveData();
    } else {
      print('原資料夾不存在: $oldPath');
    }
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

  // 合併檔案
  Future<void> mergeFiles(List<File> filesToMerge) async {
    final PdfDocument mergedDocument = PdfDocument();

    try {
      // 迭代所有要合併的文件
      for (File file in filesToMerge) {
        final bytes = await file.readAsBytes();
        final PdfDocument document = PdfDocument(inputBytes: bytes);

        // 將頁面加入到合併文檔中
        for (int i = 0; i < document.pages.count; i++) {
          final PdfTemplate template = document.pages[i].createTemplate();
          mergedDocument.pages.add().graphics.drawPdfTemplate(
                template,
                Offset(0, 0),
              );
        }

        // 釋放資源
        document.dispose();
      }

      // // 保存合併後的文檔到本地
      // final Directory outputDir = await getApplicationDocumentsDirectory();
      // final String outputPath = '${outputDir.path}/$outputFileName';
      // final File outputFile = File(outputPath);
      // await outputFile.writeAsBytes(mergedDocument.saveSync());

      // 獲取 pdf_reader 資料夾
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      List<String> currDirs = currentPath;
      String wholeDir = '${appDocDir.path}/pdf_reader';
      for (var currDir in currDirs) {
        wholeDir += '/';
        wholeDir += currDir;
      }
      final Directory pdfDir = Directory(wholeDir);
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true); // 遞迴建立資料夾
      }

      String pdfPath = '${pdfDir.path}/mergedFile.pdf';

      // 儲存 PDF 到本地
      File savedPdfFile = File(pdfPath);
      await savedPdfFile.writeAsBytes(await mergedDocument.save()).then((s) =>
          {addFile(Document(name: 'mergedFile.pdf', path: savedPdfFile.path))});

      // 清理資源
      mergedDocument.dispose();
    } catch (e) {
      print("合併 PDF 發生錯誤: $e");
      rethrow;
    }
  }

  // 分割檔案
  Future<void> splitFile(
      File fileToSplit, List<int> pageRanges, String outputFileName) async {
    final PdfDocument document =
        PdfDocument(inputBytes: await fileToSplit.readAsBytes());
    final PdfDocument splitDocument = PdfDocument();

    try {
      for (int pageIndex in pageRanges) {
        if (pageIndex < 1 || pageIndex > document.pages.count) {
          throw Exception("頁數範圍無效：$pageIndex");
        }

        final PdfTemplate template =
            document.pages[pageIndex - 1].createTemplate();
        splitDocument.pages.add().graphics.drawPdfTemplate(
              template,
              Offset(0, 0),
            );
      }

      // 根據原始檔案的路徑動態生成新檔案的存放位置
      final String originalDir = fileToSplit.parent.path;
      final String outputPath = '$originalDir/$outputFileName';
      final File outputFile = File(outputPath);

      await outputFile.writeAsBytes(await splitDocument.save());

      addFile(Document(name: outputFileName, path: outputFile.path));

      print("PDF 分割成功，另存為：$outputPath");
    } catch (e) {
      print("分割 PDF 發生錯誤：$e");
      rethrow;
    } finally {
      document.dispose();
      splitDocument.dispose();
    }
  }
}
