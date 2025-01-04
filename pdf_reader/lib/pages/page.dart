import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import 'dart:io';

import '../data_manager.dart';
import '../data_structure.dart';
import '../converter.dart';
import 'pdf_viewer.dart';

DataManager dataManager = DataManager();

// 新增資料夾的彈跳視窗
Future<String?> _addItemScreen(
    BuildContext context, String title, String hint) async {
  TextEditingController inputController = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: inputController,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(null);
            },
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(inputController.text);
            },
            child: const Text("確認"),
          ),
        ],
      );
    },
  );
}

// 打開檔案選擇器並轉換為 PDF
Future<String> pickAndConvertFile() async {
  try {
    // 打開檔案選擇器
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'pdf', 'docx', 'doc'],
    );
    if (result == null || result.files.single.path == null) {
      return "未選擇檔案或檔案路徑無效";
    }

    // 選取的檔案
    File selectedFile = File(result.files.single.path!);
    String selectedName = result.files.single.name;

    File pdfFile;
    Converter converter = Converter(selectedFile);

    // pdf to pdf
    if (selectedName.endsWith('.pdf')) {
      pdfFile = await converter.pdfToPdf(selectedName);
    }
    // txt to pdf
    else if (selectedName.endsWith('.txt')) {
      pdfFile = await converter.txtToPdf(selectedName);
    }
    // docx to pdf
    else if (selectedName.endsWith('.docx') || selectedName.endsWith('.doc')) {
      pdfFile = await converter.docxToPdf(selectedName);
    }
    // else if (originalName.endsWith('.pptx')) {
    // }
    else {
      return "不支援的檔案格式";
    }

    // 存到本地
    dataManager.addFile(
        Document(name: path.basename(pdfFile.path), path: pdfFile.path));

    return "檔案已成功轉換";
  } catch (e) {
    return "轉換失敗：$e";
  }
}

void reloadPage(context) {
  print("reload page");
  String currFolderName = dataManager.getPageFolder().name;

  if (dataManager.getPageFolder() != dataManager.homeFolder) {
    dataManager.popCurrPath();
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderPage(
          folderName: currFolderName,
        ),
      ),
    );
  } else {
    dataManager.clearCurrPath();
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return const HomePage();
      }),
    );
  }
}

// 顯示功能選單
void showMenu(context, Data item) {
  bool isFolder = (item.type == "folder") ? true : false;

  isFolder
      ? showModalBottomSheet(
          context: context,
          builder: (context) {
            return Wrap(
              children: [
                ListTile(
                  // 刪除
                  title: Text("刪除"),
                  onTap: () async {
                    Navigator.pop(context);

                    // 刪除資料夾
                    dataManager.deleteFolder(Folder(name: item.name.trim()));
                    if (context.mounted) reloadPage(context);
                  },
                ),
                ListTile(
                  // 修改名稱
                  title: Text("修改名稱"),
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("修改完成後請重新進入資料夾頁面"),
                    ));

                    Navigator.pop(context);

                    // 修改資料夾
                    String? newFolderName =
                        await _addItemScreen(context, "重新命名資料夾", "資料夾名稱");
                    if (newFolderName != null &&
                        newFolderName.trim().isNotEmpty) {
                      dataManager
                          .renameFolder(
                              Folder(name: item.name.trim()), newFolderName)
                          .then((s) {
                        if (context.mounted) reloadPage(context);
                      });
                    }
                  },
                ),
              ],
            );
          },
        )
      : showModalBottomSheet(
          context: context,
          builder: (context) {
            return Wrap(
              children: [
                ListTile(
                  // 刪除
                  title: Text("刪除"),
                  onTap: () async {
                    Navigator.pop(context);

                    Folder currFolder = dataManager.getPageFolder();
                    List<Document> currFiles = currFolder.files;
                    int fileToDelIdx = currFiles
                        .indexWhere((file) => file.name == item.name.trim());
                    await dataManager
                        .deleteFile(currFiles[fileToDelIdx])
                        .then((s) {
                      if (context.mounted) reloadPage(context);
                    });
                  },
                ),
                ListTile(
                  // 修改名稱
                  title: Text("修改名稱"),
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("修改完成後請重新進入資料夾頁面"),
                    ));
                    Navigator.pop(context);
                    // 修改檔案
                    String? newFilename =
                        await _addItemScreen(context, "重新命名檔案", "檔案名稱");
                    if (newFilename != null) {
                      Folder currFolder = dataManager.getPageFolder();
                      List<Document> currFiles = currFolder.files;
                      int fileToRenameIdx = currFiles
                          .indexWhere((file) => file.name == item.name.trim());
                      if (fileToRenameIdx >= 0) {
                        await dataManager
                            .renameFile(currFiles[fileToRenameIdx], newFilename)
                            .then((s) {
                          if (context.mounted) reloadPage(context);
                        });
                      }
                    }
                  },
                ),
                ListTile(
                  title: Text("分割"),
                  onTap: () {
                    Navigator.pop(context);
                    reloadPage(context);
                    // TODO
                  },
                ),
              ],
            );
          },
        );
}

