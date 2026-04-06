import 'dart:developer';
import 'package:breffini_staff/controller/calls_page_controller.dart';
import 'package:breffini_staff/controller/individual_call_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';

import 'package:breffini_staff/core/utils/extentions.dart';
import 'package:breffini_staff/core/utils/firebase_utils.dart';
import 'package:breffini_staff/core/utils/key_center.dart';

import 'package:breffini_staff/http/chat_socket.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/model/current_call_model.dart';
import 'package:breffini_staff/model/save_call_model.dart';
import 'package:breffini_staff/view/pages/calls/incoming_call_screen.dart';
import 'package:breffini_staff/view/pages/calls/teacher_initiate_call_screen.dart';

import 'package:breffini_staff/view/pages/chats/chat_firebase_screen.dart';
import 'package:breffini_staff/view/pages/chats/widgets/custom_appbar_widget.dart';
import 'package:breffini_staff/view/pages/chats/widgets/loading_circle.dart';
import 'package:breffini_staff/view/pages/home_screen.dart';
import 'package:breffini_staff/view/pages/profile/profile_view_page.dart';
import 'package:breffini_staff/view/widgets/home_screen_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/scheduler.dart' as scheduler;
import 'package:flutter_callkit_incoming_yoer/flutter_callkit_incoming.dart';

class OneToOneCallScreen extends StatefulWidget {
  const OneToOneCallScreen({super.key});

  @override
  State<OneToOneCallScreen> createState() => _OneToOneCallScreenState();
}

class _OneToOneCallScreenState extends State<OneToOneCallScreen> {
  final CallandChatController callandChatController =
      Get.find<CallandChatController>();
  final RxString searchQuery = ''.obs;
  final Rx<TextEditingController> searchController =
      TextEditingController().obs;
  final IndividualCallController controller =
      Get.put(IndividualCallController());

  @override
  void initState() {
    super.initState();
    callandChatController.getStudentTimeSlotsList.clear();
    SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    await callandChatController.getStudentTimeSlots();
  }

  String formatTime(String time24Hour) {
    try {
      DateTime time = DateFormat("HH:mm").parse(time24Hour);
      return DateFormat("h:mm a").format(time);
    } catch (e) {
      log("Error formatting time: $e");
      return "Invalid time";
    }
  }

  bool isCurrentTimeInRange(String startTime, String endTime) {
    try {
      DateTime now = DateTime.now();
      DateTime start = DateFormat("HH:mm").parse(startTime);
      DateTime end = DateFormat("HH:mm").parse(endTime);
      start = DateTime(now.year, now.month, now.day, start.hour, start.minute);
      end = DateTime(now.year, now.month, now.day, end.hour, end.minute);

      DateTime current =
          DateTime(now.year, now.month, now.day, now.hour, now.minute);

      log("Current Time: ${current.toString()}");
      log("Start Time: ${start.toString()}");
      log("End Time: ${end.toString()}");

      return current.isAtSameMomentAs(start) ||
          (current.isAfter(start) && current.isBefore(end));
    } catch (e) {
      log("Error parsing time: $e");
      return false;
    }
  }

