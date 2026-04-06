import 'dart:convert';

import 'package:breffini_staff/core/utils/pref_utils.dart';
import 'package:breffini_staff/http/http_requests.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/model/invoice_model.dart';
import 'package:breffini_staff/model/one_to_one_model.dart';
import 'package:breffini_staff/model/teacher_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ProfileController profileController = Get.put(ProfileController());

class ProfileController extends GetxController {
  var getTeacher = <TeacherProfileModel>[].obs;
  var getInvoice = <Invoicemodel>[].obs;
  var getBatchesOfTeacher = <Onetoonebatchmodel>[].obs;
  RxBool isOneToOneBatchLoading = false.obs;

  TextEditingController fNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController gMeetController = TextEditingController();

  TextEditingController lNameController = TextEditingController();
  RxBool isLoadingProfile = false.obs;

  fetchTeacherProfile({bool showLoader = true}) async {
    isLoadingProfile.value = true;
    final prefs = await SharedPreferences.getInstance();
    String teacherId = prefs.getString('breffini_teacher_Id') ?? "0";
    await HttpRequest.httpGetRequest(
            endPoint: HttpUrls.getTeacherProfile + teacherId,
            showLoader: showLoader)
        .then((response) {
      isLoadingProfile.value = false;

      if (response != null && response.statusCode == 200) {
        final responseData = response.data as List<dynamic>;
        final getTeacherList = responseData[0] as List<dynamic>;
        print(
            "DEBUG: Raw Teacher Data: ${getTeacherList[0]}"); // Check for Registered_Date
        print(
            "DEBUG: Registered_Date value: ${getTeacherList[0]['Registered_Date']}");
        getTeacher.value = getTeacherList
            .map((result) => TeacherProfileModel.fromJson(result))
            .toList();
        print('teacher details');
        print(getTeacher);
        print("DEBUG: Model registeredDate: ${getTeacher[0].registeredDate}");
        PrefUtils().setTeacherName(getTeacher[0].firstName);
        PrefUtils().setProfileUrl(getTeacher[0].profilePhotoPath);
        PrefUtils().setMeetLink(getTeacher[0].gMeetLink ?? '');

        fNameController.text = getTeacher[0].firstName;
        lNameController.text = getTeacher[0].lastName;
        phoneController.text = getTeacher[0].phoneNumber;
        passwordController.text = getTeacher[0].password;
        emailController.text = getTeacher[0].email;
        gMeetController.text = getTeacher[0].gMeetLink ?? '';
      } else {
        if (response != null) {
          throw Exception(
              'Failed to load profile data: ${response.statusCode}');
        }
      }
    });

    update();
  }

  getInvoiceData() async {
    final prefs = await SharedPreferences.getInstance();
    String teacherId = prefs.getString('breffini_teacher_Id') ?? "0";
    await HttpRequest.httpGetRequest(
      endPoint: '${HttpUrls.getInvoiceReport}/$teacherId',
    ).then((response) {
      if (response != null && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is List<dynamic>) {
          final invoiceReports = responseData;
          getInvoice.value = invoiceReports
              .map((result) => Invoicemodel.fromJson(result))
              .toList();
        } else if (responseData is Map<String, dynamic>) {
          final invoiceReports = [responseData];
          getInvoice.value = invoiceReports
              .map((result) => Invoicemodel.fromJson(result))
              .toList();
        } else {
          throw Exception('Unexpected response data format');
        }
      } else {
        if (response != null) {
          throw Exception(
              'Failed to load profile data: ${response.statusCode}');
        }
      }
    }).catchError((error) {
      print('Error fetching data: $error');
    });

