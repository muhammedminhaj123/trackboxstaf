import 'package:breffini_staff/controller/profile_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/view/pages/calls/batch_student_list_screen.dart';
import 'package:breffini_staff/view/pages/chats/widgets/custom_appbar_widget.dart';
import 'package:breffini_staff/view/pages/chats/widgets/loading_circle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentBatchListScreen extends StatefulWidget {
  const StudentBatchListScreen({super.key});

  @override
  State<StudentBatchListScreen> createState() => _StudentBatchListScreenState();
}

class _StudentBatchListScreenState extends State<StudentBatchListScreen> {
  final ProfileController profileController = Get.find<ProfileController>();
  final RxString searchQuery = ''.obs;
  final Rx<TextEditingController> searchController =
      TextEditingController().obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileController.getOneToOneBatch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResources.colorgrey200,
      appBar: CustomAppBar(
        title: "Students",
        isStudentList: false,
        controller: searchController.value,
        onChanged: (value) {
          searchQuery.value = value;
        },
        labelText: 'Search Batch',
      ),
      body: RefreshIndicator(
        onRefresh: () => profileController.getOneToOneBatch(),
        child: Obx(() {
          var filteredList =
              profileController.getBatchesOfTeacher.where((batch) {
            final name = (batch.batchNames ?? batch.courseName).toLowerCase();
            return name.contains(searchQuery.value.toLowerCase());
          }).toList();

          if (profileController.isOneToOneBatchLoading.value &&
              profileController.getBatchesOfTeacher.isEmpty) {
            return const Center(child: LoadingCircle());
          }

          if (filteredList.isEmpty &&
              !profileController.isOneToOneBatchLoading.value) {
            return ListView(
              children: [
                SizedBox(height: 200.h),
                Center(
                  child: Text(
                    searchQuery.value.isEmpty
                        ? "No batches found"
                        : "No matching batches",
                    style: GoogleFonts.plusJakartaSans(
                      color: ColorResources.colorgrey500,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: filteredList.length,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final batch = filteredList[index];
              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  title: Text(
                    batch.batchNames ?? batch.courseName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: ColorResources.colorgrey900,
                    ),
                  ),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      "${batch.courseName} | ${batch.batchStart} - ${batch.batchEnd}",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        color: ColorResources.colorgrey500,
                      ),
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: ColorResources.colorgrey400,
                  ),
                  onTap: () {
                    if (batch.batchIDs != null) {
                      Get.to(() => BatchStudentListScreen(
                            batchId: batch.batchIDs.toString(),
                            batchName: batch.batchNames ?? batch.courseName,
                          ));
                    } else {
                      Get.snackbar(
                        "Info",
                        "No batch ID found for this selection",
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