  Future<bool> _onWillPop() async {
    // Navigate to HomePage and clear the navigation stack
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => const HomePage(initialIndex: 0),
    ));

    return false; // Prevents default back action
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
            backgroundColor: ColorResources.colorgrey200,
            appBar: CustomAppBar(
              labelText: 'Search Student',
              isStudentList: false,
              onChanged: (value) {
                searchQuery.value = value;
              },
              title: "Students",
              controller: searchController.value,
            ),
            body: RefreshIndicator(
              onRefresh: _initializeData,
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Obx(() {
                  var filteredList = callandChatController
                      .getStudentTimeSlotsList
                      .where((slot) => slot.firstName
                          .toLowerCase()
                          .contains(searchQuery.value.toLowerCase()))
                      .toList();
                  return callandChatController.isOneToOneLoading.value
                      ? const Center(
                          child: LoadingCircle(),
                        )
                      : Column(
                          children: [
                            Expanded(
                                child: searchQuery.value.isNotEmpty &&
                                        filteredList.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No students available',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: ColorResources.colorgrey500,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: filteredList.length,
                                        shrinkWrap: true,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          final slot = filteredList[index];
                                          final isEnabled =
                                              isCurrentTimeInRange(
                                                  slot.startTime, slot.endTime);

                                          log("Slot ${index + 1}: ${slot.firstName}");
                                          log("Is Enabled: $isEnabled");

                                          return Column(
                                            children: [
                                              SizedBox(
                                                height: 16.h,
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  Get.to(() => ProfileViewPage(
                                                      courseId: slot.courseId
                                                          .toString(),
                                                      profileUrl:
                                                          '${HttpUrls.imgBaseUrl}${slot.imageUrl}',
                                                      studentName:
                                                          '${slot.firstName} ${slot.lastName}',
                                                      contactDetails:
                                                          slot.courseName,
                                                      studentId: slot.studentId
                                                          .toString()));
                                                },
                                                child: callStudentWidget(
                                                  chatIcon: Icons
                                                      .chat_bubble_outline_rounded,
                                                  onChatTap: () async {
                                                    final prefs =
                                                        await SharedPreferences
                                                            .getInstance();
                                                    String userTypeId =
                                                        prefs.getString(
                                                                'user_type_id') ??
                                                            '2';
                                                    final String teacherId =
                                                        prefs.getString(
                                                                'breffini_teacher_Id') ??
                                                            "0";
                                                    // Loader.showLoader();
                                                    // log('loader showing ?????????');
                                                    await ChatSocket
                                                        .joinConversationRoom(
                                                            slot.studentId
                                                                .toString(),
                                                            int.parse(
                                                                teacherId),
                                                            userTypeId == '2'
                                                                ? 'teacher_student'
                                                                : 'hod_student');
                                                    await Get.to(() =>
                                                        ChatFireBaseScreen(
                                                          isDeletedUser: false,
                                                          courseId: userTypeId ==
                                                                  '2'
                                                              ? '0'
                                                              : '${slot.courseId}Hod',
                                                          userType: userTypeId,
                                                          contactDetails:
                                                              slot.courseName,
                                                          studentName:
                                                              '${slot.firstName} ${slot.lastName}',
                                                          studentId: slot
                                                              .studentId
                                                              .toString(),
                                                          profileUrl:
                                                              '${HttpUrls.imgBaseUrl}${slot.imageUrl}',
                                                        ))?.then((value) {
                                                      // _fetchData();
                                                    });
                                                    // Loader.stopLoader();
                                                  },
                                                  avatarTap: () {
                                                    Get.to(() => ProfileViewPage(
                                                        courseId: slot.courseId
                                                            .toString(),
                                                        profileUrl: HttpUrls
                                                                .imgBaseUrl +
                                                            slot.imageUrl,
                                                        studentName:
                                                            '${slot.firstName} ${slot.lastName}',
                                                        contactDetails:
                                                            slot.courseName,
                                                        studentId: slot
                                                            .studentId
                                                            .toString()));
                                                  },

                                                  name:
                                                      "${slot.firstName} ${slot.lastName}",
                                                  content: slot.courseName,
                                                  endTime:
                                                      formatTime(slot.endTime),
                                                  startTime: formatTime(
                                                      slot.startTime),
                                                  image: HttpUrls.imgBaseUrl +
                                                      slot.imageUrl,

                                                  // onAudioTap: isEnabled
                                                  //     ? () async {
                                                  //         if (!await isCallExist(
                                                  //             context,
                                                  //             callandChatController)) {
                                                  //           Get.to(() =>
                                                  //               IncomingCallPage(
                                                  //                 liveLink:
                                                  //                     "",
                                                  //                 callId: "",
                                                  //                 studentId: slot
                                                  //                     .studentId
                                                  //                     .toString(),
                                                  //                 video:
                                                  //                     false,
                                                  //                 profileImageUrl:
                                                  //                     slot.imageUrl,
                                                  //                 studentName:
                                                  //                     slot.firstName,
                                                  //               ));
                                                  //           //   Get.to(() =>
                                                  //           //       TeacherInitiateCallScreen(
                                                  //           //           studentId:
                                                  //           //               slot.studentId,
                                                  //           //           video: false));
                                                  //         }
                                                  //       }
                                                  //     : () {
                                                  //         ScaffoldMessenger
                                                  //                 .of(context)
                                                  //             .showSnackBar(
                                                  //           SnackBar(
                                                  //             content: Text(
                                                  //                 "Calls Allowed Only During Available Hours\n${formatTime(slot.startTime)}-${formatTime(slot.endTime)}"),
                                                  //             duration:
                                                  //                 const Duration(
                                                  //                     seconds:
                                                  //                         2),
                                                  //           ),
                                                  //         );
                                                  //       },

                                                  // onVideoTap: isEnabled
                                                  //     ? () async {
                                                  //         if (!await isCallExist(
                                                  //             context,
                                                  //             callandChatController)) {
                                                  //           // Get.to(() =>
                                                  //           //     TeacherInitiateCallScreen(
                                                  //           //         studentId:
                                                  //           //             slot.studentId,
                                                  //           //         video: true));
                                                  //           Get.to(() =>
                                                  //               IncomingCallPage(
                                                  //                 liveLink:
                                                  //                     "",
                                                  //                 callId: "",
                                                  //                 studentId: slot
                                                  //                     .studentId
                                                  //                     .toString(),
                                                  //                 video: true,
                                                  //                 profileImageUrl:
                                                  //                     slot.imageUrl,
                                                  //                 studentName:
                                                  //                     slot.firstName,
                                                  //               ));
                                                  //         }
                                                  //       }
                                                  //     : () {
                                                  //         ScaffoldMessenger
                                                  //                 .of(context)
                                                  //             .showSnackBar(
                                                  //           SnackBar(
                                                  //             content: Text(
                                                  //                 "Calls Allowed Only During Available Hours\n${formatTime(slot.startTime)}-${formatTime(slot.endTime)}"),
                                                  //             duration:
                                                  //                 const Duration(
                                                  //                     seconds:
                                                  //                         2),
                                                  //           ),
                                                  //         );
                                                  //       },
                                                ),
                                              ),
                                              SizedBox(
                                                height: 4.h,
                                              ),
                                            ],
                                          );
                                        },
                                      ))
                          ],
                        );
                }),
              ),
            )),
      ),
    );
  }
}
