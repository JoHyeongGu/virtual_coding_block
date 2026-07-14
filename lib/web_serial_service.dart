// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('navigator.serial')
external JSObject? get _serial;

class WebSerialService {
  JSObject? _port;
  JSObject? _reader;
  bool _isReading = false;

  final StreamController<List<int>> _dataStreamController =
      StreamController<List<int>>.broadcast();
  Stream<List<int>> get receivedDataStream => _dataStreamController.stream;

  Future<bool> requestPort() async {
    try {
      if (_serial == null) return false;
      final promise = _serial!.callMethod('requestPort'.toJS) as JSPromise;
      final result = await promise.toDart;
      return result != null;
    } catch (e) {
      return false;
    }
  }

  Future<List<JSObject>> getAccessiblePorts() async {
    try {
      if (_serial == null) return [];
      final promise = _serial!.callMethod('getPorts'.toJS) as JSPromise;
      final jsArray = await promise.toDart as JSArray;

      return List<JSObject>.generate(
        jsArray.length,
        (index) => jsArray.getProperty(index.toString().toJS) as JSObject,
      );
    } catch (e) {
      return [];
    }
  }

  Future<bool> openPort(JSObject port, {int baudRate = 115200}) async {
    try {
      final options = {'baudRate': baudRate}.jsify();
      final promise = port.callMethod('open'.toJS, options) as JSPromise;
      await promise.toDart;

      _port = port;
      _startReading();
      return true;
    } catch (e) {
      _port = null;
      return false;
    }
  }

  Future<void> sendData(List<int> data) async {
    if (_port == null) return;
    try {
      final writable = _port!.getProperty('writable'.toJS) as JSObject?;
      if (writable == null) return;

      final writer = writable.callMethod('getWriter'.toJS) as JSObject;
      final jsBytes = Uint8List.fromList(data).toJS;

      final writePromise =
          writer.callMethod('write'.toJS, jsBytes) as JSPromise;
      await writePromise.toDart;

      writer.callMethod('releaseLock'.toJS);
    } catch (e) {}
  }

  void _startReading() async {
    if (_port == null || _isReading) return;
    _isReading = true;

    try {
      while (_isReading && _port != null) {
        final readable = _port!.getProperty('readable'.toJS) as JSObject?;
        if (readable == null) break;

        _reader = readable.callMethod('getReader'.toJS) as JSObject;
        List<int> _buffer = [];

        while (_isReading) {
          final readPromise = _reader!.callMethod('read'.toJS) as JSPromise;
          final result = await readPromise.toDart as JSObject;

          final done = (result.getProperty('done'.toJS) as JSBoolean).toDart;
          if (done) break;

          final value = result.getProperty('value'.toJS) as JSUint8Array?;
          if (value != null) {
            _buffer.addAll(value.toDart);

            while (_buffer.contains(0x7E)) {
              int endIdx = _buffer.indexOf(0x7E);
              int startIdx = _buffer.lastIndexOf(0x7C, endIdx);

              if (startIdx != -1 && startIdx < endIdx) {
                List<int> packet = _buffer.sublist(startIdx, endIdx + 1);
                _dataStreamController.add(packet);
              }
              _buffer = _buffer.sublist(endIdx + 1);
            }
          }
        }
      }
    } catch (e) {
      _isReading = false;
    } finally {
      _closeReader();
    }
  }

  void _closeReader() {
    if (_reader != null) {
      try {
        _reader!.callMethod('releaseLock'.toJS);
      } catch (_) {}
      _reader = null;
    }
  }

  Future<void> closePort() async {
    _isReading = false;
    _closeReader();

    if (_port != null) {
      try {
        final promise = _port!.callMethod('close'.toJS) as JSPromise;
        await promise.toDart;
      } catch (e) {
        // Ignore
      } finally {
        _port = null;
      }
    }
  }
}
