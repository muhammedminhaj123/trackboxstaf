import 'dart:developer';

import 'package:breffini_staff/controller/course_content_controller.dart';
import 'package:breffini_staff/controller/login_controller.dart';
import 'package:breffini_staff/controller/profile_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/core/utils/image_constants.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/http/profile_service.dart';
import 'package:breffini_staff/view/pages/home_screen.dart';
import 'package:breffini_staff/view/pages/profile/batch_screen.dart';
import 'package:breffini_staff/view/pages/profile/edit_profile.dart';
import 'package:breffini_staff/view/pages/profile/qualification/qualificationmodal.dart';
import 'package:breffini_staff/view/pages/profile/qualification/qualificationui.dart';
import 'package:breffini_staff/view/pages/profile/qualification/qualificationwidegets.dart';
import 'package:breffini_staff/view/pages/profile/workexpiriance/workexpiriancemodal.dart';
import 'package:breffini_staff/view/pages/profile/workexpiriance/workexpirianceui.dart';
import 'package:breffini_staff/view/widgets/home_screen_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController profileController = Get.put(ProfileController());
  final LoginController loginController = Get.put(LoginController());
  final CourseContentController courseContentController =
      Get.find<CourseContentController>();

  final TeacherProfileService service = TeacherProfileService();

  bool showWorkExperience = false;
  bool showQualification = false;

  int teacherId = 0;
  PackageInfo? packageInfo;

  List<Qualification> qualificationList = [];
  List<WorkExperience> workExperienceList = [];

  @override
  void initState() {
    super.initState();
    _loadTeacherId();
    _initPackageInfo();
  }

  Future<void> _loadTeacherId() async {
    final prefs = await SharedPreferences.getInstance();
    final teacherIdStr = prefs.getString('breffini_teacher_Id');
    teacherId = int.tryParse(teacherIdStr ?? '') ?? 0;

    log("Teacher ID = $teacherId");

    if (teacherId != 0) {
      await loadQualifications();
      await loadExperience();
    }
  }

  Future<void> loadQualifications() async {
    final data = await service.getQualifications(teacherId);
    qualificationList = data.map<Qualification>((e) {
      return Qualification(
        id: e['Qualification_ID'], // 🔥 backend id
        degree: e['Course_Name'],
        institute: e['Institution_Name'],
        year: e['Passout_Date'].toString().substring(0, 4),
      );
    }).toList();
    setState(() {});
    log("Qualifications count: ${qualificationList.length}");
  }

  Future<void> loadExperience() async {
    final data = await service.getExperience(teacherId);
    workExperienceList = data.map<WorkExperience>((e) {
      return WorkExperience(
        id: e['Experience_ID'], // 🔥 backend id
        role: e['Job_Role'],
        company: e['Organization_Name'],
        duration: "${e['Years_Of_Experience']} Years",
      );
    }).toList();

    setState(() {});
  }

  Future<void> _initPackageInfo() async {
    packageInfo = await PackageInfo.fromPlatform();
    setState(() {});
  }

  Future<bool> _onWillPop() async {
    Get.offAll(() => const HomePage(initialIndex: 0));
    return false;
  }

  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: Get.back, child: const Text("No")),
          TextButton(
            onPressed: () {
              Get.back();
              loginController.logout();
            },
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> deleteQualification(Qualification q) async {
    await service.deleteQualification(
      qualificationId: q.id,
      teacherId: teacherId,
    );

    await loadQualifications(); // 🔥 reload from backend
  }

  Future<void> deleteExperience(WorkExperience exp) async {
    try {
      await service.deleteExperience(
        experienceId: exp.id,
        teacherId: teacherId,
      );

      await loadExperience(); // 🔥 refresh UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to delete work experience"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: ColorResources.colorgrey200,
          body: Obx(
            () => profileController.getTeacher.isEmpty
                ? const Center(child: Text("Unable to load profile"))
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8.h),

                        Text(
                          "My Profile",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        SizedBox(height: 16.h),

                        /// PROFILE CARD
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: ColorResources.colorwhite,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 30.w,
                                backgroundColor: ColorResources.colorBlue500,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30.w),
                                  child: profileController.getTeacher[0]
                                          .profilePhotoPath.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl:
                                              "${HttpUrls.imgBaseUrl}${profileController.getTeacher[0].profilePhotoPath}?t=${DateTime.now().millisecondsSinceEpoch}",
                                          fit: BoxFit.cover,
                                        )
                                      : Image.asset(
                                          ImageConstant.breffniLogo,
                                        ),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                "${profileController.getTeacher[0].firstName} ${profileController.getTeacher[0].lastName}",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                profileController.getTeacher[0].email,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.sp,
                                  color: ColorResources.colorgrey600,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              // DEBUG: Always show this to verify the data
                              Builder(
                                builder: (context) {
                                  final regDate = profileController
                                      .getTeacher[0].registeredDate;
                                  log("DEBUG Profile Screen - Registered Date: $regDate");

                                  if (regDate == null || regDate.isEmpty) {
                                    return Text(
                                      "Registered Date: Not Available",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.sp,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  }

                                  String formattedDate = '';
                                  try {
                                    final dateTime = DateTime.parse(regDate);
                                    formattedDate = DateFormat('dd MMM yyyy')
                                        .format(dateTime);
                                  } catch (e) {
                                    log("Date parsing failed: $e");
                                    formattedDate = regDate.length > 10
                                        ? regDate.substring(0, 10)
                                        : regDate;
                                  }

                                  return Text(
                                    "Registered Date: $formattedDate",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.sp,
                                      color: ColorResources.colorgrey600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 8.h),
                              TextButton(
                                onPressed: () =>
                                    Get.to(() => const EditProfileScreen()),
                                child: const Text("Edit Details"),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16.h),

                        /// ASSIGNED BATCHES
                        InkWell(
                          onTap: () {
                            Get.to(() => const BatchScreen());
                          },
                          child: profileTileWidget(
                            name: 'Assigned Batches',
                            svgIcon: 'assets/images/ic_connect.svg',
                            onPressed: () {
                              Get.to(() => const BatchScreen());
                            },
                          ),
                        ),

                        SizedBox(height: 16.h),

                        /// WORK EXPERIENCE
                        profileActionTile(
                          title: "Work Experience",
                          onTap: () {
                            setState(() {
                              showWorkExperience = !showWorkExperience;
                              showQualification = false;
                            });
                          },
                        ),
                        if (showWorkExperience)
                          workExperienceSection(
                            context: context,
                            workExperienceList: workExperienceList,
                            refresh: loadExperience,
                            deleteExperience: deleteExperience, // ✅ CORRECT
                          ),

                        /// QUALIFICATION
                        profileActionTile(
                          title: "Qualification",
                          onTap: () {
                            setState(() {
                              showQualification = !showQualification;
                              showWorkExperience = false;
                            });
                          },
                        ),
                        if (showQualification)
                          qualificationSection(
                            context: context,
                            qualificationList: qualificationList,
                            refresh: loadQualifications,
                            onDelete: deleteQualification, // ✅ PASS FUNCTION
                          ),

                        const Divider(),

                        InkWell(
                          onTap: showLogoutDialog,
                          child: Text(
                            "Log Out",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.red,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),

                        SizedBox(height: 20.h),

                        Center(
                          child: Text(
                            "App Version ${packageInfo?.version ?? "0.0"}",
                            style: const TextStyle(color: Color(0xff949596)),
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
