import 'package:flutter/material.dart';
import '../data_manager.dart';
import '../data_structure.dart';

class Pages extends StatefulWidget {
  final Widget child; // 子頁面內容
  final String pageName; // 頁面標題

  const Pages({super.key, required this.pageName, required this.child});

  @override
  Page createState() => Page();
}

// 點進資料夾的頁面模板
class Page extends State<Pages> {
  DataManager dataManager = DataManager();

  bool showAddOptions = false; // 控制新增檔案按鈕的顯示狀態

  // 重新載入頁面
  void _reload() {
    String currFolderName = dataManager.getPageFolder().name;
    dataManager.popCurrPath();
    Navigator.pop(context);

    if (dataManager.getPageFolder() != dataManager.homeFolder) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            folderName: currFolderName,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return const HomePage();
        }),
      );
    }
  }

  // 新增檔案
  void _addFile(String fileName) {
    dataManager.addFile(File(name: fileName, size: 0));
    _reload();
  }

  // 新增資料夾
  void _addFolder(String folderName) {
    dataManager.addFolder(Folder(name: folderName));
    _reload();
  }

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
              // TODO
              String? fileName = await _addItemScreen(context, "新增檔案", "檔案名稱");
              if (fileName != null && fileName.trim().isNotEmpty) {
                _addFile(fileName.trim());
              }
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
              )),

          // 檔案部分
          ...currFolder.files.map((file) => ListTile(
                leading: Icon(
                  Icons.insert_drive_file,
                  color: Colors.red.shade900,
                ),
                title: Text(file.name),
                onTap: () {
                  // TODO
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("打開檔案：${file.name}"),
                  ));
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
              )),

          // 檔案部分
          ...currFolder.files.map((file) => ListTile(
                leading: Icon(
                  Icons.insert_drive_file,
                  color: Colors.red.shade900,
                ),
                title: Text(file.name),
                onTap: () {
                  // TODO
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("打開檔案：${file.name}"),
                  ));
                },
              )),
        ],
      ),
    );
  }
}
