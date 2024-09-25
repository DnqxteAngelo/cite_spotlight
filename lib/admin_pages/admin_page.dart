// ignore_for_file: avoid_print, prefer_const_constructors, unused_field, library_private_types_in_public_api, use_key_in_widget_constructors, prefer_const_constructors_in_immutables, use_super_parameters, sort_child_properties_last

import 'package:cite_spotlight/admin_pages/display_page.dart';
import 'package:cite_spotlight/admin_pages/manage_nominees.dart';
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
    final now = DateTime.now().toUtc().add(Duration(hours: 8));
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
    final now = DateTime.now().toUtc().add(Duration(hours: 8));
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
              DateTime.now()
                  .toUtc()
                  .add(Duration(hours: 8))
                  .isAfter(_nominationEndTime!)) &&
          (_votingEndTime == null ||
              DateTime.now()
                  .toUtc()
                  .add(Duration(hours: 8))
                  .isAfter(_votingEndTime!))) {
        timer.cancel();
      }

      setState(() {});
    });
  }

  String _getNominationRemainingTime() {
    if (_nominationEndTime == null) return "No Session";

    final now = DateTime.now().toUtc().add(Duration(hours: 8));
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

    final now = DateTime.now().toUtc().add(Duration(hours: 8));
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
        title: Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade800,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green.shade800,
              ),
              child: Text(
                'Admin Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Manage Nominees'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageNominees()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.visibility),
              title: Text('Display Nominees'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DisplayPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDashboardCard(
                'Nomination',
                _getNominationRemainingTime(),
                _startNominationSession,
                _endNominationSession,
              ),
              SizedBox(height: 20),
              _buildDashboardCard(
                'Voting',
                _getVotingRemainingTime(),
                _startVotingSession,
                _endVotingSession,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, String remainingTime,
      VoidCallback startSession, VoidCallback endSession) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Time Remaining: $remainingTime',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.play_arrow),
                  label: Text('Start'),
                  onPressed: startSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.stop),
                  label: Text('End'),
                  onPressed: endSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
