import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/http/profile_service.dart';
import 'package:breffini_staff/view/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'qualificationmodal.dart';

class AddQualificationPage extends StatefulWidget {
  final Qualification? qualification; // null = add, not null = edit

  const AddQualificationPage({super.key, this.qualification});

  @override
  State<AddQualificationPage> createState() => _AddQualificationPageState();
}

class _AddQualificationPageState extends State<AddQualificationPage> {
  final TextEditingController degreeController = TextEditingController();
  final TextEditingController instituteController = TextEditingController();
  final TextEditingController yearController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  int teacherId = 0;

  /// Full selected date
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _loadTeacherId();

    /// PREFILL FOR EDIT
    if (widget.qualification != null) {
      degreeController.text = widget.qualification!.degree;
      instituteController.text = widget.qualification!.institute;
      yearController.text = widget.qualification!.year;
      selectedDate = DateTime(int.parse(widget.qualification!.year), 1, 1);
    }
  }

  Future<void> _loadTeacherId() async {
    final prefs = await SharedPreferences.getInstance();
    teacherId = int.tryParse(prefs.getString('breffini_teacher_Id') ?? '') ?? 0;
  }

  /// ================= YEAR → DATE PICKER =================
  void _showYearPicker() {
    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Select Year"),
          content: SizedBox(
            height: 300,
            width: 300,
            child: YearPicker(
              firstDate: DateTime(1980),
              lastDate: DateTime.now(),
              selectedDate: selectedDate ?? DateTime.now(),
              onChanged: (yearDate) async {
                Navigator.pop(context);

                /// After year → open date picker
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime(yearDate.year, 1, 1),
                  firstDate: DateTime(yearDate.year, 1, 1),
                  lastDate: DateTime(yearDate.year, 12, 31),
                );

                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                    yearController.text = pickedDate.year.toString();
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveQualification() async {
    if (!_formKey.currentState!.validate()) return;

    if (teacherId == 0 || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid data")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final service = TeacherProfileService();

      final passoutDate =
          "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

      if (widget.qualification == null) {
        /// ADD
        await service.saveQualification(
          teacherId: teacherId,
          courseName: degreeController.text.trim(),
          institutionName: instituteController.text.trim(),
          passoutDate: passoutDate,
        );
      } else {
        /// EDIT
        await service.editQualification(
          qualificationId: widget.qualification!.id,
          teacherId: teacherId,
          courseName: degreeController.text.trim(),
          institutionName: instituteController.text.trim(),
          passoutDate: passoutDate,
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to save qualification"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(String label, {Widget? suffixIcon}) {
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
      suffixIcon: suffixIcon,
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
  void dispose() {
    degreeController.dispose();
    instituteController.dispose();
    yearController.dispose();
    super.dispose();
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
                  widget.qualification == null
                      ? "Add Qualification"
                      : "Edit Qualification",
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
                            controller: degreeController,
                            style: GoogleFonts.plusJakartaSans(
                              color: ColorResources.colorBlue800,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _buildInputDecoration("Degree"),
                            validator: (v) =>
                                v == null || v.isEmpty ? "Enter degree" : null,
                          ),
                          SizedBox(height: 12.h),
                          TextFormField(
                            controller: instituteController,
                            style: GoogleFonts.plusJakartaSans(
                              color: ColorResources.colorBlue800,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _buildInputDecoration("Institute"),
                            validator: (v) => v == null || v.isEmpty
                                ? "Enter institute"
                                : null,
                          ),
                          SizedBox(height: 12.h),

                          /// SINGLE CALENDAR FIELD
                          TextFormField(
                            controller: yearController,
                            readOnly: true,
                            style: GoogleFonts.plusJakartaSans(
                              color: ColorResources.colorBlue800,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _buildInputDecoration(
                              "Passout Date",
                              suffixIcon: const Icon(Icons.calendar_today,
                                  color: ColorResources.colorgrey500),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? "Select date" : null,
                            onTap: _showYearPicker,
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
            onPressed: isLoading ? null : _saveQualification,
          ),
        ),
      ),
    );
  }
}
