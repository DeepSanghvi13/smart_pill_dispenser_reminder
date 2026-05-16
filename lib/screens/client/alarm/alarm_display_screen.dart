import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/alarm_service.dart';
import '../../../services/voice_reminder_service.dart';

class AlarmDisplayScreen extends StatefulWidget {
  const AlarmDisplayScreen({super.key});

  @override
  State<AlarmDisplayScreen> createState() => _AlarmDisplayScreenState();
}

class _AlarmDisplayScreenState extends State<AlarmDisplayScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  AlarmService? _alarmService;
  String _lastSpeechKey = '';
  bool _listenerAttached = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_listenerAttached) {
      return;
    }

    _alarmService = Provider.of<AlarmService>(context, listen: false);
    _alarmService?.addListener(_onAlarmStateChanged);
    _listenerAttached = true;
  }

  Future<void> _onAlarmStateChanged() async {
    final service = _alarmService;
    if (!mounted || service == null) {
      return;
    }

    if (!service.isAlarmActive) {
      _lastSpeechKey = '';
      await VoiceReminderService.stop();
      return;
    }

    final key =
        '${service.currentMedicineId}:${service.alarmTriggeredTime?.millisecondsSinceEpoch ?? 0}';
    if (key == _lastSpeechKey) {
      return;
    }

    _lastSpeechKey = key;
    await VoiceReminderService.speakReminder(
      medicineName: service.currentMedicineName,
      dosage: service.currentMedicineDosage,
    );
  }

  void _setupAnimations() {
    // Pulse animation for the alarm icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    // Scale animation for the alarm button press
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _alarmService?.removeListener(_onAlarmStateChanged);
    VoiceReminderService.stop();
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleStop(BuildContext context) {
    final alarmService = Provider.of<AlarmService>(context, listen: false);
    alarmService.stopAlarm();
    VoiceReminderService.stop();
    _showStopConfirmation();
  }

  void _showStopConfirmation() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Alarm stopped ✓',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.blue.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlarmService>(
      builder: (context, alarmService, child) {
        if (!alarmService.isAlarmActive) {
          return const SizedBox.shrink();
        }

        return Scaffold(
          backgroundColor: Colors.red.shade50,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header with time
                    Column(
                      children: [
                        Text(
                          'MEDICATION REMINDER',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.red.shade700,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatTime(DateTime.now()),
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Animated Alarm Icon
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.2).animate(
                        CurvedAnimation(
                            parent: _pulseController, curve: Curves.easeInOut),
                      ),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.alarm,
                          size: 70,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Medicine Details
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Take Your Medicine',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Colors.grey.shade600,
                                  letterSpacing: 1,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            alarmService.currentMedicineName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            alarmService.currentMedicineDosage,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.grey.shade700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    const SizedBox(height: 40),

                    // Stop Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleStop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.stop_circle, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'STOP ALARM',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
