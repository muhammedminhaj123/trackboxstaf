import 'package:breffini_staff/controller/profile_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/view/pages/calls/batch_student_list_screen.dart';
import 'package:breffini_staff/view/pages/chats/widgets/custom_appbar_widget.dart';
import 'package:breffini_staff/view/pages/chats/widgets/loading_circle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
        title: "Batches",
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

              // Date Formatting
              String formatDate(String dateStr) {
                if (dateStr.isEmpty) return 'N/A';
                try {
                  DateTime dateTime = DateTime.parse(dateStr);
                  return DateFormat('dd MMM yyyy').format(dateTime);
                } catch (e) {
                  return dateStr;
                }
              }

              final String formattedStart = formatDate(batch.batchStart);
              final String formattedEnd = formatDate(batch.batchEnd);

              return Container(
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: ColorResources.colorgrey300.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
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
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                batch.batchNames ?? batch.courseName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: ColorResources.colorgrey900,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14.sp,
                              color: ColorResources.colorgrey400,
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Divider(
                          height: 1,
                          color: ColorResources.colorgrey200,
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 16.sp,
                              color: ColorResources.colorBlue600,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                "Course: ${batch.courseName}",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: ColorResources.colorgrey700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16.sp,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "Duration: ",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: ColorResources.colorgrey600,
                              ),
                            ),
                            Text(
                              "$formattedStart - $formattedEnd",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: ColorResources.colorgrey800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