void showMergeOption(context, List<Document> filesToMerge) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Wrap(
        children: [
          ListTile(
            title: Text("合併"),
            onTap: () async {
              Navigator.pop(context);

              // TODO
            },
          ),
        ],
      );
    },
  );
}

// 頁面建立
class Pages extends StatefulWidget {
  final Widget child; // 子頁面內容
  final String pageName; // 頁面標題

  const Pages({super.key, required this.pageName, required this.child});

  @override
  Page createState() => Page();
}

// 點進資料夾的頁面模板
class Page extends State<Pages> {
  bool showAddOptions = false; // 控制新增檔案按鈕的顯示狀態

  // 模擬重新載入資料
  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 2)); // 模擬延遲
    setState(() {
      String currFolderName = dataManager.getPageFolder().name;

      if (dataManager.getPageFolder() != dataManager.homeFolder) {
        dataManager.popCurrPath();
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FolderPage(
              folderName: currFolderName,
            ),
          ),
        );
      } else {
        dataManager.clearCurrPath();
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return const HomePage();
          }),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(
        appBar: AppBar(
          title: Text(widget.pageName),
          automaticallyImplyLeading:
              (dataManager.getPageFolder() == dataManager.homeFolder)
                  ? false
                  : true,
          leading: (dataManager.getPageFolder() == dataManager.homeFolder)
              ? null
              : IconButton(
                  // 返回上一頁的按鈕
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    dataManager.popCurrPath();
                    Navigator.pop(context);
                  },
                ),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: Stack(
            children: [
              widget.child, // 子頁面內容
            ],
          ),
        ),

        // + 的按鈕
        floatingActionButton: Stack(
          alignment: Alignment.bottomRight,
          children: [
            FloatingActionButton(
              heroTag: "main_add",
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              backgroundColor:
                  showAddOptions ? Colors.grey.shade500 : Colors.blue,
              onPressed: () {
                setState(() {
                  showAddOptions = !showAddOptions; // 切換狀態
                });
              },
              child: Icon(
                showAddOptions ? Icons.close : Icons.add,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),

      // 背景半透明特效
      if (showAddOptions)
        GestureDetector(
          behavior: HitTestBehavior.opaque, // 確保捕捉空白點擊
          onTap: () {
            setState(() {
              showAddOptions = false;
            });
          },
          child: Container(
            color: Colors.black.withOpacity(0.5),
            // 覆蓋整個螢幕
            width: double.infinity,
            height: double.infinity,
          ),
        ),

      // 新增檔案的按鈕
      if (showAddOptions)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          bottom: 75,
          right: 16,
          width: 135,
          child: TextButton.icon(
            label: const Text('新增檔案', style: TextStyle(color: Colors.white)),
            icon: const Icon(
              Icons.note_add,
              color: Colors.white,
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            onPressed: () async {
              await pickAndConvertFile().then((s) {
                if (context.mounted) reloadPage(context);
              });
              setState(() {
                showAddOptions = false; // 點擊後收起按鈕
              });
            },
          ),
        ),

      // 新增資料夾的按鈕
      if (showAddOptions)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          bottom: 120,
          right: 16,
          width: 135,
          child: TextButton.icon(
            label: const Text('新增資料夾', style: TextStyle(color: Colors.white)),
            icon: const Icon(
              Icons.create_new_folder,
              color: Colors.white,
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            onPressed: () async {
              String? folderName =
                  await _addItemScreen(context, "新增資料夾", "資料夾名稱");
              if (folderName != null && folderName.trim().isNotEmpty) {
                dataManager
                    .addFolder(Folder(name: folderName.trim()))
                    .then((s) {
                  if (context.mounted) reloadPage(context);
                });
              }
              setState(() {
                showAddOptions = false; // 點擊後收起按鈕
              });
            },
          ),
        ),
    ]);
  }
}

