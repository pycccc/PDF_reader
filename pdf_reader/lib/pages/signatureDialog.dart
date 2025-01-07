import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';

class SignatureDialog extends StatefulWidget {
  @override
  _SignatureDialogState createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _clearSignature() async {
    _signatureController.clear();
  }

  Future<void> _saveSignature() async {
    final Uint8List? signature = await _signatureController.toPngBytes();
    if (signature != null) {
      Navigator.of(context).pop(signature);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請完成您的簽名')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              '請在下方簽名',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            height: 200,
            color: Colors.grey[200],
            child: Signature(
              controller: _signatureController,
              backgroundColor: Colors.grey[200]!,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                onPressed: _clearSignature,
                child: const Text('清除'),
              ),
              TextButton(
                onPressed: _saveSignature,
                child: const Text('儲存'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
