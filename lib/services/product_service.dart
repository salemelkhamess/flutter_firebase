import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firebase/models/product.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProductService {
  final CollectionReference productsCollection =
      FirebaseFirestore.instance.collection('products');
  final CollectionReference productImagesCollection =
      FirebaseFirestore.instance.collection('product_images');

  final storageRef = FirebaseStorage.instance.ref(); // Create storage reference

  Future<void> addProduct(
      Product product, String id, XFile? image, List<XFile> images) async {
    if (image != null) {
      final imageUrl = await uploadImage(image);
      if (imageUrl != null) {
        product.imageUrl = imageUrl;
      }
    }
    await productsCollection.doc(id).set(product.toMap());

    // Récupérez l'ID du produit ajouté

    for (var image in images) {
      String imageUrl = await uploadImageToFirebaseStorage(
          image); // Utilisez votre logique pour télécharger l'image dans le stockage Firebase
      await productImagesCollection.add({
        'product_id': id,
        'image_url': imageUrl,
      });
    }
  }

  Future<List<Product>> getProducts() async {
    QuerySnapshot querySnapshot = await productsCollection.get();
    return querySnapshot.docs
        .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<Product?> getProductById(String id) async {
    try {
      DocumentSnapshot snapshot = await productsCollection.doc(id).get();
      if (snapshot.exists) {
        return Product.fromMap(snapshot.data() as Map<String, dynamic>);
      } else {
        return null; // Le produit n'existe pas
      }
    } catch (e) {
      print('Error getting product: $e');
      throw e; // Rejette l'erreur pour la traiter plus haut si nécessaire
    }
  }

  Future<void> updateProduct(Product product, XFile? image) async {
    try {
      // Vérifie la présence du document
      DocumentSnapshot snapshot =
          await productsCollection.doc(product.id).get();
      print(snapshot.get('id'));
      if (snapshot.exists) {
        // Effectue la mise à jour si le document existe
        if (image != null) {
          final imageUrl = await uploadImage(image);
          if (imageUrl != null) {
            product.imageUrl = imageUrl;
          }
        }
        await productsCollection.doc(product.id).update(product.toMap());
        print('Product updated successfully');
      } else {
        // Affiche un message indiquant que le document n'existe pas
        print('Error updating product: Document not found');
      }
    } catch (e) {
      print('Error updating product: $e');
      throw e; // Rejette l'erreur pour la traiter plus haut si nécessaire
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(id).delete();
      print('Product deleted successfully');
    } catch (e) {
      print('Error deleting product: $e');
      throw e; // Rejette l'erreur pour la traiter plus haut si nécessaire
    }
  }

  Future<String?> uploadImage(XFile image) async {
    try {
      final imageRef =
          storageRef.child('products/${image.path.split('/').last}');
      final uploadTask = imageRef.putFile(File(image.path));
      final snapshot = await uploadTask.whenComplete(() => null);
      print('Image uploaded .');
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null; // Handle upload error appropriately
    }
  }

  Future<String> uploadImageToFirebaseStorage(XFile image) async {
    try {
      // Référence au stockage Firebase Storage
      final FirebaseStorage storage = FirebaseStorage.instance;
      // Référence au dossier où vous souhaitez stocker les images
      Reference storageRef = storage
          .ref()
          .child('product_images')
          .child(image.path.split('/').last);

      // Téléchargez l'image dans le stockage Firebase Storage
      UploadTask uploadTask = storageRef.putFile(File(image.path));

      // Récupérez l'URL de téléchargement une fois le téléchargement terminé
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Retournez l'URL de téléchargement de l'image
      return downloadUrl;
    } catch (e) {
      print('Erreur lors du téléchargement de l\'image: $e');
      throw e;
    }
  }
}
