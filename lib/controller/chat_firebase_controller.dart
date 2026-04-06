// import 'dart:io';

// import 'package:breffini_staff/model/chat_message_model.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:get/get.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../http/aws_upload.dart';

// class ChatFireBaseController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final RxList<ChatMessage> messages = <ChatMessage>[].obs;

//   fetchMessages(String studentId) async {
//     final prefs = await SharedPreferences.getInstance();
//     final String teacherId = prefs.getString('breffini_teacher_Id') ?? "0";

//     _firestore
//         .collection('chats')
//         .doc(teacherId)
//         .collection('messages')
//         .where('studentId', isEqualTo: studentId)
//         .orderBy('sentTime')
//         .snapshots()
//         .listen((snapshot) {
//       final fetchedMessages = snapshot.docs.map((doc) {
//         final data = doc.data();
//         return ChatMessage.fromMap(data);
//       }).toList();
//       messages.value = fetchedMessages;
//     });
//   }

//   Future<void> sendMessage(String messageText, String studentId,
//       {String filePath = ""}) async {
//     fetchMessages(studentId);
//     final prefs = await SharedPreferences.getInstance();
//     final String teacherId = prefs.getString('breffini_teacher_Id') ?? "0";
//     final message = ChatMessage(
//       studentId: studentId,
//       teacherId: teacherId,
//       chatMessage: messageText,
//       sentTime: DateTime.now(),
//       isStudent: false,
//       filePath: filePath,
//     );

//     _firestore
//         .collection('chats')
//         .doc(studentId)
//         .collection('messages')
//         .add(message.toMap());
//     _firestore
//         .collection('chats')
//         .doc(teacherId)
//         .collection('messages')
//         .add(message.toMap());
//   }

//   Future<void> uploadFileAndSendMessage(
//       String messageText, String studentId, PlatformFile selectedFile) async {
//     fetchMessages(studentId);
//     final prefs = await SharedPreferences.getInstance();
//     final String teacherId = prefs.getString('breffini_teacher_Id') ?? "0";
//     String? uploadedFilePath = await AwsUpload.uploadChatImageToAws(
//       File(selectedFile.path!),
//       studentId,
//       teacherId,
//       selectedFile.extension!,
//     );

//     await sendMessage(messageText, studentId, filePath: uploadedFilePath!);
//   }
// }

import 'dart:async';
import 'dart:io';

import 'package:breffini_staff/core/utils/extentions.dart';
import 'package:breffini_staff/core/utils/file_utils.dart';
import 'package:breffini_staff/core/utils/pref_utils.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/model/chat_message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../http/cloud_flare_upload.dart';

