import 'dart:math';
import 'package:flutter/material.dart';
import 'package:elimupepe/core/theme/app_theme.dart';

/// Shows a math-based parental gate dialog.
/// Returns [true] if the user successfully solves the math problem, [false] otherwise.
Future<bool> showParentalGate(BuildContext context) async {
  final random = Random();
  final num1 = random.nextInt(8) + 5; // Generates a number between 5 and 12
  final num2 = random.nextInt(8) + 5; // Generates a number between 5 and 12
  final correctAnswer = num1 * num2;

  final TextEditingController controller = TextEditingController();
  bool hasError = false;

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Ask Your Parents'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('To continue, please solve this math problem:'),
                    const SizedBox(height: 16),
                    Text(
                      '$num1 x $num2 = ?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Answer',
                        errorText: hasError ? 'Incorrect, try again.' : null,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final answer = int.tryParse(controller.text.trim());
                      if (answer == correctAnswer) {
                        Navigator.of(context).pop(true); // Success
                      } else {
                        setState(() => hasError = true); // Failure
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ],
              );
            },
          );
        },
      ) ??
      false; // Return false if the dialog is dismissed by other means
}
