// ignore_for_file: prefer_const_constructors, avoid_print, use_build_context_synchronously

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
        _showWinnersDialog();
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

// Function to get the winners from the Supabase database
  Future<void> _showWinnersDialog() async {
    try {
      final supabase = Supabase.instance.client;

      // Query to get the female nominees with vote counts
      final femaleResponse = await supabase.from('tbl_nominees').select('''
            nominee_id, 
            nominee_name, 
            nominee_image, 
            nominee_gender,
            vote_count:tbl_votes(count)
        ''').eq('nominee_gender', 'Female');

      // Query to get the male nominees with vote counts
      final maleResponse = await supabase.from('tbl_nominees').select('''
            nominee_id, 
            nominee_name, 
            nominee_image, 
            nominee_gender,
            vote_count:tbl_votes(count)
        ''').eq('nominee_gender', 'Male');

      if (femaleResponse.isNotEmpty && maleResponse.isNotEmpty) {
        // Find the female and male winners (assuming highest vote count wins)
        final femaleData = femaleResponse.reduce((curr, next) =>
            (curr['vote_count'] as List).first['count'] >
                    (next['vote_count'] as List).first['count']
                ? curr
                : next);
        final maleData = maleResponse.reduce((curr, next) =>
            (curr['vote_count'] as List).first['count'] >
                    (next['vote_count'] as List).first['count']
                ? curr
                : next);

        print(femaleData);
        print(maleData);

        final femaleWinnerId = femaleData['nominee_id'];
        final maleWinnerId = maleData['nominee_id'];

        // Extract the vote counts as integers
        final femaleVotes =
            (femaleData['vote_count'] as List).first['count'] as int;
        final maleVotes =
            (maleData['vote_count'] as List).first['count'] as int;

        // Rest of the function remains the same...
        final now =
            DateTime.now().toUtc().add(Duration(hours: 8)).toIso8601String();
        final insertResponse = await supabase.from('tbl_winners').insert({
          'winner_femaleid': femaleWinnerId,
          'winner_maleid': maleWinnerId,
          'winner_time': now,
        });

        if (insertResponse == null) {
          // Show winners dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 600;
                    return Container(
                      width: isSmallScreen ? constraints.maxWidth * 0.9 : 500,
                      padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade800
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Voting Session Ended',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 24 : 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isSmallScreen ? 15 : 20),
                            Text(
                              'The winners are:',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 22,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 15 : 20),
                            Flex(
                              direction: isSmallScreen
                                  ? Axis.vertical
                                  : Axis.horizontal,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildWinnerCard(
                                  femaleData['nominee_image'],
                                  femaleData['nominee_name'],
                                  femaleVotes,
                                  'Female',
                                  isSmallScreen,
                                ),
                                if (!isSmallScreen) SizedBox(width: 10),
                                if (isSmallScreen) SizedBox(height: 10),
                                _buildWinnerCard(
                                  maleData['nominee_image'],
                                  maleData['nominee_name'],
                                  maleVotes,
                                  'Male',
                                  isSmallScreen,
                                ),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 15 : 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.green.shade800,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 30 : 40,
                                  vertical: isSmallScreen ? 10 : 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'OK',
                                style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        } else {
          print('Error adding winners to tbl_winners');
        }
      } else {
        print('Error fetching winners.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Widget _buildWinnerCard(String imageUrl, String name, int votes,
      String category, bool isSmallScreen) {
    return Container(
      width: isSmallScreen ? double.infinity : 200,
      padding: EdgeInsets.all(isSmallScreen ? 10 : 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: isSmallScreen ? 40 : 50,
            backgroundImage: NetworkImage(imageUrl),
          ),
          SizedBox(height: 10),
          Text(
            name.split(',').last.trim().split(' ').take(2).join(' '),
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '$category Winner',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            'Votes: $votes',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
