import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class TutorialVirtualPort extends StatefulWidget {
  const TutorialVirtualPort({super.key});

  @override
  State<TutorialVirtualPort> createState() => _TutorialVirtualPortState();
}

class _TutorialVirtualPortState extends State<TutorialVirtualPort> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late TapGestureRecognizer _tapRecognizer;

  final List<Map<String, String>> _tutorialData = [
    {
      'image': 'assets/tuto_1.png',
      'desc': '1. [여기]를 눌러 가상 COM 포트 에뮬레이터(VSPE)를 설치합니다.',
    },
    {
      'image': 'assets/tuto_2.png',
      'desc':
          '2. VSPE 프로그램 실행 후, 라이선스 구매 권장 창이 뜨면,\nContinure (with limitations) 버튼을 클릭하거나 닫습니다.',
    },
    {
      'image': 'assets/tuto_3.png',
      'desc':
          '3. Device 목록을 우클릭하여 Create new device를 선택하거나,\n빨간 별 표시 아이콘이 그려져 있는 버튼을 클릭하여 새 장치를 생성합니다.',
    },
    {
      'image': 'assets/tuto_4.png',
      'desc':
          '4. Virtual Connector로 되어 있는 장치 타입을 Virutal Pair로 선택하고,\n다음 버튼을 클릭합니다.',
    },
    {
      'image': 'assets/tuto_5.png',
      'desc':
          '5. Unity와 연결할 수신용 Port 1과 현재 프로그램에서 사용할 송신용 Port 2를\n원하는 COM으로 선택 후 마침 버튼을 클릭합니다. (다른 COM과 중복 불가)',
    },
    {
      'image': 'assets/tuto_6.png',
      'desc':
          '6. 이제 장치관리자에서 생성된 가상 포트 한 쌍을 확인할 수 있습니다.\n서로 중복되지 않도록 하나는 현재 앱에서 연결,\n다른 하나는 Unity에서 연결하여 사용할 수 있습니다!',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tapRecognizer = TapGestureRecognizer()..onTap = _extractAndRunExe;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tapRecognizer.dispose();
    super.dispose();
  }

  Future<void> _extractAndRunExe() async {
    if (defaultTargetPlatform != TargetPlatform.windows) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: const Text(
              '현재 OS가 Windows가 아니어서 설치 프로그램을 실행할 수 없습니다. OS에 맞는 VSPE를 설치해주세요.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      return;
    }

    try {
      html.AnchorElement(href: 'assets/assets/SetupVSPE_64.msi')
        ..setAttribute('download', 'SetupVSPE_64.msi')
        ..click();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: const Text('다운로드 된 설치마법사를 실행하여 VSPE를 설치해주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('설치 파일을 다운로드할 수 없습니다: $e')));
      }
    }
  }

  Widget _buildDescriptionText(String text) {
    if (!text.contains('[여기]')) {
      return Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      );
    }

    final parts = text.split('[여기]');

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        children: [
          TextSpan(text: parts[0]),
          TextSpan(
            text: '여기',
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            recognizer: _tapRecognizer,
            mouseCursor: SystemMouseCursors.click,
          ),
          TextSpan(text: parts[1]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 450,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '가상 COM 포트 생성 가이드',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _tutorialData.length,
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset(_tutorialData[index]['image']!),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDescriptionText(_tutorialData[index]['desc']!),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _currentPage > 0
                      ? () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                      : null,
                  child: const Text('이전'),
                ),
                Row(
                  children: List.generate(
                    _tutorialData.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.blueAccent
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (_currentPage < _tutorialData.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(
                    _currentPage == _tutorialData.length - 1 ? '완료' : '다음',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
