import 'package:flutter/material.dart';
import '../data_structure.dart';
import 'folder.dart';

class PageHome extends StatefulWidget {
  const PageHome({super.key});

  @override
  HomePage createState() => HomePage();
}

// 主頁面
class HomePage extends State<PageHome> {
  List<dynamic> items = [];
  List<Map<String, dynamic>> folders = [];
  List<Map<String, dynamic>> files = [];

  bool showAddOptions = false; // 控制圓形按鈕的顯示狀態

  // 新增資料夾
  void _addFolder(String folderName) {
    Folder newFolder = Folder(name: folderName);
    setState(() {
      folders.add({"name": folderName, "content": newFolder});
    });
    // _saveData(); // 同步到本地端
  }

  // 新增檔案
  void _addFile(String fileName) {
    setState(() {
      // TODO
      File newFile = File(name: fileName, size: 0);
      files.add({"name": fileName, "content": newFile});
    });
    // _saveData(); // 同步到本地端
  }

  // 新增資料夾的彈跳視窗
  Future<String?> _createFolder(
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
          title: const Text('所有檔案'),
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: [
            ListView(
              children: [
                // 資料夾部分
                ...folders.map((item) => ListTile(
                      leading: const Icon(
                        Icons.folder,
                        color: Colors.orange,
                      ),
                      title: Text(item['name']),
                      onTap: () {
                        setState(() {
                          showAddOptions = false;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FolderPage(
                              folder: item['content'],
                            ),
                          ),
                        );
                      },
                    )),

                // 檔案部分
                ...files.map((item) => ListTile(
                      leading: Icon(
                        Icons.insert_drive_file,
                        color: Colors.red.shade900,
                      ),
                      title: Text(item['name']),
                      onTap: () {
                        // TODO
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("打開檔案：${item['name']}"),
                        ));
                      },
                    )),
              ],
            ),
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
              String? fileName = await _createFolder(context, "新增檔案", "檔案名稱");
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
                  await _createFolder(context, "新增資料夾", "資料夾名稱");
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
