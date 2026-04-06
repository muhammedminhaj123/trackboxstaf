import 'package:breffini_staff/controller/calls_page_controller.dart';
import 'package:breffini_staff/controller/individual_call_controller.dart';
import 'package:breffini_staff/controller/profile_controller.dart';
import 'package:breffini_staff/core/utils/common_utils.dart';
import 'package:breffini_staff/core/utils/extentions.dart';
import 'package:breffini_staff/core/utils/firebase_utils.dart';
import 'package:breffini_staff/core/utils/native_utils.dart';

import 'package:breffini_staff/http/chat_socket.dart';

import 'package:breffini_staff/http/notification_permission_handler.dart';

import 'package:breffini_staff/testpage/exams_page.dart';

import 'package:breffini_staff/view/pages/calls/widgets/google_meet.dart';
import 'package:breffini_staff/view/pages/calls/widgets/handle_new_call.dart';
import 'package:breffini_staff/view/pages/calls/widgets/no_internet_widget.dart';
import 'package:breffini_staff/view/pages/chats/chat_firebase_screen.dart';
import 'package:breffini_staff/view/pages/chats/widgets/loading_circle.dart';
import 'package:breffini_staff/view/pages/courses/course_list_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:flutter_callkit_incoming_yoer/flutter_callkit_incoming.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/view/pages/calls/student_batch_list_screen.dart';
import 'package:breffini_staff/view/pages/chats/student_chat_history_screen.dart';

