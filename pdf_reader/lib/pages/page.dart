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

Future<void> showSplitFileDialog(BuildContext context, Document file) async {
  TextEditingController startPageController = TextEditingController();
  TextEditingController endPageController = TextEditingController();
  TextEditingController outputFileNameController = TextEditingController();

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("分割檔案"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startPageController,
              decoration: InputDecoration(
                labelText: "從第幾頁 ",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: endPageController,
              decoration: InputDecoration(
                labelText: "到第幾頁",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: outputFileNameController,
              decoration: InputDecoration(
                labelText: "輸出文件名稱",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("取消"),
          ),
          ElevatedButton(
            onPressed: () async {
              final String startPageInput = startPageController.text.trim();
              final String endPageInput = endPageController.text.trim();
              final String outputFileName =
                  outputFileNameController.text.trim();

              if (startPageInput.isEmpty ||
                  endPageInput.isEmpty ||
                  outputFileName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("請完整填寫正確頁數範圍＆文件名稱")),
                );
                return;
              }

              // 解析頁数範圍
              int startPage;
              int endPage;
              try {
                startPage = int.parse(startPageInput);
                endPage = int.parse(endPageInput);

                if (startPage < 1 || endPage < startPage) {
                  throw Exception("無效的頁數範圍");
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("頁數範圍格式無效，請輸入有效的數字")),
                );
                return;
              }

              try {
                // 生成頁數範圍
                List<int> pageRanges = List.generate(
                    endPage - startPage + 1, (index) => startPage + index);
                await dataManager.splitFile(
                  File(file.path),
                  pageRanges,
                  outputFileName,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("分割成功: $outputFileName")),
                );
                Navigator.of(context).pop(); // 關閉對話框
                if (context.mounted) reloadPage(context); // 刷新頁面
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("分割失败: $e")),
                );
              }
            },
            child: const Text("分割"),
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
      allowedExtensions: ['txt', 'pdf', 'docx', 'pptx', 'xlsx', 'png'],
    );
    if (result == null || result.files.single.path == null) {
      return "未選擇檔案或檔案路徑無效";
    }

    // 選取的檔案
    File selectedFile = File(result.files.single.path!);
    String selectedName = result.files.single.name;

    File pdfFile;
    Converter converter = Converter(selectedFile);

    // 重複命名
    String newName = selectedName.split('.').first;
    Folder curr = dataManager.getPageFolder();
    int sameNameCnt = 0;
    for (var file in curr.files) {
      final regex = RegExp(r'^(.+?)\(\d+\)$');
      final match = regex.firstMatch(file.name.split('.').first);
      if (match?.group(1).toString() == newName ||
          file.name.split('.').first == newName) {
        sameNameCnt++;
      }
    }
    if (sameNameCnt > 0) {
      newName = '$newName($sameNameCnt)';
    }
    newName = '$newName.${selectedName.split('.').last}';

    // pdf to pdf
    if (selectedName.endsWith('.pdf')) {
      pdfFile = await converter.pdfToPdf(newName);
    }
    // others to pdf
    else {
      pdfFile = await converter.fileToPdf(newName);
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

// 建立資料夾選單項目
Widget buildFolderMenu(BuildContext context,
    {required IconData icon,
    required String label,
    required String value,
    required Data item}) {
  return GestureDetector(
    onTap: () async {
      Navigator.of(context).pop(); // 關閉選單
      switch (value) {
        case 'delete': // 刪除資料夾
          dataManager.deleteFolder(Folder(name: item.name.trim()));
          if (context.mounted) reloadPage(context);
          break;
        case 'rename': // 修改資料夾名稱
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("修改完成後請重新進入資料夾頁面"),
          ));

          String? newFolderName =
              await _addItemScreen(context, "重新命名資料夾", "資料夾名稱");
          if (newFolderName != null && newFolderName.trim().isNotEmpty) {
            dataManager
                .renameFolder(Folder(name: item.name.trim()), newFolderName)
                .then((s) {
              if (context.mounted) reloadPage(context);
            });
          }
          break;
      }
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 24, color: Colors.grey.shade600)],
      ),
    ),
  );
}

