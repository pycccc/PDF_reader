import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
  // PDF Viewer Controller: 用來控制 PDF 的放大縮小、搜尋等功能
  final PdfViewerController _pdfViewerController = PdfViewerController();
  // 儲存搜尋結果
  PdfTextSearchResult _searchResult = PdfTextSearchResult();

  // 用來暫存搜尋字串、輸入的縮放比例
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _zoomController = TextEditingController(text: "100"); // 預設 100%

  // 目前頁面上的 SnackBar
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _snackBar;

  // 當搜尋結束時 (找到幾個結果)
  void _onSearchComplete(PdfTextSearchResult result) {
    setState(() {
      _searchResult = result;
    });
    // 移除舊的提示
    _snackBar?.close();
    // 若有找到，顯示找到幾項
    if (result.totalInstanceCount > 0) {
      _snackBar = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("找到 ${result.totalInstanceCount} 項符合結果")),
      );
    } else {
      // 沒找到
      _snackBar = ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("找不到相符的文字")),
      );
    }
  }

  // 執行搜尋
  void _searchText() async {
    String keyword = _searchController.text.trim();
    if (keyword.isNotEmpty) {
      // 先清除之前的搜尋結果
      _searchResult.clear();
      // 進行搜尋
      PdfTextSearchResult result = await _pdfViewerController.searchText(
        keyword,
        // 匹配模式 (ex: caseSensitive, wholeWord, 等)
      );
      _onSearchComplete(result);
    }
  }

  // 顯示下一個搜尋結果
  void _searchNext() {
    if (_searchResult.hasResult) {
      _searchResult.nextInstance();
    }
  }

  // 顯示上一個搜尋結果
  void _searchPrevious() {
    if (_searchResult.hasResult) {
      _searchResult.previousInstance();
    }
  }

  // 變更縮放
  void _applyZoom() {
    // 嘗試把輸入框的值轉成 double
    String zoomInput = _zoomController.text.trim();
    double? zoomValue = double.tryParse(zoomInput);
    if (zoomValue != null && zoomValue > 0) {
      setState(() {
        // Syncfusion 的 zoomLevel = 1.0 代表 100%
        _pdfViewerController.zoomLevel = zoomValue / 100.0;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("請輸入有效的數字")),
      );
    }
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
          // 上方工具列
          Container(
            color: Colors.grey[300],
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                // 搜尋輸入框
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "搜尋文字...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _searchText,
                  icon: const Icon(Icons.search),
                  tooltip: "搜尋",
                ),
                const SizedBox(width: 8),

                // 上一個、下一個搜尋結果
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

                const SizedBox(width: 12),
              ],
            ),
          ),

          // PDF Viewer
          Expanded(
            child: SfPdfViewer.file(
              file,
              controller: _pdfViewerController,
              enableTextSelection: true, // 支援選取文字
              canShowScrollHead: true,   // 顯示滾動條
              canShowScrollStatus: true, // 顯示頁數
            ),
          ),

          // 下方工具列：放大/縮小、輸入縮放比例
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // 縮小按鈕
                IconButton(
                  onPressed: () {
                    // 目前 zoomLevel + step
                    double newZoom = (_pdfViewerController.zoomLevel - 0.1).clamp(0.1, 10.0);
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
                    double newZoom = (_pdfViewerController.zoomLevel + 0.1).clamp(0.1, 10.0);
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



// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'dart:io';
//
// class PDFViewerPage extends StatefulWidget {
//   final String filePath;
//
//   const PDFViewerPage({super.key, required this.filePath});
//
//   @override
//   State<PDFViewerPage> createState() => _PDFViewerPageState();
// }
//
// class _PDFViewerPageState extends State<PDFViewerPage> {
//   final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
//   final PdfViewerController _pdfViewerController = PdfViewerController();
//   double _zoomLevel = 1.0; // 縮放比例
//   final TextEditingController _zoomController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     _zoomController.text = '100'; // 預設縮放為100%
//   }
//
//   // 放大功能（顯示提示）
//   void _zoomIn() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('使用雙指手勢進行放大'),
//       ),
//     );
//   }
//
//   // 縮小功能（顯示提示）
//   void _zoomOut() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('使用雙指手勢進行縮小'),
//       ),
//     );
//   }
//
//   // 自訂縮放百分比（顯示提示）
//   void _setZoom(String value) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('無法透過程式設計調整縮放比例，請使用手勢進行縮放'),
//       ),
//     );
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('檢視 PDF'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search),
//             onPressed: () {
//               // 開啟 PDF Viewer 的內建搜尋功能
//               _pdfViewerKey.currentState?.openBookmarkView();
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // 放大/縮小控制
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.zoom_in),
//                 onPressed: _zoomIn,
//               ),
//               IconButton(
//                 icon: const Icon(Icons.zoom_out),
//                 onPressed: _zoomOut,
//               ),
//               SizedBox(
//                 width: 80,
//                 child: TextField(
//                   controller: _zoomController,
//                   keyboardType: TextInputType.number,
//                   decoration: const InputDecoration(
//                     labelText: '縮放 (%)',
//                   ),
//                   onSubmitted: _setZoom,
//                 ),
//               ),
//             ],
//           ),
//           // PDF 檢視器
//           Expanded(
//             child: SfPdfViewer.file(
//               File(widget.filePath),
//               key: _pdfViewerKey,
//               canShowScrollHead: true,
//               canShowScrollStatus: true,
//               canShowPaginationDialog: true,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
