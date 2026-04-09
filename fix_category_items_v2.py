content = open('lib/features/home/category_items_screen.dart').read()
old_snippet = """            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElimuCard(
                padding: const EdgeInsets.all(4),
                child: ListTile(
                onTap: () => _openItem(item, title),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                leading: _buildItemLeading(imageUrl),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandGreen,
                    fontSize: 15,
                  ),
                ),
                subtitle: subtitle == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF5C6F8A)),
                        ),
                      ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF5C6F8A),
                ),
              ),
            );"""
new_snippet = """            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElimuCard(
                padding: const EdgeInsets.all(4),
                child: ListTile(
                  onTap: () => _openItem(item, title),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: _buildItemLeading(imageUrl),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandGreen,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: subtitle == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF5C6F8A)),
                          ),
                        ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF5C6F8A),
                  ),
                ),
              ),
            );"""
content = content.replace(old_snippet, new_snippet)
with open('lib/features/home/category_items_screen.dart', 'w') as f:
    f.write(content)
