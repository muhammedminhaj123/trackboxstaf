import 'dart:io';

import 'package:breffini_staff/controller/profile_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/core/utils/image_constants.dart';
import 'package:breffini_staff/http/cloud_flare_upload.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/http/loader.dart';
import 'package:breffini_staff/model/teacher_profile_model.dart';
import 'package:breffini_staff/view/widgets/common_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileController pController = Get.put(ProfileController());
  File? image;
  final _picker = ImagePicker();
  String userTypeId = '2';
  bool _isPickingImage = false; // Flag to check if the image picker is active

  @override
  void initState() {
    print('<<<<<<<<<<<<<<<<<<object>>>>>>>>>>>>>>>>>>');
    print('edit ${pController.getTeacher[0].userId}');
    pController.fNameController.text = pController.getTeacher[0].firstName;
    pController.lNameController.text = pController.getTeacher[0].lastName;
    pController.passwordController.text = pController.getTeacher[0].password;
    pController.emailController.text = pController.getTeacher[0].email;
    pController.phoneController.text = pController.getTeacher[0].phoneNumber;
    pController.gMeetController.text =
        pController.getTeacher[0].gMeetLink ?? '';

    _loadUserTypeId();
    super.initState();
  }

  Future<void> _loadUserTypeId() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String userType = preferences.getString('user_type_id') ?? '2';

    setState(() {
      userTypeId = userType;
    });
  }

  //from gallery
  Future<void> pickImageFromGallery() async {
    if (_isPickingImage) return; // Prevent multiple instances
    _isPickingImage = true;

    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        image = File(pickedImage.path);
        Get.back();
      });
    }
    _isPickingImage = false; // Reset the flag after picking the image
  }

  //from camera
  Future<void> pickImageFromCamera() async {
    if (_isPickingImage) return; // Prevent multiple instances
    _isPickingImage = true;

    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        image = File(pickedImage.path);
        Get.back();
      });
    }
    _isPickingImage = false; // Reset the flag after picking the image
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: ColorResources.colorgrey200,
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => Get.back(),
                  child: CircleAvatar(
                    backgroundColor: ColorResources.colorBlue100,
                    radius: 18.r,
                    child: Padding(
                      padding: EdgeInsets.only(left: 8.0.w),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: ColorResources.colorgrey600,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 8.h,
                ),
                Text(
                  "Edit Profile",
                  style: GoogleFonts.plusJakartaSans(
                    color: ColorResources.colorgrey700,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(
                  height: 16.h,
                ),
                Container(
                  width: Get.width,
                  decoration: BoxDecoration(
                      color: ColorResources.colorwhite,
                      borderRadius: BorderRadius.circular(10.r)),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        profileImageStackWidget(context),
                        SizedBox(
                          height: 16.h,
                        ),
                        commonTextFieldWidget(
                            controller: pController.fNameController,
                            labelText: 'First Name',
                            onChanged: (value) {}),
                        SizedBox(
                          height: 6.h,
                        ),
                        commonTextFieldWidget(
                            controller: pController.lNameController,
                            labelText: 'Last Name',
                            onChanged: (value) {}),
                        SizedBox(
                          height: 6.h,
                        ),
                        commonTextFieldWidget(
                            controller: pController.emailController,
                            labelText: 'Email',
                            onChanged: (value) {}),
                        SizedBox(
                          height: 6.h,
                        ),
                        commonTextFieldWidget(
                            controller: pController.phoneController,
                            labelText: 'Phone Number',
                            onChanged: (value) {}),
                        SizedBox(
                          height: 6.h,
                        ),
                        commonTextFieldWidget(
                            controller: pController.passwordController,
                            labelText: 'Password',
                            onChanged: (value) {}),
                        /*SizedBox(
                          height: 6.h,
                        ),
                        commonTextFieldWidget(
                            controller: pController.gMeetController,
                            labelText: 'Google meet link',
                            onChanged: (value) {}),*/
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: buttonWidget(
              context: context,
              text: 'Save',
              backgroundColor: ColorResources.colorBlue600,
              txtColor: ColorResources.colorwhite,
              onPressed: () async {
                Loader.showLoader();
                String imagePath = '';
                if (image != null) {
                  var img =
                      await CloudFlareUpload.uploadToCloudFlare(image!) ?? '';
                  if (img != '') {
                    imagePath = Uri.parse(img).path.replaceFirst('/', '');
                  }
                }
                TeacherProfileModel teacherProfile = TeacherProfileModel(
                  gMeetLink: pController.gMeetController.text,
                  userActiveStatus: pController.getTeacher[0].userActiveStatus,
                  userId: pController.getTeacher[0].userId,
                  firstName: pController.fNameController.text.trim(),
                  lastName: pController.lNameController.text.trim(),
                  email: pController.emailController.text.trim(),
                  phoneNumber: pController.phoneController.text.trim(),
                  deleteStatus: pController.getTeacher[0].deleteStatus,
                  userTypeId: pController.getTeacher[0].userTypeId,
                  userRoleId: pController.getTeacher[0].userRoleId,
                  userStatus: pController.getTeacher[0].userStatus,
                  otp: pController.getTeacher[0].otp,
                  password: pController.passwordController.text.trim(),
                  profilePhotoPath: image != null
                      ? imagePath
                      : pController.getTeacher[0].profilePhotoPath,
                  profilePhotoName: pController.getTeacher[0].profilePhotoName,
                  registeredDate: pController.getTeacher[0].registeredDate,
                );
                await pController.saveEditedProfile(teacherProfile, context);

                Loader.stopLoader();
              }),
        ),
      ),
    );
  }

  Widget profileImageStackWidget(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 100.h,
          width: 100.h,
          decoration: const BoxDecoration(
            color: ColorResources.colorBlue500,
            shape: BoxShape.circle,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50.h),
            child: image != null
                ? Image.file(
                    image!,
                    fit: BoxFit.cover,
                    errorBuilder: (BuildContext context, Object error,
                        StackTrace? stackTrace) {
                      return const Center(
                        child: Icon(Icons.image_not_supported_outlined,
                            color: ColorResources.colorBlue100, size: 10),
                      );
                    },
                  )
                : profileController.getTeacher[0].profilePhotoPath.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl:
                            '${HttpUrls.imgBaseUrl}${pController.getTeacher[0].profilePhotoPath}?t=${DateTime.now().millisecondsSinceEpoch}',
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: ColorResources.colorBlue100,
                            size: 40,
                          ),
                        ),
                        progressIndicatorBuilder:
                            (context, url, downloadProgress) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: ColorResources.colorBlue500,
                            value: downloadProgress.progress,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Image.asset(
                          ImageConstant.breffniLogo,
                          fit: BoxFit.fill,
                        ),
                      ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return ShowDialogWidget(
                    fromCamera: () {
                      pickImageFromCamera();
                    },
                    fromGallery: () {
                      pickImageFromGallery();
                    },
                  );
                },
              );
            },
            child: Container(
              height: 30.h,
              width: 30.w,
              decoration: BoxDecoration(
                  color: ColorResources.colorgrey600,
                  borderRadius: BorderRadius.circular(8.w)),
              child: Icon(
                Icons.camera_alt_outlined,
                size: 14.sp,
                color: ColorResources.colorwhite,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ShowDialogWidget extends StatelessWidget {
  final void Function()? fromGallery;
  final void Function()? fromCamera;
  const ShowDialogWidget(
      {super.key, required this.fromGallery, required this.fromCamera});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: false,
      shadowColor: ColorResources.colorBlack,
      elevation: 15,
      backgroundColor: ColorResources.colorwhite,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: fromGallery,
                icon: const Icon(Icons.photo_size_select_actual_rounded),
              ),
              Text(
                'Gallery',
                style: GoogleFonts.dmSans(
                  color: ColorResources.colorBlack,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  onPressed: fromCamera,
                  icon: const Icon(Icons.camera_alt_rounded)),
              Text(
                'Camera',
                style: GoogleFonts.dmSans(
                  color: ColorResources.colorBlack,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
