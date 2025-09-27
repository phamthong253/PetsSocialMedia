import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quanlythucung/main.dart';

class PetDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pet;
  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  late final Stream<List<Map<String, dynamic>>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _eventsStream = supabase
        .from('pet_events')
        .stream(primaryKey: ['id'])
        .eq('pet_id', widget.pet['id'])
        .order('event_time', ascending: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pet['name'] ?? 'Chi tiết thú cưng')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.pet['image_url'] != null)
              Image.network(
                widget.pet['image_url'],
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.pet['name'] ?? 'Chưa có tên',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Giới tính:', widget.pet['gender']),
                  _buildDetailRow(
                    'Cân nặng:',
                    '${widget.pet['weight_kg'] ?? 'N/A'} kg',
                  ),
                  _buildDetailRow('Giới thiệu:', widget.pet['bio']),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Lịch hẹn sắp tới',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _eventsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('Chưa có lịch hẹn nào.'),
                        );
                      }
                      final events = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          final eventTime = DateTime.parse(event['event_time']);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: Text(event['event_name']),
                              subtitle: Text(
                                DateFormat(
                                  'dd/MM/yyyy, hh:mm a',
                                ).format(eventTime),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/add_pet_event',
            arguments: widget.pet['id'],
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm sự kiện'),
      ),
    );
  }

  Widget _buildDetailRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value ?? 'Chưa cập nhật')),
        ],
      ),
    );
  }
}