class ChatFireBaseController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;

  RxInt currentPlayingIndex = (-1).obs;
  Rx<Duration> duration = (Duration.zero).obs;
  Rx<Duration> position = (Duration.zero).obs;
  final isSendingMessage = false.obs;
  RxBool isMicOn = true.obs;
  RxBool isLoadingChat = false.obs;
  RxBool shouldAutoScroll = true.obs;
  RxBool scrollNow = false.obs;
  RxBool visibleScrollBtn = false.obs;
  RxInt notVisibleMsgCount = 0.obs;
  RxBool isVoiceMessage = false.obs;
  RxBool isRecording = false.obs;
  RxBool isRecordingPaused = false.obs;
  RxString formattedTime = "00:00".obs;
  bool isFirstFetch = true;
  StreamSubscription? chatSubscription;

  updateDownloadProgress(int index, double progress) {
    messages[index].progress?.value = progress;

    update();
  }

  updatePlayerStatus(int index, bool playing) {
    if (playing) {
      currentPlayingIndex.value = index;
    } else {
      currentPlayingIndex.value = -1;
    }
    // messages[currentPlayingIndex.value].isPlaying=playing;

    update();
  }

  updatePlayerPosition(Duration pos) {
    position.value = pos;

    update();
  }

  updatePlayerDuration(Duration dur) {
    duration.value = dur;

    update();
  }

  String _getChatCollectionPath(String teacherId, String studentId) {
    return 'chats/$teacherId/students/$studentId/messages';
  }

  Future<void> updateLog(String messageText, String extraData) async {
    //
    // DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    // AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String teacherId = prefs.getString('breffini_teacher_Id') ?? "0";
    String teacherName = prefs.getString('First_Name') ?? "NA";
    final message = {
      "teacherId": teacherId,
      "teacherName": teacherName,
      "errorMsg": messageText,
      "extraData": extraData,
      "time": DateTime.now().toString(),
      // "modelName":androidInfo.model,
      // "osVersion":androidInfo.version.release,
      // 'sdkInt': androidInfo.version.sdkInt.toString(), // API Level (e.g. 26)
      // 'manufacturer': androidInfo.manufacturer, // e.g. Samsung
    };

    await FirebaseFirestore.instance.collection("staffLog").add(message);
  }

  Future<void> fetchMessages(String studentId, String teacherId) async {
    // Show loading only on first fetch
    if (isFirstFetch) {
      isLoadingChat.value = true;
    }
    if (null != chatSubscription) {
      chatSubscription?.cancel();
    }

    final chatCollectionPath = _getChatCollectionPath(teacherId, studentId);

    chatSubscription = _firestore
        .collection(chatCollectionPath)
        .orderBy('sentTime')
        .snapshots()
        .listen((snapshot) {
      if (!isFirstFetch) {
        notVisibleMsgCount.value =
            notVisibleMsgCount.value + snapshot.docChanges.length;
      } else {}
      scrollNow.value = true;

      final fetchedMessages = snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessageModel.fromMap(data);
      }).toList();
      messages.value = fetchedMessages;

      // Hide loading and update first fetch flag
      if (isFirstFetch) {
        isLoadingChat.value = false;
        isFirstFetch = false;
      }
    });
  }

  // Future<void> fetchHodmessages(String studentId, String courseId) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   // final String teacherId = prefs.getString('breffini_teacher_Id') ?? "0";
  //   final chatCollectionPath = _getChatCollectionPath(courseId, studentId);
  //
  //   print('Teacher ID: $studentId, Student ID: $courseId');
  //
  //   _firestore
  //       .collection(chatCollectionPath)
  //       .orderBy('sentTime')
  //       .snapshots()
  //       .listen((snapshot) {
  //     final fetchedMessages = snapshot.docs.map((doc) {
  //       final data = doc.data();
  //       return ChatMessageModel.fromMap(data);
  //     }).toList();
  //     messages.value = fetchedMessages;
  //   });
  // }

  Future<void> sendMessage(String messageText, String teacherId,
      String studentId, double localFileSize, String thumbUrl,
      {String filePath = ""}) async {
    final message = ChatMessageModel(
      studentId: studentId,
      teacherId: teacherId,
      chatMessage: messageText,
      sentTime: DateTime.now().toUtc(),
      isStudent: false,
      filePath: filePath,
      fileSize: localFileSize,
      thumbUrl: thumbUrl,
      senderName: PrefUtils().getTeacherName(),
    );

    final chatCollectionPath = _getChatCollectionPath(teacherId, studentId);

    _firestore.collection(chatCollectionPath).add(message.toMap());
    // // Refresh messages to include the new message
    // fetchMessages(
    //   studentId,
    // );
  }

  // Future<void> sendHodMessage(
  //     String messageText, String studentId, String courseId,
  //     {String filePath = ""}) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   // final String teacherId = prefs.getString('breffini_teacher_Id') ?? "0";
  //   final message = ChatMessageModel(
  //     studentId: studentId,
  //     teacherId: courseId,
  //     chatMessage: messageText,
  //     sentTime: DateTime.now(),
  //     isStudent: false,
  //     filePath: filePath,
  //     senderName: PrefUtils().getTeacherName(),
  //
  //   );
  //
  //   final chatCollectionPath = _getChatCollectionPath(courseId, studentId);
  //
  //   _firestore.collection(chatCollectionPath).add(message.toMap());
  // }

  // uploadFileAndSendMessage(
  //     String messageText, String studentId,  File selectedFile,String thumbUrl) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final String teacherId = prefs.getString('breffini_teacher_Id') ?? "0";
  //   String? uploadedFilePath = await AwsUpload.uploadChatImageToAws(
  //     selectedFile,
  //     studentId,
  //     teacherId,
  //     FileUtils.getFileExtension(selectedFile.path),
  //   );
  //   await sendMessage(messageText, studentId, filePath: uploadedFilePath!);
  // }
  Future<String> uploadFileAndSendMessage(String messageText, String studentId,
      String teacherId, File selectedFile, String thumbUrl) async {
    String? uploadedFilePath =
        await CloudFlareUpload.uploadChatImageToCloudFlare(
      selectedFile,
      studentId,
      teacherId,
      FileUtils.getFileExtension(selectedFile.path),
    );
    if (!thumbUrl.isNullOrEmpty()) {
      DefaultCacheManager().putFile(HttpUrls.imgBaseUrl + uploadedFilePath!,
          selectedFile.readAsBytesSync(),
          fileExtension: FileUtils.getFileExtension(selectedFile.path));
    }

    await sendMessage(messageText, teacherId, studentId,
        FileUtils.getFileSizeInKB(selectedFile.path) ?? 0.0, thumbUrl,
        filePath: uploadedFilePath!);

    return uploadedFilePath;
  }
  // uploadFileAndSendMessageofHod(String messageText, String studentId,
  //     String courseId, String path, String ext) async {
  //   final prefs = await SharedPreferences.getInstance();
  //
  //   String? uploadedFilePath = await AwsUpload.uploadChatImageToAws(
  //     File(path),
  //     studentId,
  //     courseId,
  //     ext,
  //   );
  //   print('dfwsget $path');
  //   print('Teacher ID: $courseId, Student ID: $studentId');
  //
  //   await sendHodMessage(messageText, studentId, courseId,
  //       filePath: uploadedFilePath!);
  // }
}
