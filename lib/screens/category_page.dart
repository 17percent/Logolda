import 'package:flutter/material.dart';
import 'package:logolda/util/colors.dart';
import 'package:logolda/util/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final TextEditingController _categoryController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;

  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    if (user != null) {
      QuerySnapshot snapshot = await _firestore
          .collection('Categories')
          .where('userId', isEqualTo: user!.uid)
          .get();

      setState(() {
        _categories =
            snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
    }
  }

  void _saveCategory() async {
    String categoryName = _categoryController.text.trim();
    if (categoryName.isNotEmpty) {
      if (user != null) {
        await _firestore.collection('Categories').add({
          'name': categoryName,
          'userId': user!.uid,
          'createdAt': Timestamp.now(),
        });
        _categoryController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sikeres mentés!')),
        );
        _fetchCategories(); // Update the state and rebuild the widget
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A mező nem lehet üres!')),
      );
    }
  }

  void _deleteCategory(String categoryName) async {
    if (user != null) {
      QuerySnapshot snapshot = await _firestore
          .collection('Categories')
          .where('name', isEqualTo: categoryName)
          .where('userId', isEqualTo: user!.uid)
          .get();

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        await _firestore.collection('Categories').doc(doc.id).delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sikeres törlés!')),
      );
      _fetchCategories(); // Update the state and rebuild the widget
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
    }
  }

  Widget _buildCategoryList(List<String> categories) {
    if (categories.isEmpty) {
      return const Column(
        children: [
          Text(
            'Nincs megjeleníthető adat!',
            style: TextStyle(color: AppColors.antiFlashWhite, fontSize: 18),
          ),
          // Add tutorial here
        ],
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      // padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: categories.map((category) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: AppStyles.customBoxDecoration(AppColors.coolGrey, 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                      color: AppColors.antiFlashWhite, fontSize: 18),
                ),
                IconButton(
                    icon: const Icon(Icons.delete_forever_rounded,
                        color: AppColors.antiFlashWhite, size: 40),
                    onPressed: () async {
                      bool? confirmDelete = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Törlés megerősítése',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            content:
                                const Text('Biztosan törlöd ezt a kategóriát?'),
                            actions: <Widget>[
                              TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                  child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration:
                                  AppStyles.customBoxDecoration(AppColors.coolGrey, 18),
                              child: const Icon(
                                  Icons.arrow_circle_left_outlined,
                                  color: AppColors.antiFlashWhite,
                                  size: 40),
                            )),
                              TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                  child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration:
                                  AppStyles.customBoxDecoration(AppColors.pantoneRed, 18),
                              child: const Icon(
                                  Icons.delete_forever_rounded,
                                  color: AppColors.antiFlashWhite,
                                  size: 40),
                            )),
                            ],
                          );
                        },
                      );

                      if (confirmDelete == true) {
                        _deleteCategory(category);
                      }
                    }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceCadet,
      appBar: AppBar(
        backgroundColor: AppColors.coolGrey,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_circle_left_outlined,
              size: 60, color: AppColors.antiFlashWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 48.0),
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.category_rounded,
                      size: 100,
                      color: AppColors.antiFlashWhite.withOpacity(0.2)),
                  const Text('Kategóriák',
                      style: TextStyle(
                          fontSize: 28, color: AppColors.antiFlashWhite)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildCategoryList(_categories),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Új kategória felvétele'),
                _buildTextField(_categoryController, 'Új kategória címe'),
                const SizedBox(height: 30),
                Center(
                  child: Container(
                    decoration: AppStyles.customBoxDecoration(AppColors.coolGrey, 18),
                    child: ElevatedButton(
                      onPressed: _saveCategory,
                      style: AppStyles.customButtonStyle(AppColors.springBud),
                      child: const Icon(Icons.save_rounded,
                          color: AppColors.spaceCadet, size: 50),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(text,
          style:
              const TextStyle(color: AppColors.antiFlashWhite, fontSize: 20)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(0.8),
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.coolGrey),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.coolGrey, width: 3.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide:
                const BorderSide(color: AppColors.springBud, width: 3.0),
          ),
          fillColor: AppColors.antiFlashWhite,
          filled: true,
        ),
      ),
    );
  }
}
