namespace AchievementsHit {
    Array<Achievements::AchievementItem> GetAchievments()
    {
        Array<Achievements::AchievementItem> items;
        for (int i = 1; i <= 10; i+=9) {
            Achievements::AchievementItem item;
            item.eventName = "HitTree";
            item.name = "Hit tree " + i;
            item.current = 0.0f;
            item.target = i;
            item.completed = false;
            items.Push(item);

            item.eventName = "HitSnake";
            item.name = "Hit snake " + i;
            item.current = 0.0f;
            item.target = i;
            item.completed = false;
            items.Push(item);

            item.eventName = "HitPacman";
            item.name = "Hit pacman " + i;
            item.current = 0.0f;
            item.target = i;
            item.completed = false;
            items.Push(item);

            item.eventName = "HitFood";
            item.name = "Hit food " + i;
            item.current = 0.0f;
            item.target = i;
            item.completed = false;
            items.Push(item);
        }
        return items;
    }
}