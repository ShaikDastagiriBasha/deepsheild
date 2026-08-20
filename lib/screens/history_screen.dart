import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String selectedFilter = "ALL";
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userUid = user?.uid ?? "";

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITLE HEADER
              const Text(
                "Verification History",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // SEARCH BAR
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      searchQuery = val.trim().toLowerCase();
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by ID, Name, PAN or Document No...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryAccent),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchQuery = "";
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // FILTER CHIPS
              Row(
                children: [
                  _buildFilterChip("ALL", "All Logs"),
                  const SizedBox(width: 10),
                  _buildFilterChip("VERIFIED", "Verified"),
                  const SizedBox(width: 10),
                  _buildFilterChip("FAILED", "Failed"),
                ],
              ),

              const SizedBox(height: 20),

              // HISTORY STREAM LIST
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  // NOTE: No server-side orderBy here.
                  // Firestore requires a composite index for (userUid + timestamp DESC).
                  // Client-side sorting in _buildDocListView handles ordering instead,
                  // so no index is needed and the query always succeeds.
                  stream: userUid.isNotEmpty
                      ? FirebaseFirestore.instance
                          .collection('scans')
                          .where('userUid', isEqualTo: userUid)
                          .limit(100)
                          .snapshots()
                      : FirebaseFirestore.instance
                          .collection('scans')
                          .limit(100)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      debugPrint("HISTORY ── Stream Error: ${snapshot.error}");
                      return _buildEmptyState("Unable to load history logs: ${snapshot.error}");
                    }

                    // Runtime verification logs
                    debugPrint('HISTORY ── currentUID: $userUid');
                    debugPrint('HISTORY ── Documents received: ${snapshot.data?.docs.length ?? 0}');
                    for (final doc in snapshot.data?.docs ?? []) {
                      final d = doc.data() as Map<String, dynamic>;
                      debugPrint('HISTORY ── doc[${doc.id}]: '
                          'userUid=${d['userUid']} '
                          'status=${d['status']} '
                          'name=${d['personName'] ?? d['name']}');
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState("No Video KYC verification logs found.");
                    }

                    return _buildDocListView(snapshot.data!.docs);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocListView(List<QueryDocumentSnapshot> rawDocs) {
    List<QueryDocumentSnapshot> docs = rawDocs.toList();

    // CLIENT-SIDE SORTING BY TIMESTAMP DESCENDING
    docs.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final Timestamp? aTime = aData['timestamp'] as Timestamp?;
      final Timestamp? bTime = bData['timestamp'] as Timestamp?;

      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return -1;
      if (bTime == null) return 1;
      return bTime.compareTo(aTime);
    });

    // FILTER BY STATUS TAB
    if (selectedFilter != "ALL") {
      docs = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = (data['status'] ?? "").toString().toUpperCase();
        return status == selectedFilter;
      }).toList();
    }

    // FILTER BY SEARCH QUERY
    if (searchQuery.isNotEmpty) {
      docs = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final verId = (data['verificationId'] ?? '').toString().toLowerCase();
        final name = (data['personName'] ?? data['name'] ?? '').toString().toLowerCase();
        final pan = (data['panNumber'] ?? '').toString().toLowerCase();
        final docNum = (data['documentNumber'] ?? '').toString().toLowerCase();
        final docType = (data['documentType'] ?? '').toString().toLowerCase();

        return verId.contains(searchQuery) ||
            name.contains(searchQuery) ||
            pan.contains(searchQuery) ||
            docNum.contains(searchQuery) ||
            docType.contains(searchQuery);
      }).toList();
    }

    if (docs.isEmpty) {
      return _buildEmptyState("No logs match search criteria.");
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      color: AppTheme.primaryColor,
      child: ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final data = docs[index].data() as Map<String, dynamic>;
          final double matchScore = (data['faceMatchScore'] ?? data['matchScore'] as num?)?.toDouble() ?? 0.0;
          final double overallConfidence = (data['overallConfidence'] as num?)?.toDouble() ?? matchScore;
          final String status = (data['status'] ?? 'FAILED').toString().toUpperCase();
          final bool isVerified = status == 'VERIFIED';
          final String verId = data['verificationId'] ?? 'DS-2026-${index + 1}';
          final String name = data['personName'] ?? data['name'] ?? 'N/A';
          // Support both new documentNumber field and legacy panNumber
          final String docType = data['documentType'] ?? 'PAN Card';
          final String docNumber =
              data['documentNumber'] ?? data['panNumber'] ?? 'N/A';
          final String deepfakeRisk =
              data['deepfakeRiskLevel'] ?? data['riskLevel'] ?? 'LOW RISK';

          Timestamp? timestamp = data['timestamp'];
          String dateText = "Recent";

          if (timestamp != null) {
            final date = timestamp.toDate();
            dateText = "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
          }

          return GestureDetector(
            onTap: () => _showScanDetails(context, data, dateText),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isVerified
                      ? Colors.greenAccent.withValues(alpha: 0.2)
                      : Colors.redAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isVerified ? Icons.verified_user : Icons.warning_rounded,
                      color: isVerified ? Colors.greenAccent : Colors.redAccent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                verId,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateText,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$docType  •  $name  •  $docNumber',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "Face Match: ${matchScore.toStringAsFixed(1)}%",
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isVerified
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Confidence: ${overallConfidence.toInt()}% • $deepfakeRisk",
                                style: TextStyle(
                                  color: isVerified ? Colors.greenAccent : Colors.redAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteLog(docs[index].id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final bool isSelected = selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryAccent : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Start a new Video KYC verification from the dashboard.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLog(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text("Delete Record", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to delete this KYC record? This action cannot be undone.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('scans').doc(docId).delete();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
        }
      }
    }
  }

  void _showScanDetails(BuildContext context, Map<String, dynamic> data, String dateText) {
    final String verId = data['verificationId'] ?? "N/A";
    final String status = (data['status'] ?? "FAILED").toString().toUpperCase();
    final bool isVerified = status == "VERIFIED";
    final double matchScore =
        (data['faceMatchScore'] ?? data['matchScore'] as num?)?.toDouble() ?? 0.0;
    final double overallConfidence =
        (data['overallConfidence'] as num?)?.toDouble() ?? matchScore;
    final String name =
        data['holderName'] ?? data['personName'] ?? data['name'] ?? "N/A";
    // Sprint 5: use documentType-aware label for document number
    final String docType = data['documentType'] ?? 'PAN Card';
    final String docNumber =
        data['documentNumber'] ?? data['panNumber'] ?? "N/A";
    final String dob = data['dateOfBirth'] ?? data['dob'] ?? "N/A";
    final String gender = data['gender'] ?? "";
    final String deepfakeRisk =
        data['deepfakeRiskLevel'] ?? data['riskLevel'] ?? "LOW RISK";
    final double ocrConf =
        (data['ocrConfidence'] as num?)?.toDouble() ?? 0.0;

    // Build a human-readable document number label based on document type
    String docNumberLabel = 'Document Number';
    final String docTypeUpper = docType.toUpperCase();
    if (docTypeUpper.contains('PAN')) {
      docNumberLabel = 'PAN Number';
    } else if (docTypeUpper.contains('AADHAAR') || docTypeUpper.contains('AADHAR')) {
      docNumberLabel = 'Aadhaar Number';
    } else if (docTypeUpper.contains('PASSPORT')) {
      docNumberLabel = 'Passport Number';
    } else if (docTypeUpper.contains('DRIVING') || docTypeUpper.contains('LICENCE') ||
        docTypeUpper.contains('LICENSE')) {
      docNumberLabel = 'Licence Number';
    } else if (docTypeUpper.contains('VOTER') || docTypeUpper.contains('EPIC')) {
      docNumberLabel = 'EPIC Number';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      verId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isVerified
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isVerified ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Verification Date: $dateText",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 16),
                // Sprint 5: show all fields, dynamic labels
                _buildDetailItem("Holder Name", name),
                _buildDetailItem("Document Type", docType),
                _buildDetailItem(docNumberLabel, docNumber),
                _buildDetailItem("Date of Birth", dob),
                if (gender.isNotEmpty && gender != 'N/A')
                  _buildDetailItem("Gender", gender),
                _buildDetailItem(
                    "Face Match Score", "${matchScore.toStringAsFixed(1)}%"),
                _buildDetailItem(
                    "OCR Confidence", "${ocrConf.toInt()}%"),
                _buildDetailItem(
                    "Overall Confidence", "${overallConfidence.toInt()}%"),
                _buildDetailItem("Deepfake Risk Level", deepfakeRisk),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text("Close Report",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}