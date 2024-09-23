// ignore_for_file: unused_field, avoid_print, prefer_const_constructors

import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService {
  static const String _nominationStartKey = 'nomination_start_time';
  static const String _nominationEndKey = 'nomination_end_time';
  static const String _votingStartKey = 'voting_start_time';
  static const String _votingEndKey = 'voting_end_time';

  DateTime? _nominationStartTime;
  DateTime? _nominationEndTime;
  DateTime? _votingStartTime;
  DateTime? _votingEndTime;

  Future<Map<String, DateTime?>> loadNominationTimes() async {
    try {
      final response = await Supabase.instance.client
          .from('tbl_sessions')
          .select('session_nominationStart, session_nominationEnd')
          .eq('session_id', 1)
          .single();

      if (response.isNotEmpty) {
        return {
          'start': DateTime.tryParse(response['session_nominationStart'] ?? ''),
          'end': DateTime.tryParse(response['session_nominationEnd'] ?? ''),
        };
      } else {
        return {
          'start': null,
          'end': null,
        };
      }
    } catch (e) {
      print('Error loading nomination times: $e');
      return {'start': null, 'end': null};
    }
  }

  Future<Map<String, DateTime?>> loadVotingTimes() async {
    try {
      final response = await Supabase.instance.client
          .from('tbl_sessions')
          .select('session_votingStart, session_votingEnd')
          .eq('session_id', 1)
          .single();

      return {
        'start': DateTime.tryParse(response['session_votingStart'] ?? ''),
        'end': DateTime.tryParse(response['session_votingEnd'] ?? ''),
      };
    } catch (e) {
      print('Error loading voting times: $e');
      return {'start': null, 'end': null};
    }
  }

  Future<bool> isWithinNominationSession() async {
    final times = await loadNominationTimes();
    final now = DateTime.now().toUtc().add(Duration(hours: 8));
    final start = times['start'];
    final end = times['end'];

    final isWithin =
        start != null && end != null && now.isAfter(start) && now.isBefore(end);

    return isWithin;
  }

  Future<bool> isWithinVotingSession() async {
    final times = await loadVotingTimes();
    final now = DateTime.now().toUtc().add(Duration(hours: 8));
    final start = times['start'];
    final end = times['end'];

    final isWithin =
        start != null && end != null && now.isAfter(start) && now.isBefore(end);

    return isWithin;
  }
}
