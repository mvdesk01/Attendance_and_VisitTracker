import 'package:flutter/material.dart';

class DiscussionPointTable extends StatelessWidget {
  final List<Widget> rows;
  final VoidCallback onAdd;

  const DiscussionPointTable({
    super.key,
    required this.rows,
    required this.onAdd,
  });

  ///test
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Discussion Points",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text("Add Point"),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1200,
                  child: Column(
                    children: [
                      _header(),
                      SizedBox(
                        height: 500,
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: Column(
                              children: rows,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header() {
    return Container(
      height: 40,
      color: primaryColor,
      child: const Row(
        children: [
          HeaderCell("Sr", 30),
          HeaderCell("Discussion Point", 320),
          HeaderCell("Discussed With", 180),
          HeaderCell("Decision", 200),
          HeaderCell("Responsibility", 260),
          HeaderCell("Target Date", 170),
          HeaderCell("", 40),
        ],
      ),
    );
  }
}

class HeaderCell extends StatelessWidget {
  final String title;
  final double width;

  const HeaderCell(
    this.title,
    this.width, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: width,
      height: 55,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Colors.white24,
          ),
        ),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
