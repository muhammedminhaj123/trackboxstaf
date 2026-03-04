import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:breffini_staff/controller/calls_page_controller.dart';
import 'package:breffini_staff/controller/individual_call_controller.dart';
import 'package:breffini_staff/controller/live_controller.dart';
import 'package:breffini_staff/controller/profile_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/core/theme/custom_text_style.dart';
import 'package:breffini_staff/controller/chat_firebase_controller.dart';

import 'package:breffini_staff/core/utils/extentions.dart';
import 'package:breffini_staff/core/utils/file_utils.dart';
import 'package:breffini_staff/core/utils/key_center.dart';
import 'package:breffini_staff/core/utils/pref_utils.dart';
import 'package:breffini_staff/http/cloud_flare_upload.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/http/chat_socket.dart';
import 'package:breffini_staff/model/chat_message_model.dart';
import 'package:breffini_staff/model/student_chat_model.dart';
import 'package:breffini_staff/view/pages/calls/incoming_call_screen.dart';

import 'package:breffini_staff/view/pages/chats/image_viewer_screen.dart';
import 'package:breffini_staff/view/pages/chats/widgets/common_widgets.dart';
import 'package:breffini_staff/view/pages/chats/widgets/video_screen.dart';
import 'package:breffini_staff/view/pages/courses/pdf_viewer_page.dart';
import 'package:breffini_staff/view/pages/profile/profile_view_page.dart';
import 'package:breffini_staff/view/widgets/player_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

class ChatFireBaseScreen extends StatefulWidget {
  final String studentId;
  final String profileUrl;
  final String studentName;
  final String contactDetails;
  final bool isDeletedUser;
  final String courseId;
  final String userType;
  const ChatFireBaseScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.profileUrl,
    required this.contactDetails,
    required this.courseId,
    required this.userType,
    required this.isDeletedUser,
  });

  @override
  State<ChatFireBaseScreen> createState() => _ChatFireBaseScreenState();
}

class _ChatFireBaseScreenState extends State<ChatFireBaseScreen> {
  final player = AudioPlayer();
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;
  final LiveClassController liveClassController =
      Get.put(LiveClassController());
  final AudioRecorder _audioRecorder = AudioRecorder();
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final callandChatController = Get.put(CallandChatController());
  final IndividualCallController controller =
      Get.put(IndividualCallController());

  // bool _isInitialLoadComplete = false;
  int _pendingImageLoads = 0;
  int _pendingVideoLoads = 0;

  // final FocusNode _messageFocusNode = FocusNode();
  File? selectedFile;
  String filePath = '';
  File? recorderAudioFile;

  // String audioUrl = '';
  File? audioFile;
  final ChatFireBaseController chatController =
      Get.put(ChatFireBaseController());
  bool isMessageTyped = false;
  String _currentAudioUrl = '';
  Timer? _timer;
  int _start = 0; // Timer starts from 0 seconds
  String _formattedTime = "00:00";
  bool isRecording = true;
  bool _isButtonEnabled = true;
  Directory tempDir = Directory("");

  @override
  void initState() {
    super.initState();
    loadData();
    _messageController.addListener(() {
      setState(() {
        isMessageTyped = _messageController.text.isNotEmpty;
      });
    });
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    chatController.isSendingMessage.value = false;
    chatController.isRecording.value = false;
    chatController.shouldAutoScroll.value = true;
    chatController.scrollNow.value = false;
    chatController.visibleScrollBtn.value = false;
    chatController.notVisibleMsgCount.value = 0;
    chatController.isFirstFetch = false;
    chatController.chatSubscription?.cancel();

    _scrollController.dispose();
    // _messageFocusNode.dispose();
    _messageController.dispose();
    _timer?.cancel();
    player.stop();
    player.dispose();
    _audioRecorder.stop();
    _audioRecorder.dispose();

    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    super.dispose();
  }

  getTempDir() async {
    tempDir = await getTemporaryDirectory();
    setState(() {});
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String teacherId = prefs.getString('breffini_teacher_Id') ?? "0";

    await chatController.fetchMessages(
        widget.studentId, widget.userType == '2' ? teacherId : widget.courseId);

    // setState(() => _isInitialLoadComplete = true);
    // _scrollToBottom(animated: false);
    await _initStreams();
    await getTempDir();
  }

  // _handleVideoLoad() {
  //   _pendingVideoLoads--;
  //   if (_pendingVideoLoads <= 0 && _isInitialLoadComplete) {
  //     _scrollToBottom(animated: false);
  //   }
  // }

  // void _scrollToBottom({bool animated = true}) {
  //   if (!_scrollController.hasClients) return;
  //
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (!_scrollController.hasClients) return;
  //
  //     try {
  //       final target = _scrollController.position.minScrollExtent;
  //       if (animated) {
  //         _scrollController.animateTo(
  //           target,
  //           duration: const Duration(milliseconds: 100),
  //           curve: Curves.linear,
  //         );
  //       }
  //       // else {
  //       //   // _scrollController.jumpTo(target);
  //       // }
  //     } catch (e) {
  //       print('Scroll error: $e');
  //     }
  //   });
  // }

  // void _handleImageLoad() {
  //   _pendingImageLoads--;
  //   if (_pendingImageLoads <= 0 && _isInitialLoadComplete) {
  //     // _scrollToBottom(animated: false);
  //   }
  // }
  // void _scrollToBottom() {
  //   if (_scrollController.hasClients) {
  //     _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  //   }
  // }

  Future<void> pickMedia(bool isDoc) async {
    List<String> docList = [
      'pdf',
      'png',
      'doc',
      'docx',
      'xls',
      'xlsx',
    ];
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: isDoc
          ? docList
          : [
              'jpeg',
              'png',
              'mp4',
            ],
    );

