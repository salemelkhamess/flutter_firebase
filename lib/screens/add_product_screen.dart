// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_firebase/models/product.dart';
import 'package:flutter_firebase/services/product_service.dart';
import 'package:flutter_firebase/widgets/custom_button.dart';
import 'package:flutter_firebase/widgets/cutom_textfield.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linear_progress_bar/linear_progress_bar.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:random_string/random_string.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();

  final _priceController = TextEditingController();

  final _qtyController = TextEditingController();

  final _productService = ProductService();

  File? _selectedImage;
  final storageRef = FirebaseStorage.instance.ref();

  bool _isLoading =
      false; // Variable d'état pour contrôler l'affichage de l'indicateur de progression

  final ImagePicker imagePicker = ImagePicker();
  List<XFile>? imageFileList = [];

  void selectImages() async {
    final List<XFile>? selectedImages = await imagePicker.pickMultiImage();
    if (selectedImages!.isNotEmpty) {
      imageFileList!.addAll(selectedImages);
    }
    print("Image List Length:" + imageFileList!.length.toString());
    setState(() {});
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    _nameController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Product'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(child: Text(' Add Product ')),
              SizedBox(
                height: 20,
              ),
              CustomTextFormField(
                controller: _nameController,
                labelText: 'Product name',
              ),
              SizedBox(
                height: 20,
              ),
              CustomTextFormField(
                controller: _priceController,
                labelText: 'Product price',
                keyboardType: TextInputType.number,
              ),
              SizedBox(
                height: 20,
              ),
              CustomTextFormField(
                controller: _qtyController,
                labelText: 'Product qty',
                keyboardType: TextInputType.number,
              ),
              SizedBox(
                height: 20,
              ),
              _selectedImage != null
                  ? Image.file(
                      _selectedImage!,
                      width: MediaQuery.sizeOf(context).width,
                      height: 150,
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
                    print(image.path);
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
              GridView.builder(
                shrinkWrap: true, // Ajoutez cette ligne
                physics: NeverScrollableScrollPhysics(), // Ajoutez cette ligne
                itemCount: imageFileList!.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing:
                      8.0, // Espacement vertical entre les éléments
                  crossAxisSpacing:
                      8.0, // Espacement horizontal entre les éléments
                ),
                itemBuilder: (BuildContext context, int index) {
                  return Image.file(
                    File(imageFileList![index].path),
                    fit: BoxFit.cover,
                  );
                },
              ),
              SizedBox(
                height: 20,
              ),
              InkWell(
                onTap: () {
                  selectImages();
                },
                child: Container(
                  padding: EdgeInsets.all(10),
                  width: MediaQuery.sizeOf(context).width,
                  decoration: BoxDecoration(color: Colors.blue),
                  child: Center(
                      child: Text(
                    'Chose images',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  )),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              CustomButton(
                text: 'Add',
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  String ID = randomAlphaNumeric(10);
                  await _productService.addProduct(
                      Product(
                          id: ID,
                          name: _nameController.text.trim(),
                          price: double.parse(_priceController.text),
                          qty: int.parse(_qtyController.text),
                          imageUrl: _selectedImage!.path),
                      ID,
                      XFile(_selectedImage!.path),
                      imageFileList!);
                  Navigator.pop(context);
                },
              ),
              SizedBox(
                height: 20,
              ),
              _isLoading
                  ? Container(
                      width: MediaQuery.sizeOf(context).width,
                      height: 50,
                      child: LoadingIndicator(
                          indicatorType: Indicator.lineScalePulseOutRapid,
                          colors: const [Colors.blue],
                          strokeWidth: 1,
                          backgroundColor: Colors.orange,
                          pathBackgroundColor: Colors.white),
                    )
                  : Container()
            ],
          ),
        ),
      ),
    );
  }
}
