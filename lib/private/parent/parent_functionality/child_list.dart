import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tap_to_expand/tap_to_expand.dart';

class ChildrenList extends StatelessWidget {
  final String parentId;

  const ChildrenList({super.key, required this.parentId});

  Future<List<Map<String, dynamic>>> _fetchChildren(String parentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('childs')
          .where('parent_id', isEqualTo: parentId)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error fetching children: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchChildren(parentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading children.',
                style: GoogleFonts.montserrat(fontSize: 14),
              ),
            );
          }

          final children = snapshot.data;

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFA1CA73),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TapToExpand(
              title: ListTile(
                leading: const Icon(Icons.list, color: Color(0xFF042F40)),
                title: Text(
                  'Your Children',
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF042F40),
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF042F40),
                  size: 15,
                ),
              ),
              content: snapshot.hasData && children!.isNotEmpty
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: children.length,
                        itemBuilder: (context, index) {
                          final child = children[index];
                          return ListTile(
                            title: Text(
                              child['child_name'] ?? 'Unknown',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: const Color(0xFF042F40),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            subtitle: Text(
                              'Email: ${child['email'] ?? 'N/A'}',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: const Color(0xFF042F40),
                              ),
                            ),
                            leading:
                                const Icon(Icons.person, color: Colors.blue),
                          );
                        },
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'No children found.',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: const Color(0xFF042F40),
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
