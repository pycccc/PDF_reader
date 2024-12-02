abstract class Data {
  String name; // 名稱
  String type; // 類型: 檔案or資料夾

  Data({
    required this.name,
    required this.type,
  });
}

/// 定義檔案類
class File extends Data {
  int size; // 檔案大小（以 byte 為單位）

  File({
    required String name,
    required this.size,
  }) : super(name: name, type: "file");
}

/// 定義資料夾類
class Folder extends Data {
  List<Data> content; // 資料夾內的內容（檔案和子資料夾）

  Folder({
    required String name,
    this.content = const [],
  }) : super(name: name, type: "folder");
}
