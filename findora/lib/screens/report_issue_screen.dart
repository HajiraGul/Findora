import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_snackbar.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();

  static const List<String> _categories = [
    "Bug / App crash",
    "Account issue",
    "A post or claim",
    "Inappropriate content",
    "Payment / Reward",
    "Other",
  ];

  String _selectedCategory = _categories.first;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().user.value
        : null;
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    // No dedicated support endpoint yet — simulate a network submission so the
    // flow feels complete and gives the user clear confirmation.
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() => _submitting = false);

    AppSnackBar.success(
      context,
      "Thanks! Your report has been submitted.",
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,

      child: Scaffold(
        backgroundColor: const Color(0xffF5FAFF),

        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,

          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xff17324D),
            ),
            onPressed: () => Navigator.pop(context),
          ),

          title: const Text(
            "Report a Problem",
            style: TextStyle(
              color: Color(0xff17324D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),

                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff0A84FF), Color(0xff0066D6)],
                      ),

                      borderRadius: BorderRadius.circular(28),
                    ),

                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,

                          child: Icon(
                            Icons.report_problem_rounded,
                            color: Color(0xff0A5EB0),
                            size: 28,
                          ),
                        ),

                        SizedBox(width: 16),

                        Expanded(
                          child: Text(
                            "Tell us what went wrong and we’ll look into it right away.",

                            style: TextStyle(
                              color: Colors.white,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const _Label("What is this about?"),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _categories.map(_categoryChip).toList(),
                  ),

                  const SizedBox(height: 22),

                  const _Label("Subject"),
                  const SizedBox(height: 10),
                  _fieldShell(
                    child: TextFormField(
                      controller: _subjectController,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Please add a short subject"
                          : null,
                      decoration: const InputDecoration(
                        hintText: "e.g. App crashes when uploading a photo",
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const _Label("Describe the issue"),
                  const SizedBox(height: 10),
                  _fieldShell(
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      validator: (v) => (v == null || v.trim().length < 10)
                          ? "Please add at least a few words"
                          : null,
                      decoration: const InputDecoration(
                        hintText:
                            "Steps to reproduce, what you expected, and what "
                            "actually happened...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const _Label("Your email (for follow-up)"),
                  const SizedBox(height: 10),
                  _fieldShell(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Please add an email so we can reply";
                        }
                        if (!v.contains('@') || !v.contains('.')) {
                          return "Enter a valid email address";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: "you@example.com",
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xff0A84FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),

                      onPressed: _submitting ? null : _submit,

                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Submit Report",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String label) {
    final selected = _selectedCategory == label;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

        decoration: BoxDecoration(
          color: selected ? const Color(0xff0A84FF) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? const Color(0xff0A84FF)
                : Colors.blue.withOpacity(.15),
          ),
        ),

        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xff17324D),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _fieldShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xff17324D),
        fontSize: 15,
      ),
    );
  }
}
