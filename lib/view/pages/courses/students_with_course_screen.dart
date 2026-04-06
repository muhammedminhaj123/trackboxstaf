import 'dart:developer';
import 'package:breffini_staff/controller/calls_page_controller.dart';
import 'package:breffini_staff/controller/individual_call_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';

import 'package:breffini_staff/core/utils/extentions.dart';
import 'package:breffini_staff/core/utils/key_center.dart';

import 'package:breffini_staff/http/chat_socket.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/view/pages/calls/incoming_call_screen.dart';
import 'package:breffini_staff/view/pages/calls/teacher_initiate_call_screen.dart';

import 'package:breffini_staff/view/pages/chats/chat_firebase_screen.dart';
import 'package:breffini_staff/view/pages/chats/widgets/custom_appbar_widget.dart';
import 'package:breffini_staff/view/pages/home_screen.dart';
import 'package:breffini_staff/view/pages/profile/profile_view_page.dart';
import 'package:breffini_staff/view/widgets/home_screen_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentsWithCourseScreen extends StatefulWidget {
  const StudentsWithCourseScreen({super.key});

  @override
  State<StudentsWithCourseScreen> createState() =>
      _StudentsWithCourseScreenState();
}

class _StudentsWithCourseScreenState extends State<StudentsWithCourseScreen> {
  final CallandChatController callandChatController =
      Get.put(CallandChatController());
  final IndividualCallController controller =
      Get.put(IndividualCallController());
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  String formatTime(String time24Hour) {
    try {
      DateTime time = DateFormat("HH:mm").parse(time24Hour);
      return DateFormat("h:mm a").format(time);
    } catch (e) {
      log("Error formatting time: $e");
      return "Invalid time";
    }
  }

  Future<bool> _onWillPop() async {
    // Navigate to HomePage and clear the navigation stack
    Get.back();
    return false; // Prevents default back action
  }

  void showAlertDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Can't Connect",
                style: TextStyle(
                    fontSize: 18.w,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff283B52)),
              ),
              // IconButton(
              //     onPressed: () {
              //       Get.back();
              //     },
              //     icon: Icon(Icons.close_sharp))
            ],
          ),
          content: Text(
            "Calls Allowed Only During Available Hours",
            style: GoogleFonts.plusJakartaSans(),
          ),
          actions: [
            TextButton(
              child: Text(
                'Back',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        );
      },
    );
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
              isStudentList: true,
              onChanged: (value) {
                searchQuery.value = value;
              },
              title: 'Student list',
              controller: searchController,
            ),
            body: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Obx(() {
                var filteredList = callandChatController.getStudentCourseList
                    .where((slot) => slot.firstName
                        .toLowerCase()
                        .contains(searchQuery.value.toLowerCase()))
                    .toList();
                return Column(
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
                                physics: const ClampingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final slot = filteredList[index];

                                  return Column(
                                    children: [
                                      SizedBox(
                                        height: 16.h,
                                      ),
                                      InkWell(
                                        onTap: () async {
                                          final prefs = await SharedPreferences
                                              .getInstance();
                                          String userTypeId =
                                              prefs.getString('user_type_id') ??
                                                  '2';
                                          final String teacherId =
                                              prefs.getString(
                                                      'breffini_teacher_Id') ??
                                                  "0";

                                          log('loader showing ?????????');
                                          await ChatSocket.joinConversationRoom(
                                              slot.studentId.toString(),
                                              int.parse(teacherId),
                                              userTypeId == '2'
                                                  ? 'teacher_student'
                                                  : 'hod_student');
                                          Get.to(() => ChatFireBaseScreen(
                                              isDeletedUser: false,
                                              studentId:
                                                  slot.studentId.toString(),
                                              profileUrl: HttpUrls.imgBaseUrl +
                                                  slot.profilePhotoPath,
                                              studentName:
                                                  '${slot.firstName} ${slot.lastName}',
                                              contactDetails: '',
                                              courseId: userTypeId == '2'
                                                  ? '0'
                                                  : '${slot.courseId}Hod',
                                              userType: userTypeId));
                                        },
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            radius: 23.r,
                                            child: CachedNetworkImage(
                                              imageUrl: HttpUrls.imgBaseUrl +
                                                  slot.profilePhotoPath,
                                              imageBuilder:
                                                  (context, imageProvider) =>
                                                      Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                    image: imageProvider,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              placeholder: (context, url) =>
                                                  const CircularProgressIndicator(
                                                color: Colors.blue,
                                                strokeWidth: 2,
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Center(
                                                child: Icon(
                                                  Icons.person_rounded,
                                                  color: ColorResources
                                                      .colorBlack
                                                      .withOpacity(.7),
                                                  size: 25.w,
                                                ),
                                              ),
                                            ),
                                          ),
                                          title: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${filteredList[index].firstName} ${filteredList[index].lastName}',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  color:
                                                      ColorResources.colorBlack,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      "${DateFormat('MMM d,y').format(DateTime.parse(filteredList[index].enrollmentDate))} - "
                                                      "${DateFormat('MMM d,y').format(DateTime.parse(filteredList[index].expiryDate))}",
                                                      style: GoogleFonts
                                                          .plusJakartaSans(
                                                        color: ColorResources
                                                            .colorBlack,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                "Batch:${filteredList[index].batchName}",
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  color:
                                                      ColorResources.colorBlack,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
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
            )),
      ),
    );
  }
}
