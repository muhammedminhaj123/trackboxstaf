import 'package:breffini_staff/controller/chat_controller.dart';
import 'package:breffini_staff/controller/chat_history_controller.dart';
import 'package:breffini_staff/controller/ongoing_call_controller.dart';
import 'dart:developer';
import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/http/chat_socket.dart';
import 'package:breffini_staff/view/pages/chats/chat_firebase_screen.dart';
import 'package:breffini_staff/view/pages/chats/widgets/custom_appbar_widget.dart';
import 'package:breffini_staff/view/widgets/home_screen_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherChatHistoryScreen extends StatefulWidget {
  const TeacherChatHistoryScreen({super.key});

  @override
  State<TeacherChatHistoryScreen> createState() =>
      _TeacherChatHistoryScreenState();
}

class _TeacherChatHistoryScreenState extends State<TeacherChatHistoryScreen> {
  final ChatHistoryController chatHistoryController =
      Get.find<ChatHistoryController>();
  final CallOngoingController ongoingController =
      Get.put(CallOngoingController());
  final ChatController chtContlr = Get.put(ChatController());

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    getTeacherChatLogHistory();
    // profileController.fetchTeacherProfile();
  }

  Future<void> _handleRefresh() async {
    _fetchData();
    setState(() {});
  }

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  getTeacherChatLogHistory() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String teacherId = preferences.getString('breffini_teacher_Id') ?? '';
    String userTypeId = preferences.getString('user_type_id') ?? '2';
    log('teacher id $teacherId');
    ChatSocket.getChatLogHistory(
        teacherId, userTypeId == '2' ? 'teacher_student' : 'hod_student');
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Exit'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: ColorResources.colorgrey200,
          appBar: CustomAppBar(
            labelText: 'Search Student',
            isStudentList: false,
            onChanged: (value) {
              searchQuery.value = value;
            },
            title: 'Chats',
            controller: searchController,
          ),
          body: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Obx(() {
                var filteredList = chatHistoryController.studentChatLogList
                    .where((chat) =>
                        chat.firstName
                            .toLowerCase()
                            .contains(searchQuery.value.toLowerCase()) ||
                        chat.lastName
                            .toLowerCase()
                            .contains(searchQuery.value.toLowerCase()))
                    .toList();

                return Column(
                  children: [
                    Expanded(
                      child: filteredList.isEmpty
                          ? Center(
                              child: Text(
                                'No chats available',
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
                                var chatItem = filteredList[index];

                                DateTime timestamp = chatItem.sentTime
                                    .toLocal(); // Convert to local time
                                final now = DateTime.now();
                                final today =
                                    DateTime(now.year, now.month, now.day);
                                final yesterday =
                                    today.subtract(const Duration(days: 1));
                                final dateToCheck = DateTime(timestamp.year,
                                    timestamp.month, timestamp.day);

                                String formattedTime =
                                    DateFormat('hh:mm a').format(timestamp);
                                String displayDate;

                                if (dateToCheck == today) {
                                  // For today, show the time instead of "Today" based on user preference/standard chat UI,
                                  // or keep "Today" if that's the specific design.
                                  // However, looking at the screenshot "11:19 AM", standard apps show Time for today.
                                  // But the user's code previously showed 'Today'.
                                  // Let's stick to the user's apparent intent but fix the value.
                                  // Wait, standard behavior:
                                  // Today -> Show Time
                                  // Yesterday -> Show "Yesterday"
                                  // Older -> Show Date
                                  // The User's previous code calculated `displayDate` and passed it to `date` param of widget.
                                  // And `formattedTime` was passed to `time` param.
                                  // Let's just fix the Date Logic first.
                                  displayDate = 'Today';
                                } else if (dateToCheck == yesterday) {
                                  displayDate = 'Yesterday';
                                } else {
                                  displayDate = DateFormat('dd MMM yyyy')
                                      .format(timestamp);
                                }

                                return Column(
                                  children: [
                                    InkWell(
                                      onTap: () async {
                                        print(
                                          "Count-------- ${chatItem.unreadCount}",
                                        );
                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        String userTypeId =
                                            prefs.getString('user_type_id') ??
                                                '2';
                                        final String teacherId =
                                            prefs.getString(
                                                    'breffini_teacher_Id') ??
                                                "0";
                                        // Loader.showLoader();
                                        // log('loader showing ?????????');
                                        await ChatSocket.joinConversationRoom(
                                            chatItem.studentId.toString(),
                                            int.parse(teacherId),
                                            userTypeId == '2'
                                                ? 'teacher_student'
                                                : 'hod_student');
                                        await Get.to(() => ChatFireBaseScreen(
                                              isDeletedUser:
                                                  chatItem.deleteStatus == 1
                                                      ? true
                                                      : false,
                                              courseId: userTypeId == '2'
                                                  ? '0'
                                                  : '${chatItem.courseId}Hod',
                                              userType: userTypeId,
                                              contactDetails:
                                                  chatItem.firstName,
                                              studentName: chatItem
                                                          .deleteStatus ==
                                                      1
                                                  ? "Deleted user"
                                                  : '${chatItem.firstName} ${chatItem.lastName}',
                                              studentId:
                                                  chatItem.studentId.toString(),
                                              profileUrl: chatItem
                                                          .deleteStatus ==
                                                      1
                                                  ? ""
                                                  : '${HttpUrls.imgBaseUrl}${chatItem.profilePhotoPath}',
                                            ))?.then((value) {
                                          _fetchData();
                                        });
                                        // Loader.stopLoader();
                                      },
                                      child: chatHistoryWidget(
                                        name: chatItem.deleteStatus == 1
                                            ? "Deleted user"
                                            : '${chatItem.firstName} ${chatItem.lastName}',
                                        content: chatItem.chatMessage.isNotEmpty
                                            ? chatItem.chatMessage
                                            : 'A file is attached',
                                        count: chatItem.unreadCount.toString(),
                                        date: displayDate,
                                        time: formattedTime,
                                        image: chatItem.deleteStatus == 1
                                            ? ''
                                            : '${HttpUrls.imgBaseUrl}${chatItem.profilePhotoPath}',
                                      ),
                                    ),
                                    SizedBox(
                                      height: 4.h,
                                    ),
                                    Divider(
                                      height: 2.h,
                                      color: ColorResources.colorgrey300,
                                    ),
                                    SizedBox(
                                      height: 4.h,
                                    ),
                                  ],
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
      ),
    );
  }
}
