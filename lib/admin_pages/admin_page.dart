// ignore_for_file: avoid_print, prefer_const_constructors, unused_field, library_private_types_in_public_api, use_key_in_widget_constructors, prefer_const_constructors_in_immutables, use_super_parameters

import 'package:cite_spotlight/admin_pages/display_page.dart';
import 'package:cite_spotlight/session/session_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final SessionService _sessionService = SessionService();
  DateTime? _nominationStartTime;
  DateTime? _nominationEndTime;
  DateTime? _votingStartTime;
  DateTime? _votingEndTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadNominationTimes();
    _loadVotingTimes();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadNominationTimes() async {
    final times = await _sessionService.loadNominationTimes();
    setState(() {
      _nominationStartTime = times['start'];
      _nominationEndTime = times['end'];
    });
  }

  Future<void> _loadVotingTimes() async {
    final times = await _sessionService.loadVotingTimes();
    setState(() {
      _votingStartTime = times['start'];
      _votingEndTime = times['end'];
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _startNominationSession() async {
    final now = DateTime.now();
    final endTime = now.add(Duration(minutes: 15));
    Map<String, dynamic> data = {
      'session_nominationStart': now.toIso8601String(),
      'session_nominationEnd': endTime.toIso8601String(),
    };

    try {
      final response = await Supabase.instance.client
          .from('tbl_sessions')
          .update(data)
          .eq('session_id', 1); // Update the row where id is 1
      if (response == null) {
        setState(() {
          _nominationStartTime = now;
          _nominationEndTime = endTime;
        });
        _startTimer();
        _showErrorSnackBar('Nomination is now starting.');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e.');
    }
  }

  Future<void> _startVotingSession() async {
    final now = DateTime.now();
    final endTime = now.add(Duration(minutes: 45));
    Map<String, dynamic> data = {
      'session_votingStart': now.toIso8601String(),
      'session_votingEnd': endTime.toIso8601String(),
    };

    try {
      final response = await Supabase.instance.client
          .from('tbl_sessions')
          .update(data)
          .eq('session_id', 1);
      if (response == null) {
        setState(() {
          _votingStartTime = now;
          _votingEndTime = endTime;
        });
        _startTimer();
        _showErrorSnackBar('Voting is now starting.');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e.');
    }
  }

  Future<void> _endNominationSession() async {
    Map<String, dynamic> data = {
      'session_nominationStart': null,
      'session_nominationEnd': null,
    };

    try {
      final response = await Supabase.instance.client
          .from('tbl_sessions')
          .update(data)
          .eq('session_id', 1);
      if (response == null) {
        setState(() {
          _nominationStartTime = null;
          _nominationEndTime = null;
        });
        _startTimer();
        _showErrorSnackBar('Nomination has ended.');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e.');
    }
  }

  Future<void> _endVotingSession() async {
    Map<String, dynamic> data = {
      'session_votingStart': null, // Updated key
      'session_votingEnd': null, // Updated key
    };

    try {
      final response = await Supabase.instance.client
          .from('tbl_sessions')
          .update(data)
          .eq('session_id', 1); // Update the row where id is 1
      if (response == null) {
        setState(() {
          _votingStartTime = null;
          _votingEndTime = null;
        });
        _startTimer();
        _showErrorSnackBar('Voting has now ended.');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e.');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }

      if ((_nominationEndTime == null ||
              DateTime.now().isAfter(_nominationEndTime!)) &&
          (_votingEndTime == null || DateTime.now().isAfter(_votingEndTime!))) {
        timer.cancel();
      }

      setState(() {});
    });
  }

  String _getNominationRemainingTime() {
    if (_nominationEndTime == null) return "No Session";

    final now = DateTime.now();
    final difference = _nominationEndTime!.difference(now);

    if (difference.isNegative) {
      _endNominationSession();
      return "Session Ended";
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getVotingRemainingTime() {
    if (_votingEndTime == null) return "No Session";

    final now = DateTime.now();
    final difference = _votingEndTime!.difference(now);

    if (difference.isNegative) {
      _endVotingSession();
      return "Session Ended";
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text('Admin Page', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade800,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade800,
              Colors.green.shade600,
              Colors.green.shade400,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nomination Time Remaining: ${_getNominationRemainingTime()}',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: _startNominationSession,
                child: Text('Start Nomination Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade800,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _endNominationSession,
                child: Text('End Nomination Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade800,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 30),
              Text(
                'Voting Time Remaining: ${_getVotingRemainingTime()}',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: _startVotingSession,
                child: Text('Start Voting Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade800,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _endVotingSession,
                child: Text('End Voting Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade800,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DisplayPage()),
                  );
                },
                child: Text('Nominees Display'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade800,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              // SizedBox(height: 50),
              // ElevatedButton(
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => CheckNominees()),
              //     );
              //   },
              //   child: Text('Manage Nominees'),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.white,
              //     foregroundColor: Colors.green.shade800,
              //     padding: EdgeInsets.symmetric(vertical: 15),
              //     textStyle:
              //         TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
