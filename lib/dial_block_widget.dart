import 'package:flutter/material.dart';
import 'blocks_view.dart';

class DialBlockWidget extends StatefulWidget {
  final PlacedBlock? placedBlock;
  final ValueChanged<bool> onFocusChanged;
  const DialBlockWidget({
    super.key,
    this.placedBlock,
    required this.onFocusChanged,
  });

  @override
  State<DialBlockWidget> createState() => DialBlockWidgetState();
}

class DialBlockWidgetState extends State<DialBlockWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    if (widget.placedBlock != null && widget.placedBlock!.dialInput == '1') {
      widget.placedBlock!.dialInput = '01';
    }
    _controller = TextEditingController(
      text: widget.placedBlock?.dialInput ?? '01',
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _refreshControllerText();
  }

  void _onFocusChange() {
    widget.onFocusChanged(_focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      Future.microtask(() {
        if (mounted) {
          _controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controller.text.length,
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant DialBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.placedBlock != oldWidget.placedBlock) {
      if (widget.placedBlock != null && widget.placedBlock!.dialInput == '1') {
        widget.placedBlock!.dialInput = '01';
      }
      _controller.text = widget.placedBlock?.dialInput ?? '01';
      _refreshControllerText();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggleDecimal() {
    if (widget.placedBlock == null) return;
    setState(() {
      widget.placedBlock!.isDecimal = !widget.placedBlock!.isDecimal;
      _refreshControllerText();
    });
  }

  void _refreshControllerText() {
    if (widget.placedBlock == null) return;
    String raw = widget.placedBlock!.dialInput;
    if (widget.placedBlock!.isDecimal) {
      _controller.text = '${raw[0]}.${raw[1]}';
    } else {
      _controller.text = raw;
    }
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 5,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: _toggleDecimal,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(
          width: 25,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              if (widget.placedBlock == null) return;

              String digits = value.replaceAll(RegExp(r'[^0-9]'), '');

              if (digits.length > 2) {
                digits = digits.substring(digits.length - 2);
              }

              digits = digits.padLeft(2, '0');
              widget.placedBlock!.dialInput = digits;

              String formatted = widget.placedBlock!.isDecimal
                  ? '${digits[0]}.${digits[1]}'
                  : digits;

              if (_controller.text != formatted) {
                _controller.text = formatted;
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
