// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, override_on_non_overriding_member, sort_child_properties_last, prefer_final_fields, unused_field

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_firebase/models/product.dart';
import 'package:flutter_firebase/screens/add_product_screen.dart';
import 'package:flutter_firebase/services/product_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestore = FirebaseFirestore.instance.collection('products');
  // Assuming 'products' collection
  late Stream<QuerySnapshot<Map<String, dynamic>>> _productStream;
  // Stream for product updates
  File? _selectedImage;
  final storageRef = FirebaseStorage.instance.ref();

  bool _isLoading =
      false; // Variable d'état pour contrôler l'affichage de l'indicateur de progression
  final _productService = ProductService();

  @override
  void initState() {
    super.initState();
    // Initialize _productStream within initState
    _productStream =
        _firestore.snapshots(); // Listen for changes in the collection
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product List'),
        backgroundColor: Colors.grey[200],
        actions: [
          InkWell(
            onTap: () async {
              try {
                await FirebaseAuth.instance.signOut();
              } catch (e) {
                print("Erreur lors de la déconnexion : $e");
                // Affichez un message d'erreur à l'utilisateur ou effectuez une autre action en cas d'échec de la déconnexion.
              }
            },
            child: Container(
              margin: EdgeInsets.only(right: 5),
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10), color: Colors.amber),
              child: Text('Logout'),
            ),
          )
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 220),
            child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddProductScreen()));
                },
                child: Text('Add Product')),
          ),
          SizedBox(
            height: 20,
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _productStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              // if (snapshot.data!.docs.isEmpty) {
              //   return Column(
              //     children: [
              //       Center(
              //         child: Icon(
              //           Icons.info,
              //           size: 100,
              //           color: Colors.green,
              //         ),
              //       ),
              //       SizedBox(
              //         height: 20,
              //       ),
              //       Center(
              //         child: Text(
              //           'No data fount ! Product is empty',
              //           style: TextStyle(
              //               color: Colors.orange,
              //               fontSize: 22,
              //               fontWeight: FontWeight.bold),
              //         ),
              //       ),
              //     ],
              //   );
              // }

              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return Center(child: CircularProgressIndicator());
                default:
                  return Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final product =
                            Product.fromMap(snapshot.data!.docs[index].data());
                        return _buildProductListTile(product);
                      },
                    ),
                  );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductListTile(Product product) {
    return ListTile(
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              _showEditProductDialog(product);
            },
            child: Icon(
              Icons.edit,
              color: Colors.green,
            ),
          ),
          SizedBox(
            height: 5,
          ),
          GestureDetector(
            onTap: () {
              Alert(
                context: context,
                type: AlertType.warning,
                title: "DELETING",
                desc: "Are you sur you want delete this product ? ",
                buttons: [
                  DialogButton(
                    child: Text(
                      "Yes ! delete.",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    onPressed: () {
                      _firestore.doc(product.id).delete();
                      Navigator.pop(context);
                    },
                    color: Color.fromRGBO(179, 0, 0, 1),
                  ),
                  DialogButton(
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    onPressed: () => Navigator.pop(context),
                    gradient: LinearGradient(colors: [
                      Color.fromRGBO(116, 116, 191, 1.0),
                      Color.fromRGBO(52, 138, 199, 1.0)
                    ]),
                  )
                ],
              ).show();
            },
            child: Icon(
              Icons.delete,
              color: Colors.red,
            ),
          )
        ],
      ),
      leading: SizedBox(
        width: 60.0,
        child: product.imageUrl != null
            ? Image.network('${product.imageUrl}')
            : Icon(Icons.check),
      ),
      title: Text(product.name,
          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
      subtitle: Row(
        children: [
          Text('${product.price.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 14.0)),
          SizedBox(width: 10.0),
          Text('${product.qty}',
              style: TextStyle(fontSize: 14.0, color: Colors.grey)),
          SizedBox(
            width: 20,
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(Product product) {
    final _nameController = TextEditingController(text: product.name);
    final _priceController =
        TextEditingController(text: product.price.toStringAsFixed(2));
    final _qtyController = TextEditingController(text: product.qty.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _qtyController,
                  decoration: InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(
                  height: 20,
                ),
                _selectedImage != null
                    ? Image.file(
                        _selectedImage!,
                        width: 400,
                        height: 100,
                      )
                    : Text('No image selected yet'),
                SizedBox(
                  height: 20,
                ),
                InkWell(
                  onTap: () async {
                    final image = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);
                    // Vérifie si une image a été sélectionnée
                    if (image != null) {
                      setState(() {
                        _selectedImage = File(image.path);
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(10),
                    width: MediaQuery.sizeOf(context).width,
                    decoration: BoxDecoration(color: Colors.blue),
                    child: Center(
                        child: Text(
                      'Chose image',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    )),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final updatedProduct = Product(
                    id: product.id,
                    name: _nameController.text,
                    price: double.parse(_priceController.text),
                    qty: int.parse(_qtyController.text),
                    imageUrl: _selectedImage!.path);
                // _firestore.doc(product.id).update(updatedProduct.toMap());

                _productService.updateProduct(
                    updatedProduct, XFile(_selectedImage!.path));

                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
