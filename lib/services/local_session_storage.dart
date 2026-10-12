import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../models/judge_model.dart';

class LocalSessionData {
  final JudgeModel judge;
  final EventModel? selectedEvent;

  LocalSessionData({required this.judge, this.selectedEvent});
}

/// Persists the active Judge session locally on the device (Android & Windows)
/// so that if the app is closed or the device restarts while offline, the judge
/// remains logged in and can continue scoring using cached Firestore data.
class LocalSessionStorage {
  static final LocalSessionStorage _instance = LocalSessionStorage._internal();
  factory LocalSessionStorage() => _instance;
  LocalSessionStorage._internal();

  File? _getSessionFile() {
    if (kIsWeb) return null;
    try {
      final dir = Directory.systemTemp;
      return File('${dir.path}${Platform.pathSeparator}scoring_app_judge_session.json');
    } catch (_) {
      return null;
    }
  }

  Future<void> saveJudgeSession({
    required JudgeModel judge,
    EventModel? selectedEvent,
  }) async {
    final file = _getSessionFile();
    if (file == null) return;

    try {
      final Map<String, dynamic> payload = {
        'judge': {
          'id': judge.id,
          'judgeNumber': judge.judgeNumber,
          'accessCode': judge.accessCode,
          'name': judge.name,
          'isActive': judge.isActive,
          'createdAt': judge.createdAt.toIso8601String(),
        },
        if (selectedEvent != null)
          'selectedEvent': {
            'id': selectedEvent.id,
            'title': selectedEvent.title,
            'description': selectedEvent.description,
            'status': selectedEvent.status.name,
            'judgeCount': selectedEvent.judgeCount,
            'assignedJudgeIds': selectedEvent.assignedJudgeIds,
            'createdAt': selectedEvent.createdAt.toIso8601String(),
            if (selectedEvent.updatedAt != null)
              'updatedAt': selectedEvent.updatedAt!.toIso8601String(),
          },
      };
      await file.writeAsString(jsonEncode(payload), flush: true);
    } catch (_) {
      // Ignore file system errors gracefully
    }
  }

  Future<LocalSessionData?> loadJudgeSession() async {
    final file = _getSessionFile();
    if (file == null) return null;

    try {
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;

      final Map<String, dynamic> data = jsonDecode(content) as Map<String, dynamic>;
      final judgeMap = data['judge'] as Map<String, dynamic>?;
      if (judgeMap == null) return null;

      final judgeId = judgeMap['id'] as String? ?? '';
      if (judgeId.isEmpty) return null;

      final judge = JudgeModel.fromMap(judgeId, judgeMap);
      EventModel? selectedEvent;

      final eventMap = data['selectedEvent'] as Map<String, dynamic>?;
      if (eventMap != null) {
        final eventId = eventMap['id'] as String? ?? '';
        if (eventId.isNotEmpty) {
          selectedEvent = EventModel.fromMap(eventId, eventMap);
        }
      }

      return LocalSessionData(judge: judge, selectedEvent: selectedEvent);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearJudgeSession() async {
    final file = _getSessionFile();
    if (file == null) return;

    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore errors
    }
  }
}
