import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleTaskScreen extends StatefulWidget {
  const ScheduleTaskScreen({super.key});

  @override
  State<ScheduleTaskScreen> createState() => _ScheduleTaskScreenState();
}

class _ScheduleTaskScreenState extends State<ScheduleTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedSalesman;
  String? _selectedTaskType;
  String? _selectedPriority;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Mock data - Replace with actual API calls
  final List<Map<String, String>> _salesmen = [
    {'id': '1', 'name': 'John Doe', 'phone': '9876543210'},
    {'id': '2', 'name': 'Jane Smith', 'phone': '9876543211'},
    {'id': '3', 'name': 'Mike Johnson', 'phone': '9876543212'},
  ];

  final List<String> _taskTypes = [
    'Client Visit',
    'Follow-up Call',
    'Product Demo',
    'Meeting',
    'Site Survey',
    'Quotation Submission',
    'Other',
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submitTask() {
    if (_formKey.currentState!.validate()) {
      if (_selectedSalesman == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a salesman'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a date'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a time'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // TODO: Implement API call to save task
      final taskData = {
        'salesman_id': _selectedSalesman,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'task_type': _selectedTaskType,
        'priority': _selectedPriority,
        'date': _selectedDate!.toIso8601String(),
        'time': '${_selectedTime!.hour}:${_selectedTime!.minute}',
        'location': _locationController.text,
      };

      print('Task Data: $taskData');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _formKey.currentState!.reset();
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      setState(() {
        _selectedSalesman = null;
        _selectedTaskType = null;
        _selectedPriority = null;
        _selectedDate = null;
        _selectedTime = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.task_outlined, size: 24),
            SizedBox(width: 10),
            Text('Schedule Task'),
          ],
        ),
        backgroundColor: const Color(0xFFD7BE69),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card

              // Select Salesman
              const Text(
                'Select Salesman *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSalesman,
                decoration: InputDecoration(
                  hintText: 'Choose a salesman',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _salesmen.map((salesman) {
                  return DropdownMenuItem<String>(
                    value: salesman['id'],
                    child: Text('${salesman['name']} (${salesman['phone']})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSalesman = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Task Title
              const Text(
                'Task Title *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter task title',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Task Type
              const Text(
                'Task Type *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedTaskType,
                decoration: InputDecoration(
                  hintText: 'Select task type',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _taskTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTaskType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select task type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Priority
              const Text(
                'Priority *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: InputDecoration(
                  hintText: 'Select priority',
                  prefixIcon: const Icon(Icons.flag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _priorities.map((priority) {
                  return DropdownMenuItem<String>(
                    value: priority,
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: _getPriorityColor(priority),
                        ),
                        const SizedBox(width: 8),
                        Text(priority),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select priority';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Date and Time Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedDate == null
                                      ? 'Select date'
                                      : DateFormat(
                                          'dd MMM yyyy',
                                        ).format(_selectedDate!),
                                  style: TextStyle(
                                    color: _selectedDate == null
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Time *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(context),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedTime == null
                                      ? 'Select time'
                                      : _selectedTime!.format(context),
                                  style: TextStyle(
                                    color: _selectedTime == null
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Location
              const Text(
                'Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Enter location (optional)',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Description
              const Text(
                'Description *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter task description',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter task description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD7BE69),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Create Task',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Urgent':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
