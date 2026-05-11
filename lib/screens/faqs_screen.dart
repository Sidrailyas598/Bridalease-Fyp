import 'package:flutter/material.dart';

class FAQsScreen extends StatefulWidget {
  const FAQsScreen({super.key});

  @override
  State<FAQsScreen> createState() => _FAQsScreenState();
}

class _FAQsScreenState extends State<FAQsScreen> {
  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'How do I rent a dress?',
      answer: 'Browse our catalog, select your preferred dress, choose rental dates, and proceed to checkout. You\'ll need to create an account first.',
    ),
    FAQItem(
      question: 'What is the rental period?',
      answer: 'Our standard rental period is 3-5 days. You can choose your preferred dates during checkout.',
    ),
    FAQItem(
      question: 'Can I purchase a dress instead of renting?',
      answer: 'Yes! Many of our dresses are available for both rental and purchase. Check the dress details for pricing options.',
    ),
    FAQItem(
      question: 'How does the virtual try-on work?',
      answer: 'Create your avatar with your body measurements in the profile section, then use the virtual try-on feature to see how dresses look on you.',
    ),
    FAQItem(
      question: 'What if the dress doesn\'t fit?',
      answer: 'We provide detailed size charts for each dress. If the dress doesn\'t fit, contact us within 2 hours of delivery for an exchange.',
    ),
    FAQItem(
      question: 'How do I become a vendor?',
      answer: 'Sign up as a vendor, complete your profile, and start uploading your dress collection. All dresses go through an approval process.',
    ),
    FAQItem(
      question: 'What are the payment methods?',
      answer: 'We accept credit/debit cards, bank transfers, and popular mobile payment methods.',
    ),
    FAQItem(
      question: 'How do I cancel my order?',
      answer: 'You can cancel your order within 24 hours of placement from your order history page.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
        backgroundColor: const Color(0xFF660033),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          return _buildFAQItem(_faqs[index]);
        },
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              faq.answer,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}