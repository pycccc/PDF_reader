abstract class Data {
  String name; // 名稱
  String type; // 類型: file or folder

  Data({
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toJson();
}

// 定義檔案類
class Document extends Data {
  String path;

  Document({
    required String name,
    required this.path,
  }) : super(name: name, type: "file");

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'path': path,
    };
  }

  static Document fromJson(Map<String, dynamic> json) {
    return Document(
      name: json['name'],
      path: json['path'],
    );
  }
}

// 定義資料夾類
class Folder extends Data {
  List<Folder> folders; // 資料夾內的內容（子資料夾）
  List<Document> files; // 資料夾內的內容（檔案）

  Folder({
    required String name,
    List<Folder>? folders, // 可選參數
    List<Document>? files, // 可選參數
  })  : folders = folders ?? [], // 如果未提供，初始化為空列表
        files = files ?? [], // 如果未提供，初始化為空列表
        super(name: name, type: "folder");

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'folders': folders.map((folder) => folder.toJson()).toList(),
      'files': files.map((file) => file.toJson()).toList(),
    };
  }

  static Folder fromJson(Map<String, dynamic> json) {
    String name = json['name'];

    List<Folder> folders = (json['folders'] as List)
        .map((folderJson) => Folder.fromJson(folderJson))
        .toList();

    // 解析資料夾中的檔案
    List<Document> files = (json['files'] as List)
        .map((fileJson) => Document.fromJson(fileJson))
        .toList();

    // 回傳 Folder 物件
    return Folder(
      name: name,
      folders: folders,
      files: files,
    );
  }
}
