import 'dart:io';
import 'package:flutter/services.dart';
import 'package:elimupepe/models/ebook.dart';
import 'package:pdfx/pdfx.dart';
import 'package:flutter/material.dart';
import 'package:elimupepe/core/utils/error_feedback.dart';

class ReaderScreen extends StatefulWidget {
  final Ebook ebook;

  const ReaderScreen({super.key, required this.ebook});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  PdfControllerPinch? _pdfController;
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _initializePdf();
    // Allow rotation while in the reader for a better reading experience
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _initializePdf() async {
    try {
      if (widget.ebook.localPath == null || widget.ebook.localPath!.isEmpty) {
        throw Exception('Ebook file path not available');
      }

      final filePath = widget.ebook.localPath!;

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Ebook file not found at: $filePath');
      }

      final document = await PdfDocument.openFile(filePath);

      setState(() {
        _pdfController = PdfControllerPinch(document: Future.value(document));
        _totalPages = document.pagesCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorFeedback.userMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    // Return the app to the default post-login autorotate behavior.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.ebook.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorFeedback.buildInlineError(
              context: context,
              title: 'Error loading PDF',
              error: _error,
              onRetry: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _initializePdf();
              },
            )
          : Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.grey[300],
                    child: PdfViewPinch(
                      controller: _pdfController!,
                      scrollDirection: Axis.vertical,
                      onPageChanged: (page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey[200],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.navigate_before),
                        onPressed: _currentPage > 1
                            ? () {
                                _pdfController?.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.ease,
                                );
                              }
                            : null,
                      ),
                      Text(
                        'Page $_currentPage of $_totalPages',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.navigate_next),
                        onPressed: _currentPage < _totalPages
                            ? () {
                                _pdfController?.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.ease,
                                );
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
