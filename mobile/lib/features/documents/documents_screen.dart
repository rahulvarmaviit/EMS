import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/api/api_client.dart';
import 'package:http_parser/http_parser.dart';
import '../../core/api/multipart_request_with_progress.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _isLoading = false;
  bool _isUploading = false;
  Map<String, String> _uploadedDocs = {}; // title -> status
  List<String> _customDocs = []; // List of custom document titles

  final List<String> _personalDocs = [
    'Passport Size Photo',
    'Aadhar Card',
    'PAN Card',
  ];

  final List<String> _educationalDocs = [
    '10th Marksheet',
    '12th Marksheet',
    'Under-Graduation Marksheet',
    'Post-Graduation Marksheet',
    'College ID Card',
  ];

  final List<String> _professionalDocs = [
    'Resume',
    'Internship Offer Letter (Signed)',
    'NDA (Non-Disclosure Agreement) (Signed)',
    'NOC (No Objection Certificate)',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final baseUrl = ApiClient.baseUrl;

      final response = await http.get(
        Uri.parse('$baseUrl/api/documents'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final Map<String, String> statusMap = {};
        final List<String> customList = [];

        final allDefaultDocs = [
          ..._personalDocs,
          ..._educationalDocs,
          ..._professionalDocs
        ];

        for (var doc in data) {
          String title = doc['title'];
          statusMap[title] = 'Uploaded';

          // If it's not a default doc, add to custom list
          if (!allDefaultDocs.contains(title)) {
            customList.add(title);
          }
        }

        if (mounted) {
          setState(() {
            _uploadedDocs = statusMap;
            _customDocs = customList;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load documents: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadDocument(String title) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final sizeInBytes = await file.length();
        final sizeInMb = sizeInBytes / (1024 * 1024);

        if (sizeInMb > 10) {
          _showErrorDialog('File size must be less than 10MB');
          return;
        }

        if (result.files.single.extension != 'pdf') {
          _showErrorDialog('Only PDF files are allowed');
          return;
        }

        setState(() => _isUploading = true);

        final progressNotifier = ValueNotifier<double>(0.0);
        final progressTextNotifier =
            ValueNotifier<String>("Starting upload...");

        // Show progress dialog
        if (mounted) {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Center(
                  child: Card(
                      child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ValueListenableBuilder<double>(
                                valueListenable: progressNotifier,
                                builder: (context, value, child) {
                                  return CircularProgressIndicator(
                                      value: value);
                                },
                              ),
                              const SizedBox(height: 16),
                              ValueListenableBuilder<String>(
                                valueListenable: progressTextNotifier,
                                builder: (context, value, child) {
                                  return Text(value);
                                },
                              ),
                            ],
                          )))));
        }

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        final baseUrl = ApiClient.baseUrl;

        var request = MultipartRequestWithProgress(
          'POST',
          Uri.parse('$baseUrl/api/documents/upload'),
          onProgress: (bytes, totalBytes) {
            if (totalBytes > 0) {
              final progress = bytes / totalBytes;
              final mbUploaded = bytes / (1024 * 1024);
              final totalMb = totalBytes / (1024 * 1024);

              progressNotifier.value = progress;
              progressTextNotifier.value =
                  "${mbUploaded.toStringAsFixed(2)} MB / ${totalMb.toStringAsFixed(2)} MB";
            }
          },
        );
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['title'] = title;

        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('application', 'pdf'),
        ));

        var stream = await request.send();
        var response = await http.Response.fromStream(stream);

        // Close progress dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (response.statusCode == 201 || response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Document uploaded successfully')),
            );
            _fetchDocuments();
          }
        } else {
          final respData = json.decode(response.body);
          if (mounted) {
            _showErrorDialog(respData['error'] ?? 'Upload failed');
          }
        }
      }
    } catch (e) {
      // Close progress dialog if open (simple check might be needed if logic gets complex,
      // but here we know it opens right before try block work)
      if (mounted && _isUploading) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        _showErrorDialog('Error uploading document: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocItem(String title) {
    bool isUploaded = _uploadedDocs.containsKey(title);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isUploaded ? 'Status: Uploaded' : 'Status: Not Uploaded',
                  style: TextStyle(
                    color: isUploaded ? Colors.greenAccent : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _uploadDocument(title),
            icon: const Icon(
              Icons.upload,
              size: 16,
              color: Colors.white,
            ),
            label: const Text(
              'Upload',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> docs) {
    if (docs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...docs.map((doc) => _buildDocItem(doc)),
      ],
    );
  }

  void _addOtherDocument() {
    showDialog(
        context: context,
        builder: (ctx) {
          final controller = TextEditingController();
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Add Other Document',
                style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Document Name',
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    Navigator.of(ctx).pop();
                    _uploadDocument(controller.text);
                  }
                },
                child: const Text('Upload'),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title:
            const Text('My Documents', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading && _uploadedDocs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manage Your Documents',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Upload and manage your required personal, educational, and professional documents. All files should be in PDF format(MAX 10mb), except where noted.',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  height: 1.4),
                            ),
                          ])),
                  const SizedBox(height: 20),
                  _buildSection('Personal Documents', _personalDocs),
                  _buildSection('Educational Documents', _educationalDocs),
                  _buildSection('Professional Documents', _professionalDocs),

                  // Custom Docs Section
                  if (_customDocs.isNotEmpty)
                    _buildSection('Other Documents', _customDocs),

                  const SizedBox(height: 20),
                  Center(
                    child: TextButton.icon(
                      onPressed: _addOtherDocument,
                      icon: const Icon(Icons.add, color: Color(0xFF6C63FF)),
                      label: const Text('Add Other Document',
                          style: TextStyle(color: Color(0xFF6C63FF))),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
