// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class RoakbotIframePlatformImpl extends StatefulWidget {
  final double width;
  final double height;

  const RoakbotIframePlatformImpl({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  State<RoakbotIframePlatformImpl> createState() => _RoakbotIframePlatformImplState();
}

class _RoakbotIframePlatformImplState extends State<RoakbotIframePlatformImpl> {
  late final String _viewId;
  html.IFrameElement? _iframeElement;

  @override
  void initState() {
    super.initState();
    _viewId = 'roakbot-iframe-${DateTime.now().microsecondsSinceEpoch}';

    final iframe = html.IFrameElement()
      ..src = 'https://roakbot.web.app/widget?botId=bot_fc456356'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..style.borderRadius = '16px'
      ..setAttribute('frameborder', '0')
      ..setAttribute('allow', 'clipboard-write');

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int id) => iframe,
    );

    _iframeElement = iframe;
  }

  @override
  void dispose() {
    try {
      _iframeElement?.remove();
    } catch (_) {}
    _iframeElement = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}
