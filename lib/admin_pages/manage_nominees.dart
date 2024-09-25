// ignore_for_file: use_super_parameters, library_private_types_in_public_api, prefer_const_constructors, avoid_print

import 'dart:async';

import 'package:cite_spotlight/models/nominees.dart';
import 'package:cite_spotlight/session/session_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageNominees extends StatefulWidget {
  const ManageNominees({Key? key}) : super(key: key);

  @override
  _ManageNomineesState createState() => _ManageNomineesState();
}

class _ManageNomineesState extends State<ManageNominees> {
  final SessionService _sessionService = SessionService();
  List<Nominees> nominees = [];
  List<Nominees> maleNominees = [];
  List<Nominees> femaleNominees = [];
  DateTime? _votingEndTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchNominees();
    _loadVotingTimes();
    _getVotingRemainingTime();
    _startTimer();
  }

  Future<void> _loadVotingTimes() async {
    final times = await _sessionService.loadVotingTimes();
    setState(() {
      _votingEndTime = times['end'];
    });
  }

  String _getVotingRemainingTime() {
    if (_votingEndTime == null) return "No Session";

    final now = DateTime.now().toUtc().add(Duration(hours: 8));
    final difference = _votingEndTime!.difference(now);

    if (difference.isNegative) return "Ended";

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }

      setState(() {});

      if (_getVotingRemainingTime() == "Ended") {
        _timer?.cancel();
      }
    });
  }

  Future<void> fetchNominees() async {
    try {
      final response = await Supabase.instance.client
          .from('tbl_nominees') // Use your actual table name
          .select();

      if (response.isNotEmpty) {
        final List<dynamic> data = response;
        final now = DateTime.now().toUtc().add(Duration(hours: 8));
        final oneHourAgo = now.subtract(Duration(hours: 1));
        setState(() {
          nominees = data
              .map((json) => Nominees.fromJson(json))
              .where((nominee) =>
                  nominee.time != null && nominee.time!.isAfter(oneHourAgo))
              .toList();
          maleNominees =
              nominees.where((nominee) => nominee.gender == 'Male').toList();
          femaleNominees =
              nominees.where((nominee) => nominee.gender == 'Female').toList();
        });
      } else {
        print('Error fetching nominees');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _deleteNominee(int id) async {
    final response = await Supabase.instance.client
        .from('tbl_nominees') // Updated table name
        .delete()
        .eq('nominee_id', id); // Updated primary key

    if (response == null) {
      setState(() {
        nominees.removeWhere((nominee) => nominee.id == id);
        maleNominees.removeWhere((nominee) => nominee.id == id);
        femaleNominees.removeWhere((nominee) => nominee.id == id);
      });
    } else {
      print('Error deleting nominee');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Manage Nominees', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green.shade800,
          iconTheme: IconThemeData(color: Colors.white),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.man), text: "Male"),
              Tab(icon: Icon(Icons.woman), text: "Female"),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _buildNomineeList(maleNominees),
            _buildNomineeList(femaleNominees),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Voting Time Remaining: ${_getVotingRemainingTime()}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNomineeList(List<Nominees> nominees) {
    return Container(
      color: Colors.grey[100],
      child: nominees.isEmpty
          ? Center(child: Text('No nominees found'))
          : ListView.builder(
              itemCount: nominees.length,
              itemBuilder: (context, index) {
                final nominee = nominees[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(nominee.imageUrl!),
                      radius: 25,
                    ),
                    title: Text(
                      nominee.name!,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text('Nominated at: ${nominee.time!.toLocal()}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(nominee),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showDeleteConfirmation(Nominees nominee) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete ${nominee.name}?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                _deleteNominee(nominee.id!);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
