import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_reader/pages/google_translate.dart';
import 'package:flutter/services.dart';
import 'signatureDialog.dart';

class PdfViewPage extends StatefulWidget {
  final String filePath; // PDF 檔案的路徑
  final String fileName; // PDF 檔名

  const PdfViewPage({
    Key? key,
    required this.filePath,
    required this.fileName,
  }) : super(key: key);

  @override
  State<PdfViewPage> createState() => _PdfViewPageState();
}

class _PdfViewPageState extends State<PdfViewPage> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _zoomController =
      TextEditingController(text: "100");
  final GoogleTranslateService _translateService = GoogleTranslateService(
      'AIzaSyCKJegTPj-NDXtwvSNzExUkJkDurPCzMWs'); // 替換成你的金鑰

  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  bool _isPdfLoaded = false;
  OverlayEntry? _overlayEntry; // 用於顯示翻譯結果
  List<String> _searchMatches = []; // 用來保存「搜尋到的文字清單」(忽略大小寫)
  bool _isStickyNoteEnabled = false; // 追蹤 Sticky Note 的狀態
  File? _pdfFile; // 新增變數來存儲 PDF 檔案
  bool _isSignatureModeEnabled = false; // 控制簽名模式開關
  int _rotationAngle = 0; // 用於追踪旋轉角度 (0°, 90°, 180°, 270°)

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    _pdfFile = File(widget.filePath); // 初始化 _pdfFile
  }

  @override
  void dispose() {
    _saveAnnotations(); // Save annotations when leaving the screen
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _hideOverlay(); // 隱藏翻譯結果的 Overlay
    super.dispose();
  }

  /// 旋轉 PDF 並保存到本地
  Future<File> _rotatePdf(File inputPdf, int pageNumber, int angle) async {
    final PdfDocument document =
        PdfDocument(inputBytes: inputPdf.readAsBytesSync());
    // 找到指定頁面，計算新旋轉角度
    final PdfPage page = document.pages[pageNumber - 1];
    final currentRotation = page.rotation.index * 90;
    final newRotation = (currentRotation + angle) % 360;
    page.rotation = PdfPageRotateAngle.values[newRotation ~/ 90];
    final List<int> bytes = await document.save();
    document.dispose();
    await inputPdf.writeAsBytes(bytes);
    return inputPdf;
  }

  /// 按下旋轉按鈕時執行的邏輯
  void _rotateAndReloadPdf() async {
    try {
      final currentPage = _pdfViewerController.pageNumber; // 獲取當前頁面
      final rotatedFile =
          await _rotatePdf(_pdfFile!, currentPage, 90); // 旋轉 PDF
      setState(() {
        _pdfFile = rotatedFile; // 更新為最新的旋轉後文件
      });
      // 等待 Viewer 重新加載後跳轉回原頁面
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pdfViewerController.jumpToPage(currentPage);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("旋轉發生錯誤: $e")),
      );
    }
  }

  /// 搜尋功能
  Future<void> _searchText() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("請輸入搜尋關鍵字")),
      );
      return;
    }
    _searchMatches.clear(); // 清空「匹配文字」清單

    try {
      // 先透過 Syncfusion PDF Viewer 來搜尋並顯示
      //     TextSearchOption.none 表示忽略大小寫的搜尋
      final result = await _pdfViewerController.searchText(
        keyword,
      );
      print(
          '搜尋結果: hasResult=${result.hasResult}, totalInstanceCount=${result.totalInstanceCount}');
      setState(() {
        _searchResult = result;
      });
      // 額外自己打開 PDF，將所有「實際符合的字串」（忽略大小寫）存入 _searchMatches
      final fileBytes = await File(widget.filePath).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: fileBytes);

      final lowerKeyword = keyword.toLowerCase();
      for (int pageIndex = 0; pageIndex < document.pages.count; pageIndex++) {
        // 抓該頁的文字
        final pageText = PdfTextExtractor(document)
            .extractText(startPageIndex: pageIndex, endPageIndex: pageIndex);
        if (pageText == null) continue;

        final lowerPageText = pageText.toLowerCase();
        int startIndex = 0;
        while (true) {
          final foundIndex = lowerPageText.indexOf(lowerKeyword, startIndex);
          if (foundIndex == -1) {
            break;
          }
          // 截取出「實際匹配」的原字串
          final matchedText =
              pageText.substring(foundIndex, foundIndex + keyword.length);
          _searchMatches.add(matchedText);

          startIndex = foundIndex + keyword.length;
        }
      }

      // 根據 Syncfusion 回傳的筆數 or 自己搜到的清單做提示
      final foundCount = _searchMatches.length;
      if (foundCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("找到 $foundCount 項符合結果")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("找不到相符的文字")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("搜尋發生錯誤: $e")),
      );
    }
  }

  /// 顯示下一個搜尋結果
  void _searchNext() {
    if (_searchResult.hasResult) {
      _searchResult.nextInstance();
    }
  }

  /// 顯示上一個搜尋結果
  void _searchPrevious() {
    if (_searchResult.hasResult) {
      _searchResult.previousInstance();
    }
  }

  //消除上一次搜尋結果
  void _clearSearchHighlight() {
    if (_searchResult.hasResult) {
      _searchResult.clear(); // 清除搜尋結果的 Highlight
      setState(() {
        _searchMatches.clear(); // 清除匹配結果清單
      });
    }
  }

  //監聽搜尋框的變化
  void _onSearchTextChanged() {
    if (_searchController.text.trim().isEmpty) {
      _clearSearchHighlight();
    }
  }

  /// 變更縮放比例
  void _applyZoom() {
    final zoomInput = _zoomController.text.trim();
    final zoomValue = double.tryParse(zoomInput);
    if (zoomValue != null && zoomValue > 0) {
      setState(() {
        _pdfViewerController.zoomLevel = zoomValue / 100.0;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("請輸入有效的數字")),
      );
    }
  }

  /// 顯示翻譯結果的 Overlay
  void _showOverlay(Rect? region, String text) async {
    _hideOverlay(); // 隱藏舊的 Overlay

    final overlay = Overlay.of(context);
    if (overlay != null) {
      // 呼叫 Google Translate API 翻譯
      final translatedText =
          await _translateService.translate(text, 'zh-TW'); // 目標語言為中文
      if (_overlayEntry != null) return; // 防止完成后再次插入

      _overlayEntry = OverlayEntry(
        builder: (context) {
          return Positioned(
            bottom: 0, // 固定在底部，與屏幕底部留一點距離
            left: 0,
            right: 0,
            child: Material(
              elevation: 4,
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                constraints: const BoxConstraints(maxWidth: 200), // 限制最大寬度
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '翻譯結果',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      translatedText,
                      style: const TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 添加複製按鈕
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: translatedText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("已複製到剪貼板")),
                            );
                          },
                          icon: const Icon(Icons.copy, color: Colors.blue),
                          label: const Text(
                            "複製",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                        TextButton(
                          onPressed: _hideOverlay,
                          child: const Text("關閉",
                              style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      overlay.insert(_overlayEntry!);
    }
  }

  /// 隱藏翻譯結果的 Overlay
  void _hideOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove(); // 移除 OverlayEntry
      _overlayEntry = null; // 清空引用
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {}); // 刷新 Overlay 树
      });
    }
    return;
  }

  ///annotation note
  void _enableStickyNoteAnnotationMode() {
    // Enable the sticky note annotation mode.
    _pdfViewerController.annotationMode = PdfAnnotationMode.stickyNote;
    debugPrint('Sticky Note 模式啟用');
  }

  void disableAnnotationMode() {
    // Disable or deactivate the annotation mode.
    _pdfViewerController.annotationMode = PdfAnnotationMode.none;
    _saveAnnotations(); // Save annotations when exiting annotation mode
    debugPrint('Sticky Note 模式關閉');
  }

  Future<void> _saveAnnotations() async {
    try {
      final file = File(widget.filePath);
      final pdfBytes = await file.readAsBytes();

      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);

      // 匯出註解為 XFDF 格式
      final List<int> xfdfData = document.exportAnnotation(PdfAnnotationDataFormat.xfdf);

      // 儲存到 XFDF 檔案
      final File annotationFile = File('${widget.filePath}_annotations.xfdf');
      await annotationFile.writeAsBytes(xfdfData);

      // 儲存 PDF 文件
      final List<int> savedBytes = await document.save();
      await file.writeAsBytes(savedBytes);

      document.dispose();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已儲存標註.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving annotations: $e')),
      );
      debugPrint('❌ [Save Error] $e');
    }
  }
  /// 開啟/關閉簽名模式
  void _toggleSignatureMode() {
    setState(() {
      _isSignatureModeEnabled = !_isSignatureModeEnabled;
      if (_isSignatureModeEnabled) {
        // 關閉文字選取功能表和翻譯 Overlay
        _hideOverlay();
      } else {
        // 恢復正常狀態
        _pdfViewerController.annotationMode = PdfAnnotationMode.none;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSignatureModeEnabled ? '簽名模式已啟用' : '簽名模式已關閉',
        ),
      ),
    );
  }

  ///digital signature
  Future<void> _addSignature(Offset position) async {
    final Uint8List? signature = await showDialog(
      context: context,
      builder: (context) => SignatureDialog(),
    );

    if (signature != null) {
      try {
        final fileBytes = await File(widget.filePath).readAsBytes();
        final PdfDocument document = PdfDocument(inputBytes: fileBytes);
        final PdfPage page =
            document.pages[_pdfViewerController.pageNumber - 1];

        final PdfBitmap bitmap = PdfBitmap(signature);

        // 將點擊座標繪製到 PDF 中
        page.graphics.drawImage(
          bitmap,
          Rect.fromLTWH(position.dx, position.dy, 200, 100),
        );

        final outputDir = await getApplicationDocumentsDirectory();
        final outputPath = '${outputDir.path}/output_with_signature.pdf';
        final savedBytes = await document.save();
        await File(outputPath).writeAsBytes(savedBytes);
        document.dispose();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('簽名已儲存')),
        );

        setState(() {
          _pdfFile = File(outputPath);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('儲存簽名失敗: $e')),
        );
      }
    }
  }

  void _showSignatureContextMenu(Rect? region) {
    if (region == null) return;

    _hideOverlay();

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: region.bottom,
          left: region.left,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 200, // 指定固定寬度
              constraints: BoxConstraints(
                maxWidth: 200,
                minWidth: 100,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [BoxShadow(blurRadius: 4, color: Colors.grey)],
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('新增簽名'),
                    onTap: () {
                      _addSignature(Offset(region.left, region.top));
                      _hideOverlay();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.close),
                    title: Text('關閉'),
                    onTap: _hideOverlay,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }
  /// 清除所有註解、便利貼和簽名
  void _clearAnnotations() async {
    try {
      final outputDir = await getApplicationDocumentsDirectory();
      final outputPath = '${outputDir.path}/output_with_annotations.pdf';
      final file = File(outputPath);

      if (await file.exists()) {
        setState(() {
          _pdfFile = file;
        });

        // 強制刷新 PDF 檢視器
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewPage(
              filePath: outputPath,
              fileName: 'output_with_annotations.pdf',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('清除註解時發生錯誤: $e')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final file = File(widget.filePath);

    return Scaffold(
      appBar: AppBar(title: Text(widget.fileName), actions: [
        IconButton(
          icon: const Icon(Icons.save),
          tooltip: '儲存註解',
          onPressed: _saveAnnotations,
        ),
        IconButton(
          icon: const Icon(Icons.delete_forever),
          tooltip: '清除所有註解',
          onPressed: _clearAnnotations,
        ),
        IconButton(
          icon: Icon(
            _isStickyNoteEnabled ? Icons.note : Icons.note_add,
            color: _isStickyNoteEnabled ? Colors.blue : Colors.grey,
          ),
          tooltip: _isStickyNoteEnabled ? '關閉便利貼模式' : '啟用便利貼模式',
          onPressed: () {
            setState(() {
              if (_isStickyNoteEnabled) {
                // 如果目前已啟用，則停用
                disableAnnotationMode();
                _isStickyNoteEnabled = false;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('便利貼模式已關閉')),
                );
              } else {
                // 如果目前未啟用，則啟用
                _enableStickyNoteAnnotationMode();
                _isStickyNoteEnabled = true;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('便利貼模式已啟用')),
                );
              }
            });
          },
        ),
        IconButton(
          icon: Icon(
            _isSignatureModeEnabled ? Icons.edit : Icons.edit_off,
            color: _isSignatureModeEnabled ? Colors.blue : Colors.grey,
          ),
          tooltip: _isSignatureModeEnabled ? '關閉簽名模式' : '啟用簽名模式',
          onPressed: _toggleSignatureMode,
        ),
      ]),
      body: Column(
        children: [
          // 🔍 搜尋工具列
          Container(
            color: Colors.grey[300],
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "搜尋文字...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isPdfLoaded ? _searchText : null,
                  icon: const Icon(Icons.search),
                  tooltip: "搜尋",
                ),
                IconButton(
                  onPressed: _searchPrevious,
                  icon: const Icon(Icons.arrow_upward),
                  tooltip: "上一個結果",
                ),
                IconButton(
                  onPressed: _searchNext,
                  icon: const Icon(Icons.arrow_downward),
                  tooltip: "下一個結果",
                ),
                IconButton(
                  icon: const Icon(Icons.rotate_right),
                  onPressed: _rotateAndReloadPdf,
                  tooltip: "旋轉頁面",
                ),
              ],
            ),
          ),

          // 📄 PDF Viewer
          Expanded(
            child: SfPdfViewer.file(
              //file,
              _pdfFile ?? File(widget.filePath),
              controller: _pdfViewerController,
              // 隱藏內建的文字選取功能表，但保留文字選取功能
              enableTextSelection: true,
              canShowTextSelectionMenu: !_isSignatureModeEnabled, // 根據簽名模式動態控制
              canShowScrollHead: true,
              canShowScrollStatus: true,
              onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
                if (_isSignatureModeEnabled) {
                  // 在簽名模式中，僅顯示簽名選單
                  _showSignatureContextMenu(details.globalSelectedRegion);
                } else if (details.selectedText != null &&
                    details.selectedText!.trim().isNotEmpty) {
                  _showOverlay(
                      details.globalSelectedRegion, details.selectedText!);
                } else {
                  _hideOverlay();
                }
              },

              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                setState(() {
                  _isPdfLoaded = true;
                });
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("PDF 載入失敗: ${details.error}")),
                );
              },
            ),
          ),

          // 🔍 縮放工具列
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // 縮小按鈕
                IconButton(
                  onPressed: () {
                    double newZoom =
                        (_pdfViewerController.zoomLevel - 0.1).clamp(0.1, 10.0);
                    setState(() {
                      _pdfViewerController.zoomLevel = newZoom;
                      _zoomController.text = (newZoom * 100).toStringAsFixed(0);
                    });
                  },
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _zoomController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.all(6),
                      suffixText: "%",
                    ),
                    onSubmitted: (_) => _applyZoom(),
                  ),
                ),
                IconButton(
                  onPressed: _applyZoom,
                  icon: const Icon(Icons.check),
                ),
                // 放大按鈕
                IconButton(
                  onPressed: () {
                    double newZoom =
                        (_pdfViewerController.zoomLevel + 0.1).clamp(0.1, 10.0);
                    setState(() {
                      _pdfViewerController.zoomLevel = newZoom;
                      _zoomController.text = (newZoom * 100).toStringAsFixed(0);
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
                const SizedBox(width: 8),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
