import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:breffini_staff/http/http_requests.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:flutter/material.dart';

class StaffAttendanceController extends GetxController {
  RxString currentStatus = "Pending".obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String savedDate = prefs.getString('attendance_date') ?? '';
    
    if (savedDate == today) {
      currentStatus.value = prefs.getString('attendance_status') ?? "Pending";
    } else {
      currentStatus.value = "Pending";
      prefs.setString('attendance_date', today);
      prefs.setString('attendance_status', "Pending");
    }
  }

  Future<void> markAttendance(String statusToMark) async {
    if (isLoading.value) return;
    isLoading.value = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      String teacherId = prefs.getString('breffini_teacher_Id') ?? "0";
      
      final response = await HttpRequest.httpPostBodyRequest(
        endPoint: HttpUrls.saveStaffAttendance,
        bodyData: {
          "Teacher_ID": teacherId,
          "Status": statusToMark,
        },
      );
      
      if (response != null) {
        // Success
        currentStatus.value = statusToMark;
        String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        prefs.setString('attendance_date', today);
        prefs.setString('attendance_status', statusToMark);
        
        Get.snackbar("Success", "Successfully marked $statusToMark", 
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar("Error", "Failed to mark attendance", 
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to mark attendance", 
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}
