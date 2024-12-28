import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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

  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  bool _isPdfLoaded = false;
  OverlayEntry? _overlayEntry; // 用於顯示翻譯結果
  String? _selectedText; // 選取的文字

  // ★ 1) 用來保存「搜尋到的文字清單」(忽略大小寫) ★
  List<String> _searchMatches = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _hideOverlay(); // 隱藏翻譯結果的 Overlay
    super.dispose();
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
    //
    // // 如果之前搜尋過，先清除舊結果
    // if (_searchResult.hasResult) {
    //   _searchResult.clear();
    // }
    _searchMatches.clear(); // 清空「匹配文字」清單

    try {
      // (A) 先透過 Syncfusion PDF Viewer 來搜尋並高亮顯示
      //     TextSearchOption.none 表示忽略大小寫的搜尋
      final result = await _pdfViewerController.searchText(
        keyword,
      );
      print(
          '搜尋結果: hasResult=${result.hasResult}, totalInstanceCount=${result.totalInstanceCount}');

      setState(() {
        _searchResult = result;
      });

      // (B) 額外自己打開 PDF，將所有「實際符合的字串」（忽略大小寫）存入 _searchMatches
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
  void _showOverlay(Rect? region, String text) {
    _hideOverlay(); // 隱藏舊的 Overlay

    final overlay = Overlay.of(context);
    if (region != null && overlay != null) {
      _overlayEntry = OverlayEntry(
        builder: (context) {
          return Positioned(
            top: region.bottom + 10, // 調整位置，顯示在功能表下方
            left: region.left,
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
                      _translateToChinese(text),
                      style: const TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _hideOverlay,
                      child: const Text("關閉",
                          style: TextStyle(color: Colors.blue)),
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
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  /// 模擬將選取的文字翻譯成中文
  String _translateToChinese(String text) {
    // 模擬翻譯，實際可以接 API，例如 Google 翻譯 API
    Map<String, String> mockTranslations = {
      "equipment": "設備",
      "flexibility": "靈活性",
      "security": "安全性",
    };

    // 如果有對應翻譯，返回中文，否則原樣返回
    return mockTranslations[text.toLowerCase()] ?? "翻譯後：$text";
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.filePath);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
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
              ],
            ),
          ),

          // 📄 PDF Viewer
          Expanded(
            child: SfPdfViewer.file(
              file,
              controller: _pdfViewerController,
              // 隱藏內建的文字選取功能表，但保留文字選取功能
              enableTextSelection: true,
              canShowTextSelectionMenu : false,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
                if (details.selectedText != null &&
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
