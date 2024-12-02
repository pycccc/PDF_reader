import 'package:flutter/material.dart';
import '../data_structure.dart';
import '../folder_page_layout.dart';

// 點進資料夾的頁面
class FolderPage extends StatelessWidget {
  const FolderPage({
    super.key,
    required this.folder,
  });
  final Folder folder;

  @override
  Widget build(BuildContext context) {
    String folderName = folder.name;
    List items = folder.content;

    return Pages(
      pageName: folderName,
      pageType: "folderContent",
      child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              leading: Icon(
                item['content'].type = Icons.insert_drive_file,
                color: item['content'].type = Colors.red.shade900,
              ),
              title: Text(folderName),
              onTap: () {
                // TODO
              },
            );
          }),
    );
  }
}
