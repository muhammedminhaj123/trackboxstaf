import 'dart:async';
import 'dart:convert';

import 'package:breffini_staff/controller/calls_page_controller.dart';
import 'package:breffini_staff/core/utils/FirebaseCallModel.dart';
import 'package:breffini_staff/core/utils/common_utils.dart';
import 'package:breffini_staff/core/utils/extentions.dart';
import 'package:breffini_staff/core/utils/pref_utils.dart';
import 'package:breffini_staff/model/current_call_model.dart';
import 'package:breffini_staff/model/save_call_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming_yoer/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controller/chat_firebase_controller.dart';

class FirebaseUtils {
  static String callAccepted = "accepted";
  static String callRinging = "ringing";

  static StreamSubscription<QuerySnapshot>?
      _callsSubscription; // Store subscription
  static StreamSubscription<DocumentSnapshot>? _currentCallListener;

  static String getDocId(String studentId) {
    String docId =
        "STD-" + studentId + "-" + "TCR-" + PrefUtils().getTeacherId();

    return docId;
  }

  static saveCall(String studentId, String studentName, String callId,
      SaveStudentCallModel saveStudentCallModel) async {
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(getDocId(studentId))
        .set({
      "id": callId,
      "teacher_id": PrefUtils().getTeacherId(),
      "teacher_name": PrefUtils().getTeacherName(),
      "student_id": studentId,
      "student_name": studentName,
      "call_start": DateTime.now().toUtc().toString(),
      "call_end": saveStudentCallModel.callEnd,
      "call_duration": null,
      "call_type": saveStudentCallModel.callType,
      "Is_Student_Called": 0,
      "Live_Link": saveStudentCallModel.liveLink,
      "profile_url": saveStudentCallModel.profileUrl,
      "call_status": callRinging,
      "updated_on": DateTime.now(),
      "type": "new_call",
    });
    // await FirebaseFirestore.instance
    //     .collection('calls').doc("TCR-"+PrefUtils().getTeacherId())
    //     .set({
    //   "id": callId,
    //   "teacher_id": PrefUtils().getTeacherId(),
    //   "teacher_name": PrefUtils().getTeacherName(),
    //   "student_id": studentId,
    //   "student_name": studentName,
    //   "call_start": DateTime.now().toString(),
    //   "call_end": saveStudentCallModel.callEnd,
    //   "call_duration": null,
    //   "call_type": saveStudentCallModel.callType,
    //   "Is_Student_Called": 0,
    //   "Live_Link": saveStudentCallModel.liveLink,
    //   "profile_url": saveStudentCallModel.profileUrl
    // });
  }

  static Future<bool> isAnyCallExists() async {
    try {
      final CallandChatController callandChatController =
          Get.find<CallandChatController>();

      // Query the collection for documents where student_id matches
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('calls')
          .where('teacher_id', isEqualTo: PrefUtils().getTeacherId())
          .limit(1) // Limit to 1 since we only need to know if it exists
          .get();

      if (result.docs.isEmpty) {
        callandChatController.currentCallModel.value = CurrentCallModel();
      }
      // If there are any documents in the result, the student_id exists
      return result.docs.isNotEmpty;
    } catch (e) {
      print('Error checking student ID: $e');
      return false; // Return false in case of error
    }
  }

  static updateCallStatus(String studentId, String callStatus) async {
    // String docId="STD-"+PrefUtils().getStudentId()+"/"+"TCR-"+teacherId;
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(getDocId(studentId))
        .update(
            {"call_status": callStatus, "updated_on": DateTime.now().toUtc()});
  }

