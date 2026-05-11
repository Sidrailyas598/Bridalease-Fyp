// import 'package:flutter/material.dart';
// import '../services/wishlist_service.dart';
// import '../supabase.dart';

// class WishlistScreen extends StatefulWidget {
//   @override
//   _WishlistScreenState createState() => _WishlistScreenState();
// }

// class _WishlistScreenState extends State<WishlistScreen> {
//   List wishlist = [];
//   bool loading = true;

//   @override
//   void initState() {
//     super.initState();
//     fetchWishlist();
//   }

//   Future<void> fetchWishlist() async {
//     final userId = supabase.auth.currentUser!.id;
//     wishlist = await WishlistService.fetchWishlist(userId);
//     setState(() => loading = false);
//   }

//   Future<void> removeItem(int id) async {
//     await WishlistService.removeFromWishlist(id);
//     fetchWishlist();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('My Wishlist')),
//       body: loading
//           ? Center(child: CircularProgressIndicator(color: Colors.pink[300]))
//           : ListView.builder(
//               padding: EdgeInsets.all(16),
//               itemCount: wishlist.length,
//               itemBuilder: (context, index) {
//                 final item = wishlist[index];
//                 return Card(
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16)),
//                   elevation: 4,
//                   margin: EdgeInsets.symmetric(vertical: 8),
//                   child: ListTile(
//                     title: Text(item['dress_name'] ?? '',
//                         style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.pink[800])),
//                     trailing: IconButton(
//                       icon: Icon(Icons.delete, color: Colors.pink[400]),
//                       onPressed: () => removeItem(item['id']),
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }

