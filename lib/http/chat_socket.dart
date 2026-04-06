import 'package:breffini_staff/controller/calls_page_controller.dart';
import 'package:breffini_staff/controller/ongoing_call_controller.dart';
import 'package:breffini_staff/core/utils/pref_utils.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/controller/chat_controller.dart';
import 'package:breffini_staff/controller/chat_history_controller.dart';
import 'package:breffini_staff/model/ongoing_call_model.dart';
import 'package:breffini_staff/model/student_chat_history_model.dart';
import 'package:breffini_staff/model/student_chat_model.dart';
import 'package:breffini_staff/model/teacher_calls_history_model.dart';
import 'package:breffini_staff/model/teacher_chat_log_model.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'dart:convert';

class ChatSocket {
  static IO.Socket? socket;
  static ChatController chatMsgController = Get.find<ChatController>();
  static ChatHistoryController chatLogController =
      Get.find<ChatHistoryController>();

  static Future<void> initSocket() async {
    if (socket != null && socket!.connected) {
      // print('Socket is already initialized and connected');
      return;
    }
    // print('<<<<<<<<<<<<<<<<<<<<socke start>>>>>>>>>>>>>>>>>>>>');

    socket = IO.io(HttpUrls.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'upgrade': false,
      'extraHeaders': {
        'Authorization': 'asdasdasdasdere',
        'ngrok-skip-browser-warning': 'true',
      },
    });

    socket?.connect();

    socket?.onConnect((_) {
      print('DEBUG: Socket Connected');
      // Attempt to join user-specific room for notifications
      SharedPreferences.getInstance().then((prefs) {
        String teacherId = prefs.getString('breffini_teacher_Id') ?? '';
        if (teacherId.isNotEmpty) {
          print('DEBUG: Emitting join for teacher: $teacherId');
          socket?.emit(
              'join', teacherId); // Assuming 'join' is the event for user room
        }
      });
      emitOngoingCalls();
    });
    // Check connection status after a delay

    //end here

    // chat log list initialise received

    socket?.on('chat history', (data) {
      // print('chat history clicked received: $data');

      // Check if data is null
      if (data == null) {
        // print('Received null data for chat history.');
        chatMsgController.chatHistoryListMap =
            {}; // Or handle it in another way
        chatMsgController.update();
        return;
      }

      // Proceed with processing if data is not null
      Map<String, dynamic> originalMap = data;
      chatMsgController.chatHistoryListMap = originalMap.map((key, value) {
        List<dynamic> chatList = value;
        return MapEntry(
          key,
          chatList
              .map((item) => StudentChatHistoryModel.fromMap(item))
              .toList(),
        );
      });

      // Print converted map for verification

      chatMsgController.update();
    });

    socket?.on('chat list', (data) async {
      print('DEBUG: chat log list clicked received: $data');
      // Loader.showLoader();
      List<dynamic> chatLogHistory = data;
      chatLogController.studentChatLogList.value =
          chatLogHistory.map((e) => StudentChatLogModel.fromJson(e)).toList();
      print(
          'DEBUG: chat log list after received: ${chatLogController.studentChatLogList}');

      chatLogController.update();

      // Trigger Notification for recent unread messages
      try {
        for (var item in chatLogHistory) {
          int unreadCount = 0;
          if (item['unread_count'] is int) {
            unreadCount = item['unread_count'];
          } else if (item['unread_count'] is String) {
            unreadCount = int.tryParse(item['unread_count']) ?? 0;
          }

          if (unreadCount > 0) {
            String? timestampStr = item['timestamp'];
            if (timestampStr != null) {
              DateTime msgTime = DateTime.parse(timestampStr).toUtc();
              DateTime now = DateTime.now().toUtc();
              // Check if message is within last 2 minutes
              if (now.difference(msgTime).inMinutes.abs() <= 2) {
                // Native notification should handle this if FCM is sent alongside socket event
                break;
              }
            }
          }
        }
      } catch (e) {
        print('DEBUG: Error triggering notification from chat list: $e');
      }

      // Loader.stopLoader();
    });

