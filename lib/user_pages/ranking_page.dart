// ignore_for_file: avoid_print, prefer_const_constructors, collection_methods_unrelated_type, use_super_parameters, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:cite_spotlight/models/votes.dart';
import 'package:cite_spotlight/session/session_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({Key? key}) : super(key: key);

  @override
  _RankingPageState createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  final SessionService _sessionService = SessionService();
  List<Votes> votes = [];
  final Map<String, AnimationController> _animationControllers = {};

  Timer? _timer;
  DateTime? _votingEndTime;

  @override
  void initState() {
    super.initState();
    _loadVotingTimes();
    _getVotingRemainingTime();
    _startTimer();
    _startSessionCheckTimer();
    fetchRankings();
    _subscribeToVotes();
  }

  Future<void> _loadVotingTimes() async {
    final times = await _sessionService.loadVotingTimes();
    setState(() {
      _votingEndTime = times['end'];
    });
  }

  String _getVotingRemainingTime() {
    if (_votingEndTime == null) return "Ended";

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

      // if (_getVotingRemainingTime() == "Ended") {
      //   _timer?.cancel();
      //   getAndAddWinners(); // Call the function when voting ends
      // }
    });
  }

  void _startSessionCheckTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!mounted) return;

      bool isVotingActive = await _sessionService.isWithinVotingSession();

      // Load the voting times if the session is active
      if (isVotingActive) {
        await _loadVotingTimes(); // Load voting end time if session is active
      } else {
        // Call the dialog to notify users that voting has ended
        _showVotingEndedDialog();

        setState(() {
          // Logic to indicate that voting has ended
          _votingEndTime = null; // Optionally reset voting end time
        });

        // Cancel the timer to stop checking
        _timer?.cancel();

        Future.delayed(Duration(seconds: 10), () {
          _timer?.cancel();
          Navigator.of(context).pop(); // Pop the navigation context
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('The voting has ended.\nThank you for participating!'),
            ),
          );
        });
      }
    });
  }

  Future<void> fetchRankings() async {
    final response = await Supabase.instance.client
        .rpc('get_rankings'); // Call the new function

    if (response != null && response.isNotEmpty) {
      final data = response as List;

      setState(() {
        votes = data
            .map((json) => Votes.fromJson(json))
            .toList(); // Update Votes.fromJson as needed
      });
    } else {
      print('Error fetching rankings');
    }
  }

  List<Votes> _filterVotesByGender(String gender) {
    return votes
        .where((vote) => vote.gender?.toLowerCase() == gender.toLowerCase())
        .toList();
  }

  void _showVotingEndedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Voting Stage Ends'),
          content: Text(
              'The voting has ended. The host will announce the winners.\n\nYou will be redirected to the landing page after a few seconds.'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
            side: BorderSide(
                color: Colors.green.shade600, width: 2), // Green border
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK', style: TextStyle(color: Colors.green.shade600)),
            ),
          ],
        );
      },
    );
  }

  void handleInserts(payload) {
    fetchRankings();
  }

  void _subscribeToVotes() {
    Supabase.instance.client
        .channel('tbl_votes')
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'tbl_votes',
            callback: handleInserts)
        .subscribe();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.green.shade400,
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _rankingListView("Current Hottest Male Rankings", "male"),
                  _rankingListView("Current Hottest Female Rankings", "female"),
                ],
              ),
            ),
            FadeInUp(
              duration: Duration(milliseconds: 500),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: const TabBar(
                  labelColor: Colors.green,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.green,
                  dividerColor: null,
                  tabs: [
                    Tab(
                      icon: Icon(
                        Icons.person,
                      ),
                      text: "Male",
                    ),
                    Tab(
                      icon: Icon(
                        Icons.person_3,
                      ),
                      text: "Female",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _rankingListView(String title, String gender) {
    final filteredVotes = _filterVotesByGender(gender);
    return Container(
      width: double.infinity,
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 20.0,
              top: 20.0,
              right: 20.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FadeInRight(
                  duration: Duration(milliseconds: 300),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                ),
                FadeInRight(
                  duration: Duration(milliseconds: 300),
                  child: Text(
                    'Time Remaining: ${_getVotingRemainingTime()}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          FadeInLeft(
            duration: Duration(milliseconds: 300),
            child: Text(
              "CITE Spotlight",
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          FadeInLeft(
            duration: Duration(milliseconds: 400),
            child: Text(
              "Who got the best face?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          SizedBox(height: 25),
          FadeInLeft(
            duration: Duration(milliseconds: 500),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: filteredVotes.length,
              itemBuilder: (context, index) {
                final vote = filteredVotes[index];
                final place = index + 1; // 1-based index for ranking

                Widget? rankingIcon;
                if (place == 1) {
                  rankingIcon = Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.crown, // Gold crown icon
                        color: Colors.amber,
                        size: 40,
                      ),
                      Positioned(
                        top: 18,
                        left: 18,
                        child: Text(
                          '$place',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  );
                } else if (place == 2) {
                  rankingIcon = Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.crown, // Silver crown icon
                        color: Colors.grey,
                        size: 40,
                      ),
                      Positioned(
                        top: 18,
                        left: 18,
                        child: Text(
                          '$place',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  );
                } else if (place == 3) {
                  rankingIcon = Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.crown, // Bronze crown icon
                        color: Colors.brown,
                        size: 40,
                      ),
                      Positioned(
                        top: 18,
                        left: 18,
                        child: Text(
                          '$place',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  rankingIcon = null; // No icon for places greater than 3
                }
                return AnimatedBuilder(
                    animation: _animationControllers[vote.id!] ??
                        AlwaysStoppedAnimation(0.0),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                            0, _animationControllers[vote.id!]?.value ?? 0),
                        child: FadeInUp(
                          duration: Duration(
                              milliseconds: 500 +
                                  (index * 100)), // Delay each item slightly
                          child: Card(
                            margin: EdgeInsets.symmetric(
                                vertical: 15.0, horizontal: 16.0),
                            // elevation: 8.0, // Add shadow for better appearance
                            child: Container(
                              height: 120, // Adjust height of the Card
                              padding: EdgeInsets.all(
                                  8.0), // Add padding inside the Card
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: _getVotingRemainingTime() ==
                                            "Ended"
                                        ? NetworkImage(vote
                                            .imageUrl!) // Load image if voting has ended
                                        : null, // Don't show image if voting is ongoing
                                    radius: 40, // Size of the avatar
                                    child: _getVotingRemainingTime() == "Ended"
                                        ? null
                                        : Icon(Icons.person,
                                            size: 40,
                                            color:
                                                Colors.white), // Default icon
                                  ),
                                  SizedBox(
                                      width:
                                          30), // Space between avatar and text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _getVotingRemainingTime() == "Ended"
                                              ? vote.name
                                                      ?.split(',')
                                                      .last
                                                      .trim()
                                                      .split(' ')
                                                      .take(2)
                                                      .join(' ') ??
                                                  'No Name'
                                              : '?' *
                                                  (vote.name
                                                          ?.split(',')
                                                          .first
                                                          .trim()
                                                          .length ??
                                                      0), // Placeholder if voting is ongoing
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text('Votes: ${vote.totalVotes}'),
                                      ],
                                    ),
                                  ),
                                  if (rankingIcon != null) rankingIcon,
                                  SizedBox(width: 30),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    });
              },
            ),
          ),
        ],
      ),
    );
  }
}
