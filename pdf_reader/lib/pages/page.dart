import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/widgets.dart' as pdf_widgets;
import 'package:pdf/pdf.dart' as pdf_pdf;
import 'package:archive/archive_io.dart';
import 'dart:io';
import 'dart:typed_data';
import '../data_manager.dart';
import '../data_structure.dart';
import 'pdf_viewer.dart';

DataManager dataManager = DataManager();

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

// 建立 pdf_reader 資料夾並獲取路徑
Future<Directory> _getOrCreatePdfReaderDirectory() async {
  // 獲取應用文件目錄
  final Directory appDocDir = await getApplicationDocumentsDirectory();
  // 建立或獲取 `pdf_reader` 資料夾
  final Directory pdfReaderDir = Directory('${appDocDir.path}/pdf_reader');
  if (!await pdfReaderDir.exists()) {
    await pdfReaderDir.create(recursive: true); // 遞迴建立資料夾
  }
  return pdfReaderDir;
}

// 將選擇的 txt 檔案轉換為 PDF 並儲存
Future<File> convertTxtToPdf(File file, String originalName) async {
  // 讀取檔案內容
  String fileContent = await file.readAsString(); // 假設檔案為文字檔

  // 建立 PDF 文件
  final pdf = pdf_widgets.Document();
  pdf.addPage(
    pdf_widgets.Page(
      build: (context) =>
          pdf_widgets.Center(child: pdf_widgets.Text(fileContent)),
    ),
  );

  // 獲取 pdf_reader 資料夾
  Directory pdfDir = await _getOrCreatePdfReaderDirectory();
  String pdfPath = '${pdfDir.path}/${originalName.split('.').first}.pdf';

  // 儲存 PDF 到本地
  File savedPdfFile = File(pdfPath);
  await savedPdfFile.writeAsBytes(await pdf.save());

  return savedPdfFile;
}

List<pdf_widgets.TextSpan> _extractStyledTextFromDocumentXml(String xml) {
  final List<pdf_widgets.TextSpan> spans = [];

  // 匹配文字運行節點
  final RegExp runRegExp =
      RegExp(r'<w:r>(.*?)<\/w:r>', multiLine: true, dotAll: true);

  // 匹配文字內容
  final RegExp textRegExp = RegExp(r'<w:t[^>]*>(.*?)<\/w:t>', multiLine: true);

  // 匹配樣式
  final RegExp boldRegExp = RegExp(r'<w:b[^>]*\/>');
  final RegExp italicRegExp = RegExp(r'<w:i[^>]*\/>');
  final RegExp colorRegExp =
      RegExp(r'<w:color[^>]*w:val="([0-9A-Fa-f]{6})"[^>]*\/>');
  final RegExp sizeRegExp = RegExp(r'<w:sz[^>]*w:val="(\d+)"[^>]*\/>');

  for (final match in runRegExp.allMatches(xml)) {
    final String runContent = match.group(1)!;

    // 提取文字內容
    final String? text = textRegExp.firstMatch(runContent)?.group(1);

    if (text != null && text.isNotEmpty) {
      // 檢查樣式
      final bool isBold = boldRegExp.hasMatch(runContent);
      final bool isItalic = italicRegExp.hasMatch(runContent);
      final String? colorHex = colorRegExp.firstMatch(runContent)?.group(1);
      final String? sizeVal = sizeRegExp.firstMatch(runContent)?.group(1);

      // 構建文字樣式
      pdf_widgets.TextStyle textStyle = pdf_widgets.TextStyle(
        fontWeight: isBold
            ? pdf_widgets.FontWeight.bold
            : pdf_widgets.FontWeight.normal,
        fontStyle: isItalic
            ? pdf_widgets.FontStyle.italic
            : pdf_widgets.FontStyle.normal,
        color: colorHex != null
            ? pdf_pdf.PdfColor.fromHex(colorHex)
            : pdf_pdf.PdfColors.black,
        fontSize:
            sizeVal != null ? double.parse(sizeVal) / 2 : 12, // Word 字號需除以 2
      );

      // 添加文字到 TextSpan
      spans.add(pdf_widgets.TextSpan(text: text, style: textStyle));
    }
  }

  return spans;
}

Future<File?> convertDocxToPdf(File file, String originalName) async {
  try {
    // 1. 解壓 docx 文件
    final File docxFile = File(file.path);
    final Uint8List docxBytes = await docxFile.readAsBytes();
    final Archive archive = ZipDecoder().decodeBytes(docxBytes);

    // 提取 document.xml 和圖片
    String documentXml = '';
    final Map<String, Uint8List> images = {};
    for (final file in archive) {
      if (file.name == 'word/document.xml') {
        documentXml = String.fromCharCodes(file.content as List<int>);
      } else if (file.name.startsWith('word/media/')) {
        images[file.name] = Uint8List.fromList(file.content as List<int>);
      }
    }

    if (documentXml.isEmpty) {
      throw '無法找到 document.xml，請確認檔案格式是否正確';
    }

    // 2. 解析文字內容（簡單範例，需根據需求解析 XML）
    final List<pdf_widgets.TextSpan> styledText =
        _extractStyledTextFromDocumentXml(documentXml);

    // 3. 建立 PDF
    final pdf = pdf_widgets.Document();

    pdf.addPage(
      pdf_widgets.MultiPage(
        build: (context) {
          final widgets = <pdf_widgets.Widget>[];

          // 添加文字
          widgets.add(
            pdf_widgets.RichText(
              text: pdf_widgets.TextSpan(children: styledText),
            ),
          );

          // 添加圖片
          for (final entry in images.entries) {
            widgets.add(
              pdf_widgets.Padding(
                padding: const pdf_widgets.EdgeInsets.all(8.0),
                child: pdf_widgets.Image(pdf_widgets.MemoryImage(entry.value)),
              ),
            );
          }

          return widgets;
        },
      ),
    );

    // 4. 保存 PDF
    Directory pdfDir = await _getOrCreatePdfReaderDirectory();
    String pdfPath = '${pdfDir.path}/${originalName.split('.').first}.pdf';

    // 儲存 PDF 到本地
    File savedPdfFile = File(pdfPath);
    await savedPdfFile.writeAsBytes(await pdf.save());

    return savedPdfFile;
  } catch (e) {
    return null;
  }
}

