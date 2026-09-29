export 'platform_notifier_stub.dart'
    if (dart.library.html) 'platform_notifier_web.dart'
    if (dart.library.io) 'platform_notifier_io.dart';
