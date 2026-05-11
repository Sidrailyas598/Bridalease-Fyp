// import '../supabase.dart';

// class RentalsService {
//   static Future<List> fetchUserRentals(String userId) async {
//     final response = await supabase
//         .from('rentals')
//         .select()
//         .eq('user_id', userId)
//         .execute();
//     return response.data ?? [];
//   }

//   static Future<void> createRental(String userId, int dressId) async {
//     await supabase.from('rentals').insert({
//       'user_id': userId,
//       'dress_id': dressId,
//       'status': 'booked',
//     }).execute();
//   }

//   static Future<void> updateRental(int rentalId, String status) async {
//     await supabase.from('rentals').update({'status': status}).eq('id', rentalId).execute();
//   }
// }
