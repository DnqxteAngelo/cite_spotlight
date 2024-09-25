// ignore_for_file: prefer_const_constructors, library_private_types_in_public_api, use_super_parameters, avoid_print, use_key_in_widget_constructors, use_build_context_synchronously

import 'package:animate_do/animate_do.dart';
import 'package:cite_spotlight/session/session_service.dart';
import 'package:cite_spotlight/user_pages/about_page.dart';
import 'package:cite_spotlight/user_pages/nomination_page.dart';
import 'package:cite_spotlight/user_pages/ranking_page.dart';
import 'package:cite_spotlight/user_pages/voting_page.dart';
import 'package:cite_spotlight/user_pages/winner_page.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  final int userId;

  LandingPage({
    required this.userId,
  });

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final SessionService _sessionService = SessionService();

  bool _isNominationSessionActive = false;
  bool _isVotingSessionActive = false;

  @override
  void initState() {
    super.initState();
    _checkSessionStatus();
  }

  Future<void> _checkSessionStatus() async {
    try {
      final isNominationActive =
          await _sessionService.isWithinNominationSession();
      final isVotingActive = await _sessionService.isWithinVotingSession();

      setState(() {
        _isNominationSessionActive = isNominationActive;
        _isVotingSessionActive = isVotingActive;
      });

      print('Nomination is ${isNominationActive ? 'active' : 'inactive'}');
      print('Voting is ${isVotingActive ? 'active' : 'inactive'}');
    } catch (e) {
      print('Error checking session status: $e');
      // Handle the error appropriately, e.g., show an error message to the user
    }
  }

  Future<void> _handleNominateButtonPressed() async {
    await _checkSessionStatus();

    if (_isNominationSessionActive) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NominationPage(
            userId: widget.userId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "The nomination hasn't started or the nomination has ended."),
        ),
      );
    }
  }

  Future<void> _handleVoteButtonPressed() async {
    await _checkSessionStatus();

    if (_isVotingSessionActive) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => VotingPage(userId: widget.userId)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("The voting hasn't started or the voting has ended."),
        ),
      );
    }
  }

  Future<void> _handleRankingButtonPressed() async {
    await _checkSessionStatus();

    if (_isVotingSessionActive) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RankingPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("The voting hasn't started yet, cannot show rankings."),
        ),
      );
    }
  }

  void _showPopupMenu(BuildContext context) async {
    final result = await showMenu(
      context: context,
      position:
          RelativeRect.fromLTRB(100, 60, 0, 0), // Adjust position as needed
      items: [
        PopupMenuItem(
          value: 'about',
          child: Text('About'),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Text('Logout'),
        ),
      ],
    );

    switch (result) {
      case 'about':
        // Navigate to About page
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => AboutPage()));
        break;
      case 'logout':
        _showLogoutConfirmationDialog();
        break;
      default:
        break;
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Confirm Logout",
            style: TextStyle(
              color: Colors.red.shade400, // Title color
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Are you sure you want to log out?",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // Rounded corners
            side: BorderSide(
              color: Colors.red.shade400, // Border color
              width: 2, // Border width
            ),
          ),
          backgroundColor: Colors.white, // Background color
          elevation: 10, // Elevation for shadow effect
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey, // Cancel button color
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Add your logout logic here
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context)
                    .pop(); // Navigate back to the previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red.shade400, // Background color of the button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                ),
              ),
              child: Text(
                "Logout",
                style: TextStyle(
                  color: Colors.white, // Text color
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final buttonSize =
        screenSize.width * 0.4; // Adjust button size based on screen width
    final buttonPadding = screenSize.width * 0.03;
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: PopupMenuButton(
          icon: Icon(
            Icons.menu,
            color: Colors.white,
          ),
          color: Colors.white,
          onSelected: (value) {
            if (value == 'about') {
              // Navigate to the About page
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AboutPage()));
            } else if (value == 'logout') {
              _showLogoutConfirmationDialog();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'about',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_rounded,
                    color: Colors.green.shade600,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    "About",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.logout,
                    color: Colors.red.shade600,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Logout",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartTop,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.green.shade800,
              Colors.green.shade600,
              Colors.green.shade400
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: screenSize.height * 0.1, // Adjust based on screen height
            ),
            Padding(
              padding: EdgeInsets.all(buttonPadding),
              child: Column(
                children: [
                  FadeInLeft(
                    duration: Duration(milliseconds: 200),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: buttonPadding,
                      ), // Add padding if you want space between the text and the border
                      decoration: BoxDecoration(
                        // color: Colors.white,
                        border: Border.all(
                          color: Colors.white, // Border color
                          width: 4, // Border width
                        ),
                        borderRadius: BorderRadius.circular(
                          30,
                        ), // Optional: Rounded corners
                      ),
                      child: Text(
                        "C I T E",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenSize.width * 0.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  FadeInLeft(
                    duration: Duration(milliseconds: 200),
                    child: Text(
                      "Spotlight",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenSize.width * 0.1,
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
                        fontSize: screenSize.width * 0.05,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FadeInUp(
                duration: Duration(milliseconds: 400),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(60),
                      topRight: Radius.circular(60),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(buttonPadding),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 30, // Adjust spacing based on screen height
                        ),
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 4.0,
                          mainAxisSpacing: 4.0,
                          shrinkWrap: true,
                          children: [
                            FadeInUp(
                              duration: Duration(milliseconds: 500),
                              child: Padding(
                                padding: EdgeInsets.all(buttonPadding),
                                child: OutlinedButton(
                                  onPressed: _handleNominateButtonPressed,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        width: 4.0,
                                        color: Colors.green.shade600),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                    minimumSize: Size(buttonSize, buttonSize),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person_add_alt,
                                          color: Colors.green.shade600,
                                          size: screenSize.width * 0.12,
                                        ),
                                        Text(
                                          "Nominate",
                                          style: TextStyle(
                                            color: Colors.green.shade600,
                                            fontWeight: FontWeight.w400,
                                            fontSize: screenSize.width * 0.04,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            FadeInUp(
                              duration: Duration(milliseconds: 500),
                              child: Padding(
                                padding: EdgeInsets.all(buttonPadding),
                                child: ElevatedButton(
                                  onPressed: _handleVoteButtonPressed,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,

                                    // side: BorderSide(
                                    //     width: 4.0, color: Colors.green.shade600),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                    minimumSize: Size(buttonSize, buttonSize),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.thumb_up,
                                          color: Colors.white,
                                          size: screenSize.width * 0.12,
                                        ),
                                        Text(
                                          "Vote",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w400,
                                            fontSize: screenSize.width * 0.04,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            FadeInUp(
                              duration: Duration(milliseconds: 500),
                              child: Padding(
                                padding: EdgeInsets.all(buttonPadding),
                                child: ElevatedButton(
                                  onPressed: _handleRankingButtonPressed,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    // side: BorderSide(
                                    //     width: 4.0, color: Colors.green.shade600),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                    minimumSize: Size(buttonSize, buttonSize),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.leaderboard,
                                          color: Colors.white,
                                          size: screenSize.width * 0.12,
                                        ),
                                        Text(
                                          "Rankings",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w400,
                                            fontSize: screenSize.width * 0.04,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            FadeInUp(
                              duration: Duration(milliseconds: 500),
                              child: Padding(
                                padding: EdgeInsets.all(buttonPadding),
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => WinnerPage()),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        width: 4.0,
                                        color: Colors.green.shade600),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                    minimumSize: Size(buttonSize, buttonSize),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.star_border_rounded,
                                          color: Colors.green.shade600,
                                          size: screenSize.width * 0.12,
                                        ),
                                        Text(
                                          "Hall of Fame",
                                          style: TextStyle(
                                            color: Colors.green.shade600,
                                            fontWeight: FontWeight.w400,
                                            fontSize: screenSize.width * 0.04,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
