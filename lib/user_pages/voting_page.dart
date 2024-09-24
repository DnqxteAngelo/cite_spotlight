// ignore_for_file: prefer_const_constructors, avoid_print

import 'package:cite_spotlight/models/nominees.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cite_spotlight/session/session_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VotingPage extends StatefulWidget {
  final int userId;

  VotingPage({
    required this.userId,
  });

  @override
  _VotingPageState createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  final SessionService _sessionService = SessionService();
  List<Nominees> nominees = [];
  Timer? _timer;
  DateTime? _votingEndTime;

  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentIndex = 0;

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
        });
      } else {
        print('Error fetching nominees');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _voteForNominee(Nominees nominee) async {
    try {
      int userId = widget.userId;

      // Step 1: Retrieve the gender of the nominee being voted for
      final genderResponse = await Supabase.instance.client
          .from('tbl_nominees')
          .select('nominee_gender')
          .eq('nominee_id', nominee.id!)
          .single();

      if (genderResponse.isEmpty) {
        _showSnackBar('Invalid nomination ID.');
        return;
      }

      final String nomineeGender = genderResponse['nominee_gender'];

      // Step 2: Check if the user has already voted for this gender within the last 30 minutes
      final checkResponse =
          await Supabase.instance.client.rpc('check_recent_votes', params: {
        'p_gender': nomineeGender,
        'p_user_id': userId,
      });

      if (checkResponse == null) {
        _showSnackBar('Error checking recent votes.');
        return;
      }

      int recentVotes = checkResponse[0]['count'];

      if (recentVotes > 0) {
        _showSnackBar('You already voted for the $nomineeGender.');
        return;
      }

      // Step 3: Proceed with voting
      final voteResponse =
          await Supabase.instance.client.from('tbl_votes').insert({
        'vote_nomineeid':
            nominee.id, // Ensure this matches the database column name
        'vote_time':
            DateTime.now().toUtc().add(Duration(hours: 8)).toIso8601String(),
        'vote_userid': userId,
      });

      if (voteResponse == null) {
        _showSnackBar('Vote successfully added.');
      } else {
        _showSnackBar(voteResponse.error!.message);
      }
    } catch (e) {
      print('Error: $e');
      _showSnackBar('Error: Unable to vote.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                  _buildTabContent("Vote for the most handsome man!", "male"),
                  _buildTabContent("Vote for the prettiest woman!", "female"),
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
                      icon: Icon(Icons.person),
                      text: "Male",
                    ),
                    Tab(
                      icon: Icon(Icons.person_3),
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

  Widget _buildTabContent(String title, String gender) {
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
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
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
                    fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          FadeInLeft(
            duration: Duration(milliseconds: 300),
            child: Text(
              "CITE Spotlight",
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width > 600 ? 40 : 30,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          FadeInLeft(
            duration: Duration(milliseconds: 300),
            child: Text(
              "Who got the best face?",
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          SizedBox(height: 25),
          FadeInLeft(
            duration: Duration(milliseconds: 300),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 15),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Builder(
                builder: (context) {
                  // Filter nominees by gender
                  final filteredNominees = nominees
                      .where(
                          (nominee) => nominee.gender?.toLowerCase() == gender)
                      .toList();

                  return filteredNominees.isEmpty
                      ? Center(
                          child: Text(
                            'No $gender nominees added in this hour.',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width > 600
                                  ? 18
                                  : 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : CarouselSlider(
                          carouselController: _carouselController,
                          options: CarouselOptions(
                            height: MediaQuery.of(context).size.height * 0.55,
                            aspectRatio: 16 / 9,
                            viewportFraction: 0.8,
                            enlargeCenterPage: true,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentIndex = index;
                              });
                            },
                          ),
                          items: filteredNominees.map(
                            (nominee) {
                              final index = filteredNominees.indexOf(nominee);
                              final isActive = index == _currentIndex;
                              return Builder(
                                builder: (context) {
                                  return SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 300),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.shade800
                                                .withOpacity(0.4),
                                            blurRadius: 10,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            Container(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.4,
                                              margin: EdgeInsets.only(top: 10),
                                              clipBehavior: Clip.hardEdge,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Image.network(
                                                nominee.imageUrl!,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            AnimatedOpacity(
                                              duration:
                                                  Duration(milliseconds: 300),
                                              opacity: isActive ? 1.0 : 0.0,
                                              child: Column(
                                                children: [
                                                  Text(
                                                    nominee.name!
                                                        .split(',')
                                                        .last
                                                        .trim()
                                                        .split(' ')
                                                        .take(2)
                                                        .join(' '),
                                                    style: TextStyle(
                                                      fontSize:
                                                          MediaQuery.of(context)
                                                                      .size
                                                                      .width >
                                                                  600
                                                              ? 20
                                                              : 18,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  ElevatedButton(
                                                    onPressed: isActive
                                                        ? () {
                                                            _voteForNominee(
                                                                nominee);
                                                          }
                                                        : null,
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.green.shade600,
                                                      foregroundColor:
                                                          Colors.white,
                                                    ),
                                                    child: Text("Vote"),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Add some padding at the bottom to ensure content is visible
                                            SizedBox(height: 20),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ).toList(),
                        );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
