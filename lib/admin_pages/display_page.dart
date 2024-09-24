// ignore_for_file: prefer_const_constructors, avoid_print

import 'dart:async';

import 'package:cite_spotlight/models/nominees.dart';
import 'package:cite_spotlight/session/session_service.dart';
import 'package:flutter/material.dart';
import 'package:marqueer/marqueer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DisplayPage extends StatefulWidget {
  const DisplayPage({Key? key}) : super(key: key);

  @override
  _DisplayPageState createState() => _DisplayPageState();
}

class _DisplayPageState extends State<DisplayPage> {
  final MarqueerController _controller = MarqueerController();
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
        Navigator.pop(context);
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
        final oneHourAgo = now.subtract(Duration(days: 1));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                colors: [
                  Colors.green.shade800,
                  Colors.green.shade600,
                  Colors.green.shade400,
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(constraints.maxWidth * 0.02),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Text(
                        'Time Remaining: ${_getVotingRemainingTime()}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: constraints.maxWidth * 0.02,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "CITE Spotlight",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: constraints.maxWidth * 0.04,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    "Who got the best face?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: constraints.maxWidth * 0.025,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.02),
                  Text(
                    "Male Nominees",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: constraints.maxWidth * 0.025,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.01),
                  Expanded(
                    child: Marqueer.builder(
                      pps: 30,
                      controller: _controller,
                      direction: MarqueerDirection.rtl,
                      autoStartAfter: const Duration(seconds: 2),
                      itemCount: maleNominees.length,
                      itemBuilder: (context, index) {
                        final nominee = maleNominees[index];
                        return _buildNomineeCard(nominee, constraints);
                      },
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.02),
                  Text(
                    "Female Nominees",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: constraints.maxWidth * 0.025,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.01),
                  Expanded(
                    child: Marqueer.builder(
                      pps: 30,
                      controller: _controller,
                      direction: MarqueerDirection.ltr,
                      autoStartAfter: const Duration(seconds: 2),
                      itemCount: femaleNominees.length,
                      itemBuilder: (context, index) {
                        final nominee = femaleNominees[index];
                        return _buildNomineeCard(nominee, constraints);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNomineeCard(Nominees nominee, BoxConstraints constraints) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.01),
      width: constraints.maxWidth * 0.15,
      height: constraints.maxHeight * 0.25,
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  nominee.imageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(constraints.maxWidth * 0.01),
                color: Colors.black.withOpacity(0.5),
                child: Text(
                  nominee.name!
                      .split(',')
                      .last
                      .trim()
                      .split(' ')
                      .take(2)
                      .join(' '),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: constraints.maxWidth * 0.012,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 4.0,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
