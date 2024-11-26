import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FileManagerScreen(),
    );
  }
}

class FileManagerScreen extends StatefulWidget {
  @override
  _FileManagerScreenState createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  List<Map<String, dynamic>> items = [];

  bool showAddOptions = false; // 控制圓形按鈕的顯示狀態

  void _addFolder(String folderName) {
    // TODO

    setState(() {
      items.add({"name": folderName, "type": "folder"});
    });
  }

  void _addFile(String fileName) {
    setState(() {
      items.add({"name": fileName, "type": "file"});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('所有檔案'),
      ),
      body: Stack(
        children: [
          Column(children: [
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: Icon(
                      item['type'] == 'folder'
                          ? Icons.folder
                          : Icons.insert_drive_file,
                      color: item['type'] == 'folder'
                          ? Colors.orange
                          : Colors.blue,
                    ),
                    title: Text(item['name']),
                    onTap: () {
                      if (item['type'] == 'folder') {
                        // TODO

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("打開資料夾：${item['name']}"),
                        ));
                      } else {
                        // TODO

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("打開檔案：${item['name']}"),
                        ));
                      }
                    },
                  );
                },
              ),
            ),
          ]),

          // 新增檔案的按鈕
          if (showAddOptions)
            AnimatedPositioned(
              duration: Duration(milliseconds: 200),
              bottom: 75,
              right: 16,
              width: 135,
              child: TextButton.icon(
                label: Text('新增檔案', style: TextStyle(color: Colors.white)),
                icon: Icon(
                  Icons.note_add,
                  color: Colors.white,
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: () async {
                  String? fileName =
                      await _showInputDialog(context, "新增檔案", "檔案名稱");
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
              duration: Duration(milliseconds: 200),
              bottom: 120,
              right: 16,
              width: 135,
              child: TextButton.icon(
                label: Text('新增資料夾', style: TextStyle(color: Colors.white)),
                icon: Icon(
                  Icons.create_new_folder,
                  color: Colors.white,
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: () async {
                  String? folderName =
                      await _showInputDialog(context, "新增資料夾", "資料夾名稱");
                  if (folderName != null && folderName.trim().isNotEmpty) {
                    _addFolder(folderName.trim());
                  }
                  setState(() {
                    showAddOptions = false; // 點擊後收起按鈕
                  });
                },
              ),
            ),
        ],
      ),

      // + 的按鈕
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          FloatingActionButton(
            heroTag: "main_add",
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            backgroundColor:
                showAddOptions ? Colors.grey.shade500 : Colors.grey.shade700,
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
    );
  }

  Future<String?> _showInputDialog(
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
              child: Text("取消"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(inputController.text);
              },
              child: Text("確認"),
            ),
          ],
        );
      },
    );
  }
}
