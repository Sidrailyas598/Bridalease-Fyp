// import '../supabase.dart';

// class WishlistService {
//   static Future<List> fetchWishlist(String userId) async {
//     final response = await supabase
//         .from('wishlist')
//         .select()
//         .eq('user_id', userId)
//         .execute();
//     return response.data ?? [];
//   }

//   static Future<void> addToWishlist(String userId, int dressId) async {
//     await supabase.from('wishlist').insert({
//       'user_id': userId,
//       'dress_id': dressId,
//     }).execute();
//   }

//   static Future<void> removeFromWishlist(int wishlistId) async {
//     await supabase.from('wishlist').delete().eq('id', wishlistId).execute();
//   }
// }
