import 'package:flutter/material.dart';
import 'roakbot_iframe_view_stub.dart'
    if (dart.library.html) 'roakbot_iframe_view_web.dart';

class RoakbotIframeView extends StatelessWidget {
  final double width;
  final double height;

  const RoakbotIframeView({
    super.key,
    this.width = 400,
    this.height = 620,
  });

  @override
  Widget build(BuildContext context) {
    return RoakbotIframePlatformImpl(
      width: width,
      height: height,
    );
  }
}
