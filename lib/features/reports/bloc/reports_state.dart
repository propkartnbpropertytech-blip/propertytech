import 'package:equatable/equatable.dart';
import '../models/report_configuration.dart';
import '../models/report_data.dart';

abstract class ReportsState extends Equatable {
  final ReportConfiguration config;

  const ReportsState({required this.config});

  @override
  List<Object?> get props => [config];
}

class ReportsInitial extends ReportsState {
  const ReportsInitial({required super.config});
}

class ReportsLoading extends ReportsState {
  final ReportOverallData? previousData;

  const ReportsLoading({
    required super.config,
    this.previousData,
  });

  @override
  List<Object?> get props => [config, previousData];
}

class ReportsLoaded extends ReportsState {
  final ReportOverallData data;

  const ReportsLoaded({
    required super.config,
    required this.data,
  });

  @override
  List<Object?> get props => [config, data];
}

class ReportsError extends ReportsState {
  final String message;
  final ReportOverallData? previousData;

  const ReportsError({
    required super.config,
    required this.message,
    this.previousData,
  });

  @override
  List<Object?> get props => [config, message, previousData];
}
