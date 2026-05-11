import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdatePasswordScreen extends StatelessWidget {
  final password = TextEditingController();

  UpdatePasswordScreen({super.key, required String accessToken});

  void updatePassword(BuildContext context) async {
    final res = await Supabase.instance.client.auth.updateUser(
      UserAttributes(password: password.text.trim()),
    );

    if (res.user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password updated successfully!")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Update Password")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: password, decoration: InputDecoration(labelText: "New Password")),
            ElevatedButton(
              onPressed: () => updatePassword(context),
              child: Text("Update Password"),
            )
          ],
        ),
      ),
    );
  }
}
