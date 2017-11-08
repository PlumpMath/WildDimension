namespace AchievementsAxe {
    Array<Achievements::AchievementItem> GetAchievments()
    {
        Array<Achievements::AchievementItem> items;
        for (int i = 1; i <= 10; i+=9) {
            Achievements::AchievementItem item;
            item.eventName = "GetAxe";
            item.name = "Get axe " + i;
            item.current = 0.0f;
            item.target = i;
            item.completed = false;
            items.Push(item);
        }
        return items;
    }
}