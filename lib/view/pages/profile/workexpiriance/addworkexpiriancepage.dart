import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/http/profile_service.dart';
import 'package:breffini_staff/view/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'workexpiriancemodal.dart';

class AddWorkExperiencePage extends StatefulWidget {
  final WorkExperience? experience; // ✅ NULL = ADD, NOT NULL = EDIT

  const AddWorkExperiencePage({super.key, this.experience});

  @override
  State<AddWorkExperiencePage> createState() => _AddWorkExperiencePageState();
}

class _AddWorkExperiencePageState extends State<AddWorkExperiencePage> {
  final TextEditingController roleController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController yearsController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  int teacherId = 0;

  @override
  void initState() {
    super.initState();
    _loadTeacherId();

    /// ✏️ PREFILL WHEN EDITING
    if (widget.experience != null) {
      roleController.text = widget.experience!.role;
      companyController.text = widget.experience!.company;
      yearsController.text =
          widget.experience!.duration.replaceAll(" Years", "");
    }
  }

  Future<void> _loadTeacherId() async {
    final prefs = await SharedPreferences.getInstance();
    final idStr = prefs.getString('breffini_teacher_Id');
    teacherId = int.tryParse(idStr ?? '') ?? 0;
  }

  @override
  void dispose() {
    roleController.dispose();
    companyController.dispose();
    yearsController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkExperience() async {
    if (!_formKey.currentState!.validate()) return;

    if (teacherId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Teacher ID missing")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final service = TeacherProfileService();

      if (widget.experience == null) {
        /// ➕ ADD
        await service.saveExperience(
          teacherId: teacherId,
          jobRole: roleController.text.trim(),
          organizationName: companyController.text.trim(),
          yearsOfExperience: double.parse(yearsController.text.trim()),
        );
      } else {
        /// ✏️ EDIT
        await service.editExperience(
          experienceId: widget.experience!.id,
          teacherId: teacherId,
          jobRole: roleController.text.trim(),
          organizationName: companyController.text.trim(),
          yearsOfExperience: double.parse(yearsController.text.trim()),
        );
      }

      /// ✅ RETURN TRUE TO REFRESH LIST
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to save work experience"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: ColorResources.colorgrey600,
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 10.w, horizontal: 10.h),
      fillColor: ColorResources.colorwhite,
      filled: true,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.w),
        borderSide: const BorderSide(color: ColorResources.colorBlack),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.w),
        borderSide: const BorderSide(color: ColorResources.colorgrey300),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.w),
        borderSide: const BorderSide(color: ColorResources.colorgrey200),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.w),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
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
                  onTap: () => Navigator.pop(context),
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
                SizedBox(height: 16.h),
                Text(
                  widget.experience == null
                      ? "Add Work Experience"
                      : "Edit Work Experience",
                  style: GoogleFonts.plusJakartaSans(
                    color: ColorResources.colorgrey700,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ColorResources.colorwhite,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextFormField(
                            controller: roleController,
                            style: GoogleFonts.plusJakartaSans(
                              color: ColorResources.colorBlue800,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _buildInputDecoration("Job Role"),
                            validator: (v) => v == null || v.isEmpty
                                ? "Enter job role"
                                : null,
                          ),
                          SizedBox(height: 12.h),
                          TextFormField(
                            controller: companyController,
                            style: GoogleFonts.plusJakartaSans(
                              color: ColorResources.colorBlue800,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _buildInputDecoration("Organization"),
                            validator: (v) => v == null || v.isEmpty
                                ? "Enter organization"
                                : null,
                          ),
                          SizedBox(height: 12.h),
                          TextFormField(
                            controller: yearsController,
                            style: GoogleFonts.plusJakartaSans(
                              color: ColorResources.colorBlue800,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _buildInputDecoration(
                                "Years of Experience (eg: 5.5)"),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return "Enter years of experience";
                              }
                              if (double.tryParse(v) == null) {
                                return "Enter valid number";
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
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
            text: isLoading ? "Saving..." : "Save",
            backgroundColor: ColorResources.colorBlue600,
            txtColor: ColorResources.colorwhite,
            onPressed: isLoading ? null : _saveWorkExperience,
          ),
        ),
      ),
    );
  }
}
