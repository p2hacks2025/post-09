import 'user.dart';

//歩数データをバックエンドから取得する
String _formatDate(DateTime date) => date.toIso8601String().split('T').first;

class StepEntry {
  final String uuid;
  final String userUuid;
  final DateTime createdAt;
  final int step;
  final bool isStarted;
  final User? user;

  StepEntry({
    required this.uuid,
    required this.userUuid,
    required this.createdAt,
    required this.step,
    required this.isStarted,
    this.user,
  });

  factory StepEntry.fromJson(Map<String, dynamic> json) {
    return StepEntry(
      uuid: json['uuid'] as String,
      userUuid: json['user_uuid'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      step: json['step'] as int,
      isStarted: json['is_started'] as bool,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'user_uuid': userUuid,
      'created_at': createdAt.toIso8601String(),
      'step': step,
      'is_started': isStarted,
      if (user != null) 'user': user!.toJson(),
    };
  }
}

class StepCreateRequest {
  final String userUuid;
  final int step;
  final bool isStarted;
  final DateTime createdAt;

  StepCreateRequest({
    required this.userUuid,
    required this.step,
    required this.isStarted,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_uuid': userUuid,
      'step': step,
      'is_started': isStarted,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class StepUpdateRequest {
  final int? step;
  final bool? isStarted;

  StepUpdateRequest({this.step, this.isStarted});

  Map<String, dynamic> toJson() {
    return {
      if (step != null) 'step': step,
      if (isStarted != null) 'is_started': isStarted,
    };
  }
}

class LatestSessionSteps {
  final String userUuid;
  final String startUuid;
  final String stopUuid;
  final DateTime startedAt;
  final DateTime stoppedAt;
  final int steps;

  LatestSessionSteps({
    required this.userUuid,
    required this.startUuid,
    required this.stopUuid,
    required this.startedAt,
    required this.stoppedAt,
    required this.steps,
  });

  factory LatestSessionSteps.fromJson(Map<String, dynamic> json) {
    return LatestSessionSteps(
      userUuid: json['user_uuid'] as String,
      startUuid: json['start_uuid'] as String,
      stopUuid: json['stop_uuid'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      stoppedAt: DateTime.parse(json['stopped_at'] as String),
      steps: json['steps'] as int,
    );
  }
}

class DailyTotalSteps {
  final String userUuid;
  final int totalSteps;

  DailyTotalSteps({required this.userUuid, required this.totalSteps});

  factory DailyTotalSteps.fromJson(Map<String, dynamic> json) {
    return DailyTotalSteps(
      userUuid: json['user_uuid'] as String,
      totalSteps: json['total_steps'] as int,
    );
  }
}
