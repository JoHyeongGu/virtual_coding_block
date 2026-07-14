import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'web_serial_service.dart';
import 'package:flutter_inner_shadow/flutter_inner_shadow.dart';

class SerialDongle extends StatefulWidget {
  final Function(String) onLog;
  final Function(List<int>) onDataReceived;
  final Function(bool) onConnectionStatusChanged;

  const SerialDongle({
    super.key,
    required this.onLog,
    required this.onDataReceived,
    required this.onConnectionStatusChanged,
  });

  @override
  State<SerialDongle> createState() => SerialDongleState();
}

class SerialDongleState extends State<SerialDongle> {
  final WebSerialService _serialService = WebSerialService();
  StreamSubscription<List<int>>? _streamSubscription;
  bool _isConnected = false;
  bool _isConnectedText = false;

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _serialService.closePort();
    super.dispose();
  }

  Future<void> handleConnect() async {
    final bool isGranted = await _serialService.requestPort();
    if (!isGranted) {
      widget.onLog("안내: 포트 선택이 취소되었거나 권한이 없습니다.");
      return;
    }

    final List<JSObject> ports = await _serialService.getAccessiblePorts();
    if (ports.isEmpty) return;

    final JSObject targetPort = ports.last;
    final bool isOpened = await _serialService.openPort(
      targetPort,
      baudRate: 115200,
    );

    if (isOpened) {
      setState(() {
        _isConnectedText = true;
      });
      widget.onLog("시스템: 가상 시리얼 포트에 성공적으로 연결되었습니다.");

      _streamSubscription = _serialService.receivedDataStream.listen((data) {
        widget.onLog("수신 (Received): $data");
        widget.onDataReceived(data);
      });

      await Future.delayed(Duration(milliseconds: 500));
      setState(() {
        widget.onConnectionStatusChanged(true);
        _isConnected = true;
      });
    } else {
      widget.onLog("에러: 포트 연결에 실패했습니다.");
    }
  }

  Future<void> handleDisconnect() async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    await _serialService.closePort();
    setState(() {
      _isConnected = false;
      _isConnectedText = false;
    });
    widget.onConnectionStatusChanged(false);
    widget.onLog("시스템: 연결이 해제되었습니다.");
  }

  void sendData(List<int> data) {
    if (!_isConnected) return;
    _serialService.sendData(data);
    widget.onLog("송신 (Send): $data");
  }

  Widget _usbDeco(double width, double height) {
    return Container(
      width: width * 0.23,
      height: height * 0.75,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 3,
            offset: Offset(-1, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: height * 0.08,
        children: [
          InnerShadow(
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 0.1,
                offset: const Offset(2, 5),
              ),
            ],
            child: Container(
              color: Colors.white,
              width: width * 0.035,
              height: height * 0.2,
            ),
          ),
          Container(color: Colors.grey, width: double.infinity, height: 2),
          InnerShadow(
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 0.1,
                offset: const Offset(2, 5),
              ),
            ],
            child: Container(
              color: Colors.white,
              width: width * 0.035,
              height: height * 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectButton(double width, double height) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        vertical: height * 0.1,
        horizontal: width * 0.11,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: height * 0.1,
        vertical: height * 0.1,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Material(
        child: InkWell(
          onTap: _isConnected ? handleDisconnect : handleConnect,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: const Color.fromARGB(255, 1, 184, 175),
                  child: Center(
                    child: Text(
                      "Coding Block",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: height * 0.12,
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: Center(
                    child: _isConnectedText
                        ? Text(
                            "Connected",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: height * 0.2,
                            ),
                          )
                        : RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: height * 0.09,
                                color: Colors.black,
                              ),
                              children: const [
                                TextSpan(text: 'Serial Port: '),
                                TextSpan(
                                  text: "Disconnected",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: "\nClick HERE",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: ' for connection.'),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double height = size.height * 0.2;
    double width = height * 3;

    double centerTop = (size.height - height) / 2;
    double centerLeft = (size.width - width) / 2;

    double connectedTop = -(width * 0.42) - (height / 2) + (width / 2);
    double connectedLeft = -10 - (width / 2) + (height / 2);

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedPositioned(
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutQuart,
            top: _isConnected ? connectedTop : centerTop,
            left: _isConnected ? connectedLeft : centerLeft,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 500),
              scale: _isConnected ? 0.4 : 1.0,
              child: AnimatedRotation(
                turns: _isConnected ? -0.25 : 0,
                duration: const Duration(seconds: 1),
                curve: Curves.easeOutQuart,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: width * 0.7,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(5),
                            bottomLeft: Radius.circular(5),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                              offset: Offset(-1, 3),
                            ),
                          ],
                          border: const Border(
                            right: BorderSide(color: Colors.grey, width: 3.5),
                          ),
                        ),
                        child: InnerShadow(
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 0),
                            ),
                          ],
                          child: _connectButton(width, height),
                        ),
                      ),
                      _usbDeco(width, height),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
