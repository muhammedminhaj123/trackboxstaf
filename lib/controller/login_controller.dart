import 'dart:developer';

import 'package:breffini_staff/controller/calls_page_controller.dart';
import 'package:breffini_staff/controller/live_controller.dart';
import 'package:breffini_staff/controller/ongoing_call_controller.dart';
import 'package:breffini_staff/controller/profile_controller.dart';
import 'package:breffini_staff/core/utils/extentions.dart';
import 'package:breffini_staff/core/utils/firebase_utils.dart';
import 'package:breffini_staff/core/utils/pref_utils.dart';
import 'package:breffini_staff/http/http_requests.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/model/teacher_login_model.dart';
import 'package:breffini_staff/view/pages/authentication/change_password_page.dart';
import 'package:breffini_staff/view/pages/authentication/login_page.dart';
import 'package:breffini_staff/view/pages/authentication/verify_otp_page.dart';
import 'package:breffini_staff/view/pages/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_callkit_incoming_yoer/flutter_callkit_incoming.dart';

class LoginController extends GetxController {
  //loginpage controllers
  TextEditingController emailIDController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  //verifyemailcontroller
  TextEditingController verifyEmailController = TextEditingController();
  //otp controller
  TextEditingController otpController = TextEditingController();
  //change password page controllers
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  String fcmToken = "";
  var isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkLoginStatus();
  }

  @override
  void onClose() {
    emailIDController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void _checkLoginStatus() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? token = preferences.getString('breffini_token');
    if (token != null) {
      isLoggedIn.value = true;
    }
  }

  Future<void> getFCMToken({bool forceRefresh = false}) async {
    // Ensure the function returns a Future and uses async/await
    try {
      if (forceRefresh) {
        // Delete the old token first to force a refresh
        print('DEBUG: Deleting old FCM token...');
        await FirebaseMessaging.instance.deleteToken();

        // Wait a bit for the deletion to complete
        await Future.delayed(Duration(milliseconds: 500));
      }

      // Get a fresh token
      String? token = await FirebaseMessaging.instance.getToken();
      print('DEBUG: FCM Token obtained: $token');
      fcmToken = token ?? "";
      log('fmcToken  $fcmToken');
    } catch (e) {
      print('Failed to get FCM token: $e');
      Get.showSnackbar(GetSnackBar(
        message: 'FCM Token Error: $e',
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> teacherLogin(TeacherLoginModel teacher,
      {bool silent = false}) async {
    // Force refresh the FCM token to ensure we get a new one for this login
    // This is critical when logging in after a logout to ensure notifications
    // go to the correct user
    print('DEBUG: Login started - Force refreshing FCM token...');
    await getFCMToken(forceRefresh: true);
    print('DEBUG: New FCM token ready for login');

    SharedPreferences preferences = await SharedPreferences.getInstance();

    Map<String, dynamic> jsonData = {
      "email": teacher.email,
      "password": teacher.password,
      "Device_ID": fcmToken
    };

    print('login data $jsonData');
    try {
      var response = await HttpRequest.httpPostLogin(
        bodyData: jsonData,
        endPoint: HttpUrls.login,
        showLoader: !silent, // Don't show loader if silent
      );

      if (response != null) {
        var userTypeId = response.data['0']['User_Type_Id'].toString();

        // Save token, teacher ID, and User_Type_Id in SharedPreferences
        preferences.setString('breffini_token', response.data['token']);
        preferences.setString(
            'breffini_teacher_Id', response.data['0']['Id'].toString());
        preferences.setString('user_type_id', userTypeId);

        // Save the synced token to avoid re-syncing until it changes again
        preferences.setString('last_synced_fcm_token', fcmToken);

        isLoggedIn.value = true;

        if (!silent) {
          // Redirect based on User_Type_Id
          if (userTypeId == '2') {
            Get.offAll(() => const HomePage());
            print("Successful, redirected to HomePage");
          } else if (userTypeId == '3') {
            Get.offAll(() => const HomePage()); // Assuming DemoPage is defined
            print("Successful, redirected to DemoPage");
          } else {
            Get.showSnackbar(const GetSnackBar(
              message: 'Invalid login credentials',
              duration: Duration(milliseconds: 800),
            ));
            print("Not Successful");
          }
        } else {
          print("DEBUG: Silent login successful. Token updated.");
        }

        // Clear controllers after successful login
        emailIDController.clear();
        passwordController.clear();
      } else {
        if (!silent) {
          Get.showSnackbar(const GetSnackBar(
            message: 'Invalid login credentials',
            duration: Duration(milliseconds: 800),
          ));
        }
        print("Not Successful");
      }
    } catch (e) {
      print('Failed to login: $e');
      if (!silent) {
        Get.showSnackbar(const GetSnackBar(
          message: 'An error occurred during login',
          duration: Duration(milliseconds: 800),
        ));
      }
    }

    update();
  }

  Future<void> checkAndSyncFCMToken() async {
    print("DEBUG: Checking if FCM token needs sync...");
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 1. Get current stored sync token
    String? lastSyncedToken = prefs.getString('last_synced_fcm_token');

    // 2. Get actual current FCM token from Firebase
    try {
      String? currentToken = await FirebaseMessaging.instance.getToken();
      if (currentToken == null) {
        print("DEBUG: Failed to get current FCM token. Aborting sync.");
        return;
      }

      print(
          "DEBUG: Last Synced Token: ${lastSyncedToken?.substring(0, 10)}...");
      print("DEBUG: Current FCM Token: ${currentToken.substring(0, 10)}...");

      // 3. Compare
      if (lastSyncedToken != currentToken) {
        print("DEBUG: Token mismatch detected! Initiating silent sync.");

        // 4. Get User Credentials from ProfileController
        // Note: We expect ProfileController to be initialized and data fetched by HomePage
        try {
          // Find ProfileController (it should have been put by HomePage)
          // We use Get.find because we expect it to be in memory.
          // If not, we might need to be careful.
          // Assuming checkAndSyncFCMToken is called AFTER fetchTeacherProfile
          final profileController = Get.find<ProfileController>();

          if (profileController.getTeacher.isNotEmpty) {
            var userProfile = profileController.getTeacher[0];
            String email = userProfile.email;
            String password =
                userProfile.password; // Assuming password is available in model

            if (email.isNotEmpty && password.isNotEmpty) {
              TeacherLoginModel loginModel =
                  TeacherLoginModel(email: email, password: password);

              // 5. Perform Silent Login
              await teacherLogin(loginModel, silent: true);
            } else {
              print(
                  "DEBUG: Cannot sync token - Email or Password missing in profile.");
            }
          } else {
            print("DEBUG: Cannot sync token - Profile data not loaded yet.");
          }
        } catch (e) {
          print("DEBUG: Error finding ProfileController or syncing: $e");
        }
      } else {
        print("DEBUG: FCM token is up to date.");
      }
    } catch (e) {
      print("DEBUG: Error getting FCM token for check: $e");
    }
  }

  verifyEmail(String email) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    Map<String, dynamic> jsonData = {
      "Email": email,
    };
    await HttpRequest.httpPostBodyRequest(
      bodyData: jsonData,
      endPoint: HttpUrls.generateForgetPassword,
    ).then((response) {
      if (response != null) {
        preferences.setString('teacherid', response.data['User_ID'].toString());
        preferences.setString('generateToken', response.data['token']);
        preferences.setString('newOtp', response.data['otp']);
        Get.to(() => VerifyOtpPage(email));

        newPasswordController.clear();
        confirmPasswordController.clear();
        if (kDebugMode) {
          Get.showSnackbar(GetSnackBar(
            message: response.data['otp'],
            duration: const Duration(milliseconds: 2000),
          ));
        }
      } else {
        Get.showSnackbar(const GetSnackBar(
          message: 'Invalid login credentials',
          duration: Duration(milliseconds: 800),
        ));
        print(response);
        print("Not Successful");
      }
    });

    update();
  }

  verifyOtp({required String otp}) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? teacherId = preferences.getString('teacherid').toString();
    String? newOtp = preferences.getString('newOtp').toString();
    String? tokens = preferences.getString('generateToken');
    print(newOtp);
    print(tokens);
    await HttpRequest.httpPostBodyRequest(
      endPoint: HttpUrls.checkOtp,
      bodyData: {"student_id": teacherId, "otp": otp, "isStudnet": 0},
    ).then((value) async {
      print('login value $value');

      if (value != null) {
        if (value.data['0']['otp_match'].toString() == '1') {
          // preferences.setString('breffini_token', value.data['token']);
          otpController.clear();
          Get.to(() => const ChangePasswordPage());
        } else {
          Get.showSnackbar(const GetSnackBar(
            message: 'invalid otp',
            duration: Duration(milliseconds: 800),
          ));
        }
      } else {
        Get.showSnackbar(const GetSnackBar(
          message: 'invalid request',
          duration: Duration(milliseconds: 800),
        ));
      }
    });
  }

  generateNewPassword({required String password}) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? teacherId = preferences.getString('teacherid').toString();
    String? tokens = preferences.getString('generateToken');

    print(tokens);
    await HttpRequest.httpPostBodyRequest(
        endPoint: HttpUrls.newPassword,
        bodyData: {
          "token": tokens,
          "password": password,
          "user_id": teacherId
        }).then((value) async {
      print('login value $value');

      if (value?.statusCode == 200) {
        await Get.offAll(() => const LoginPage());
        newPasswordController.clear();
        confirmPasswordController.clear();
        emailIDController.clear();
        passwordController.clear();
        Get.showSnackbar(const GetSnackBar(
          message: 'Password changed successfully',
          duration: Duration(milliseconds: 1000),
        ));
      } else {
        Get.showSnackbar(const GetSnackBar(
          message: 'invalid otp',
          duration: Duration(milliseconds: 700),
        ));
      }
    });
  }

  void logout() async {
    print('DEBUG: Logout started...');

    FirebaseFirestore.instance.clearPersistence();
    FirebaseFirestore.instance.terminate();
    CallandChatController callOngoingController = Get.find();
    String callId = callOngoingController.currentCallModel.value.callId ?? "";

    if (!callOngoingController.currentCallModel.value.callId.isNullOrEmpty()) {
      if (callOngoingController.currentCallModel.value.type == "new_live") {
        LiveClassController liveController = Get.find();

        await liveController.stopBatchLive(
            callOngoingController.currentCallModel.value.callId!,
            batchId: callOngoingController.currentCallModel.value.batchId!,
            courseId: callOngoingController.currentCallModel.value.courseId!);
      } else {
        await callOngoingController.disconnectCall(
            true,
            false,
            callOngoingController.currentCallModel.value.callerId!,
            callOngoingController.currentCallModel.value.callId!);
      }

      await FlutterCallkitIncoming.endCall(callId);
    }

    // Unsubscribe from FCM topic
    print('DEBUG: Unsubscribing from topic: TCR-${PrefUtils().getTeacherId()}');
    FirebaseMessaging.instance
        .unsubscribeFromTopic("TCR-" + PrefUtils().getTeacherId());

    // CRITICAL: Delete the FCM token to prevent notifications going to the wrong user
    // This ensures that when a new user logs in, they get a fresh token
    try {
      print('DEBUG: Deleting FCM token on logout...');
      await FirebaseMessaging.instance.deleteToken();
      print('DEBUG: FCM token deleted successfully');
    } catch (e) {
      print('DEBUG: Error deleting FCM token: $e');
    }

    // Clear local storage
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove('breffini_token');
    await preferences.remove('breffini_teacher_Id');
    await preferences.remove('user_type_id'); // Also clear user type

    isLoggedIn.value = false;
    print('DEBUG: Logout complete, navigating to login page');

    // await Get.delete(force: true);

    Get.offAll(() => const LoginPage());
    // Get.deleteAll(force: false); //riyas brain
  }
}
