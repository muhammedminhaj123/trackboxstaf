import 'package:breffini_staff/controller/calls_page_controller.dart';
import 'package:breffini_staff/controller/individual_call_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/http/chat_socket.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/view/pages/chats/chat_firebase_screen.dart';
import 'package:breffini_staff/view/pages/chats/widgets/custom_appbar_widget.dart';
import 'package:breffini_staff/view/pages/chats/widgets/loading_circle.dart';
import 'package:breffini_staff/view/pages/profile/profile_view_page.dart';
import 'package:breffini_staff/view/widgets/home_screen_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BatchStudentListScreen extends StatefulWidget {
  final String batchId;
  final String batchName;

  const BatchStudentListScreen({
    super.key,
    required this.batchId,
    required this.batchName,
  });

  @override
  State<BatchStudentListScreen> createState() => _BatchStudentListScreenState();
}

class _BatchStudentListScreenState extends State<BatchStudentListScreen> {
  final CallandChatController callandChatController =
      Get.find<CallandChatController>();
  final IndividualCallController individualCallController =
      Get.put(IndividualCallController());
  final RxString searchQuery = ''.obs;
  final Rx<TextEditingController> searchController =
      TextEditingController().obs;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final String teacherId = prefs.getString('breffini_teacher_Id') ?? "0";
    callandChatController.getFacultyBatchStudents(teacherId);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: ColorResources.colorgrey200,
        appBar: CustomAppBar(
          labelText: 'Search Student',
          isStudentList: true,
          onChanged: (value) {
            searchQuery.value = value;
          },
          title: widget.batchName,
          controller: searchController.value,
        ),
        body: RefreshIndicator(
          onRefresh: () => _fetchStudents(),
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Obx(() {
              var filteredList = callandChatController.facultyBatchStudentsList
                  .where((student) {
                // Filter by batchId first
                final matchesBatch =
                    student.batchId.toString() == widget.batchId;
                if (!matchesBatch) return false;

                // Then filter by search query
                final fullName =
                    "${student.firstName} ${student.lastName}".toLowerCase();
                return fullName.contains(searchQuery.value.toLowerCase());
              }).toList();

              if (callandChatController.isFacultyBatchStudentsLoading.value &&
                  callandChatController.facultyBatchStudentsList.isEmpty) {
                return const Center(child: LoadingCircle());
              }

              if (filteredList.isEmpty &&
                  !callandChatController.isFacultyBatchStudentsLoading.value) {
                return ListView(
                  children: [
                    SizedBox(height: 200.h),
                    Center(
                      child: Text(
                        searchQuery.value.isEmpty
                            ? 'No students found'
                            : 'No matching students',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: ColorResources.colorgrey500,
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: filteredList.length,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final student = filteredList[index];
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: InkWell(
                            onTap: () {
                              Get.to(() => ProfileViewPage(
                                    courseId: student.courseId.toString(),
                                    profileUrl: student.profilePhotoPath != null
                                        ? '${HttpUrls.imgBaseUrl}${student.profilePhotoPath}'
                                        : '',
                                    studentName:
                                        '${student.firstName} ${student.lastName}',
                                    contactDetails: student.courseName ?? '',
                                    studentId: student.studentId.toString(),
                                  ));
                            },
                            child: callStudentWidget(
                              chatIcon: Icons.chat_bubble_outline_rounded,
                              onChatTap: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                String userTypeId =
                                    prefs.getString('user_type_id') ?? '2';
                                final String teacherId =
                                    prefs.getString('breffini_teacher_Id') ??
                                        "0";

                                await ChatSocket.joinConversationRoom(
                                  student.studentId.toString(),
                                  int.parse(teacherId),
                                  userTypeId == '2'
                                      ? 'teacher_student'
                                      : 'hod_student',
                                );

                                Get.to(() => ChatFireBaseScreen(
                                      isDeletedUser: false,
                                      courseId: userTypeId == '2'
                                          ? '0'
                                          : '${student.courseId}Hod',
                                      userType: userTypeId,
                                      contactDetails: student.courseName ?? '',
                                      studentName:
                                          '${student.firstName} ${student.lastName}',
                                      studentId: student.studentId.toString(),
                                      profileUrl: student.profilePhotoPath !=
                                              null
                                          ? '${HttpUrls.imgBaseUrl}${student.profilePhotoPath}'
                                          : '',
                                    ));
                              },
                              avatarTap: () {
                                Get.to(() => ProfileViewPage(
                                      courseId: student.courseId.toString(),
                                      profileUrl: student.profilePhotoPath !=
                                              null
                                          ? '${HttpUrls.imgBaseUrl}${student.profilePhotoPath}'
                                          : '',
                                      studentName:
                                          '${student.firstName} ${student.lastName}',
                                      contactDetails: student.courseName ?? '',
                                      studentId: student.studentId.toString(),
                                    ));
                              },
                              name: "${student.firstName} ${student.lastName}",
                              content: student.courseName ?? '',
                              endTime: "", // Not available in new API response
                              startTime:
                                  "", // Not available in new API response
                              image: student.profilePhotoPath != null
                                  ? '${HttpUrls.imgBaseUrl}${student.profilePhotoPath}'
                                  : '',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
