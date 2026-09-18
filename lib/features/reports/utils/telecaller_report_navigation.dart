import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/reports_bloc.dart';
import '../bloc/reports_event.dart';

class TelecallerReportNavigation {
  static const path = '/reports/leads/telecaller';

  static String location({String? userId, String? userName}) {
    final params = <String, String>{};
    if (userId != null && userId.isNotEmpty) params['userId'] = userId;
    if (userName != null && userName.isNotEmpty) params['userName'] = userName;
    return Uri(path: path, queryParameters: params.isEmpty ? null : params).toString();
  }

  static void open(
    BuildContext context, {
    required String userId,
    required String userName,
  }) {
    try {
      context.read<ReportsBloc>().add(
            SelectTelecallerSubjectEvent(userId: userId, userName: userName),
          );
    } catch (_) {}
    context.go(location(userId: userId, userName: userName));
  }
}
