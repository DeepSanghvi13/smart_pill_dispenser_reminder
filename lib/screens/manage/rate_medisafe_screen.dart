import 'package:flutter/material.dart';

class RateMedisafeScreen extends StatefulWidget {
  const RateMedisafeScreen({super.key});

  @override
  State<RateMedisafeScreen> createState() => _RateMedisafeScreenState();
}

class _RateMedisafeScreenState extends State<RateMedisafeScreen> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Medisafe'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.star,
                    size: 64,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'How do you like Medisafe?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your feedback helps us improve',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Star Rating
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 1; i <= 5; i++)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = i;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.star,
                          size: 50,
                          color: i <= _rating ? Colors.amber : Colors.grey[300],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Rating Labels
            if (_rating > 0)
              Center(
                child: Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Text(
                      _getRatingLabel(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D4F8B),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // Feedback Section
            if (_rating > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Additional Comments (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Tell us what you think...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D4F8B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thank you for rating Medisafe!'),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Submit Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Center(
                child: Text(
                  'Please select a rating',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel() {
    switch (_rating) {
      case 1:
        return '😞 Poor';
      case 2:
        return '😕 Fair';
      case 3:
        return '😊 Good';
      case 4:
        return '😄 Very Good';
      case 5:
        return '😍 Excellent';
      default:
        return '';
    }
  }
}

