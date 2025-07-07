import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart'; // We need this for NeumorphicContainer
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late Future<List<Map<String, dynamic>>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _conversationsFuture = _fetchConversations();
  }

  Future<List<Map<String, dynamic>>> _fetchConversations() async {
    final response = await Supabase.instance.client.rpc(
      'get_sorted_conversations',
    );
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _refreshConversations() async {
    setState(() {
      _conversationsFuture = _fetchConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('محادثاتي')),
      body: RefreshIndicator(
        onRefresh: _refreshConversations,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _conversationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const Center(
                child: Text('لا توجد لديك أي محادثات حاليًا.'),
              );
            }

            final groupedConversations = _groupConversations(snapshot.data!);
            final userGroups = groupedConversations.entries.toList();

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: userGroups.length,
              itemBuilder: (context, index) {
                final userGroup = userGroups[index];
                final otherUser =
                    (userGroup.value.first['merchant']['id'] ==
                        Supabase.instance.client.auth.currentUser!.id)
                    ? userGroup.value.first['driver']
                    : userGroup.value.first['merchant'];
                final lastMessage =
                    userGroup.value.first['last_message_content'] ?? '...';

                // The fix is here: Use Padding around NeumorphicContainer
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: NeumorphicContainer(
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        child: Text(otherUser['full_name']?[0] ?? ''),
                      ),
                      title: Text(
                        otherUser['full_name'] ?? 'مستخدم',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      children: userGroup.value.map((conv) {
                        final shipmentTitle =
                            conv['shipment']?['title'] ?? 'شحنة محذوفة';
                        return ListTile(
                          title: Text('شحنة: $shipmentTitle'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  conversationId: conv['id'],
                                  recipientId: otherUser['id'],
                                ),
                              ),
                            );
                            _refreshConversations();
                          },
                        );
                      }).toList(),
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

  // This function remains the same.
  Map<String, List<Map<String, dynamic>>> _groupConversations(
    List<Map<String, dynamic>> conversations,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    for (final conv in conversations) {
      final otherUser = (conv['merchant']['id'] == currentUserId)
          ? conv['driver']
          : conv['merchant'];
      final otherUserId = otherUser['id'];

      if (grouped.containsKey(otherUserId)) {
        grouped[otherUserId]!.add(conv);
      } else {
        grouped[otherUserId] = [conv];
      }
    }
    return grouped;
  }
}
