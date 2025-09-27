import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quanlythucung/main.dart';

class AddEditEventScreen extends StatefulWidget {
  final int petId;
  const AddEditEventScreen({super.key, required this.petId});

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _isLoading = false;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày giờ cho sự kiện')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.from('pet_events').insert({
        'pet_id': widget.petId,
        'event_name': _eventNameController.text,
        'event_time': _selectedDateTime!.toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm sự kiện thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm sự kiện mới')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _eventNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên sự kiện (VD: Tiêm phòng dại)',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên sự kiện';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Thời gian diễn ra:'),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _pickDateTime,
                    child: Text(
                      _selectedDateTime == null
                          ? 'Chọn ngày giờ'
                          : DateFormat(
                              'dd/MM/yyyy, hh:mm a',
                            ).format(_selectedDateTime!),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _submitEvent,
                    child: const Text('Lưu sự kiện'),
                  ),
                ],
              ),
            ),
    );
  }
}
