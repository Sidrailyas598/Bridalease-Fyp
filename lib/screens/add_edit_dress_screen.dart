// import 'package:flutter/material.dart';
// import '../supabase.dart';

// class AddEditDressScreen extends StatefulWidget {
//   final Map? dress;
//   AddEditDressScreen({this.dress});

//   @override
//   _AddEditDressScreenState createState() => _AddEditDressScreenState();
// }

// class _AddEditDressScreenState extends State<AddEditDressScreen> {
//   final nameController = TextEditingController();
//   final priceController = TextEditingController();
//   bool loading = false;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.dress != null) {
//       nameController.text = widget.dress!['name'] ?? '';
//       priceController.text = widget.dress!['price'].toString();
//     }
//   }

//   Future<void> saveDress() async {
//     setState(() => loading = true);
//     if (widget.dress == null) {
//       // Add
//       await supabase.from('dresses').insert({
//         'name': nameController.text,
//         'price': double.tryParse(priceController.text) ?? 0,
//       }).execute();
//     } else {
//       // Edit
//       await supabase.from('dresses').update({
//         'name': nameController.text,
//         'price': double.tryParse(priceController.text) ?? 0,
//       }).eq('id', widget.dress!['id']).execute();
//     }
//     setState(() => loading = false);
//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.dress == null ? 'Add Dress' : 'Edit Dress'),
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(
//               controller: nameController,
//               decoration: InputDecoration(
//                   labelText: 'Dress Name',
//                   border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12))),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: priceController,
//               keyboardType: TextInputType.number,
//               decoration: InputDecoration(
//                   labelText: 'Price',
//                   border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12))),
//             ),
//             SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: loading ? null : saveDress,
//               child: loading
//                   ? CircularProgressIndicator(color: Colors.white)
//                   : Text('Save', style: TextStyle(fontSize: 18)),
//               style: ElevatedButton.styleFrom(
//                   minimumSize: Size(double.infinity, 50)),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