    update();
  }

  Future<void> getOneToOneBatch() async {
    try {
      isOneToOneBatchLoading.value = true;
      final prefs = await SharedPreferences.getInstance();
      String teacherId = prefs.getString('breffini_teacher_Id') ?? "0";

      final response = await HttpRequest.httpGetRequest(
          endPoint: '${HttpUrls.getBatchOfTeacher}$teacherId',
          showLoader: false);

      if (response == null) {
        print('Error: No response received from server');
        return;
      }

      if (response.statusCode == 200) {
        final rawResponseData = response.data;

        if (rawResponseData == null) {
          print('Error: Response data is null');
          return;
        }

        // Check if the response is a string and decode if necessary
        final responseData = rawResponseData is String
            ? jsonDecode(rawResponseData)
            : rawResponseData;

        // Ensure responseData is a list or map
        if (responseData is List<dynamic>) {
          // If it's a list, map it to Onetoonebatchmodel
          getBatchesOfTeacher.value = responseData
              .map((result) => Onetoonebatchmodel.fromJson(result))
              .toList();
        } else if (responseData is Map<String, dynamic>) {
          // If it's a map, wrap it in a list and map it
          getBatchesOfTeacher.value = [
            Onetoonebatchmodel.fromJson(responseData)
          ];
        } else {
          print(
              'Error: Unexpected response data format: ${responseData.runtimeType}');
        }
      } else {
        print('Error: Server returned status code: ${response.statusCode}');
        if (response.data != null) {
          print('Error message: ${response.data}');
        }
      }
    } catch (error, stackTrace) {
      print('Error fetching batch data: $error');
      print('Stack trace: $stackTrace');

      Get.snackbar(
        'Error',
        'Failed to load batch data. Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isOneToOneBatchLoading.value = false;

      update();
    }
  }

  saveEditedProfile(
      TeacherProfileModel editedProfile, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final String teacherId = prefs.getString('breffini_teacher_Id') ?? "0";

    await HttpRequest.httpPostBodyRequest(
      endPoint: HttpUrls.editTeacherProfile,
      bodyData: editedProfile.toJson(),
      // bodyData: {
      //   "User_ID": teacherId,
      //   "First_Name": editedProfile.firstName,
      //   "Last_Name": editedProfile.lastName,
      //   "Email": editedProfile.email,
      //   "PhoneNumber": editedProfile.phoneNumber,
      //   "password": editedProfile.password,
      //   "Delete_Status": 0,
      //   "User_Type_Id": 2,
      //   "User_Role_Id": "",
      //   "User_Status": ""
      // },
    ).then((value) async {
      print('edited teacher profile $value');

      if (value != null) {
        await fetchTeacherProfile();
        Get.back();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        fNameController.clear();
        lNameController.clear();
        emailController.clear();
        phoneController.clear();
        passwordController.clear();
      } else {
        Get.showSnackbar(const GetSnackBar(
          message: 'Invalid request',
          duration: Duration(milliseconds: 800),
        ));
      }
    });
    update();
  }

  updatedHodStatus(bool updates) async {
    final prefs = await SharedPreferences.getInstance();
    final String teacherId = prefs.getString('breffini_teacher_Id') ?? "0";

    final String status = updates ? 'true' : 'false';
    final String endPoint = '${HttpUrls.updateHodStatus}?status=$status';

    try {
      final response = await HttpRequest.httpPostBodyRequest(
          endPoint: endPoint, showLoader: false);

      if (response != null) {
        Get.showSnackbar(GetSnackBar(
          message: updates
              ? 'You are currently online'
              : 'You are currently offline',
          duration: const Duration(milliseconds: 2000),
        ));
        fetchTeacherProfile(showLoader: false);
      } else {
        Get.showSnackbar(const GetSnackBar(
          message: 'Invalid request',
          duration: Duration(milliseconds: 800),
        ));
      }
    } catch (e) {
      print('Error updating HOD status: $e');
      Get.showSnackbar(const GetSnackBar(
        message: 'Failed to update status',
        duration: Duration(milliseconds: 800),
      ));
    }
  }

  changeStudentModuleLockStatus(
      {required String studentId,
      required String courseId,
      required int status}) async {
    final prefs = await SharedPreferences.getInstance();
    final String teacherId = prefs.getString('breffini_teacher_Id') ?? "0";
    try {
      await HttpRequest.httpPostBodyRequest(
        endPoint: HttpUrls.changeStudentModuleLockStatus,
        bodyData: {
          "Student_ID": studentId,
          "Course_ID": courseId,
          "Status": status
        },
      ).then((value) async {
        print('edited status $value');

        if (value != null) {
          Get.showSnackbar(const GetSnackBar(
            message: 'Updated successfully',
            duration: Duration(milliseconds: 800),
          ));
        } else {
          Get.showSnackbar(const GetSnackBar(
            message: 'Invalid request',
            duration: Duration(milliseconds: 800),
          ));
        }
      });
    } catch (e) {
      print('Error updating  status: $e');
      Get.showSnackbar(const GetSnackBar(
        message: 'Failed to update status',
        duration: Duration(milliseconds: 800),
      ));
    }
  }
}
