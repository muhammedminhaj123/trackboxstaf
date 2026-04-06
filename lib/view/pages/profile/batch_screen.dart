import 'package:breffini_staff/controller/profile_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/view/pages/chats/widgets/loading_circle.dart';
import 'package:breffini_staff/view/widgets/profile_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  String formatDate(String? date) {
    try {
      // Check if date is null or empty
      if (date == null || date.isEmpty) {
        return '-';
      }

      // Parse the date from the input string
      DateTime parsedDate = DateTime.parse(date.trim());

      // Format the date in dd-mm-yyyy format
      String formattedDate = "${parsedDate.day.toString().padLeft(2, '0')}-"
          "${parsedDate.month.toString().padLeft(2, '0')}-"
          "${parsedDate.year}";

      return formattedDate;
    } catch (e) {
      // Return a default value if parsing fails
      return '-';
    }
  }

  @override
  void initState() {
    super.initState();
    profileController.getOneToOneBatch();
  }

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController = Get.put(ProfileController());

    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: ColorResources.colorwhite,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: ColorResources.colorBlue100,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: ColorResources.colorBlack.withOpacity(.4),
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Assigned Batches',
                    style: GoogleFonts.plusJakartaSans(
                      color: ColorResources.colorBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: ColorResources.colorgrey200,
        body: Obx(
          () => profileController.isOneToOneBatchLoading.value
              ? const Center(
                  child: LoadingCircle(),
                )
              : profileController.getBatchesOfTeacher.isEmpty
                  ? const Center(
                      child: Text('No Batches assigned'),
                    )
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Column(
                          children: [
                            ListView.separated(
                              separatorBuilder: (context, index) {
                                return const SizedBox(
                                  height: 16,
                                );
                              },
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  profileController.getBatchesOfTeacher.length,
                              itemBuilder: (context, index) {
                                return batchOfTeacherWidget(
                                    badgeColor: Colors
                                        .transparent, // Hidden as requested
                                    badgeText: '', // Hidden as requested
                                    icon: profileController.getBatchesOfTeacher[index].batchIDs != null
                                        ? Icons.group
                                        : Icons.person,
                                    iconColor: ColorResources.colorwhite,
                                    txtColor: ColorResources.colorwhite,
                                    color: profileController
                                                .getBatchesOfTeacher[index]
                                                .batchIDs !=
                                            null
                                        ? ColorResources.colorgrey600
                                        : const Color.fromARGB(255, 0, 133, 60),
                                    timeSlot: 'Time slots :',
                                    batchNames: profileController
                                        .getBatchesOfTeacher[index].courseName,
                                    context: context,
                                    batchStart: formatDate(profileController
                                        .getBatchesOfTeacher[index].batchStart),
                                    batchEnd: formatDate(profileController
                                        .getBatchesOfTeacher[index].batchEnd),
                                    studentsName: profileController
                                                .getBatchesOfTeacher[index]
                                                .batchIDs !=
                                            null
                                        ? 'Batch : ${profileController.getBatchesOfTeacher[index].batchNames}'
                                        : 'No Batch assigned',
                                    studentCount: profileController
                                        .getBatchesOfTeacher[index].timeSlots
                                        .toString());
                              },
                            )
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}
