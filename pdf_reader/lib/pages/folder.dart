import 'package:flutter/material.dart';
import '../data_manager.dart';
import '../data_structure.dart';
import '../page_layout.dart';

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
    dataManager.addCurrPath(folderName);
    Folder currFolder = dataManager.getPageFolder();

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
