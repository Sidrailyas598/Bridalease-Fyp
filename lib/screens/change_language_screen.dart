import 'package:flutter/material.dart';

class ChangeLanguageScreen extends StatefulWidget {
  const ChangeLanguageScreen({super.key});

  @override
  State<ChangeLanguageScreen> createState() => _ChangeLanguageScreenState();
}

class _ChangeLanguageScreenState extends State<ChangeLanguageScreen> {
  String _selectedLanguage = 'English';

  final List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'ur', 'name': 'Urdu', 'nativeName': 'اردو'},
    {'code': 'pa', 'name': 'Punjabi', 'nativeName': 'پنجابی'},
    {'code': 'sd', 'name': 'Sindhi', 'nativeName': 'سنڌي'},
    {'code': 'ps', 'name': 'Pashto', 'nativeName': 'پښتو'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Language'),
        backgroundColor: const Color(0xFF660033),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final language = languages[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: RadioListTile<String>(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language['name']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    language['nativeName']!,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              value: language['name']!,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Language changed to ${language['name']}')),
                );
              },
              activeColor: const Color(0xFF660033),
            ),
          );
        },
      ),
    );
  }
}