// 打開檔案選擇器並轉換為 PDF
Future<String> pickAndConvertFile() async {
  try {
    // 打開檔案選擇器
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'pdf', 'docx', 'doc'],
    );
    if (result == null || result.files.single.path == null) {
      return "未選擇檔案或檔案路徑無效";
    }

    // 選取的檔案
    File selectedFile = File(result.files.single.path!);
    String originalName = result.files.single.name;
    String returnContext, newFileName, newFilePath;

    if (originalName.endsWith('.pdf')) {
      // 如果是 pdf，複製一份
      Directory pdfReaderDir = await _getOrCreatePdfReaderDirectory();
      File pdfFile =
          await selectedFile.copy('${pdfReaderDir.path}/$originalName');

      newFileName = originalName;
      newFilePath = pdfFile.path;

      returnContext = "PDF 檔案已儲存至：$newFilePath";
    } else if (originalName.endsWith('.txt')) {
      // 如果是 txt，轉換為 PDF
      File pdfFile = await convertTxtToPdf(selectedFile, originalName);

      newFileName = path.basename(pdfFile.path);
      newFilePath = pdfFile.path;

      returnContext = "文字檔已轉為 PDF，存放於：$newFilePath";
    } else if (originalName.endsWith('.docx') ||
        originalName.endsWith('.doc')) {
      File? pdfFile = await convertDocxToPdf(selectedFile, originalName);

      if (pdfFile == null) {
        print("檔案轉換失敗\n");
        return "檔案轉換失敗";
      }
      newFileName = path.basename(pdfFile.path);
      newFilePath = pdfFile.path;
      returnContext = "doc 檔已轉為 PDF，存放於：$newFilePath";
    } else {
      return "不支援的檔案格式";
    }
    // 存到本地
    dataManager.addFile(Document(name: newFileName, path: newFilePath));

    return "檔案已成功存放於：$returnContext";
  } catch (e) {
    return "轉換失敗：$e";
  }
}

// 顯示功能選單
void _showMenu(context, Data item) {
  bool isFolder = (item.type == "folder") ? true : false;

  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Wrap(
        children: [
          ListTile(
            title: Text("刪除"),
            onTap: () {
              Navigator.pop(context);
              // 執行刪除操作
              if (isFolder)
                ; // DeleteFolder();
              else
                ; // DeleteFile();
              // TODO
            },
          ),
          ListTile(
            title: Text("修改名稱"),
            onTap: () {
              Navigator.pop(context);
              // 執行修改名稱操作
              // TODO
            },
          ),
          ListTile(
            title: Text("移動"),
            onTap: () {
              Navigator.pop(context);
              // TODO
            },
          ),
        ],
      );
    },
  );
}

// 頁面建立
class Pages extends StatefulWidget {
  final Widget child; // 子頁面內容
  final String pageName; // 頁面標題

  const Pages({super.key, required this.pageName, required this.child});

  @override
  Page createState() => Page();
}

// 點進資料夾的頁面模板
class Page extends State<Pages> {
  bool showAddOptions = false; // 控制新增檔案按鈕的顯示狀態

  // 重新載入頁面
  void _reload() {
    String currFolderName = dataManager.getPageFolder().name;

    if (dataManager.getPageFolder() != dataManager.homeFolder) {
      dataManager.popCurrPath();
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FolderPage(
            folderName: currFolderName,
          ),
        ),
      );
    } else {
      dataManager.clearCurrPath();
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return const HomePage();
        }),
      );
    }
  }

  // 新增檔案
  void _addFile() async {
    await pickAndConvertFile().then((s) {
      _reload();
    });
  }

  // 新增資料夾
  void _addFolder(String folderName) {
    dataManager.addFolder(Folder(name: folderName));
    _reload();
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
              _addFile();
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
                onLongPress: () {
                  _showMenu(context, folder);
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PdfViewPage(
                              filePath: file.path,
                              fileName: file.name,
                            )),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("打開檔案：${file.name}"),
                  ));
                },
                onLongPress: () {
                  _showMenu(context, file);
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
                //       ),
                //     ),
                //   );
                // },
                onLongPress: () {
                  _showMenu(context, folder);
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PdfViewPage(
                              filePath: file.path,
                              fileName: file.name,
                            )),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("打開檔案：${file.name}"),
                  ));
                },
                onLongPress: () {
                  _showMenu(context, file);
                },
              )),
        ],
      ),
    );
  }
}