    if (result != null) {
      if (isDoc && docList.contains(result.files.first.extension) || !isDoc) {
        // blocking not listed files like audio
        int maxFileSize = 20 * 1024 * 1024; // Example: 20 MB
        File file = File(result.files.first.path!);
        int fileSize = await file.length();

        if (fileSize > maxFileSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Maximum file size is 20 mb")),
          );
        } else {
          selectedFile = file;
        }
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  (result.files.first.extension ?? "") + " not supported")),
        );
      }
    } else {
      log('User closed without selecting');
    }
  }

  Future<void> downloadAndOpenFile(
      String fileName, int index, ChatMessageModel messageModel) async {
    final filePath = '${tempDir.path}/$fileName';
    String messageId = messageModel.sentTime.toString();
    // If the file is already downloaded, open it directly
    if (File(filePath).existsSync()) {
      if (fileName.endsWith(".pdf")) {
        OpenFile.open(filePath);
      } else if (fileName.endsWith(".m4a")) {
        playAudio(index, messageModel, filePath, false);
      }
      return;
    }

    chatController.updateDownloadProgress(index, 0.1);

    try {
      final dio = Dio();
      String url = HttpUrls.imgBaseUrl + messageModel.filePath!;
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            print((received / total).toString());
            chatController.updateDownloadProgress(index, received / total);
          }
        },
      );

      if (fileName.endsWith(".pdf")) {
        OpenFile.open(filePath);
      } else if (fileName.endsWith(".m4a")) {
        playAudio(index, messageModel, filePath, false);
      }
    } catch (e) {
      log('Error downloading or opening file: $e');
    } finally {
      chatController.updateDownloadProgress(index, 0);
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: ColorResources.colorgrey200,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(58.h),
          child: buildAppBar(
            usertype: widget.userType,
            studentId: widget.studentId,
            profileUrl: widget.profileUrl,
            studentName: widget.studentName,
            onAvatarTap: widget.isDeletedUser
                ? () {
                    Get.showSnackbar(const GetSnackBar(
                      message: 'This user is deleted',
                      duration: Duration(milliseconds: 2000),
                    ));
                  }
                : () {
                    Get.to(() => ProfileViewPage(
                          courseId: widget.courseId,
                          studentId: widget.studentId,
                          contactDetails: widget.contactDetails,
                          profileUrl: widget.profileUrl,
                          studentName: widget.studentName,
                        ));
                  },
            // onAudioTap: widget.isDeletedUser
            //     ? () {
            //         Get.showSnackbar(const GetSnackBar(
            //           message: 'This user is deleted',
            //           duration: Duration(milliseconds: 2000),
            //         ));
            //       }
            //     : () async {
            //         // disable double click

            //         if (_isButtonEnabled) {
            //           setState(() {
            //             _isButtonEnabled = false;
            //           });
            //           if (!await isCallExist(context, callandChatController)) {
            //             Get.to(() => IncomingCallPage(
            //                   liveLink: "",
            //                   callId: "",
            //                   studentId: widget.studentId.toString(),
            //                   video: false,
            //                   profileImageUrl: widget.profileUrl,
            //                   studentName: widget.studentName,
            //                 ));
            //           }

            //           Future.delayed(const Duration(seconds: 1), () {
            //             if (mounted) {
            //               setState(() {
            //                 _isButtonEnabled = true;
            //               });
            //             }
            //           });
            //         }
            //       },

            // onVideoTap: widget.isDeletedUser
            //     ? () {
            //         Get.showSnackbar(const GetSnackBar(
            //           message: 'This user is deleted',
            //           duration: Duration(milliseconds: 2000),
            //         ));
            //       }
            //     : () async {
            //         // Get.to(() => TeacherInitiateCallScreen(
            //         //     studentId: int.parse(widget.studentId), video: true));
            //         // disable double click
            //         if (_isButtonEnabled) {
            //           setState(() {
            //             _isButtonEnabled = false;
            //           });

            //           if(!await isCallExist(context,callandChatController)) {

            //             Get.to(() => IncomingCallPage(
            //                             liveLink: "",
            //                             callId: "",
            //                             studentId: widget.studentId.toString(),
            //                             video: true,
            //                             profileImageUrl: widget.profileUrl,
            //                             studentName: widget.studentName,
            //                           ));
            //           }

            //           Future.delayed(const Duration(seconds: 1), () {
            //             if (mounted) {
            //               setState(() {
            //                 _isButtonEnabled = true;
            //               });
            //             }
            //           });
            //         }
            //       },
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: 16.h,
                ),
                Obx(
                  () {
                    if (chatController.scrollNow.value) {
                      _scrollToBottom(false);
                    }

                    return chatController.isLoadingChat.value
                        ? Expanded(
                            child: Center(
                                child: CircularProgressIndicator(
                              color: ColorResources.colorBlue600,
                            )),
                          )
                        : Expanded(
                            child: chatController.messages.isEmpty
                                ? Center(
                                    child: Text(
                                    'No messages yet',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: ColorResources.colorgrey700,
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ))
                                : ListView.builder(
                                    reverse: false,
                                    // cacheExtent: 1000,
                                    // addAutomaticKeepAlives: true,
                                    itemCount: chatController.messages.length,
                                    shrinkWrap: true,
                                    physics: BouncingScrollPhysics(),
                                    controller: _scrollController,
                                    itemBuilder: (context, index) {
                                      // final reversedIndex =
                                      //     chatController.messages.length - 1 - index;
                                      ChatMessageModel messageModel =
                                          chatController.messages[index];
                                      final messageDate =
                                          DateFormat('yyyy-MM-dd').format(
                                              messageModel.sentTime.toLocal());
                                      {
                                        return Column(
                                          children: [
                                            if (index == 0 ||
                                                messageDate !=
                                                    DateFormat('yyyy-MM-dd')
                                                        .format(chatController
                                                            .messages[index - 1]
                                                            .sentTime
                                                            .toLocal()))
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 8.h),
                                                child: Center(
                                                  child: Text(
                                                    _formatDateHeader(
                                                        messageModel.sentTime
                                                            .toLocal()),
                                                    style: GoogleFonts
                                                        .plusJakartaSans(
                                                      color: ColorResources
                                                          .colorgrey700,
                                                      fontSize: 12.0,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                  left: 16.h, right: 16.h),
                                              child: Row(
                                                mainAxisAlignment: messageModel
                                                        .isStudent
                                                    ? MainAxisAlignment.start
                                                    : MainAxisAlignment.end,
                                                children: [
                                                  if (!messageModel.isStudent)
                                                    SizedBox(width: 50.h),
                                                  Expanded(
                                                    child: Align(
                                                      alignment: messageModel
                                                              .isStudent
                                                          ? Alignment.centerLeft
                                                          : Alignment
                                                              .centerRight,
                                                      child: Column(
                                                        crossAxisAlignment: messageModel
                                                                .isStudent
                                                            ? CrossAxisAlignment
                                                                .start
                                                            : CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(5.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: messageModel.isStudent
                                                                  ? ColorResources
                                                                      .colorgrey300
                                                                  : ColorResources
                                                                      .colorgrey300,
                                                              borderRadius: BorderRadius.only(
                                                                  topLeft:
                                                                      const Radius.circular(
                                                                          12),
                                                                  topRight:
                                                                      const Radius.circular(
                                                                          12),
                                                                  bottomLeft: !messageModel
                                                                          .isStudent
                                                                      ? const Radius.circular(
                                                                          12)
                                                                      : const Radius
                                                                          .circular(
                                                                          0),
                                                                  bottomRight: !messageModel
                                                                          .isStudent
                                                                      ? const Radius
                                                                          .circular(
                                                                          0)
                                                                      : const Radius
                                                                          .circular(
                                                                          12)),
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  messageModel
                                                                          .isStudent
                                                                      ? CrossAxisAlignment
                                                                          .start
                                                                      : CrossAxisAlignment
                                                                          .end,
                                                              children: [
                                                                if (messageModel
                                                                    .filePath
                                                                    .isNotEmpty)
                                                                  Column(
                                                                    children: [
                                                                      (messageModel
                                                                              .filePath
                                                                              .endsWith('.pdf'))
                                                                          ? GestureDetector(
                                                                              onTap: () {
                                                                                downloadAndOpenFile(messageModel.filePath.split('/').last, index, messageModel);
                                                                              },
                                                                              child: Container(
                                                                                height: 67.h,
                                                                                width: 200.h,
                                                                                decoration: BoxDecoration(
                                                                                    color: messageModel.isStudent ? ColorResources.colorwhite : ColorResources.colorwhite,
                                                                                    borderRadius: BorderRadius.all(
                                                                                      Radius.circular(12),
                                                                                    )),
                                                                                child: Padding(
                                                                                  padding: const EdgeInsets.all(8.0),
                                                                                  child: Row(
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                                    children: [
                                                                                      Obx(() {
                                                                                        return Container(
                                                                                          width: 40,
                                                                                          child: Column(
                                                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                                                            children: [
                                                                                              messageModel.progress! > 0
                                                                                                  ? Container(
                                                                                                      height: 23,
                                                                                                      width: 23,
                                                                                                      child: CircularProgressIndicator(
                                                                                                        value: messageModel.progress?.value,
                                                                                                      ),
                                                                                                    )
                                                                                                  : Icon(Icons.picture_as_pdf),
                                                                                              Padding(
                                                                                                padding: const EdgeInsets.only(top: 4.0),
                                                                                                child: Text(
                                                                                                  messageModel.fileSize! > 0 ? FileUtils.getFileSize(messageModel.fileSize ?? 0) : "",
                                                                                                  style: GoogleFonts.plusJakartaSans(color: ColorResources.colorBlack, fontSize: 8, fontWeight: FontWeight.w600),
                                                                                                ),
                                                                                              )
                                                                                            ],
                                                                                          ),
                                                                                        );
                                                                                      }),
                                                                                      Padding(
                                                                                        padding: const EdgeInsets.only(top: 4.0, left: 8),
                                                                                        child: Text(
                                                                                          'Pdf file',
                                                                                          style: GoogleFonts.plusJakartaSans(color: ColorResources.colorBlack, fontSize: 12, fontWeight: FontWeight.w600),
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            )
                                                                          : (messageModel.filePath.endsWith('.mp4'))
                                                                              ? GestureDetector(
                                                                                  onTap: () async {
                                                                                    Get.to(() => VideoViewScreen(videoUrl: '${HttpUrls.imgBaseUrl}${messageModel.filePath}', thumbUrl: '${HttpUrls.imgBaseUrl}${messageModel.thumbUrl}'));
                                                                                  },
                                                                                  child: Container(
                                                                                      height: 200.h,
                                                                                      width: 200.h,
                                                                                      decoration: BoxDecoration(
                                                                                        color: messageModel.isStudent! ? ColorResources.colorwhite : ColorResources.colorwhite,
                                                                                        borderRadius: BorderRadius.all(
                                                                                          Radius.circular(12),
                                                                                        ),
                                                                                      ),
                                                                                      child: Stack(
                                                                                        alignment: Alignment.center,
                                                                                        // mainAxisAlignment: MainAxisAlignment.center,
                                                                                        // crossAxisAlignment: CrossAxisAlignment.center,
                                                                                        children: [
                                                                                          if (!messageModel.thumbUrl!.isNullOrEmpty())
                                                                                            ClipRRect(
                                                                                              borderRadius: BorderRadius.circular(12),
                                                                                              child: CachedNetworkImage(
                                                                                                  imageUrl: '${HttpUrls.imgBaseUrl}${messageModel.thumbUrl}',
                                                                                                  width: double.infinity,
                                                                                                  height: double.infinity,
                                                                                                  fit: BoxFit.cover,
                                                                                                  errorWidget: (context, url, error) => const Center(
                                                                                                        child: Icon(
                                                                                                          Icons.image_not_supported_outlined,
                                                                                                          color: ColorResources.colorBlue100,
                                                                                                          size: 40,
                                                                                                        ),
                                                                                                      )),
                                                                                            ),
                                                                                          Icon(
                                                                                            Icons.play_circle,
                                                                                            color: ColorResources.colorgrey300,
                                                                                            size: 50,
                                                                                          ),
                                                                                          Padding(
                                                                                            padding: EdgeInsets.only(top: 70.h),
                                                                                            child: Text(
                                                                                              messageModel.fileSize! > 0 ? FileUtils.getFileSize(messageModel.fileSize ?? 0) : "",
                                                                                              style: GoogleFonts.plusJakartaSans(color: ColorResources.colorgrey300, fontSize: 10, fontWeight: FontWeight.w600),
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      )),
                                                                                )
                                                                              : (messageModel.filePath.endsWith('.m4a'))
                                                                                  ? SizedBox(
                                                                                      // height: 0,
                                                                                      width: 500,
                                                                                      child: Obx(() {
                                                                                        return Row(
                                                                                          children: [
                                                                                            (messageModel.progress! > 0)
                                                                                                ? Container(
                                                                                                    height: 20,
                                                                                                    width: 20,
                                                                                                    margin: EdgeInsets.symmetric(horizontal: 5),
                                                                                                    child: CircularProgressIndicator(
                                                                                                      color: ColorResources.colorBlue300,
                                                                                                      value: messageModel.progress?.value,
                                                                                                    ),
                                                                                                  )
                                                                                                : Container(
                                                                                                    width: 45,
                                                                                                    height: 45,
                                                                                                    margin: const EdgeInsets.all(4),
                                                                                                    decoration: const BoxDecoration(
                                                                                                      color: Color(0xFF6A7487),
                                                                                                      borderRadius: BorderRadius.all(Radius.circular(20)),
                                                                                                    ),
                                                                                                    child: InkWell(
                                                                                                        onTap: () {
                                                                                                          if (chatController.currentPlayingIndex.value == index) {
                                                                                                            final filePath = tempDir.path + "/" + messageModel.filePath.split('/').last;
                                                                                                            playAudio(index, messageModel, filePath, true);
                                                                                                          } else {
                                                                                                            downloadAndOpenFile(messageModel.filePath.split('/').last, index, messageModel);
                                                                                                          }
                                                                                                        },
                                                                                                        child: Icon(
                                                                                                          chatController.currentPlayingIndex == index ? Icons.pause : Icons.play_arrow,
                                                                                                          color: Colors.white,
                                                                                                          size: 28,
                                                                                                        )),
                                                                                                  ),
                                                                                            Expanded(
                                                                                              child: Slider(
                                                                                                thumbColor: messageModel.isStudent ? const Color(0xFFE3E7EE) : const Color(0xFF6A7487),
                                                                                                activeColor: messageModel.isStudent ? const Color(0xFF6A7487) : const Color(0xFF6A7487),
                                                                                                inactiveColor: messageModel.isStudent ? const Color(0xFF6A7487) : const Color(0xFF6A7487),

                                                                                                min: 0,
                                                                                                max: chatController.currentPlayingIndex == index ? chatController.duration.value.inMilliseconds.toDouble() : 0,
                                                                                                // inactiveColor: ColorResources.colorgrey700,
                                                                                                // activeColor: ColorResources.colorgrey700,
                                                                                                value: chatController.currentPlayingIndex == index ? (chatController.position.value.inMilliseconds.toDouble() < chatController.duration.value.inMilliseconds.toDouble() ? chatController.position.value.inMilliseconds.toDouble() : chatController.duration.value.inMilliseconds.toDouble()) : 0,
                                                                                                onChanged: (value) {
                                                                                                  player.seek(Duration(milliseconds: value.round()));
                                                                                                },
                                                                                              ),
                                                                                            ),
                                                                                            (chatController.currentPlayingIndex == index)
                                                                                                ? Padding(
                                                                                                    padding: const EdgeInsets.only(right: 0),
                                                                                                    child: Text(
                                                                                                      ((chatController.position.value.inSeconds.toMinSecond()) + "/" + chatController.duration.value.inSeconds.toMinSecond()),
                                                                                                      style: GoogleFonts.plusJakartaSans(color: messageModel.isStudent ?? false ? ColorResources.colorBlack : ColorResources.colorBlack, fontSize: 8, fontWeight: FontWeight.w600),
                                                                                                    ),
                                                                                                  )
                                                                                                : Padding(
                                                                                                    padding: const EdgeInsets.only(right: 0),
                                                                                                    child: Text(
                                                                                                      "00:00/00:00",
                                                                                                      style: GoogleFonts.plusJakartaSans(color: messageModel.isStudent ?? false ? ColorResources.colorBlack : ColorResources.colorBlack, fontSize: 8, fontWeight: FontWeight.w600),
                                                                                                    ),
                                                                                                  ),
                                                                                          ],
                                                                                        );
                                                                                      }))
                                                                                  : GestureDetector(
                                                                                      onTap: () {
                                                                                        Get.to(() => ImageViewerScreen(imageUrl: '${HttpUrls.imgBaseUrl}${messageModel.filePath}'));
                                                                                      },
                                                                                      child: ClipRRect(
                                                                                          borderRadius: BorderRadius.circular(12),

                                                                                          // height: 150.h,
                                                                                          // width: 200.h,
                                                                                          // decoration:
                                                                                          // BoxDecoration(
                                                                                          //     color: messageModel
                                                                                          //         .isStudent!
                                                                                          //         ? ColorResources
                                                                                          //         .colorwhite
                                                                                          //         : ColorResources
                                                                                          //         .colorwhite,
                                                                                          //     borderRadius: BorderRadius.all(Radius
                                                                                          //         .circular(12),
                                                                                          //     )
                                                                                          // ),
                                                                                          child: CachedNetworkImage(
                                                                                            height: 150.h,
                                                                                            width: 200.h,
                                                                                            imageUrl: '${HttpUrls.imgBaseUrl}${messageModel.filePath}',
                                                                                            fit: BoxFit.cover,
                                                                                            errorWidget: (context, url, error) => const Center(
                                                                                              child: Icon(
                                                                                                Icons.image_not_supported_outlined,
                                                                                                color: ColorResources.colorBlue100,
                                                                                                size: 40,
                                                                                              ),
                                                                                            ),
                                                                                            progressIndicatorBuilder: (context, url, downloadProgress) => Center(
                                                                                              child: CircularProgressIndicator(
                                                                                                strokeWidth: 3,
                                                                                                color: ColorResources.colorBlue500,
                                                                                                value: downloadProgress.progress,
                                                                                              ),
                                                                                            ),
                                                                                            imageBuilder: (context, imageProvider) {
                                                                                              // WidgetsBinding.instance.addPostFrameCallback((_) {
                                                                                              //   _handleImageLoad();
                                                                                              // });
                                                                                              return Image(image: imageProvider, fit: BoxFit.cover);
                                                                                            },
                                                                                          )),
                                                                                    ),
                                                                      SizedBox(
                                                                          height:
                                                                              2),
                                                                    ],
                                                                  ),
                                                                if (!messageModel
                                                                    .chatMessage
                                                                    .isNullOrEmpty())
                                                                  SizedBox(
                                                                    child:
                                                                        Padding(
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          8.0),
                                                                      child:
                                                                          Text(
                                                                        messageModel
                                                                            .chatMessage,
                                                                        style: GoogleFonts
                                                                            .plusJakartaSans(
                                                                          color: messageModel.isStudent
                                                                              ? ColorResources.colorBlack
                                                                              : ColorResources.colorBlack,
                                                                          fontSize:
                                                                              14.0,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                          SizedBox(height: 4.h),
                                                          Text(
                                                            messageModel
                                                                .formattedTime,
                                                            style: GoogleFonts
                                                                .plusJakartaSans(
                                                              color: ColorResources
                                                                  .colorgrey600,
                                                              fontSize: 10.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                              height: 15.h),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  if (messageModel.isStudent)
                                                    SizedBox(width: 50.h),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                            // child: Obx(() {
                            //   List<Widget> messageWidgets = [];
                            //   String? lastDate;

                            //   for (var i = 0; i < _chatController.messages.length; i++) {
                            //     ChatMessage messageModel = _chatController.messages[i];
                            //     // audioUrl = message.filePath;
                            //     final messageDate =
                            //         DateFormat('yyyy-MM-dd').format(messageModel.sentTime);

                            //     if (messageDate != lastDate) {
                            //       lastDate = messageDate;
                            //       final dateTime = messageModel.sentTime;
                            //       messageWidgets.add(
                            //         Padding(
                            //           padding: EdgeInsets.symmetric(vertical: 8.h),
                            //           child: Center(
                            //             child: Text(
                            //               _formatDateHeader(dateTime),
                            //               style: GoogleFonts.plusJakartaSans(
                            //                 color: ColorResources.colorgrey700,
                            //                 fontSize: 12.sp,
                            //                 fontWeight: FontWeight.w500,
                            //               ),
                            //             ),
                            //           ),
                            //         ),
                            //       );
                            //     }

                            //     messageWidgets.add(
                            //       Padding(
                            //         padding: EdgeInsets.only(left: 16.h, right: 16.h),
                            //         child: Row(
                            //           mainAxisAlignment: messageModel.isStudent
                            //               ? MainAxisAlignment.start
                            //               : MainAxisAlignment.end,
                            //           children: [
                            //             if (!messageModel.isStudent) SizedBox(width: 50.h),
                            //             Expanded(
                            //               child: Align(
                            //                 alignment: messageModel.isStudent
                            //                     ? Alignment.centerLeft
                            //                     : Alignment.centerRight,
                            //                 child: Column(
                            //                   crossAxisAlignment: messageModel.isStudent
                            //                       ? CrossAxisAlignment.start
                            //                       : CrossAxisAlignment.end,
                            //                   children: [
                            //                     Container(
                            //                       // padding: const EdgeInsets.all(10.0),
                            //                       decoration: BoxDecoration(
                            //                         color: messageModel.isStudent
                            //                             ? ColorResources.colorwhite
                            //                             : ColorResources.colorgrey700,
                            //                         borderRadius: BorderRadius.only(
                            //                             topLeft: const Radius.circular(12),
                            //                             topRight: const Radius.circular(12),
                            //                             bottomLeft: messageModel.isStudent
                            //                                 ? const Radius.circular(0)
                            //                                 : const Radius.circular(12),
                            //                             bottomRight: messageModel.isStudent
                            //                                 ? const Radius.circular(12)
                            //                                 : const Radius.circular(0)),
                            //                       ),
                            //                       child: Column(
                            //                         crossAxisAlignment: messageModel.isStudent
                            //                             ? CrossAxisAlignment.start
                            //                             : CrossAxisAlignment.end,
                            //                         children: [
                            //                           if (messageModel.filePath.isNotEmpty)
                            //                             Column(
                            //                               children: [
                            //                                 if (messageModel.filePath
                            //                                     .endsWith('.pdf'))
                            //                                   Padding(
                            //                                     padding: const EdgeInsets.all(
                            //                                         10.0),
                            //                                     child: GestureDetector(
                            //                                       onTap: () {
                            //                                         downloadAndOpenFile(
                            //                                           '${HttpUrls.imgBaseUrl}${messageModel.filePath}',
                            //                                           messageModel.filePath
                            //                                               .split('/')
                            //                                               .last,
                            //                                           messageModel.sentTime
                            //                                               .toString(),
                            //                                         );
                            //                                       },
                            //                                       child: Container(
                            //                                         height: 60.h,
                            //                                         width: 200.h,
                            //                                         decoration: BoxDecoration(
                            //                                           borderRadius: BorderRadius.only(
                            //                                               topLeft: const Radius
                            //                                                   .circular(12),
                            //                                               topRight: const Radius
                            //                                                   .circular(12),
                            //                                               bottomLeft: messageModel
                            //                                                       .isStudent
                            //                                                   ? const Radius
                            //                                                       .circular(0)
                            //                                                   : const Radius.circular(
                            //                                                       12),
                            //                                               bottomRight: messageModel
                            //                                                       .isStudent
                            //                                                   ? const Radius
                            //                                                       .circular(
                            //                                                       12)
                            //                                                   : const Radius
                            //                                                       .circular(0)),
                            //                                           color: ColorResources
                            //                                               .colorwhite,
                            //                                         ),
                            //                                         child: Center(
                            //                                           child: downloadProgressMap
                            //                                                   .containsKey(
                            //                                                       messageModel
                            //                                                           .sentTime
                            //                                                           .toString())
                            //                                               ? CircularProgressIndicator(
                            //                                                   value: downloadProgressMap[
                            //                                                       messageModel
                            //                                                           .sentTime
                            //                                                           .toString()],
                            //                                                 )
                            //                                               : Row(
                            //                                                   children: [
                            //                                                     const SizedBox(
                            //                                                       width: 10,
                            //                                                     ),
                            //                                                     const Icon(
                            //                                                       Icons
                            //                                                           .picture_as_pdf_outlined,
                            //                                                       color: Colors
                            //                                                           .red,
                            //                                                     ),
                            //                                                     Text(
                            //                                                       '    Pdf file',
                            //                                                       style: GoogleFonts.plusJakartaSans(
                            //                                                           color: Colors
                            //                                                               .red,
                            //                                                           fontSize: 12
                            //                                                               .sp,
                            //                                                           fontWeight:
                            //                                                               FontWeight.w600),
                            //                                                     ),
                            //                                                   ],
                            //                                                 ),
                            //                                         ),
                            //                                       ),
                            //                                     ),
                            //                                   )
                            //                                 else if (messageModel.filePath
                            //                                     .endsWith('.mp4'))
                            //                                   GestureDetector(
                            //                                     onTap: () {
                            //                                       Get.to(
                            //                                           () => VideoViewScreen(
                            //                                                 videoUrl:
                            //                                                     '${HttpUrls.imgBaseUrl}${messageModel.filePath}',
                            //                                               ));
                            //                                     },
                            //                                     child: Container(
                            //                                       height: 150.h,
                            //                                       width: 200.h,
                            //                                       color: ColorResources
                            //                                           .colorBlack,
                            //                                       child: const Center(
                            //                                         child: Icon(
                            //                                           Icons.play_arrow,
                            //                                           color: Colors.white,
                            //                                           size: 50,
                            //                                         ),
                            //                                       ),
                            //                                     ),
                            //                                   )
                            //                                 else if (messageModel.filePath
                            //                                     .endsWith('.m4a'))
                            //                                   PlayerWidget(
                            //                                     isStudent:
                            //                                         messageModel.isStudent,
                            //                                     key: ValueKey(messageModel
                            //                                         .filePath), // Use the file path as a unique key
                            //                                     isPlaying:
                            //                                         messageModel.isPlaying ??
                            //                                             false,
                            //                                     onClickPlay: (v) async {
                            //                                       // Stop any currently playing audio before starting a new one
                            //                                       if (_currentAudioUrl !=
                            //                                           messageModel.filePath) {
                            //                                         // Stop previous playback and update the state
                            //                                         setState(() {
                            //                                           _currentAudioUrl =
                            //                                               messageModel
                            //                                                   .filePath;
                            //                                           _chatController.messages
                            //                                               .forEach((msg) {
                            //                                             msg.isPlaying =
                            //                                                 false; // Stop all others
                            //                                           });
                            //                                           messageModel.isPlaying =
                            //                                               true; // Set this one to playing
                            //                                         });

                            //                                         await player
                            //                                             .stop(); // Stop any previous playback
                            //                                         await player.play(UrlSource(
                            //                                             '${HttpUrls.imgBaseUrl}$_currentAudioUrl'));
                            //                                       } else if (messageModel
                            //                                               .isPlaying ==
                            //                                           false) {
                            //                                         // If the current message is paused, resume it
                            //                                         setState(() {
                            //                                           messageModel.isPlaying =
                            //                                               true; // Update state to playing
                            //                                         });
                            //                                         await player
                            //                                             .resume(); // Resume playback
                            //                                       }
                            //                                     },
                            //                                     onClickPaused: (v) {
                            //                                       setState(() {
                            //                                         messageModel.isPlaying =
                            //                                             false;
                            //                                         _chatController
                            //                                             .messages[i]
                            //                                             .isPlaying = false;
                            //                                       });
                            //                                       player.pause();
                            //                                     },
                            //                                     player: player,
                            //                                     moreMenuButton: false,
                            //                                     durationTextColor:
                            //                                         !messageModel.isStudent
                            //                                             ? Colors.white
                            //                                             : const Color(
                            //                                                 0xFF6A7487),
                            //                                   )
                            //                                 else
                            //                                   Padding(
                            //                                     padding: const EdgeInsets.all(
                            //                                         10.0),
                            //                                     child: GestureDetector(
                            //                                       onTap: () {
                            //                                         Get.to(() =>
                            //                                             ImageViewerScreen(
                            //                                                 imageUrl:
                            //                                                     '${HttpUrls.imgBaseUrl}${messageModel.filePath}'));
                            //                                       },
                            //                                       child: SizedBox(
                            //                                           height: 150.h,
                            //                                           width: 200.h,
                            //                                           child:
                            //                                               CachedNetworkImage(
                            //                                             imageUrl:
                            //                                                 '${HttpUrls.imgBaseUrl}${messageModel.filePath}',
                            //                                             fit: BoxFit.cover,
                            //                                             errorWidget: (context,
                            //                                                     url, error) =>
                            //                                                 const Center(
                            //                                               child: Icon(
                            //                                                 Icons
                            //                                                     .image_not_supported_outlined,
                            //                                                 color: ColorResources
                            //                                                     .colorBlue100,
                            //                                                 size: 40,
                            //                                               ),
                            //                                             ),
                            //                                             progressIndicatorBuilder:
                            //                                                 (context, url,
                            //                                                         downloadProgress) =>
                            //                                                     Center(
                            //                                               child:
                            //                                                   CircularProgressIndicator(
                            //                                                 strokeWidth: 3,
                            //                                                 color: ColorResources
                            //                                                     .colorBlue500,
                            //                                                 value:
                            //                                                     downloadProgress
                            //                                                         .progress,
                            //                                               ),
                            //                                             ),
                            //                                             imageBuilder: (context,
                            //                                                 imageProvider) {
                            //                                               WidgetsBinding
                            //                                                   .instance
                            //                                                   .addPostFrameCallback(
                            //                                                       (_) {
                            //                                                 _handleImageLoad();
                            //                                               });
                            //                                               return Image(
                            //                                                   image:
                            //                                                       imageProvider,
                            //                                                   fit: BoxFit
                            //                                                       .cover);
                            //                                             },
                            //                                           )),
                            //                                     ),
                            //                                   ),
                            //                               ],
                            //                             )
                            //                           else
                            //                             SizedBox(
                            //                               child: Padding(
                            //                                 padding:
                            //                                     const EdgeInsets.all(10.0),
                            //                                 child: Text(
                            //                                   messageModel.chatMessage,
                            //                                   maxLines: 4,
                            //                                   overflow: TextOverflow.ellipsis,
                            //                                   style:
                            //                                       GoogleFonts.plusJakartaSans(
                            //                                     color: messageModel.isStudent
                            //                                         ? ColorResources
                            //                                             .colorBlack
                            //                                         : ColorResources
                            //                                             .colorwhite,
                            //                                     fontSize: 14.sp,
                            //                                     fontWeight: FontWeight.w500,
                            //                                   ),
                            //                                 ),
                            //                               ),
                            //                             ),
                            //                         ],
                            //                       ),
                            //                     ),
                            //                     SizedBox(height: 4.h),
                            //                     Text(
                            //                       messageModel.formattedTime,
                            //                       style: GoogleFonts.plusJakartaSans(
                            //                         color: ColorResources.colorgrey600,
                            //                         fontSize: 10.sp,
                            //                         fontWeight: FontWeight.w500,
                            //                       ),
                            //                     ),
                            //                     SizedBox(height: 15.h),
                            //                   ],
                            //                 ),
                            //               ),
                            //             ),
                            //             if (messageModel.isStudent) SizedBox(width: 50.h),
                            //           ],
                            //         ),
                            //       ),
                            //     );
                            //   }

                            //   return ListView(
                            //     controller: _scrollController,
                            //     cacheExtent: 1000,
                            //     addAutomaticKeepAlives: true,
                            //     children: messageWidgets,
                            //   );
                            // }),
                          );
                  },
                ),
              ],
            ),
            Obx(() {
              return (chatController.visibleScrollBtn.value ||
                      chatController.messages.isEmpty)
                  ? const SizedBox.shrink()
                  : Positioned(
                      right: -5,
                      bottom: 90,
                      child: FloatingActionButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        )),
                        mini: true,
                        backgroundColor: Colors.grey[800],
                        onPressed: () {
                          _scrollToBottom(true);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                            ),
                            if (chatController.notVisibleMsgCount > 0)
                              Text(
                                (chatController.notVisibleMsgCount).toString(),
                                style:
                                    TextStyle(color: Colors.white, fontSize: 8),
                              )
                          ],
                        ),
                      ),
                    );
            }),
          ],
        ),
        bottomNavigationBar: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Obx(() {
            return buildMessageSection(
              isVoiceMessage: chatController.isVoiceMessage.value,
              isRecording: chatController.isRecording.value,
              formattedTime: chatController.formattedTime.value,
              isMicOn: _messageController.text.isEmpty,
              isMessageTyped: isMessageTyped,
              isRecordingPaused: chatController.isRecordingPaused.value,
              onTextChanged: (value) {
                if (value.isEmpty || value.length == 1) {
                  setState(() {});
                }
              },
              controller: _messageController,
              isSendingMessage: chatController.isSendingMessage.value,
              onTapDocument: () async {
                await pickMedia(true);
                setState(() {});
                Get.back();
              },
              onTapFile: () async {
                await pickMedia(false);
                setState(() {});
                Get.back();
              },
              onPause: pauseRecording,
              onResume: resumeRecording,
              onStopVoice: () {
                stopRecording(true);
              },
              height: selectedFile == null ? 68.h : Get.height / 1.6,
              context: context,
              fileName: null != selectedFile
                  ? FileUtils.getFileName(selectedFile!.path ?? "")
                  : "",
              onTap: () async {
                // _scrollToBottom();
                if (_messageController.text.isNotEmpty ||
                    selectedFile != null) {
                  chatController.isSendingMessage.value = true;

                  await sendMessage(
                      selectedFile != null, selectedFile ?? File(""));
                  chatController.isSendingMessage.value = false;
                } else {
                  // Voice recording logic
                  if (recorderAudioFile == null ||
                      recorderAudioFile!.path.isNullOrEmpty()) {
                    chatController.isMicOn.value =
                        !chatController.isMicOn.value;
                    chatController.isVoiceMessage.value =
                        !chatController.isVoiceMessage.value;
                  }

                  if (!(await _audioRecorder.isRecording())) {
                    _startTimer();
                    await startRecording(); // Start recording
                  } else {
                    _stopTimer();
                    await stopRecording(false);
                    // Ensure file exists before sending
                    if (recorderAudioFile != null &&
                        recorderAudioFile!.existsSync()) {
                      chatController.isSendingMessage.value = true;
                      await sendMessage(true, recorderAudioFile!);
                      chatController.isSendingMessage.value = false;
                    }
                  }
                }

                // // Check if there's an audio file to send
                // if (selectedFile != null || audioFile != null) {
                //   print('fgdf2');
                //   File file = File(selectedFile?.path ?? audioFile!.path);
                //
                //   String? uploadKey = await AwsUpload.uploadChatImageToAws(
                //     file,
                //     widget.studentId,
                //     await SharedPreferences.getInstance().then((prefs) =>
                //         prefs.getString('breffini_teacher_Id') ?? "0"),
                //     selectedFile?.extension ?? p.extension(audioFile!.path),
                //   );
                //
                //   if (uploadKey != null) {
                //     final filePath = uploadKey;
                //     widget.userType == '2'
                //         ? await chatController.uploadFileAndSendMessage(
                //             _messageController.text,
                //             widget.studentId,
                //             selectedFile?.path ?? audioFile!.path,
                //             selectedFile?.extension ??
                //                 p.extension(audioFile!.path))
                //         : await chatController.uploadFileAndSendMessageofHod(
                //             _messageController.text,
                //             widget.studentId,
                //             widget.courseId.toString(),
                //             selectedFile?.path ?? audioFile!.path,
                //             selectedFile?.extension ??
                //                 p.extension(audioFile!.path));
                //
                //     SharedPreferences preferences =
                //         await SharedPreferences.getInstance();
                //     String teacherId =
                //         preferences.getString('breffini_teacher_Id') ?? '';
                //     String courseIdString = widget.courseId;
                //     int courseId = int.parse(
                //         RegExp(r'\d+').stringMatch(courseIdString)!);
                //     log("////////courseIDDDDDDDDD$courseId");
                //
                //     StudentChatModel studentMsg = StudentChatModel(
                //       courseId: courseId,
                //       chatType: widget.userType == '2'
                //           ? 'teacher_student'
                //           : 'hod_student',
                //       teacherId: int.parse(teacherId),
                //       studentId: int.parse(widget.studentId),
                //       chatMessage: _messageController.text.trim(),
                //       sentTime: DateTime.now().toString(),
                //       isStudent: false,
                //       filePath: filePath,
                //       senderName:  widget.userType == '2' ? PrefUtils().getTeacherName(): "HOD", // sanju told idea
                //       profileUrl: HttpUrls.imgBaseUrl+PrefUtils().getProfileUrl(),
                //
                //
                //     );
                //
                //     ChatSocket.startChatting(studentMsg);
                //     _messageController.clear();
                //
                //     // String userTypeId =
                //     //     preferences.getString('user_type_id') ?? '2';
                //     // log('teacher id $teacherId');
                //     // ChatbotSocket.getChatLogHistory(
                //     //     teacherId,
                //     //     userTypeId == '2'
                //     //         ? 'teacher_student'
                //     //         : 'hod_student');
                //   } else {
                //     log('Error uploading image');
                //   }
                // }

                setState(() {
                  selectedFile = null; // Reset the selected file
                  audioFile = null; // Reset the audio file
                });
              },
              imageWidget: selectedFile != null
                  ? Expanded(
                      child: Container(
                        // height: selectedFile!.path.isPdfFile()?(Get.height/2):40.h,
                        padding:
                            EdgeInsets.symmetric(horizontal: 10.h, vertical: 5),
                        alignment: Alignment.center,
                        // width: MediaQuery.of(context).size.width - 80.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.h),
                          color: ColorResources.colorwhite,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedFile = null;
                                      filePath = '';
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      CupertinoIcons.clear_circled,
                                      color: ColorResources.colorBlue300,
                                      size: 35,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${FileUtils.getFileName(selectedFile!.path!)}.${FileUtils.getFileExtension(selectedFile!.path!)}",
                                          overflow: TextOverflow.ellipsis,
                                          style: CustomTextStyles
                                              .titleSmallBluegray300Medium,
                                        ),
                                        Text(
                                          FileUtils.getFileSize(
                                              FileUtils.getFileSizeInKB(
                                                      selectedFile!.path!) ??
                                                  0.0),
                                          overflow: TextOverflow.ellipsis,
                                          style: CustomTextStyles
                                              .titleSmallBluegray300Medium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Container(height: 50,),
                            Expanded(
                              child: selectedFile!.path.isPdfFile()
                                  ? PdfViewerPage(
                                      fileUrl: (selectedFile!.path!),
                                      showAppBar: false,
                                    )
                                  : selectedFile!.path.isImageFile()
                                      ? Image.file(File(selectedFile!.path!))
                                      : selectedFile!.path.isVideoFile()
                                          ? VideoViewScreen(
                                              videoUrl: selectedFile!.path!,
                                              showAppBar: false,
                                            )
                                          : Text(
                                              FileUtils.getFileName(
                                                  selectedFile!.path!),
                                              overflow: TextOverflow.ellipsis,
                                              style: CustomTextStyles
                                                  .titleSmallBluegray300Medium,
                                            ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(),
            );
          }),
        ),
      ),
    );
  }

  void _scrollListener() {
    // If user scrolls up manually, disable auto-scroll
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 100) {
      chatController.shouldAutoScroll.value = false;
      chatController.visibleScrollBtn.value = false;
    }
    // Re-enable auto-scroll if user scrolls to bottom manually
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 10) {
      chatController.shouldAutoScroll.value = true;

      chatController.visibleScrollBtn.value = true;
      chatController.notVisibleMsgCount.value = 0;
    }
  }

  Future<void> _scrollToBottom(bool forceScroll) async {
    if ((chatController.shouldAutoScroll.value) || forceScroll) {
      // Use Future.delayed to ensure scroll happens after layout
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          // Scroll to the very bottom, considering all content
          // if(isJump) {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent +
                (!forceScroll
                    ? 50
                    : 5000), // to handle when last msg is img or video need to scroll extra to visible
          );
          // }else{
          //   _scrollController.animateTo(
          //
          //     _scrollController.position.maxScrollExtent+
          //         (!forceScroll ?50:5000), duration: Duration(milliseconds: 100), curve: Curves.easeIn,// to handle when last msg is img or video need to scroll extra to visible
          //   );
          // }
          chatController.scrollNow.value = false;
        }
      });
    }
  }

  Future<void> sendMessage(bool isFileUpload, File file) async {
    String? thumbUrl = "";
    String? awsFileUrl = "";
    final prefs = await SharedPreferences.getInstance();
    final String prefTeacherId = prefs.getString('breffini_teacher_Id') ?? "0";

    String teacherId =
        widget.userType == '2' ? prefTeacherId : widget.courseId.toString();
    if (isFileUpload) {
      if (file.path.isVideoFile()) {
        // generate thumbnail
        String thumbnailFilePath =
            await FileUtils.generateThumbnail(selectedFile!.path!);
        thumbUrl = await CloudFlareUpload.uploadChatImageToCloudFlare(
          File(thumbnailFilePath),
          widget.studentId,
          teacherId,
          FileUtils.getFileExtension(thumbnailFilePath),
        );
      }

      awsFileUrl = await chatController.uploadFileAndSendMessage(
          _messageController.text,
          widget.studentId,
          teacherId,
          file,
          thumbUrl ?? "");
    } else {
      await chatController.sendMessage(
          _messageController.text, teacherId, widget.studentId, 0.0, "");
    }

    String courseIdString = widget.courseId;
    int courseId = int.parse(RegExp(r'\d+').stringMatch(courseIdString)!);

    StudentChatModel studentMsg = StudentChatModel(
      courseId: courseId,
      chatType: widget.userType == '2' ? 'teacher_student' : 'hod_student',
      teacherId: int.parse(prefTeacherId),
      studentId: int.parse(widget.studentId),
      chatMessage: _messageController.text.trim(),
      sentTime: DateTime.now().toUtc().toString(),
      isStudent: false,
      filePath: filePath,
      senderName: widget.userType == '2'
          ? PrefUtils().getTeacherName()
          : "HOD", // sanju told idea
      profileUrl: HttpUrls.imgBaseUrl + PrefUtils().getProfileUrl(),
    );
    log(DateTime.now().toUtc().toString());
    chatController.shouldAutoScroll.value = true;
    ChatSocket.startChatting(studentMsg);
    setState(() {
      selectedFile = null;
      filePath = '';
      recorderAudioFile = null;
    });
    _messageController.clear();
  }

  void _startTimer() {
    _timer?.cancel(); // Cancel any existing timer

    _start = 0; // Reset start time
    _updateTime(); // Update time immediately

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _start++;
        _updateTime();
      });
    });
  }

  void _updateTime() {
    int minutes = (_start ~/ 60);
    int seconds = (_start % 60);
    chatController.formattedTime.value =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _pauseTimer() {
    if (_timer == null) return; // Only pause if the timer is running

    _timer?.cancel(); // Cancel the timer
    _timer = null; // Clear the timer variable
  }

  void _resumeTimer() {
    if (_timer != null)
      return; // Prevent resuming if the timer is already running

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _start++;
        _updateTime();
      });
    });
  }

  startRecording() async {
    try {
      if (player.state == PlayerState.playing) {
        await player.pause();
      }
      if (await _audioRecorder.hasPermission()) {
        chatController.isRecording.value = true;
        String fileName =
            DateTime.now().millisecondsSinceEpoch.toString() + ".m4a";
        final filePath = '${tempDir.path}/$fileName';

        recorderAudioFile = File(filePath);
        setState(() {});
        await _audioRecorder.start(const RecordConfig(), path: filePath);
      }
    } catch (e) {
      log('Error starting recording: $e');
    }
  }

  stopRecording(bool isStopAndExit) async {
    _stopTimer();
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        if (path != null) {
          recorderAudioFile = File(path);
        }
        if (isStopAndExit) {
          recorderAudioFile = null;
        }
      });
      chatController.isRecording.value = false;
      chatController.isRecordingPaused.value = false;
      chatController.isMicOn.value = !chatController.isMicOn.value;
      chatController.isVoiceMessage.value =
          !chatController.isVoiceMessage.value;
    } catch (e) {
      log('Error stopping recording: $e');
    }
  }

  pauseRecording() async {
    try {
      _pauseTimer();

      if (player.state == PlayerState.playing) {
        await player.pause();
      }
      await _audioRecorder.pause();
      setState(() {
        chatController.isRecording.value = false;
        chatController.isRecordingPaused.value = true;
      });
    } catch (e) {
      log('Error pausing recording: $e');
    }
  }

  resumeRecording() async {
    try {
      _resumeTimer();
      await _audioRecorder.resume();
      chatController.isRecordingPaused.value = false;
      chatController.isRecording.value = true;
    } catch (e) {
      log('Error resuming recording: $e');
    }
  }

  playAudio(int index, ChatMessageModel messageModel, String localPath,
      bool isPause) async {
    if (player.state == PlayerState.playing) {
      await player.pause();
      chatController.updatePlayerStatus(index, false);
      if (isPause) {
        return;
      }
    }
    if (localPath.isNotEmpty) {
      chatController.updatePlayerStatus(index, true);
      await player.play(DeviceFileSource(localPath));
    } else {
      await player.play(UrlSource(messageModel.filePath!));
    }
  }

  _initStreams() {
    _durationSubscription = player.onDurationChanged.listen((duration) {
      chatController.updatePlayerDuration(duration);

      // setState(() => _duration = duration);
      // print(duration.inSeconds.toString() + "dddddddddddd");
    });

    _positionSubscription = player.onPositionChanged.listen(
      (p) {
        chatController.updatePlayerPosition(p);
        // setState(() => _position = p);
        // print(_position.inSeconds.toString() + "position");
      },
    );

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      chatController.updatePlayerStatus(-1, false);

      // setState(() {
      //   _playerState = PlayerState.stopped;
      //   _position = Duration.zero;
      // });
    });

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((state) {
      // setState(() {
      //   _playerState = state;
      // });
    });
  }
}
