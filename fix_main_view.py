with open('lib/features/home/main_view.dart', 'r') as f:
    content = f.read()

# 1. Replace _buildDailyProgressCard body
old_daily_progress = """    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row("""
new_daily_progress = """    return ElimuCard(
      padding: const EdgeInsets.all(20),
      child: Row("""
content = content.replace(old_daily_progress, new_daily_progress)

# 2. Replace _buildStatTile body
old_stat_tile = """    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column("""
new_stat_tile = """    return ElimuCard(
      backgroundColor: color.withValues(alpha: 0.1),
      borderColor: color.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(16),
      child: Column("""
content = content.replace(old_stat_tile, new_stat_tile)

# 3. Replace _buildActivityCard body
old_activity_card = """    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceGray, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile("""
new_activity_card = """    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElimuCard(
        padding: const EdgeInsets.all(4),
        child: ListTile("""
content = content.replace(old_activity_card, new_activity_card)

with open('lib/features/home/main_view.dart', 'w') as f:
    f.write(content)
