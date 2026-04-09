with open('lib/features/home/main_view.dart', 'r') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if 'child: ListTile(' in line and 'leading: CircleAvatar(' in lines[i+1]:
        # Missing closing parenthesis for ListTile and ElimuCard
        pass

# It's easier to just write the correct method
content = open('lib/features/home/main_view.dart').read()
old_method = """  Widget _buildActivityCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElimuCard(
        padding: const EdgeInsets.all(4),
        child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, size: 18),
      ),
    );
  }"""
new_method = """  Widget _buildActivityCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElimuCard(
        padding: const EdgeInsets.all(4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right, size: 18),
        ),
      ),
    );
  }"""
content = content.replace(old_method, new_method)
with open('lib/features/home/main_view.dart', 'w') as f:
    f.write(content)
