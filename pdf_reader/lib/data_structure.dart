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
class File extends Data {
  int size; // 檔案大小（以 byte 為單位）

  File({
    required String name,
    required this.size,
  }) : super(name: name, type: "file");

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'size': size,
    };
  }

  static File fromJson(Map<String, dynamic> json) {
    return File(
      name: json['name'],
      size: json['size'],
    );
  }
}

// 定義資料夾類
class Folder extends Data {
  List<Folder> folders; // 資料夾內的內容（子資料夾）
  List<File> files; // 資料夾內的內容（檔案）

  Folder({
    required String name,
    List<Folder>? folders, // 可選參數
    List<File>? files, // 可選參數
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
    List<File> files = (json['files'] as List)
        .map((fileJson) => File.fromJson(fileJson))
        .toList();

    // 回傳 Folder 物件
    return Folder(
      name: name,
      folders: folders,
      files: files,
    );
  }
}