// 點進資料夾的頁面
class FolderPage extends StatelessWidget {
  const FolderPage({
    super.key,
    required this.folderName,
  });
  final String folderName;
  @override
  Widget build(BuildContext context) {
    DataManager dataManager = DataManager();

    // 獲得新頁面路徑畫面的資料夾內容
    dataManager.addCurrPath(folderName);
    Folder currFolder = dataManager.getPageFolder();

    // 新增選取檔案的狀態管理器
    final ValueNotifier<Set<int>> selectedFiles = ValueNotifier<Set<int>>({});

    // 回傳子頁面內容
    return Pages(
      pageName: folderName,
      child: ValueListenableBuilder<Set<int>>(
          valueListenable: selectedFiles,
          builder: (context, selectedSet, child) {
            return ListView(
              children: [
                // 資料夾部分
                ...currFolder.folders.map((folder) => ListTile(
                      leading: const Icon(
                        Icons.folder,
                        color: Colors.orange,
                      ),
                      title: Text(folder.name),
                      onTap: () {
                        // 跳轉到點擊的資料夾頁面
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FolderPage(
                              folderName: folder.name,
                            ),
                          ),
                        );
                      },
                      onLongPress: () {
                        showMenu(context, folder);
                      },
                    )),

                // 檔案部分
                ...currFolder.files.asMap().entries.map((entry) {
                  int index = entry.key;
                  Document file = entry.value;

                  return GestureDetector(
                    onLongPress: () {
                      // 選取檔案
                      selectedFiles.value = selectedSet.contains(index)
                          ? {...selectedSet..remove(index)}
                          : {...selectedSet..add(index)};

                      if (selectedSet.contains(index)) {
                        List<Document> filesToMerge = [];
                        for (int selectIdx in selectedSet) {
                          filesToMerge.add(currFolder.files[selectIdx]);
                        }

                        selectedSet.length > 1
                            ? showMergeOption(context, filesToMerge)
                            : showMenu(context, file);
                      }
                    },
                    child: ListTile(
                      leading: Icon(
                        Icons.insert_drive_file,
                        color: Colors.red.shade900,
                      ),
                      title: Text(file.name),
                      trailing: selectedSet.contains(index)
                          ? const Icon(Icons.check_circle, color: Colors.blue)
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PdfViewPage(
                                    filePath: file.path,
                                    fileName: file.name,
                                  )),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("打開檔案：${file.name}"),
                        ));
                      },
                    ),
                  );
                }),
              ],
            );
          }),
    );
  }
}

// 主頁面
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    folderName,
  });
  final String folderName = "所有檔案";

  @override
  Widget build(BuildContext context) {
    DataManager dataManager = DataManager();

    // 獲得新頁面路徑畫面的資料夾內容
    Folder currFolder = dataManager.getPageFolder();

    // 新增選取檔案的狀態管理器
    final ValueNotifier<Set<int>> selectedFiles = ValueNotifier<Set<int>>({});

    // 回傳子頁面內容
    return Pages(
      pageName: folderName,
      child: ValueListenableBuilder<Set<int>>(
          valueListenable: selectedFiles,
          builder: (context, selectedSet, child) {
            return ListView(
              children: [
                // 資料夾部分
                ...currFolder.folders.map((folder) => ListTile(
                      leading: const Icon(
                        Icons.folder,
                        color: Colors.orange,
                      ),
                      title: Text(folder.name),
                      onTap: () {
                        // 跳轉到點擊的資料夾頁面
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FolderPage(
                              folderName: folder.name,
                            ),
                          ),
                        );
                      },
                      onLongPress: () {
                        showMenu(context, folder);
                      },
                    )),

                // 檔案部分
                ...currFolder.files.asMap().entries.map((entry) {
                  int index = entry.key;
                  Document file = entry.value;

                  return GestureDetector(
                    onLongPress: () {
                      // 選取檔案
                      selectedFiles.value = selectedSet.contains(index)
                          ? {...selectedSet..remove(index)}
                          : {...selectedSet..add(index)};

                      if (selectedSet.contains(index)) {
                        List<Document> filesToMerge = [];
                        for (int selectIdx in selectedSet) {
                          filesToMerge.add(currFolder.files[selectIdx]);
                        }

                        selectedSet.length > 1
                            ? showMergeOption(context, filesToMerge)
                            : showMenu(context, file);
                      }
                    },
                    child: ListTile(
                      leading: Icon(
                        Icons.insert_drive_file,
                        color: Colors.red.shade900,
                      ),
                      title: Text(file.name),
                      trailing: selectedSet.contains(index)
                          ? const Icon(Icons.check_circle, color: Colors.blue)
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PdfViewPage(
                                    filePath: file.path,
                                    fileName: file.name,
                                  )),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("打開檔案：${file.name}"),
                        ));
                      },
                    ),
                  );
                }),
              ],
            );
          }),
    );
  }
}
