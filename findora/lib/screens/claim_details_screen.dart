import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClaimDetailsScreen extends StatelessWidget {
  final String title;
  final String claimId;
  final String date;
  final String status;
  final Color statusColor;

  const ClaimDetailsScreen({
    super.key,
    required this.title,
    required this.claimId,
    required this.date,
    required this.status,
    required this.statusColor,
  });

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

          iconTheme: const IconThemeData(color: Color(0xff17324D)),

          title: const Text(
            "Claim Details",
            style: TextStyle(
              color: Color(0xff17324D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),

            child: Container(
              padding: const EdgeInsets.all(22),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),

                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xffDCEFFF),

                      child: Icon(
                        Icons.verified_user_rounded,
                        size: 38,
                        color: Color(0xff0A5EB0),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  _detailRow("Item", title),
                  _detailRow("Claim ID", claimId),
                  _detailRow("Submission Date", date),
                  _detailRow("Owner", "Areesha Abbasi"),
                  _detailRow("Verification", "Documents Submitted"),

                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),

                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(.12),
                      borderRadius: BorderRadius.circular(30),
                    ),

                    child: Text(
                      status,

                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Claim Notes",

                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff17324D),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Your claim is being processed by the Lost & Found administration team. You will receive an update once verification is completed.",

                    style: TextStyle(height: 1.6, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Row(
        children: [
          SizedBox(
            width: 130,

            child: Text(
              title,

              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,

              style: const TextStyle(
                color: Color(0xff17324D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
