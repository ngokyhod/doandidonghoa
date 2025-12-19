
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_item_model.dart';
import 'product_model.dart';

class CartService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _getCartCollection() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in. Cannot access cart.");
    }
    return _firestore.collection('users').doc(user.uid).collection('cart');
  }

  Stream<List<CartItem>> getCartItems() {
    return _getCartCollection().snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CartItem.fromFirestore(doc)).toList();
    });
  }

  // Sửa quantity thành double
  Future<void> addProductToCart(Product product, double quantity, Map<String, String> selectedVariants) async {
    final cartRef = _getCartCollection().doc(product.id);
    final doc = await cartRef.get();

    if (doc.exists) {
      await cartRef.update({
        'quantity': FieldValue.increment(quantity),
      });
    } else {
      final newItem = CartItem(
        productId: product.id,
        title: product.title,
        imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
        price: product.price,
        quantity: quantity,
        unit: product.unit,
        selectedVariants: selectedVariants,
      );
      await cartRef.set(newItem.toMap());
    }
  }

  // Sửa newQuantity thành double
  Future<void> updateItemQuantity(String productId, double newQuantity) async {
    if (newQuantity <= 0) {
      await removeItemFromCart(productId);
    } else {
      await _getCartCollection().doc(productId).update({'quantity': newQuantity});
    }
  }

  Future<void> removeItemFromCart(String productId) async {
    await _getCartCollection().doc(productId).delete();
  }

  Future<void> clearCart() async {
    final cartSnapshot = await _getCartCollection().get();
    WriteBatch batch = _firestore.batch();
    for (DocumentSnapshot doc in cartSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