import 'package:breffini_staff/view/pages/live/live_page.dart';
import 'package:breffini_staff/view/pages/profile/profile_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:breffini_staff/core/utils/file_utils.dart';
import 'package:breffini_staff/controller/login_controller.dart';
// import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;

  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  bool _isLivePageVisible = true;
  final CallandChatController callandChatController =
      Get.put<CallandChatController>(CallandChatController());
  final IndividualCallController controller =
      Get.put(IndividualCallController());

  final List<Widget> _pages = [
    const TeacherChatHistoryScreen(),
    // const CallLogScreen(),
    const StudentBatchListScreen(),
    ExamsScreen(),
    const LivePage(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    Get.put(ProfileController());

    super.initState();
    _selectedIndex = widget.initialIndex;
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _loadUserType();
      initPermission();
      getInitialData();
      listenCalls();
      // initLocalNotification();
    });
  }

  initPermission() async {
    await NativeUtils.requestFullScreenIntentPermission();

    await Future.delayed(const Duration(seconds: 3), () async {
      await NativeUtils.requestBatteryOptimization();
    });
  }

  Future<void> getInitialData() async {
    ChatSocket.emitOngoingCalls(); // used to listen calls when first login...
    FirebaseUtils.listenCalls();

    await Get.put(ProfileController()).fetchTeacherProfile(showLoader: false);

    // Automatically check and sync FCM token if needed
    Get.put(LoginController()).checkAndSyncFCMToken();
  }

  Future<void> _loadUserType() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? token = preferences.getString('breffini_token');
    if (token != null) {
      String userTypeId = preferences.getString('user_type_id') ?? '2';

      if (userTypeId == '3') {
        setState(() {
          _isLivePageVisible = false;
          // Index 3 is LivePage/Courses in the list [Chats, OneOne, Exams, LivePage, Profile]
          if (_pages.length > 3) {
            _pages[3] = const CourseListPage(
              isFromProfile: false,
            );
          }

          // _pages.removeAt(3);
        });
      }
    }
  }

  // to handle call notification
  listenCalls() async {
    getCurrentCall();

    ChatSocket().listenCurrentCall((status, callId) {
      if (status) {
        // ChatSocket().removeCallStatusListener();
        if (mounted) {
          FlutterCallkitIncoming.endAllCalls();
          // if (Get.currentRoute == "/IncomingCallPage") {
          //   safeBack();
          //   Get.showSnackbar(const GetSnackBar(
          //     message: 'Call Rejected',
          //     duration: Duration(milliseconds: 2000),
          //   ));
          // } else {
          //   FlutterCallkitIncoming.endAllCalls();
          // }
        }
      }
    });
  }

  Future getCurrentCall() async {
    //check current call from pushkit if possible
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List) {
      if (calls.isNotEmpty) {
        print('DATA: $calls');
        // _currentUuid = calls[0]['id'];
        if (calls[0].length > 0) {
          bool isAccepted = calls[0]["accepted"];
          var payload = calls[0]["extra"];
          String callId = payload!['id'] ?? '';

          if (isAccepted) {
            int studentId = int.parse(payload!['student_id'] ?? "0");

            if (await FirebaseUtils.checkIfCallExists(
                studentId.toString(), callId)) {
              String liveLink = payload!['Live_Link'] ?? '';
              if (!liveLink.isNullOrEmpty()) {
                String callId = payload!['id'] ?? '';
                String callType = payload!['call_type'] ?? '';
                String profileImgUrl = payload!.containsKey("profile_url")
                    ? payload!['profile_url'] ?? ""
                    : "";
                String callerName = payload!.containsKey("student_name")
                    ? payload!['student_name'] ?? ""
                    : "";
                await handleCall(
                  studentId: studentId.toString(),
                  studentName: callerName,
                  callId: callId,
                  isVideo: true,
                  profileImageUrl: profileImgUrl,
                  liveLink: liveLink,
                  controller: controller,
                  callandChatController: callandChatController,
                  safeBack: safeBack,
                );

                MeetCallTracker(
                  onCallEnded: () {},
                ).startMeetCall(meetCode: liveLink);
              }
            }
          }
        }
      } else {
        // _currentUuid = "";
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationPermissionHandler(
        onPermissionChanged: (isGranted) {
          setState(() {});
        },
        child: SafeArea(
          child: Obx(() {
            return profileController.isLoadingProfile.value
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: const LoadingCircle(),
                  )
                : NoInternetScreen(
                    onConnected: () {
                      getInitialData();
                    },
                    child: Column(
                      children: [
                        Expanded(child: _pages.elementAt(_selectedIndex)),
                      ],
                    ),
                  );
          }),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: ColorResources.colorgrey300,
              width: 1,
            ),
          ),
        ),
        height: 92.h,
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: SizedBox(
                height: 25.h,
                width: 25.w,
                child: SvgPicture.asset(
                  _selectedIndex == 0
                      ? 'assets/images/ic_icon_chat_filled.svg'
                      : 'assets/images/ic_icon_chat.svg',
                ),
              ),
              label: 'Chats',
            ),
            // BottomNavigationBarItem(
            //   icon: SizedBox(
            //     height: 25.h,
            //     width: 25.w,
            //     child: SvgPicture.asset(
            //       _selectedIndex == 1
            //           ? 'assets/images/ic_icon_phone_filled.svg'
            //           : 'assets/images/ic_icon_phone.svg',
            //     ),
            //   ),
            //   label: 'Calls',
            // ),
            BottomNavigationBarItem(
              icon: SizedBox(
                height: 25.h,
                width: 25.w,
                child: SvgPicture.asset(
                  _selectedIndex == 1
                      ? 'assets/images/ic_connect_filled.svg'
                      : 'assets/images/ic_connect.svg',
                ),
              ),
              label: 'Students',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 2 ? Icons.school : Icons.school_outlined,
              ),
              label: 'Exams',
            ),
            // if (_isLivePageVisible)
            BottomNavigationBarItem(
              icon: SizedBox(
                height: 25.h,
                width: 25.w,
                child: SvgPicture.asset(
                  _selectedIndex == 3
                      ? 'assets/images/batch_filled.svg'
                      : 'assets/images/batch.svg',
                ),
              ),
              label: _isLivePageVisible ? 'Courses' : 'Courses',
            ),
            BottomNavigationBarItem(
              icon: SizedBox(
                height: 25.h,
                width: 25.w,
                child: SvgPicture.asset(
                  _selectedIndex == 4
                      ? 'assets/images/ic_icon_profile_filled.svg'
                      : 'assets/images/ic_icon_profile.svg',
                ),
              ),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: ColorResources.colorBlue600,
          unselectedItemColor: ColorResources.colorgrey400,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(
            color: ColorResources.colorBlue600,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            color: ColorResources.colorgrey500,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
          iconSize: 26.sp,
        ),
      ),
    );
  }

  handleNotificationClick(Map<String, dynamic> payLoad) async {
    String type = payLoad.containsKey("type") ? payLoad['type'] : "";
    if (type == "new_message") {
      if (!callandChatController.currentCallModel.value.callId
          .isNullOrEmpty()) {
        // await handleChatNotification();
        // _onItemTapped(0);
        // if (!ZegoUIKitPrebuiltCallController().minimize.isMinimizing) {
        //   ZegoUIKitPrebuiltCallController().minimize.minimize(
        //         navigatorKey.currentContext ?? Get.context!,
        //         rootNavigator: true,
        //       );
        // }
      }
      String senderId = payLoad['sender_id'];
      String senderName = payLoad['senderName'];
      final prefs = await SharedPreferences.getInstance();
      String userTypeId = prefs.getString('user_type_id') ?? '2';
      String courseId = payLoad['course_id'];
      String profileUrl = payLoad['profileUrl'] ?? "";
      Get.to(() => ChatFireBaseScreen(
          isDeletedUser: false,
          studentId: senderId,
          profileUrl: FileUtils.getFileExtension(profileUrl).isNullOrEmpty()
              ? ""
              : profileUrl,
          studentName: senderName,
          contactDetails: "",
          courseId: userTypeId == '2' ? '0' : '${courseId}Hod',
          userType: userTypeId));
    } else if (type == "new_call") {
      // if (!Get.currentRoute.isNullOrEmpty() &&
      //     Get.currentRoute != "/IncomingCallPage") {
      //   CurrentCallModel callModel = CurrentCallModel.fromMap(payLoad);
      //
      //
      //  String liveLink = payLoad['Live_Link'];
      //  String callId = payLoad['id'];
      //  String callerId = payLoad['receiver_id'];
      //  bool isVideo = payLoad['call_type']=="Video";
      //  String profileImg = payLoad['Profile_Photo_Img'];
      //  String callerName = payLoad['Caller_Name'];

      // }
      _selectedIndex = 1;
      setState(() {});
    }
  }
}
