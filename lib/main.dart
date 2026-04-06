import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:breffini_staff/controller/calls_page_controller.dart';
import 'package:breffini_staff/controller/course_content_controller.dart';
import 'package:breffini_staff/controller/course_enrol_controller.dart';
import 'package:breffini_staff/controller/course_module_controler.dart';
import 'package:breffini_staff/controller/individual_call_controller.dart';
import 'package:breffini_staff/controller/login_controller.dart';
import 'package:breffini_staff/controller/ongoing_call_controller.dart';
import 'package:breffini_staff/controller/profile_controller.dart';
import 'package:breffini_staff/controller/student_course_controller.dart';
import 'package:breffini_staff/controller/chat_controller.dart';
import 'package:breffini_staff/controller/chat_history_controller.dart';

import 'package:breffini_staff/core/utils/pref_utils.dart';

import 'package:breffini_staff/firebase_options.dart';
import 'package:breffini_staff/http/chat_socket.dart';
import 'package:breffini_staff/http/notification_service.dart';
import 'package:breffini_staff/http/http_urls.dart';

import 'package:breffini_staff/view/pages/authentication/login_page.dart';
import 'package:breffini_staff/view/pages/courses/widgets/size_utils.dart';
import 'package:breffini_staff/view/pages/home_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Set background handler BEFORE other firebase execution
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await NotificationService().initialize();
  } catch (e) {
    print("DEBUG: Firebase init error: $e");
  }

  /// 🔹 Permanent Controllers
  Get.put(ProfileController(), permanent: true);
  Get.put(CallandChatController(), permanent: true);
  Get.put(IndividualCallController(), permanent: true);
  Get.put(ChatController(), permanent: true);
  Get.put(ChatHistoryController(), permanent: true);
  Get.put(CallOngoingController(), permanent: true);
  Get.put(StudentCourseController(), permanent: true);
  Get.put(CourseModuleController(), permanent: true);
  Get.put(CourseContentController(), permanent: true);
  Get.put(CourseEnrolController(), permanent: true);

  try {
    await PrefUtils().init();
  } catch (e) {
    print("DEBUG: PrefUtils error: $e");
  }

  /// 🔹 Socket init (non-blocking)
  print("DEBUG: main.dart - BaseURL before socket init: '${HttpUrls.baseUrl}'");
  ChatSocket.initSocket().catchError((e) => print("DEBUG: Socket error: $e"));

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final loginController = Get.put(LoginController());

    /// ✅ SIZER INITIALIZES SizeUtils.width & height
    return Sizer(
      builder: (context, orientation, deviceType) {
        /// ✅ SCREENUTIL INITIALIZES .sp .w .h
        return ScreenUtilInit(
          designSize: MediaQuery.of(context).size.width > 600 &&
                  MediaQuery.of(context).size.width < 1440
              ? const Size(834, 700)
              : MediaQuery.of(context).size.width < 600
                  ? const Size(390, 890.2446)
                  : const Size(1440, 900),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return GetMaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'Happy English-Staff',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                useMaterial3: true,
              ),
              home: Obx(() {
                return loginController.isLoggedIn.value
                    ? const HomePage()
                    : const LoginPage();
              }),
            );
          },
        );
      },
    );
  }
}
