// import 'package:flutter/material.dart';
// import '../services/rentals_service.dart';
// import '../supabase.dart';

// class RentalsScreen extends StatefulWidget {
//   @override
//   _RentalsScreenState createState() => _RentalsScreenState();
// }

// class _RentalsScreenState extends State<RentalsScreen> {
//   List rentals = [];
//   bool loading = true;

//   @override
//   void initState() {
//     super.initState();
//     fetchRentals();
//   }

//   Future<void> fetchRentals() async {
//     final userId = supabase.auth.currentUser!.id;
//     rentals = await RentalsService.fetchUserRentals(userId);
//     setState(() => loading = false);
//   }

//   Future<void> returnRental(int rentalId) async {
//     await RentalsService.updateRental(rentalId, 'returned');
//     fetchRentals();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('My Rentals')),
//       body: loading
//           ? Center(child: CircularProgressIndicator(color: Colors.pink[300]))
//           : ListView.builder(
//               padding: EdgeInsets.all(16),
//               itemCount: rentals.length,
//               itemBuilder: (context, index) {
//                 final rental = rentals[index];
//                 return Card(
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16)),
//                   elevation: 4,
//                   margin: EdgeInsets.symmetric(vertical: 8),
//                   child: ListTile(
//                     title: Text(rental['dress_name'] ?? '',
//                         style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.pink[800])),
//                     subtitle: Text('Status: ${rental['status']}',
//                         style: TextStyle(color: Colors.pink[600])),
//                     trailing: rental['status'] == 'booked'
//                         ? TextButton(
//                             onPressed: () => returnRental(rental['id']),
//                             child: Text('Return',
//                                 style: TextStyle(color: Colors.pink[400])),
//                           )
//                         : null,
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }
