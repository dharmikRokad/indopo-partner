import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/request_model.dart';
import '../../../data/repositories/request_repo.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  late Future<List<RequestModel>> _chatsFuture;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  void _loadChats() {
    setState(() {
      _chatsFuture = context.read<RequestRepository>().fetchRequests(RequestStatus.inProgress);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue3,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Active Chats',
          style: TextStyles.headingSemiBold.copyWith(fontSize: 20),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadChats();
        },
        child: FutureBuilder<List<RequestModel>>(
          future: _chatsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.blue1),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Failed to load chats', style: TextStyles.headingSemiBold),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadChats,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final chats = snapshot.data ?? [];
            if (chats.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No active chats',
                          style: TextStyles.headingSemiBold.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Accept a request to start a chat with the patient.',
                          style: TextStyles.labelRegular,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final req = chats[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      context.push(AppRoutes.chat.replaceAll(':id', req.id)).then((_) {
                        _loadChats(); // Reload when returning to capture status changes
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.blue2,
                            child: Text(
                              req.patientInitials,
                              style: TextStyles.headingBold.copyWith(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.patientName,
                                  style: TextStyles.headingSemiBold.copyWith(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to view conversation history',
                                  style: TextStyles.labelRegular.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.blue1,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
