import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pdf_widgets;
import 'package:pdf/pdf.dart' as pdf_pdf;
import 'package:archive/archive_io.dart';
import 'dart:typed_data';
import 'dart:io';
import './data_manager.dart';

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

  // 轉換 docx 格式
  List<pdf_widgets.TextSpan> _extractStyledTextFromDocumentXml(String xml) {
    final List<pdf_widgets.TextSpan> spans = [];

    // 匹配文字運行節點
    final RegExp runRegExp =
        RegExp(r'<w:r>(.*?)<\/w:r>', multiLine: true, dotAll: true);

    // 匹配文字內容
    final RegExp textRegExp =
        RegExp(r'<w:t[^>]*>(.*?)<\/w:t>', multiLine: true);

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
              sizeVal != null ? double.parse(sizeVal) / 2 : 14, // Word 字號需除以 2
        );

        // 添加文字到 TextSpan
        spans.add(pdf_widgets.TextSpan(text: text, style: textStyle));
      }
    }

    return spans;
  }

// public:

  Future<File> pdfToPdf(String filename) async {
    // 如果是 pdf，複製一份
    Directory pdfReaderDir = await _getWholeDir();
    File pdfFile = await file.copy('${pdfReaderDir.path}/$filename');
    return pdfFile;
  }

  Future<File> txtToPdf(String filename) async {
    // 讀取檔案內容
    String fileContent = await file.readAsString();

    // 建立 PDF 文件
    final pdf = pdf_widgets.Document();
    pdf.addPage(
      pdf_widgets.Page(
        build: (context) => pdf_widgets.Text(fileContent),
      ),
    );

    // 獲取 pdf_reader 資料夾
    Directory pdfDir = await _getWholeDir();
    String pdfPath = '${pdfDir.path}/${filename.split('.').first}.pdf';

    // 儲存 PDF 到本地
    File savedPdfFile = File(pdfPath);
    await savedPdfFile.writeAsBytes(await pdf.save());

    return savedPdfFile;
  }

  Future<File> docxToPdf(String filename) async {
    // 解壓 docx 文件
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
      throw '無法找到 document.xml';
    }

    // 解析文字內容
    final List<pdf_widgets.TextSpan> styledText =
        _extractStyledTextFromDocumentXml(documentXml);

    // 建立 PDF
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

    //保存 PDF
    Directory pdfDir = await _getWholeDir();
    String pdfPath = '${pdfDir.path}/${filename.split('.').first}.pdf';

    // 儲存 PDF 到本地
    File savedPdfFile = File(pdfPath);
    await savedPdfFile.writeAsBytes(await pdf.save());

    return savedPdfFile;
  }
}
