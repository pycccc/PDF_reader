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

// 顯示功能選單
void _showMenu(context, Data item) {
  bool isFolder = (item.type == "folder") ? true : false;

  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Wrap(
        children: [
          ListTile(
            title: Text("刪除"),
            onTap: () {
              Navigator.pop(context);
              // 執行刪除操作
              if (isFolder)
                ; // DeleteFolder();
              else
                ; // DeleteFile();
              // TODO
            },
          ),
          ListTile(
            title: Text("修改名稱"),
            onTap: () {
              Navigator.pop(context);
              // 執行修改名稱操作
              // TODO
            },
          ),
          ListTile(
            title: Text("移動"),
            onTap: () {
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

  // 重新載入頁面
  void _reload() {
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

  // 新增檔案
  void _addFile() async {
    await pickAndConvertFile().then((s) {
      _reload();
    });
  }

  // 新增資料夾
  void _addFolder(String folderName) {
    dataManager.addFolder(Folder(name: folderName));
    _reload();
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
        body: Stack(
          children: [
            widget.child, // 子頁面內容
          ],
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
              _addFile();
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
                _addFolder(folderName.trim());
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

    // 回傳子頁面內容
    return Pages(
      pageName: folderName,
      child: ListView(
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
                  _showMenu(context, folder);
                },
              )),

          // 檔案部分
          ...currFolder.files.map((file) => ListTile(
                leading: Icon(
                  Icons.insert_drive_file,
                  color: Colors.red.shade900,
                ),
                title: Text(file.name),
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
                onLongPress: () {
                  _showMenu(context, file);
                },
              )),
        ],
      ),
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

    // 回傳子頁面內容
    return Pages(
      pageName: folderName,
      child: ListView(
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
                //       ),
                //     ),
                //   );
                // },
                onLongPress: () {
                  _showMenu(context, folder);
                },
              )),

          // 檔案部分
          ...currFolder.files.map((file) => ListTile(
                leading: Icon(
                  Icons.insert_drive_file,
                  color: Colors.red.shade900,
                ),
                title: Text(file.name),
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
                onLongPress: () {
                  _showMenu(context, file);
                },
              )),
        ],
      ),
    );
  }
}
