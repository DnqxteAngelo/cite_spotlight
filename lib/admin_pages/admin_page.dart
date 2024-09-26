// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors, use_super_parameters

import 'package:cite_spotlight/admin_pages/session_page.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cite_spotlight/admin_pages/display_page.dart';
import 'package:cite_spotlight/admin_pages/manage_nominees.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<FlSpot> _databaseSizes = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _nomineeCounts;
  bool _isNomineeLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNomineeCounts();
    _loadDatabaseSize();
    _subscribeToNominees();
  }

  Future<void> _fetchNomineeCounts() async {
    try {
      final response =
          await Supabase.instance.client.rpc('count_nominees_by_gender');
      if (response != null) {
        setState(() {
          _nomineeCounts = response as Map<String, dynamic>;
          _isNomineeLoading = false;
        });
      } else {
        throw Exception('Failed to fetch nominee counts');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading nominee counts: ${e.toString()}';
        _isNomineeLoading = false;
      });
    }
  }

  Future<void> _loadDatabaseSize() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await Supabase.instance.client.rpc('get_database_size_intervals');

      if (response != null) {
        List<FlSpot> spots = [];
        for (int i = 0; i < response.length; i++) {
          double sizeMB =
              response[i]['db_size'] / (1024 * 1024); // Convert to MB
          spots.add(FlSpot(i.toDouble(), sizeMB));
        }

        setState(() {
          _databaseSizes = spots;
          _isLoading = false;
        });
      } else {
        throw Exception('No data received');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading database size: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void handleCounts(payload) {
    _fetchNomineeCounts();
  }

  void _subscribeToNominees() {
    Supabase.instance.client
        .channel('tbl_nominees')
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'tbl_votes',
            callback: handleCounts)
        .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'tbl_votes',
            callback: handleCounts)
        .subscribe();
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
    final buttonPadding = screenSize.width * 0.03;
    final isLargeScreen = screenSize.width > 600;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.green.shade800,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            DrawerHeader(
              padding: EdgeInsets.zero,
              child: Container(
                width: double.infinity, // Ensures the header takes full width
                decoration: BoxDecoration(
                  color: Colors.green.shade800,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: buttonPadding),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          "C I T E",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize:
                                isLargeScreen ? 48 : screenSize.width * 0.10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        "Spotlight",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize:
                              isLargeScreen ? 36 : screenSize.width * 0.07,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  ListTile(
                    leading: Icon(
                      Icons.timer,
                      color: Colors.green.shade400,
                    ),
                    title: Text('Manage Sessions'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SessionPage()),
                      );
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.people,
                      color: Colors.green.shade400,
                    ),
                    title: Text('Manage Nominees'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ManageNominees()),
                      );
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.visibility,
                      color: Colors.green.shade400,
                    ),
                    title: Text('Display Nominees'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DisplayPage()),
                      );
                    },
                  ),
                  Divider(),
                  // Add more tiles here if needed
                ],
              ),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                // Implement your logout functionality here
                Navigator.pop(context);
                _showLogoutConfirmationDialog();
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green.shade50, Colors.white],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadDatabaseSize();
              await _fetchNomineeCounts();
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDatabaseLineChart(constraints),
                        SizedBox(height: 20),
                        _buildNomineeCountsRow(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNomineeCountsRow() {
    return Row(
      children: [
        Expanded(child: _buildNomineeCountCard('Male', Icons.male)),
        SizedBox(width: 16),
        Expanded(child: _buildNomineeCountCard('Female', Icons.female)),
      ],
    );
  }

  Widget _buildNomineeCountCard(String gender, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green.shade800, size: 24),
                SizedBox(width: 8),
                Text(
                  '$gender \nNominees',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _isNomineeLoading
                ? Center(child: CircularProgressIndicator())
                : _nomineeCounts == null
                    ? Center(child: Text(_errorMessage))
                    : Text(
                        '${_nomineeCounts![gender]}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatabaseLineChart(BoxConstraints constraints) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.green.shade800, size: 24),
                SizedBox(width: 8),
                Text(
                  'Database Size',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Last 24 Hours',
              style: TextStyle(fontSize: 14, color: Colors.green.shade600),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: constraints.maxWidth > 600 ? 300 : 200,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Text(_errorMessage,
                              style: TextStyle(color: Colors.red)))
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.green.shade100, strokeWidth: 1),
                              getDrawingVerticalLine: (value) => FlLine(
                                  color: Colors.green.shade100, strokeWidth: 1),
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    final now = DateTime.now().subtract(
                                        Duration(
                                            hours: (5 - value.toInt()) * 4));
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        DateFormat('HH:mm').format(now),
                                        style: TextStyle(
                                            color: Colors.green.shade800,
                                            fontSize: 12),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: 100,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toInt()} MB',
                                      style: TextStyle(
                                          color: Colors.green.shade800,
                                          fontSize: 12),
                                    );
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(
                                show: true,
                                border: Border.all(
                                    color: Colors.green.shade300, width: 1)),
                            minX: 0,
                            maxX: 5,
                            minY: 0,
                            maxY: _databaseSizes.isNotEmpty
                                ? _databaseSizes
                                        .map((spot) => spot.y)
                                        .reduce((a, b) => a > b ? a : b) *
                                    1.2
                                : 100,
                            lineBarsData: [
                              LineChartBarData(
                                spots: _databaseSizes,
                                isCurved: true,
                                color: Colors.green.shade600,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) =>
                                          FlDotCirclePainter(
                                    radius: 4,
                                    color: Colors.green.shade800,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.green.shade200.withOpacity(0.3),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems:
                                    (List<LineBarSpot> touchedBarSpots) {
                                  return touchedBarSpots.map((barSpot) {
                                    final flSpot = barSpot;
                                    final now = DateTime.now().subtract(
                                        Duration(
                                            hours: (5 - flSpot.x.toInt()) * 4));
                                    return LineTooltipItem(
                                      '${DateFormat('MMM d, HH:mm').format(now)}\n',
                                      const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                      children: [
                                        TextSpan(
                                          text:
                                              '${flSpot.y.toStringAsFixed(2)} MB',
                                          style: TextStyle(
                                              color: Colors.yellow,
                                              fontWeight: FontWeight.normal),
                                        ),
                                      ],
                                    );
                                  }).toList();
                                },
                              ),
                              handleBuiltInTouches: true,
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
