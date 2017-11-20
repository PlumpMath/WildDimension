namespace AchievementsPlaces {
    Array<Achievements::AchievementItem> GetAchievments()
    {
        Array<Achievements::AchievementItem> items;

        Achievements::AchievementItem item;
        item.eventName = "VisitPyramid";
        item.name = "See a pyramid!";
        item.current = 0.0f;
        item.target = 1;
        item.completed = false;
        items.Push(item);

        item.eventName = "VisitVillage";
        item.name = "Find abandoned vilalge!";
        item.current = 0.0f;
        item.target = 1;
        item.completed = false;
        items.Push(item);

        item.eventName = "VisitStonehedge";
        item.name = "Find stonehedge!";
        item.current = 0.0f;
        item.target = 1;
        item.completed = false;
        items.Push(item);

        return items;
    }
}