    socket?.on(
      'new message',
      (data) async {
        print('DEBUG: SOCKET NEW MESSAGE RECEIVED: $data');
        print('DEBUG: MESSAGE CONTENT: ${data['message']}');

        SharedPreferences preferences = await SharedPreferences.getInstance();
        String teacherId = preferences.getString('breffini_teacher_Id') ?? '';

        String userTypeId = preferences.getString('user_type_id') ?? '2';
        StudentChatHistoryModel newChat = StudentChatHistoryModel(
          messageId: null,
          teacherId: int.parse(teacherId),
          studentId: data['studentId'],

          message: data['message'],
          messageTimestamp: DateTime.now(),
          callId: null,
          callStart: null,
          callEnd: null,
          // callDuration: 0,
          callType: '',
          filePath: data['File_Path'] ?? '',
          isStudent: data['isStudent'] ?? false,
        );
// Get the current date
        DateTime now = DateTime.now();

        // Format the current date
        String formattedDate = DateFormat('yyyy-MM-dd').format(now);

        print('DEBUG: Date: $formattedDate'); // Output: 2024-07-22
        if (!chatMsgController.chatHistoryListMap.containsKey(formattedDate)) {
          chatMsgController.chatHistoryListMap[formattedDate] = [];
        }
        chatMsgController.chatHistoryListMap[formattedDate]!.add(newChat);
        chatMsgController.update();
        print('DEBUG: mark as read: ${data['isStudent']}');
        socket?.emit('mark as read', {
          "studentId": data['studentId'],
          "teacherId": teacherId,
          "isStudent": data['isStudent'] ?? false,
          "chatType": userTypeId == '2' ? 'teacher_student' : 'hod_student',
        });

        chatLogController.update();
      },
    );

    socket?.on('connect', (_) {
      socket?.emit('send', 'hi');
    });

    socket?.emit('send', 'hi');
    socket?.on('get', (data) {});

    socket?.on('connect_error', (data) {});

    socket?.on('error', (data) {
      print('DEBUG: Socket Error: $data');
    });

    // Debug listener for troubleshooting
    socket?.onAny((event, data) {
      print('DEBUG: SOCKET EVENT RECEIVED: $event -> $data');
    });
  }

  static joinConversationRoom(
      String studentId, int teacherId, String chatType) {
    chatMsgController.chatHistoryListMap.clear();
    socket?.emit('join conversation', {
      "studentId": studentId,
      "teacherId": teacherId,
      "isStudent": false,
      "chatType": chatType
    });
  }

  static leaveConversationRoom(
      String studentId, int teacherId, String chatType) {
    socket?.emit('leave conversation', {
      "studentId": studentId,
      "teacherId": teacherId,
      "isStudent": false,
      "chatType": chatType
    });
  }

  static getChatLogHistory(String teacherId, String chatType) {
    // print('chat log list clicked received');
    socket?.emit('get list',
        {"id": teacherId, "isStudent": false, "chatType": chatType});
  }

  static leaveChatLogHistory(String userId, String chatType) {
    // chat log list leaved
    socket?.emit('leave chatlist',
        {"id": userId, "isStudent": false, "chatType": chatType});
  }

  static startChatting(StudentChatModel chat) {
    socket?.emit('send message', chat.toMap());
  }

  static initializeSocket() {
    // print('start');

    socket = IO.io('https://brifniapi.ufstech.in/', <String, dynamic>{
      'transports': ['polling'],
      'autoConnect': true,
      'extraHeaders': {
        'ngrok-skip-browser-warning': 'true',
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer yJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2NCIsImlhdCI6MTcxOTA1MDAxNn0.hdn_nCOdf9BCTiPqaaD358XOdsdJqT2BT2IkfOmIqTQ',
      },
    });
    socket?.connect();

    socket?.on('Connection', (_) {
      // print('Connected');
    });

    socket?.on('connect_error', (data) {
      // print('Connection Error: $data');
    });

    socket?.on('connect_timeout', (data) {
      // print('Connection Timeout: $data');
    });

    socket?.on('disconnect', (_) {
      // print('Disconnected');
    });

    socket?.on('message', (data) {
      // print('Received: $data');
    });

    if (!socket!.connected) {
      socket?.connect();
    }
  }

  static socketConnection() {
    if (socket == null || !socket!.connected) {
      initializeSocket();
    }

    socket?.onConnect((_) {
      // print('Connected');
      socket?.emit('msg', 'test');
    });

    socket?.on('event', (data) => print(data));
    socket?.onDisconnect((_) => print('Disconnected'));
    socket?.on('fromServer', (_) => print(_));
  }

  //call
  static emitOngoingCalls() {
    String ss = PrefUtils().getTeacherId();
    socket?.emit('Get_Ongoing_Calls', {"user_Id": ss, "isStudent": 0});
  }

  static listenOngoingCalls() {
    CallandChatController callandChatController =
        Get.find<CallandChatController>();
    // used to block looping of getting calles
    socket?.off("Get_Ongoing_Calls");
    final chatController =
        Get.put<CallOngoingController>(CallOngoingController());
    socket?.on('Get_Ongoing_Calls', (data) async {
      var dataList = data as List;

      if (dataList.isNotEmpty) {
        List<OnGoingCallsModel> onGoingList = dataList
            .map((result) => OnGoingCallsModel.fromJson(result))
            .toList();

        callandChatController.callandChatList.value = dataList
            .map((result) => CallAndChatHistoryModel.fromJson(result))
            .toList();
      } else {
        callandChatController.callandChatList.value = [];
      }
    });
  }

  //listen current Call
  void listenCurrentCall(Function(bool, String) callback) {}

  void removeCallStatusListener() {
    socket?.off('Call_Status');
  }
}
