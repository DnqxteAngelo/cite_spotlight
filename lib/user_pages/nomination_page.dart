// ignore_for_file: use_super_parameters, library_private_types_in_public_api, prefer_const_constructors, avoid_print, use_build_context_synchronously

import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:cite_spotlight/session/session_service.dart';
import 'package:cite_spotlight/user_pages/camera_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // For date formatting

class NominationPage extends StatefulWidget {
  final int userId;

  NominationPage({
    required this.userId,
  });

  @override
  _NominationPageState createState() => _NominationPageState();
}

class _NominationPageState extends State<NominationPage> {
  final SessionService _sessionService = SessionService();
  bool _isLoading = false;
  // String _gender = 'Male';
  final TextEditingController _nameController = TextEditingController();
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  List<String> _userNames = [];

  Timer? _timer;
  DateTime? _nominationEndTime;

  @override
  void initState() {
    super.initState();
    _fetchUserNames();
    _loadNominationEndTime();
    _startSessionCheckTimer();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadNominationEndTime() async {
    final times = await _sessionService.loadNominationTimes();
    setState(() {
      _nominationEndTime = times['end'];
    });
  }

  String _getNominationRemainingTime() {
    if (_nominationEndTime == null) return "No Session";

    final now = DateTime.now().toUtc().add(Duration(hours: 8));
    final difference = _nominationEndTime!.difference(now);

    if (difference.isNegative) return "Ended";

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        // If the widget is not mounted, stop the timer.
        _timer?.cancel();
        return;
      }

      setState(() {});
    });
  }

  void _startSessionCheckTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      bool isNominationActive =
          await _sessionService.isWithinNominationSession();

      if (!isNominationActive) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'The nomination has ended. Please go to the voting page.')),
        );
      }
    });
  }

  Future<void> _fetchUserNames() async {
    try {
      List<Map<String, dynamic>> allUsers = [];
      int pageSize = 1000;
      int offset = 0;
      bool hasMore = true;

      while (hasMore) {
        final response = await _supabaseClient
            .from('tbl_users')
            .select('user_name')
            .order('user_name', ascending: true)
            .range(offset, offset + pageSize - 1); // Paginate results

        if (response.isNotEmpty) {
          allUsers.addAll(response);
          offset += pageSize;
        } else {
          hasMore = false; // No more data
        }
      }

      setState(() {
        _userNames = List<String>.from(
            allUsers.map((item) => item['user_name'].toString()));
      });
    } catch (e) {
      print('Error fetching user names: $e');
    }
  }

  Future<void> _requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.request();
    if (status.isGranted) {
      // Permission is granted, proceed with camera access
    } else if (status.isDenied) {
      // Permission is denied, show a dialog or message to the user
    } else if (status.isPermanentlyDenied) {
      // Permission is permanently denied, you may open the app settings
      openAppSettings();
    }
  }

  Future<void> selectImageFromCamera() async {
    await _requestCameraPermission();

    try {
      if (!kIsWeb) {
        final XFile? photo =
            await _picker.pickImage(source: ImageSource.camera);

        if (photo != null) {
          final Uint8List imageData = await photo.readAsBytes();
          setState(() {
            _imageBytes = imageData;
          });
        } else {
          print("No image captured");
        }
      } else {
        print("Camera feature is not supported on web.");
        // You may want to handle the case for web differently or use a different method
        // such as a file picker with media types.
      }
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  Future<void> _addNominee() async {
    if (_nameController.text.isEmpty || _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nominee name or image is missing')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String userName = _nameController.text;

      // Step 1: Check if the same user_name has been added within the last 30 minutes
      final recentNomineeResponse = await _supabaseClient
          .from('tbl_nominees')
          .select('nominee_time')
          .eq('nominee_name', userName)
          .gt(
            'nominee_time',
            DateTime.now()
                .toUtc()
                .add(Duration(hours: 8))
                .subtract(Duration(minutes: 30))
                .toIso8601String(),
          );

      if (recentNomineeResponse.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('This nominee was already added.')),
        );
        return;
      }

      // Step 2: Upload image to Supabase storage
      final String imageName =
          '${userName}_${DateTime.now().millisecondsSinceEpoch}.png';
      final String imagePath = imageName;

      await _supabaseClient.storage.from('nominee-images').uploadBinary(
            imagePath,
            _imageBytes!,
            fileOptions: FileOptions(contentType: 'image/png'),
          );

      // Step 3: Get the public URL of the uploaded image
      final String imageUrl = _supabaseClient.storage
          .from('nominee-images')
          .getPublicUrl(imagePath);

      // Step 4: Get the selected user's gender from the tbl_users table
      final userResponse = await _supabaseClient
          .from('tbl_users')
          .select('user_gender')
          .eq('user_name', userName)
          .single();

      if (userResponse.isEmpty || userResponse['user_gender'] == null) {
        throw Exception('User not found or gender is missing');
      }

      String nomineeGender = userResponse['user_gender'];

      // Step 5: Insert the nominee data into the tbl_nominees table
      String currentTime = DateFormat('yyyy-MM-dd HH:mm:ss')
          .format(DateTime.now().toUtc().add(Duration(hours: 8)));

      await _supabaseClient.from('tbl_nominees').insert({
        'nominee_name': userName,
        'nominee_image': imageUrl,
        'nominee_gender': nomineeGender,
        'nominee_time': currentTime,
        'nominee_userid': widget.userId,
      });

      setState(() {
        _imageBytes = null; // Clear the image
        _nameController.clear(); // Clear the name input
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nominee added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding nominee: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
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
              padding: EdgeInsets.symmetric(
                horizontal: screenSize.width * 0.05, // 5% from both sides
                vertical: screenSize.height * 0.02, // 2% from top
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FadeInRight(
                    duration: Duration(milliseconds: 1000),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: screenSize.width * 0.07, // 7% of screen width
                      ),
                    ),
                  ),
                  FadeInRight(
                    duration: Duration(milliseconds: 1000),
                    child: Text(
                      'Time Remaining: ${_getNominationRemainingTime()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize:
                            screenSize.width * 0.04, // Responsive font size
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FadeInLeft(
              duration: Duration(milliseconds: 1000),
              child: Text(
                "CITE Spotlight",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize.width * 0.08, // Responsive font size
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            FadeInLeft(
              duration: Duration(milliseconds: 1100),
              child: Text(
                "Who got the best face?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize.width * 0.05, // Responsive font size
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            SizedBox(height: screenSize.height * 0.03), // Responsive height
            FadeInLeft(
              duration: Duration(milliseconds: 1200),
              child: Text(
                "Nominate someone pretty/handsome!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize.width * 0.05, // Responsive font size
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.05, // 5% from both sides
                  vertical: screenSize.height * 0.04, // 4% from top and bottom
                ),
                child: FadeInUp(
                  duration: Duration(milliseconds: 1300),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(
                          Radius.circular(20)), // Adjusted border radius
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0), // Adjusted padding
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CameraPage(
                                    onImageSelected: (imageData) {
                                      setState(() {
                                        _imageBytes = imageData;
                                      });
                                    },
                                  ),
                                ),
                              );
                            }, // Handle image upload
                            child: FadeInUp(
                              duration: Duration(milliseconds: 1500),
                              child: Container(
                                width: double.infinity,
                                height: screenSize.height *
                                    0.25, // Responsive height
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                      8), // Adjusted border radius
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.shade200,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _imageBytes == null
                                      ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons
                                                  .add_photo_alternate_outlined,
                                              size: screenSize.width *
                                                  0.1, // Responsive icon size
                                              color: Colors.grey,
                                            ),
                                            SizedBox(
                                                height: screenSize.height *
                                                    0.01), // Responsive height
                                            Text(
                                              "Click to upload image",
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: screenSize.width *
                                                    0.04, // Responsive font size
                                              ),
                                            ),
                                          ],
                                        )
                                      : Image.memory(
                                          _imageBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.02),
                          FadeInUp(
                            duration: Duration(milliseconds: 1400),
                            child: DropdownSearch<String>(
                              items: (f, cs) => _userNames,
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: "Name",
                                  hintText: "Select or search a name",
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors
                                            .green.shade600), // Green border
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.green.shade600,
                                        width:
                                            2.0), // Green border when focused
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.green
                                            .shade600), // Green border when not focused
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                _nameController.text = value ?? '';
                              },
                              selectedItem: _nameController.text.isEmpty
                                  ? null
                                  : _nameController.text,
                              popupProps: PopupProps.dialog(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    labelText: "Search Name",
                                    labelStyle: TextStyle(
                                      color: Colors.grey,
                                    ),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors
                                              .green), // Green border for search input
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.green.shade600,
                                          width:
                                              2.0), // Green border when focused in search
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                              height: screenSize.height *
                                  0.02), // Responsive height
                          // Responsive height
                          SizedBox(
                              height: screenSize.height *
                                  0.05), // Responsive height
                          FadeInUp(
                            duration: Duration(milliseconds: 1700),
                            child: _isLoading
                                ? Center(child: CircularProgressIndicator())
                                : MaterialButton(
                                    onPressed: _addNominee,
                                    height: screenSize.height *
                                        0.07, // Responsive height

                                    color: Colors.green.shade600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Submit",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenSize.width *
                                              0.04, // Responsive font size
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
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