// 建立檔案選單項目
Widget buildFileMenu(BuildContext context,
    {required IconData icon,
    required String label,
    required String value,
    required Data item}) {
  return GestureDetector(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 24, color: Colors.grey.shade600)],
      ),
    ),
    onTap: () async {
      Navigator.of(context).pop(); // 關閉選單
      switch (value) {
        case 'delete': // 刪除檔案
          Folder currFolder = dataManager.getPageFolder();
          List<Document> currFiles = currFolder.files;
          int fileToDelIdx =
              currFiles.indexWhere((file) => file.name == item.name.trim());
          await dataManager.deleteFile(currFiles[fileToDelIdx]).then((s) {
            if (context.mounted) reloadPage(context);
          });
          break;
        case 'rename': // 修改檔案名稱
          String? newFilename = await _addItemScreen(context, "重新命名檔案", "檔案名稱");
          if (newFilename != null) {
            Folder currFolder = dataManager.getPageFolder();
            List<Document> currFiles = currFolder.files;
            int fileToRenameIdx =
                currFiles.indexWhere((file) => file.name == item.name.trim());
            if (fileToRenameIdx >= 0) {
              await dataManager
                  .renameFile(currFiles[fileToRenameIdx], newFilename)
                  .then((s) {
                if (context.mounted) reloadPage(context);
              });
            }
          }
          break;
        case 'divide': // 分割檔案
          await showSplitFileDialog(context, item as Document);
          break;
      }
    },
  );
}

// 建立合併項目
Widget buildMergeOption(BuildContext context,
    {required IconData icon,
    required String label,
    required String value,
    required List<File> filesToMerge}) {
  return GestureDetector(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: Colors.grey.shade600),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    ),
    onTap: () async {
      await dataManager.mergeFiles(filesToMerge);
      if (context.mounted) {
        String? newFilename = await _addItemScreen(context, "命名合併檔案", "檔案名稱");
        if (newFilename != null) {
          Folder currFolder = dataManager.getPageFolder();
          List<Document> currFiles = currFolder.files;
          int fileToRenameIdx =
              currFiles.indexWhere((file) => file.name == "mergedFile.pdf");
          if (fileToRenameIdx >= 0) {
            await dataManager
                .renameFile(currFiles[fileToRenameIdx], newFilename)
                .then((s) {
              if (context.mounted) reloadPage(context);
            });
          }
        }
      }
    },
  );
}

// 顯示功能清單
void showMenuSheet(context, Data item) async {
  bool isFolder = (item.type == "folder") ? true : false;

  await showDialog(
      context: context,
      barrierColor: const Color.fromARGB(20, 0, 0, 0),
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              child: Material(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isFolder)
                        buildFileMenu(context,
                            icon: Icons.border_horizontal,
                            label: '分割',
                            value: 'divide',
                            item: item),
                      isFolder
                          ? buildFolderMenu(context,
                              icon: Icons.delete,
                              label: "刪除",
                              value: 'delete',
                              item: item)
                          : buildFileMenu(context,
                              icon: Icons.delete,
                              label: "刪除",
                              value: 'delete',
                              item: item),
                      isFolder
                          ? buildFolderMenu(context,
                              icon: Icons.edit,
                              label: '修改名稱',
                              value: 'rename',
                              item: item)
                          : buildFileMenu(context,
                              icon: Icons.edit,
                              label: '修改名稱',
                              value: 'rename',
                              item: item),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      });
}

