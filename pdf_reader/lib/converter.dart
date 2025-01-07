import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import './data_manager.dart';

String convertURL = 'https://805c-140-117-177-206.ngrok-free.app/convert';

class Converter {
  late File file;
  DataManager datamanager = DataManager();

// constuctor
  Converter(File fileToConvert) {
    file = fileToConvert;
  }

// private:

  // 建立完整路徑
  Future<Directory> _getWholeDir() async {
    // 獲取應用文件目錄
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    List<String> currDirs = datamanager.currentPath;
    String wholeDir = '${appDocDir.path}/pdf_reader';
    for (var currDir in currDirs) {
      wholeDir += '/';
      wholeDir += currDir;
    }
    final Directory pdfReaderDir = Directory(wholeDir);
    if (!await pdfReaderDir.exists()) {
      await pdfReaderDir.create(recursive: true); // 遞迴建立資料夾
    }
    return pdfReaderDir;
  }

// public:

  Future<File> pdfToPdf(String filename) async {
    // 如果是 pdf，複製一份
    Directory pdfReaderDir = await _getWholeDir();
    File pdfFile = await file.copy('${pdfReaderDir.path}/$filename');
    return pdfFile;
  }

  Future<File> fileToPdf(String filename) async {
    final File fileToConvert = File(file.path);

    // 設置 API URL
    var url = Uri.parse(convertURL);
    var request = http.MultipartRequest('POST', url);

    // 添加檔案
    var multipartFile =
        await http.MultipartFile.fromPath('file', fileToConvert.path);
    request.files.add(multipartFile);

    // 發送請求
    var response = await request.send();

    //保存 PDF
    Directory pdfDir = await _getWholeDir();
    String pdfPath = '${pdfDir.path}/${filename.split('.').first}.pdf';

    // 儲存 PDF 到本地
    File savedPdfFile = File(pdfPath);

    // 檢查回應狀態
    if (response.statusCode == 200) {
      // API 返回的檔案流
      var pdf = await response.stream.toBytes();
      await savedPdfFile.writeAsBytes(pdf);
    } else {
      print('檔案上傳失敗，狀態碼：${response.statusCode}');
    }
    return savedPdfFile;
  }
}
