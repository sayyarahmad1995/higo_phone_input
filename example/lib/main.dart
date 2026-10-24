
import 'package:flutter/material.dart';
import 'package:higo_phone_input/higo_phone_input.dart';

void main() {
  runApp(const HiGoExampleApp());
}

class HiGoExampleApp extends StatelessWidget {
  const HiGoExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HiGO Phone Input',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const PhoneInputDemo(),
    );
  }
}

class PhoneInputDemo extends StatefulWidget {
  const PhoneInputDemo({super.key});

  @override
  State<PhoneInputDemo> createState() => _PhoneInputDemoState();
}

class _PhoneInputDemoState extends State<PhoneInputDemo> {
  PhoneValidationResult? result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HiGO Phone Input'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your phone number',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              HiGoPhoneInput(
                onChanged: (value) {
                  setState(() {
                    result = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              Text(
                'Country: ${result?.countryCode ?? "Not entered"}',
              ),
              Text(
                'Number: ${result?.e164 ?? "Not valid"}',
              ),
              Text(
                'Valid: ${result?.isValid ?? false}',
              ),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: result?.isValid == true
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Valid number: ${result!.e164}',
                            ),
                          ),
                        );
                      }
                    : null,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
