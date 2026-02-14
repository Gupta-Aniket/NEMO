import 'package:flutter/material.dart';
import '../states/SessionState.dart';
import '../view/EventListItem.dart';

class EventListPanel extends StatefulWidget {
  final SessionState sessionState;

  const EventListPanel({super.key, required this.sessionState});

  @override
  State<EventListPanel> createState() => _EventListPanelState();
}

class _EventListPanelState extends State<EventListPanel> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.sessionState.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.sessionState.removeListener(_onStateChanged);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (widget.sessionState.autoScroll && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        const Divider(height: 1),
        Expanded(child: _buildEventList()),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          _buildLevelFilter(),
          const SizedBox(width: 16),
          Expanded(child: _buildSearchField()),
          const SizedBox(width: 16),
          _buildAutoScrollToggle(),
          const SizedBox(width: 16),
          _buildEventCount(),
        ],
      ),
    );
  }

  Widget _buildLevelFilter() {
    return Row(
      children: [
        const Text('Level:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: widget.sessionState.levelFilter,
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All')),
            DropdownMenuItem(value: 'debug', child: Text('Debug')),
            DropdownMenuItem(value: 'info', child: Text('Info')),
            DropdownMenuItem(value: 'warn', child: Text('Warn')),
            DropdownMenuItem(value: 'error', child: Text('Error')),
          ],
          onChanged: (value) {
            if (value != null) {
              widget.sessionState.setLevelFilter(value);
            }
          },
          underline: Container(),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search messages, files, or functions...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon:
            _searchController.text.isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    widget.sessionState.setSearchQuery('');
                  },
                )
                : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      onChanged: (value) {
        widget.sessionState.setSearchQuery(value);
      },
    );
  }

  Widget _buildAutoScrollToggle() {
    return Row(
      children: [
        const Text('Auto-scroll', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Switch(
          value: widget.sessionState.autoScroll,
          onChanged: (value) {
            widget.sessionState.setAutoScroll(value);
          },
        ),
      ],
    );
  }

  Widget _buildEventCount() {
    final count = widget.sessionState.events.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        '$count event${count != 1 ? 's' : ''}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.blue[900],
        ),
      ),
    );
  }

  Widget _buildEventList() {
    final events = widget.sessionState.events;

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No events yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              widget.sessionState.isConnected
                  ? 'Waiting for log events...'
                  : 'Connect a mobile app to start receiving events',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return EventListItem(event: events[index]);
      },
    );
  }
}
