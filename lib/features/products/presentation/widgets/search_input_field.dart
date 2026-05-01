import 'dart:async';
import 'package:flutter/material.dart';

class SearchInputField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onScannerTap;
  final String hintText;

  const SearchInputField({
    super.key,
    required this.onChanged,
    required this.onScannerTap,
    this.hintText = 'Search by name or code...',
  });

  @override
  State<SearchInputField> createState() => _SearchInputFieldState();
}

class _SearchInputFieldState extends State<SearchInputField> {
  Timer? _debounce;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onChanged(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2D31FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              onPressed: widget.onScannerTap,
            ),
          ),
        ],
      ),
    );
  }
}
