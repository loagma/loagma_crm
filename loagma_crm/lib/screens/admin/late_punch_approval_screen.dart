import 'package:flutter/material.dart';
import '../../widgets/late_punch_approval_widget.dart';

class LatePunchApprovalScreen extends StatefulWidget {
  const LatePunchApprovalScreen({super.key});

  @override
  State<LatePunchApprovalScreen> createState() =>
      _LatePunchApprovalScreenState();
}

class _LatePunchApprovalScreenState extends State<LatePunchApprovalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Late Punch Approvals'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const LatePunchApprovalWidget(),
    );
  }
}