  static Future<bool> checkForRecentCallWithSameStudent(
      String studentId) async {
    // Calculate timestamp from 20 seconds ago
    DateTime twentySecondsAgo =
        DateTime.now().toUtc().subtract(Duration(seconds: 30));

    try {
      // Get the specific document
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('calls')
          .doc(getDocId(studentId))
          .get();

      // Check if document exists and meets our conditions
      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        DateTime updatedOn = (data['updated_on'] as Timestamp).toDate();

        return updatedOn.isAfter(twentySecondsAgo);
      }

      return false;
    } catch (e) {
      print('Error checking for recent calls: $e');
      return false;
    }
  }

  static deleteTeacherInactiveCalls() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String teacherId = preferences.getString('breffini_teacher_Id') ?? '';

    try {
      // Query all documents where id = 50
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("calls")
          .where('teacher_id', isEqualTo: teacherId)
          .get();

      // Delete each matching document
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        await doc.reference.delete();
        print('Deleted document with ID: ${doc.id}');
      }

      // print('Successfully deleted ${querySnapshot.docs.length} documents with id 50');
    } catch (e) {
      print('Error deleting documents: $e');
    }
  }

  static deleteCall(String studentId, String sss) async {
    try {
      await FirebaseFirestore.instance
          .collection("calls")
          .doc(getDocId(studentId))
          .delete();

      Get.put(ChatFireBaseController()).updateLog(
          "Deleted call" +
              "_STD" +
              PrefUtils().getTeacherId() +
              "_route=" +
              Get.currentRoute,
          sss);
      // Query all documents where id = 50
      // QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      //     .collection("calls")
      //     .where('id', isEqualTo: callId)
      //     .get();
      //
      // // Delete each matching document
      // for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      //   await doc.reference.delete();
      //   print('Deleted document with ID: ${doc.id}');
      // }

      // print('Successfully deleted ${querySnapshot.docs.length} documents with id 50');
    } catch (e) {
      print('Error deleting documents: $e');
    }
    // await FirebaseFirestore.instance
    //     .collection("calls")
    //     .doc("STD-"+studentId)
    //     .delete();
    //
    // await FirebaseFirestore.instance
    //     .collection("calls")
    //     .doc("TCR-"+PrefUtils().getTeacherId())
    //     .delete();
  }

  static Future<bool> checkIfCallExists(String studentId, String callId) async {
    // Create the document reference with the dynamic ID
    final documentReference =
        FirebaseFirestore.instance.collection("calls").doc(getDocId(studentId));

    try {
      // Fetch the document once
      final documentSnapshot = await documentReference.get();

      // Check if the document exists
      if (documentSnapshot.exists) {
        // DocumentSnapshot data = documentSnapshot.data() as Map<String, dynamic>;
        final Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;

        // Use fromMap instead of fromSnapshot
        FirebaseCallModel callModel = FirebaseCallModel.fromMap(data);

        print("Document exists with data: ${documentSnapshot.data()}");
        return callModel.id == callId;
      } else {
        print("Document does not exist.");
        return false;
      }
    } catch (e) {
      print("Error checking document existence: $e");
      return false;
    }
  }

  static listenCalls() async {
    if (null != _callsSubscription) {
      _callsSubscription?.cancel();
    }
    // Get.put(ChatFireBaseController()).updateLog(
    //     "listencalled", "");

    final prefs = await SharedPreferences.getInstance();
    final String teacherId = prefs.getString('breffini_teacher_Id') ?? "0";
    CallandChatController callChatController = getCallChatController();

    _callsSubscription = FirebaseFirestore.instance
        .collection("calls")
        .where('teacher_id', isEqualTo: teacherId)
        .snapshots()
        .listen((QuerySnapshot querySnapshot) async {
      List<dynamic> activeCalls = await FlutterCallkitIncoming.activeCalls();

      // Check if there are any documents in the snapshot
      if (querySnapshot.docs.isNotEmpty) {
        // Get.put(ChatFireBaseController()).updateLog(
        //     "data exist", "");
        final doc = querySnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;

        List<FirebaseCallModel> fireBaseCallList = querySnapshot.docs
            .map((doc) =>
                FirebaseCallModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
        // FirebaseCallModel callModel = FirebaseCallModel.fromMap(data);

        // Check for active calls
        bool showCall = true;

        for (FirebaseCallModel model in fireBaseCallList) {
          // case whn new call and ring not shown
          if (model.callStatus == FirebaseUtils.callRinging &&
              model.isStudentCalled!) {
            bool hasAlreadyRinging =
                activeCalls.any((call) => call["id"] == model.id);
            bool isLocalAccepted = activeCalls
                .any((call) => call["id"] == model.id && call['accepted']);
            if (!hasAlreadyRinging && !isLocalAccepted) {
              Future.delayed(const Duration(seconds: 1), () async {
                // added this delay to handle (when app killed and firebase default notification arrive.
                //so default notification showing over call ring dialog fix// )
                if (callChatController.currentCallModel.value.callId
                        .isNullOrEmpty() ||
                    callChatController.currentCallModel.value.callId !=
                        model.id) {
                  // check call is created before 10 second from firebase triggered...issue when app has no internet..but data in firebase db..
                  // when app opened or internet come old call ring show fix after
                  DateTime sendTime = DateTime.parse(model.callStart!).toUtc();
                  DateTime arrivalTime = DateTime.now().toUtc();

                  int delayInSeconds =
                      arrivalTime.difference(sendTime).inSeconds;

                  if (delayInSeconds <= 50) {
                    // await showCallkitIncoming(
                    //     model.id ?? '',
                    //     model.studentName ?? '',
                    //     model.profileUrl ?? '',
                    //     model.callType ?? '',
                    //     model.toJson(),
                    //     false);
                  } else {
                    // await showCallkitIncoming(
                    //     model.id ?? '',
                    //     model.studentName ?? '',
                    //     model.profileUrl ?? '',
                    //     model.callType ?? '',
                    //     model.toJson(),
                    //     true);
                  }
                }
              });
            } else {}
          }
        }
        for (var call in activeCalls) {
          int index = fireBaseCallList
              .indexWhere((element) => element.id == call["id"]);
          if (index == -1) {
            final String callId = call['id'] ?? '';
            FlutterCallkitIncoming.endCall(callId);
          }
        }
        // // Get the first document
        // final doc = querySnapshot.docs.first;
        // final data = doc.data() as Map<String, dynamic>;
        //
        // List<FirebaseCallModel> fireBaseCallList = querySnapshot.docs
        //     .map((doc) => FirebaseCallModel.fromMap(doc.data() as Map<String, dynamic>))
        //     .toList();
        //
        //
        // FirebaseCallModel callModel = FirebaseCallModel.fromMap(data);
        //
        // // Check for active calls
        // List<dynamic> activeCalls = await FlutterCallkitIncoming.activeCalls();
        // bool showCall = true;
        //
        // // if (activeCalls.isNotEmpty && activeCalls[0] is Map<String, dynamic>) {
        // //   final activeCall = activeCalls[0] as Map<String, dynamic>;
        // //
        // //   // Check if call is already accepted
        // //   final bool isAccepted = activeCall['accepted'] ?? false;
        // //   final String callId = activeCall['id'] ?? '';
        // //
        // //   if (isAccepted && callId == callModel.id) {
        // //     showCall = false;
        // //   }
        // // }
        // if (activeCalls.isNotEmpty) {
        //   for (var call in activeCalls) {
        //     // if (call is Map<String, dynamic>) {
        //       final bool isAccepted = call['accepted'] ?? false;
        //       final String callId = call['id'] ?? '';
        //       // case when a and b on call and c calls b then c disconnect call then remove call ringing from b phone
        //       int existIndex=fireBaseCallList.indexWhere((element)=> element.id==callId);
        //       if(existIndex==-1){
        //         await FlutterCallkitIncoming.endCall(callId);
        //       }
        //
        //       // Don't show call if it's already accepted
        //       if (isAccepted && callId == callModel.id) {
        //         showCall = false;
        //         // break;
        //       }
        //     // }
        //   }
        // }
        //
        // // Show incoming call if conditions are met
        // if (callModel.isStudentCalled! && callModel.callStatus==FirebaseUtils.callRinging) {
        //   await showCallkitIncoming(
        //     callModel.id ?? '',
        //     callModel.teacherName ?? '',
        //     callModel.profileUrl ?? '',
        //     callModel.callType ?? '',
        //     callModel.toJson(),
        //   );
        // }
      } else {
        // Get.put(ChatFireBaseController()).updateLog(
        //     "no exist", teacherId.toString());
        // End all calls if no documents exist
        for (var call in activeCalls) {
          final String callId = call['id'] ?? '';

          FlutterCallkitIncoming.endCall(callId);
        }
        // await FlutterCallkitIncoming.endAllCalls();
      }
    }, onError: (error) {
      print("Error listening to document: $error");
    });
  }

  static listeningToCurrentCall(
    String studentId,
    String callId,
  ) {
    _currentCallListener = FirebaseFirestore.instance
        .collection("calls")
        .doc(getDocId(
            studentId)) // Directly access the document with the specified ID
        .snapshots()
        .listen((DocumentSnapshot snapshot) async {
      if (snapshot.exists) {
        // Document found, handle the data
        var callData = snapshot.data();
        print("Call data with id 50: $callData");

        // Use setState to update the UI or perform other actions here
      } else {
        if (null != _currentCallListener) {
          _currentCallListener?.cancel();
        }
        CallandChatController callandChatController = Get.find();

        if (Get.currentRoute == "/IncomingCallPage") {
          safeBack();
          Get.showSnackbar(const GetSnackBar(
            message: 'Call Ended',
            duration: Duration(milliseconds: 2000),
          ));
        } else {
          Get.showSnackbar(const GetSnackBar(
            message: 'Call Ended',
            duration: Duration(milliseconds: 2000),
          ));
          FlutterCallkitIncoming.endAllCalls();
        }
        if (!callandChatController.currentCallModel.value.callId
            .isNullOrEmpty()) {
          // added this because when already disconnectCall called then call
          // this function may create call reject true by checking callandChatController.enteredUserList.isEmpty(callandChatController.enteredUserList.isEmpty cleared in first api call)

          callandChatController.disconnectCall(true, false, studentId, callId);
        }
      }
    });
  }

  static cancelCallListening() {
    if (null != _currentCallListener) {
      _currentCallListener?.cancel();
    }
  }
}
