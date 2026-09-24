import 'package:flutter/material.dart';
import '../../../models/doctor_feedback.dart';
import '../../../services/mysql_api_service.dart';

class DoctorFeedbackScreen extends StatefulWidget {
  const DoctorFeedbackScreen({super.key});

  @override
  State<DoctorFeedbackScreen> createState() => _DoctorFeedbackScreenState();
}

class _DoctorFeedbackScreenState extends State<DoctorFeedbackScreen> {
  List<DoctorFeedback> _feedbacks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    setState(() => _isLoading = true);
    
    final list = await MySQLApiService().getDoctorFeedback();
    if (mounted) {
      setState(() {
        _feedbacks = list.map((e) => DoctorFeedback.fromMap(e)).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Feedback')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _feedbacks.isEmpty
              ? const Center(child: Text('No feedback from doctors yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _feedbacks.length,
                  itemBuilder: (ctx, i) {
                    final f = _feedbacks[i];
                    return Card(
                      child: ListTile(
                        title: Text(f.doctorName ?? 'Unknown Doctor'),
                        subtitle: Text('${f.feedbackText}\n${f.formattedDate}'),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
