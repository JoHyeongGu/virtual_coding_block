import 'dart:async';
import 'package:flutter/material.dart';

class LogTerminal extends StatefulWidget {
  final bool isConnected;
  final bool isActive;
  final VoidCallback onClose;

  const LogTerminal({
    super.key,
    required this.isConnected,
    required this.isActive,
    required this.onClose,
  });

  @override
  State<LogTerminal> createState() => LogTerminalState();
}

class LogTerminalState extends State<LogTerminal> {
  final List<String> _logs = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void pushLog(String message) {
    final timestamp = DateTime.now().toString().split(' ').last.substring(0, 8);
    if (mounted) {
      setState(() {
        _logs.add("[$timestamp] $message");
      });
      _scrollToBottom();
    }
  }

  @override
  void didUpdateWidget(covariant LogTerminal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 80), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              color: const Color(0xFF2D2D2D),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(
                    Icons.terminal,
                    color: Colors.greenAccent,
                    size: 20,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white70,
                    ),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.isActive
                  ? ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        Color logColor = Colors.white70;

                        if (log.contains("수신"))
                          logColor = const Color(0xFF4AF626);
                        if (log.contains("송신"))
                          logColor = const Color(0xFF00BFFF);
                        if (log.contains("시스템"))
                          logColor = const Color(0xFFFFD700);
                        if (log.contains("에러") || log.contains("안내"))
                          logColor = Colors.redAccent;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: Text(
                            log,
                            style: TextStyle(
                              color: logColor,
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        );
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
