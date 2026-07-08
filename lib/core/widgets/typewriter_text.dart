import 'dart:async';

import 'package:flutter/material.dart';

/// Reveals [text] one character at a time, like a typewriter.
class TypewriterText extends StatefulWidget {
  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.durationPerCharacter = const Duration(milliseconds: 35),
    this.repeat = false,
    this.pauseBeforeRepeat = const Duration(milliseconds: 800),
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Duration durationPerCharacter;
  final bool repeat;
  final Duration pauseBeforeRepeat;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  Timer? _typingTimer;
  Timer? _repeatTimer;
  int _visibleCharacterCount = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.repeat != widget.repeat ||
        oldWidget.durationPerCharacter != widget.durationPerCharacter ||
        oldWidget.pauseBeforeRepeat != widget.pauseBeforeRepeat) {
      _restartTyping();
    }
  }

  void _restartTyping() {
    _typingTimer?.cancel();
    _repeatTimer?.cancel();
    _visibleCharacterCount = 0;
    _startTyping();
  }

  void _startTyping() {
    if (widget.text.isEmpty) return;

    _typingTimer = Timer.periodic(widget.durationPerCharacter, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_visibleCharacterCount < widget.text.length) {
        setState(() => _visibleCharacterCount++);
        return;
      }

      timer.cancel();

      if (!widget.repeat) return;

      _repeatTimer?.cancel();
      _repeatTimer = Timer(widget.pauseBeforeRepeat, () {
        if (!mounted) return;
        setState(() => _visibleCharacterCount = 0);
        _startTyping();
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final end = _visibleCharacterCount.clamp(0, widget.text.length);
    return Text(
      widget.text.substring(0, end),
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}
