import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'home.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  bool isLoaded = false;

  @override
  Widget build(BuildContext context) {
    return (Scaffold(
        backgroundColor: Colors.blue,
        body: GestureDetector(
            behavior: HitTestBehavior.opaque, // 確保捕捉空白點擊
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return const PageHome();
                }),
              );
            },
            child: Center(
              child: DefaultTextStyle(
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold),
                child: isLoaded
                    ? Text.rich(
                        // 動畫播完的顯示文字
                        TextSpan(
                          children: [
                            const TextSpan(text: "PDF Reader\n"),
                            TextSpan(
                              text: "點擊空白進入主頁面",
                              style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.grey.shade300,
                                  fontWeight: FontWeight.normal),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center, // 多行文字居中
                      )
                    : AnimatedTextKit(
                        // 開始動畫
                        animatedTexts: [
                          RotateAnimatedText('PDF Reader'),
                        ],
                        isRepeatingAnimation: false,
                        onFinished: () {
                          setState(() {
                            isLoaded = true;
                          });
                        },
                        onTap: () {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text("點擊空白進入主頁面"),
                          ));
                        },
                      ),
              ),
            ))));
  }
}
