import 'dart:developer';
import 'package:breffini_staff/controller/login_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/core/utils/pref_utils.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/http/loader.dart';
import 'package:breffini_staff/view/pages/authentication/login_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getx;
import 'package:shared_preferences/shared_preferences.dart';

class HttpRequest {
  static Future<Response?> httpGetRequest(
      {Map<String, dynamic>? bodyData,
      String endPoint = '',
      bool showLoader = true}) async {
    final LoginController loginController = getx.Get.put(LoginController());
    if (showLoader) {
      Loader.showLoader();
    }

    if (kDebugMode) {
      log('get request ====> $endPoint $bodyData ');
    }

    final Dio dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    final String token = prefs.getString('breffini_token') ?? "";
    print(token);
    try {
      final response = await dio.get(
        '${HttpUrls.baseUrl}$endPoint',
        options: Options(headers: {
          'ngrok-skip-browser-warning': 'true',
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        }),
        queryParameters: bodyData,
      );
      if (kDebugMode) {
        log('get result ====> $response  ');
      }
      if (showLoader) {
        Loader.stopLoader();
      }
      return response;
    } catch (ex) {
      if (ex.toString().contains('401')) {
        getx.Get.find<LoginController>().logout();

        loginController.isLoggedIn.value = false;

        getx.Get.snackbar(
          '',
          '',
          backgroundColor: ColorResources.colorgrey800,
          titleText: const Text(
            'Your session was expired',
            style: TextStyle(color: ColorResources.colorwhite),
          ),
          messageText: const Text(
              "Please contact support for more information.",
              style: TextStyle(color: ColorResources.colorwhite)),
          snackPosition: getx.SnackPosition.BOTTOM,
        );
      }

      //  Loader.stopLoader();
      return null;
    }
  }

  static Future<Response?> httpPostBodyRequest(
      {Map<String, dynamic>? bodyData,
      String endPoint = '',
      bool showLoader = true,
      bool dismissible = true}) async {
    if (showLoader) {
      Loader.showLoader(dismissible: dismissible);
    }
    if (kDebugMode) {
      log('post request ====> $endPoint $bodyData ');
    }
    final Dio dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    final String token = prefs.getString('breffini_token') ?? "";

    // String token =
    //     'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOnsiSWQiOjcsIkZpcnN0X05hbWUiOiJqb2huX2RvZSIsIkVtYWlsIjoibW9oYW5AZ21haWwuY29tIiwiUGhvbmVOdW1iZXIiOiIxMjMtNDU2LTc4OTAiLCJVc2VyX1R5cGVfSWQiOjJ9LCJpYXQiOjE3MjAwNzAwNTd9.rFEkWmUwoEh2Q65Ht88nO485cjngPR7skqLuIUtggOQ';

    log('post token $token');
    try {
      final Response response = await dio.post(
        '${HttpUrls.baseUrl}$endPoint',
        options: Options(headers: {
          'ngrok-skip-browser-warning': 'true',
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        }),
        data: bodyData,
      );
      if (kDebugMode) {
        log('post result ====> ${response.data}  ');
      }
      if (showLoader) {
        Loader.stopLoader();
      }

      return response;
    } catch (ex) {
      if (showLoader) {
        Loader.stopLoader();
      }
      if (ex.toString().contains('401')) {
        getx.Get.find<LoginController>().logout();
        final LoginController loginController = getx.Get.put(LoginController());

        loginController.isLoggedIn.value = false;

        getx.Get.snackbar(
          '',
          '',
          backgroundColor: ColorResources.colorgrey800,
          titleText: const Text(
            'Your session was expired',
            style: TextStyle(color: ColorResources.colorwhite),
          ),
          messageText: const Text(
              "Please contact support for more information.",
              style: TextStyle(color: ColorResources.colorwhite)),
          snackPosition: getx.SnackPosition.BOTTOM,
        );
      }
      return null;
    }
  }

  static Future<Response?> httpPostLogin(
      {Map<String, dynamic>? bodyData,
      String endPoint = '',
      bool showLoader = true,
      bool dismissible = true}) async {
    if (showLoader) {
      Loader.showLoader(dismissible: dismissible);
    }
    if (kDebugMode) {
      log('post request ====> $endPoint $bodyData ');
    }
    final Dio dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    final String token = prefs.getString('breffini_token') ?? "";

    try {
      final Response response = await dio.post(
        '${HttpUrls.baseUrl}$endPoint',
        options: Options(headers: {
          'ngrok-skip-browser-warning': 'true',
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        }),
        data: bodyData,
      );
      if (kDebugMode) {
        log('post result ====> ${response.data}  ');
      }
      if (showLoader) {
        Loader.stopLoader();
      }

      return response;
    } catch (ex) {
      if (showLoader) {
        Loader.stopLoader();
      }

      return null;
    }
  }
}
