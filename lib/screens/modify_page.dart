import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logolda/util/colors.dart';

class ModifyPage extends StatefulWidget {
  final String taskId;

  const ModifyPage({super.key, required this.taskId});

  @override
  State<ModifyPage> createState() => _ModifyPageState();
}

class _ModifyPageState extends State<ModifyPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  var _categories = [];
  var _difficulties = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _selectedCategory;
  String? _selectedDifficulty;
  bool _isLoadingCategories = true;
  bool _isLoadingDifficulties = true;
  DateTime? _startDate;
  String? _startTime;
  DateTime? _dueDate;
  String? _dueTime;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchDifficulties();
    _loadTaskData();
  }

  Future<void> _loadTaskData() async {
    DocumentSnapshot task = await FirebaseFirestore.instance
        .collection('Tasks')
        .doc(widget.taskId)
        .get();
    if (task.exists) {
      setState(() {
        _titleController.text = task['title'];
        _descriptionController.text = task['description'];
        _locationController.text = task['location'];
        _startDate = DateTime.parse(task['startDate']);
        _startTime = task['startTime'];
        _dueDate = DateTime.parse(task['dueDate']);
        _dueTime = task['dueTime'];
        _selectedCategory = task['category'];
        _selectedDifficulty = task['difficulty'];
      });
    }
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      if (_titleController.text.isEmpty ||
          _descriptionController.text.isEmpty ||
          _locationController.text.isEmpty ||
          _selectedCategory == null ||
          _selectedDifficulty == null) {
        _showSnackBar('Minden mező kitöltése kötelező!');
        return;
      }

      if (_startDate!.isAfter(_dueDate!)) {
        _showSnackBar("Az esemény nem kezdőthet később a határidőnél!");
        return;
      }

      try {
        await _firestore.collection('Tasks').doc(widget.taskId).update({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'location': _locationController.text.trim(),
          'startDate': _startDate!.toIso8601String().substring(0, 10),
          'startTime': _startTime,
          'dueDate': _dueDate!.toIso8601String().substring(0, 10),
          'dueTime': _dueTime,
          'category': _selectedCategory,
          'difficulty': _selectedDifficulty,
        });
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (Route<dynamic> route) => false);
        }
      } catch (e) {
        _showSnackBar('Error saving task: $e');
      }
    }
  }

  Future<void> _pickDate(BuildContext context, DateTime? initialDate,
      ValueChanged<DateTime> onDatePicked) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      onDatePicked(pickedDate);
    }
  }

  static String _formatTimeOfDay(TimeOfDay time) =>
      "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

  Future<void> _pickTime(BuildContext context, String? initialTime,
      ValueChanged<String> onTimePicked) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      onTimePicked(_formatTimeOfDay(pickedTime));
    }
  }

  Future<void> fetchCategories() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('Categories').get();
      setState(() {
        _categories =
            snapshot.docs.map((doc) => doc['name'] as String).toList();
        _isLoadingCategories = false; // Update loading state
      });
    } catch (e) {
      _showSnackBar('Error fetching categories: $e');
      setState(() {
        _isLoadingCategories = false; // Stop loading spinner even on error
      });
    }
  }

  Future<void> fetchDifficulties() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('Difficulties').get();
      setState(() {
        _difficulties =
            snapshot.docs.map((doc) => doc['name'] as String).toList();
        _isLoadingDifficulties = false; // Update loading state
      });
    } catch (e) {
      _showSnackBar('Error fetching difficulties: $e');
      setState(() {
        _isLoadingDifficulties = false; // Stop loading spinner even on error
      });
    }
  }

  Widget _buildDropDownForCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _isLoadingCategories
            ? const CircularProgressIndicator(color: AppColors.springBud)
            : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.antiFlashWhite,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.8),
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  hint: const Icon(
                    Icons.category_rounded,
                    color: AppColors.coolGrey,
                    size: 50,
                  ),
                  items: _categories
                      .map<DropdownMenuItem<String>>((dynamic category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  dropdownColor: AppColors.antiFlashWhite,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.coolGrey),
                  iconSize: 50,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: "Michroma"),
                ),
              ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropDownForDifficulties() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _isLoadingDifficulties
            ? const CircularProgressIndicator(color: AppColors.springBud)
            : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.antiFlashWhite,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.8),
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: DropdownButton<String>(
                  value: _selectedDifficulty,
                  hint: const Icon(
                    Icons.speed_rounded,
                    color: AppColors.coolGrey,
                    size: 50,
                  ),
                  items: _difficulties
                      .map<DropdownMenuItem<String>>((dynamic diff) {
                    return DropdownMenuItem<String>(
                      value: diff,
                      child: Text(diff),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDifficulty = newValue;
                    });
                  },
                  dropdownColor: AppColors.antiFlashWhite,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.coolGrey),
                  iconSize: 50,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: "Michroma"),
                ),
              ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDateTimePicker(
    BuildContext context,
    DateTime? date,
    String? time,
    ValueChanged<DateTime> onDatePicked,
    ValueChanged<String> onTimePicked,
  ) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                blurStyle: BlurStyle.normal,
                color: Colors.black.withOpacity(0.8),
                offset: const Offset(0, 5),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => _pickDate(context, date, onDatePicked),
            style: _buttonStyle(),
            child: const Icon(Icons.calendar_month_rounded,
                color: AppColors.coolGrey, size: 50),
          ),
        ),
        const SizedBox(width: 20),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                blurStyle: BlurStyle.normal,
                color: Colors.black.withOpacity(0.8),
                offset: const Offset(0, 5),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => _pickTime(context, time, onTimePicked),
            style: _buttonStyle(),
            child: const Icon(Icons.schedule_rounded,
                color: AppColors.coolGrey, size: 50),
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateTimeText(date?.toIso8601String().substring(0, 10)),
            _buildDateTimeText(time),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTimeText(String? text) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.antiFlashWhite, width: 2),
        ),
      ),
      child: Text(
        text ?? '',
        style: const TextStyle(color: AppColors.antiFlashWhite, fontSize: 16),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      backgroundColor: AppColors.antiFlashWhite,
    );
  }

  BoxDecoration customBoxDeoration(Color color, double radius) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: color,
      boxShadow: [
        BoxShadow(
          blurRadius: 10,
          blurStyle: BlurStyle.normal,
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(0, 5),
          spreadRadius: 0,
        )
      ],
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceCadet,
      appBar: AppBar(
        title: const Text('Módosítás',
            style: TextStyle(color: AppColors.antiFlashWhite, fontSize: 28)),
        centerTitle: true,
        backgroundColor: AppColors.coolGrey,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_circle_left_outlined,
              size: 60, color: AppColors.antiFlashWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Cím'),
              _buildTextField(_titleController, 'Esemény címe'),
              const SizedBox(height: 16),
              _buildLabel('Leírás'),
              _buildTextField(_descriptionController, 'Esemény leírása',
                  maxLines: 5),
              const SizedBox(height: 16),
              _buildLabel('Helyszín'),
              _buildTextField(_locationController, 'Esemény helyszíne'),
              const SizedBox(height: 16),
              _buildLabel('Kezdő időpont'),
              _buildDateTimePicker(
                context,
                _startDate,
                _startTime,
                (date) => setState(() => _startDate = date),
                (time) => setState(() => _startTime = time),
              ),
              const SizedBox(height: 16),
              _buildLabel('Záró időpont'),
              _buildDateTimePicker(
                context,
                _dueDate,
                _dueTime,
                (date) => setState(() => _dueDate = date),
                (time) => setState(() => _dueTime = time),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      _buildLabel("Kategória"),
                      _buildDropDownForCategories(),
                    ],
                  ),
                  Column(
                    children: [
                      _buildLabel("Nehézség"),
                      _buildDropDownForDifficulties(),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  decoration: customBoxDeoration(AppColors.springBud, 18),
                  child: IconButton(
                    icon: const Icon(Icons.save_rounded,
                        size: 50, color: AppColors.spaceCadet),
                    onPressed: _saveTask,
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(90, 80),
                    ),
                  ),
                ),
              ),
            ],
          ),
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
