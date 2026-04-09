with open('lib/features/home/home_screen.dart', 'r') as f:
    content = f.read()

if "elimu_button.dart" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:elimupepe/core/widgets/elimu_button.dart';\nimport 'package:elimupepe/core/widgets/elimu_card.dart';")

# 1. Replace _buildBookCard container with ElimuCard
# This one is tricky because of the complex internal structure. Let's do a more surgical replacement.
old_book_card_start = """      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column("""
new_book_card_start = """      child: ElimuCard(
        padding: EdgeInsets.zero,
        child: Column("""
content = content.replace(old_book_card_start, new_book_card_start)

# 2. Replace ElevatedButton.icon with ElimuButton
# For "Download" button
old_download_btn = """                              : ElevatedButton.icon(
                                  onPressed: () => _downloadBook(book),
                                  icon: const Icon(Icons.download, size: 16),
                                  label: const Text('Download'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.lightGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ))"""
new_download_btn = """                              : ElimuButton(
                                  text: 'Download',
                                  icon: Icons.download,
                                  onPressed: () => _downloadBook(book),
                                ))"""
content = content.replace(old_download_btn, new_download_btn)

# For "Read" button
old_read_btn = """                        : ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ReaderScreen(ebook: book),
                                ),
                              );
                            },
                            icon: const Icon(Icons.menu_book, size: 16),
                            label: const Text('Read'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.lightGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),"""
new_read_btn = """                        : ElimuButton(
                            text: 'Read',
                            icon: Icons.menu_book,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ReaderScreen(ebook: book),
                                ),
                              );
                            },
                          ),"""
content = content.replace(old_read_btn, new_read_btn)

# Fix daily reward dialog claim button
old_claim_btn = """            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'CLAIM REWARD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),"""
new_claim_btn = """            child: ElimuButton(
              text: 'CLAIM REWARD',
              onPressed: () => Navigator.of(context).pop(),
              width: 200,
            ),"""
content = content.replace(old_claim_btn, new_claim_btn)

with open('lib/features/home/home_screen.dart', 'w') as f:
    f.write(content)
