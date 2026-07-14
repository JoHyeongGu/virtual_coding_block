import 'package:flutter/material.dart';
import 'blocks_view.dart';
import 'serial_dongle.dart';
import 'tutorial_virtual_port.dart';
import 'log_terminal.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        splashColor: Colors.teal.withValues(alpha: 0.3),
        highlightColor: Colors.grey.withValues(alpha: 0.2),
        hoverColor: Colors.blueGrey.withValues(alpha: 0.3),
      ),
      home: const Scaffold(body: MainFrame()),
    );
  }
}

class MainFrame extends StatefulWidget {
  const MainFrame({super.key});

  @override
  State<MainFrame> createState() => _MainFrameState();
}

class _MainFrameState extends State<MainFrame> {
  final GlobalKey<SerialDongleState> _serialKey = GlobalKey();
  final GlobalKey<LogTerminalState> _terminalKey = GlobalKey();
  final GlobalKey<BlocksViewState> _blocksKey = GlobalKey();

  bool _isConnected = false;
  bool _isTerminalOpen = false;

  void _handleLog(String message) {
    _terminalKey.currentState?.pushLog(message);
  }

  void _handleSend(List<int> data) {
    _serialKey.currentState?.sendData(data);
  }

  void _handleDataReceived(List<int> data) {
    _blocksKey.currentState?.handleIncomingData(data);
  }

  void _handleConnectionStatus(bool isConnected) {
    setState(() {
      _isConnected = isConnected;
    });
  }

  void _openTerminal() {
    setState(() {
      _isTerminalOpen = true;
    });
  }

  void _closeTerminal() {
    setState(() {
      _isTerminalOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final terminalHeight = screenHeight * 0.55;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 233, 187, 143),
      body: Stack(
        children: [
          Image.asset(
            "assets/wood_background.jpg",
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            fit: BoxFit.fill,
          ),
          BlocksView(
            key: _blocksKey,
            play: _isConnected,
            onSend: _handleSend,
            onOpenTerminal: _openTerminal,
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          SerialDongle(
            key: _serialKey,
            onLog: _handleLog,
            onDataReceived: _handleDataReceived,
            onConnectionStatusChanged: _handleConnectionStatus,
          ),

          Center(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.27,
                right: MediaQuery.of(context).size.width * 0.11,
              ),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return const TutorialVirtualPort();
                      },
                    );
                  },
                  child: const Text(
                    '연결할 수 있는 시리얼 포트는 어떻게 생성하나요?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isTerminalOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeTerminal,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.black.withValues(alpha: 0.4)),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuart,
            top: _isTerminalOpen ? 0 : -terminalHeight,
            left: 0,
            right: 0,
            height: terminalHeight,
            child: GestureDetector(
              onTap: () {},
              child: LogTerminal(
                key: _terminalKey,
                isConnected: _isConnected,
                isActive: _isTerminalOpen,
                onClose: _closeTerminal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
