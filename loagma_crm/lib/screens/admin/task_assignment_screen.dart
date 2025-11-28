import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../models/salesman_model.dart';
import '../../services/task_assignment_service.dart';

class TaskAssignmentScreen extends StatefulWidget {
  const TaskAssignmentScreen({super.key});

  @override
  State<TaskAssignmentScreen> createState() => _TaskAssignmentScreenState();
}

class _TaskAssignmentScreenState extends State<TaskAssignmentScreen> {
  bool isLoading = true;
  bool isAssigning = false;
  List<Salesman> salesmen = [];
  Salesman? selectedSalesman;
  final TextEditingController _pinCodeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<String> localAssignedPinCodes = [];

  @override
  void initState() {
    super.initState();
    _loadSalesmen();
  }

  @override
  void dispose() {
    _pinCodeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSalesmen() async {
    setState(() => isLoading = true);
    try {
      final fetchedSalesmen = await TaskAssignmentService.fetchSalesmen();
      setState(() {
        salesmen = fetchedSalesmen;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Fluttertoast.showToast(msg: 'Error loading salesmen: $e');
    }
  }

  Future<void> _assignPinCode() async {
    if (selectedSalesman == null) {
      Fluttertoast.showToast(msg: 'Please select a salesman');
      return;
    }

    final pinCode = _pinCodeController.text.trim();
    if (pinCode.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter a pin code');
      return;
    }

    if (pinCode.length != 6 || int.tryParse(pinCode) == null) {
      Fluttertoast.showToast(msg: 'Please enter a valid 6-digit pin code');
      return;
    }

    if (localAssignedPinCodes.contains(pinCode)) {
      Fluttertoast.showToast(msg: 'Pin code already assigned to this salesman');
      return;
    }

    setState(() => isAssigning = true);

    try {
      final result = await TaskAssignmentService.assignPinCodeToSalesman(
        salesmanId: selectedSalesman!.id,
        salesmanName: selectedSalesman!.name,
        pinCode: pinCode,
      );

      if (result['success'] == true) {
        setState(() {
          localAssignedPinCodes.add(pinCode);
          _pinCodeController.clear();
        });

        // Show success dialog
        if (mounted) {
          _showSuccessDialog(pinCode);
        }

        Fluttertoast.showToast(
          msg: result['message'] ?? 'Pin code assigned successfully',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => isAssigning = false);
    }
  }

  void _showSuccessDialog(String pinCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pin code $pinCode has been successfully assigned to:',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(215, 190, 105, 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD7BE69)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFD7BE69),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedSalesman!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          selectedSalesman!.contactNumber,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFD7BE69))),
          ),
        ],
      ),
    );
  }

  void _removePinCode(String pinCode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Pin Code'),
        content: Text(
          'Remove pin code $pinCode from ${selectedSalesman?.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && selectedSalesman != null) {
      try {
        await TaskAssignmentService.removePinCodeAssignment(
          salesmanId: selectedSalesman!.id,
          pinCode: pinCode,
        );

        setState(() {
          localAssignedPinCodes.remove(pinCode);
        });

        Fluttertoast.showToast(
          msg: 'Pin code removed successfully',
          backgroundColor: Colors.orange,
        );
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error removing pin code: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Assignment'),
        backgroundColor: const Color(0xFFD7BE69),
        automaticallyImplyLeading: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD7BE69)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Assign Pin-Code Areas to Salesmen',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a salesman and assign pin codes for area allocation',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Salesman Dropdown
                  const Text(
                    'Select Salesman',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD7BE69)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Salesman>(
                        isExpanded: true,
                        value: selectedSalesman,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Choose a salesman'),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        borderRadius: BorderRadius.circular(12),
                        items: salesmen.map((salesman) {
                          return DropdownMenuItem<Salesman>(
                            value: salesman,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFFD7BE69),
                                  child: Text(
                                    salesman.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        salesman.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        salesman.contactNumber,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (Salesman? value) {
                          setState(() {
                            selectedSalesman = value;
                            localAssignedPinCodes = value != null
                                ? List.from(value.assignedPinCodes)
                                : [];
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pin Code Input
                  const Text(
                    'Enter Pin Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pinCodeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            hintText: 'Enter 6-digit pin code',
                            prefixIcon: const Icon(
                              Icons.location_on,
                              color: Color(0xFFD7BE69),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFD7BE69),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFD7BE69),
                                width: 2,
                              ),
                            ),
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isAssigning ? null : _assignPinCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD7BE69),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isAssigning
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Assign'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Assigned Pin Codes List
                  if (selectedSalesman != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Assigned Pin Codes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(215, 190, 105, 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${localAssignedPinCodes.length} areas',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD7BE69),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    localAssignedPinCodes.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.location_off,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No pin codes assigned yet',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: localAssignedPinCodes.length,
                            itemBuilder: (context, index) {
                              final pinCode = localAssignedPinCodes[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: Color.fromRGBO(215, 190, 105, 0.3),
                                  ),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(
                                        215,
                                        190,
                                        105,
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Color(0xFFD7BE69),
                                    ),
                                  ),
                                  title: Text(
                                    'Pin Code: $pinCode',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Assigned to ${selectedSalesman!.name}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removePinCode(pinCode),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ],
              ),
            ),
    );
  }
}