// 顯示合併清單
void showMergeOption(context, List<File> filesToMerge) async {
  await showDialog(
      context: context,
      barrierColor: const Color.fromARGB(20, 0, 0, 0),
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              child: Material(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildMergeOption(context,
                          icon: Icons.merge_type,
                          label: '合併',
                          value: 'merge',
                          filesToMerge: filesToMerge),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      });
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
        child: GestureDetector(
          // 當點擊空白區域時清空 selectedSet
          onTap: () {
            selectedFiles.value = {}; // 清空選擇集
          },
          child: ValueListenableBuilder<Set<int>>(
              valueListenable: selectedFiles,
              builder: (context, selectedSet, child) {
                return ListView(
                  children: [
                    // 資料夾部分
                    ...currFolder.folders.asMap().entries.map((entry) {
                      int index = entry.key;
                      Folder folder = entry.value;

                      return GestureDetector(
                          onLongPress: () {
                            if (selectedSet.contains(index) &&
                                selectedSet.length == 1) {
                              selectedFiles.value = selectedSet.contains(index)
                                  ? {...selectedSet..remove(index)}
                                  : {...selectedSet..add(index)};
                            } else {
                              selectedSet.clear();
                              selectedSet.add(index);
                              selectedFiles.value = {index};
                            }
                            if (selectedSet.contains(index)) {
                              showMenuSheet(context, folder);
                            }
                          },
                          child: ListTile(
                            leading: const Icon(
                              Icons.folder,
                              color: Colors.orange,
                            ),
                            trailing: selectedSet.contains(index)
                                ? const Icon(Icons.check_circle,
                                    color: Colors.blue)
                                : null,
                            title: Text(folder.name),
                            onTap: () {
                              // 跳轉到點擊的資料夾頁面
                              selectedFiles.value = {}; // 清空選擇集
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FolderPage(
                                    folderName: folder.name,
                                  ),
                                ),
                              );
                            },
                          ));
                    }),

                    // 檔案部分
                    ...currFolder.files.asMap().entries.map((entry) {
                      int index = entry.key + currFolder.folders.length;
                      Document file = entry.value;

                      return GestureDetector(
                        onLongPress: () {
                          // 選取檔案
                          selectedFiles.value = selectedSet.contains(index)
                              ? {...selectedSet..remove(index)}
                              : {...selectedSet..add(index)};

                          if (selectedSet.contains(index)) {
                            List<File> filesToMerge = [];
                            for (int selectIdx in selectedSet) {
                              if (selectIdx > currFolder.folders.length - 1) {
                                filesToMerge.add(File(currFolder
                                    .files[
                                        selectIdx - currFolder.folders.length]
                                    .path));
                              }
                            }

                            selectedSet.length > 1
                                ? showMergeOption(context, filesToMerge)
                                : showMenuSheet(context, file);
                          }
                        },
                        child: ListTile(
                          leading: Icon(
                            Icons.insert_drive_file,
                            color: Colors.red.shade900,
                          ),
                          title: Text(file.name),
                          trailing: selectedSet.contains(index)
                              ? const Icon(Icons.check_circle,
                                  color: Colors.blue)
                              : null,
                          onTap: () {
                            selectedFiles.value = {}; // 清空選擇集
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
        ));
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
        child: GestureDetector(
          // 當點擊空白區域時清空 selectedSet
          onTap: () {
            selectedFiles.value = {}; // 清空選擇集
          },
          child: ValueListenableBuilder<Set<int>>(
              valueListenable: selectedFiles,
              builder: (context, selectedSet, child) {
                return ListView(
                  children: [
                    // 資料夾部分
                    ...currFolder.folders.asMap().entries.map((entry) {
                      int index = entry.key;
                      Folder folder = entry.value;

                      return GestureDetector(
                          onLongPress: () {
                            if (selectedSet.contains(index) &&
                                selectedSet.length == 1) {
                              selectedFiles.value = selectedSet.contains(index)
                                  ? {...selectedSet..remove(index)}
                                  : {...selectedSet..add(index)};
                            } else {
                              selectedSet.clear();
                              selectedSet.add(index);
                              selectedFiles.value = {index};
                            }
                            if (selectedSet.contains(index)) {
                              showMenuSheet(context, folder);
                            }
                          },
                          child: ListTile(
                            leading: const Icon(
                              Icons.folder,
                              color: Colors.orange,
                            ),
                            trailing: selectedSet.contains(index)
                                ? const Icon(Icons.check_circle,
                                    color: Colors.blue)
                                : null,
                            title: Text(folder.name),
                            onTap: () {
                              selectedFiles.value = {}; // 清空選擇集
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
                          ));
                    }),

                    // 檔案部分
                    ...currFolder.files.asMap().entries.map((entry) {
                      int index = entry.key + currFolder.folders.length;
                      Document file = entry.value;

                      return GestureDetector(
                        onLongPress: () {
                          // 選取檔案
                          selectedFiles.value = selectedSet.contains(index)
                              ? {...selectedSet..remove(index)}
                              : {...selectedSet..add(index)};

                          if (selectedSet.contains(index)) {
                            List<File> filesToMerge = [];
                            for (int selectIdx in selectedSet) {
                              if (selectIdx > currFolder.folders.length - 1) {
                                filesToMerge.add(File(currFolder
                                    .files[
                                        selectIdx - currFolder.folders.length]
                                    .path));
                              }
                            }

                            selectedSet.length > 1
                                ? showMergeOption(context, filesToMerge)
                                : showMenuSheet(context, file);
                          }
                        },
                        child: ListTile(
                          leading: Icon(
                            Icons.insert_drive_file,
                            color: Colors.red.shade900,
                          ),
                          title: Text(file.name),
                          trailing: selectedSet.contains(index)
                              ? const Icon(Icons.check_circle,
                                  color: Colors.blue)
                              : null,
                          onTap: () {
                            selectedFiles.value = {}; // 清空選擇集
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
        ));
  }
}
