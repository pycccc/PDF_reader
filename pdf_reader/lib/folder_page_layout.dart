import 'package:flutter/material.dart';
import 'data_structure.dart';

class Pages extends StatefulWidget {
  final Widget child; // 子頁面內容
  final String pageName; // 頁面標題
  final String pageType; // 頁面種類

  const Pages(
      {super.key,
      required this.pageName,
      required this.pageType,
      required this.child});

  @override
  Page createState() => Page();
}

class Page extends State<Pages> {
  List<Map<String, dynamic>> items = [];

  bool showAddFile = false; // 控制新增檔案按鈕的顯示狀態

  // 新增檔案
  void _addFile(String fileName) {
    setState(() {
      // TODO
      File newFile = File(name: fileName, size: 0);
      items.add({"name": fileName, "content": newFile});
    });
  }

  // 新增資料夾的彈跳視窗
  Future<String?> _addFileScreen(
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageName),
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
            heroTag: "add_file",
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            backgroundColor: Colors.blue.shade800,
            child: const Icon(
              Icons.note_add,
              color: Colors.white,
            ),
            onPressed: () async {
              String? fileName = await _addFileScreen(context, "新增檔案", "檔案名稱");
              if (fileName != null && fileName.trim().isNotEmpty) {
                _addFile(fileName.trim());
              }
              setState(() {
                // 點擊後收起按鈕
                showAddFile = false;
              });
            },
          ),
        ],
      ),
    );
  }
}
