namespace AchievementsBranch {
    Array<Achievements::AchievementItem> GetAchievments()
    {
        Array<Achievements::AchievementItem> items;
        int count = 1;
        while(true) {
            Achievements::AchievementItem item;
            item.eventName = "GetBranch";
            item.name = "Get branch " + count;
            item.current = 0.0f;
            item.target = count;
            item.completed = false;
            items.Push(item);

            count *= 10;
            
            if (count > 100) {
                break;
            }
        }
        return items;
    }
}