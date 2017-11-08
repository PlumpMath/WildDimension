namespace AchievementsHit {
    Array<Achievements::AchievementItem> GetAchievments()
    {
        Array<Achievements::AchievementItem> items;
        int count = 1;
        while(true) {
            Achievements::AchievementItem item;
            item.eventName = "HitTree";
            item.name = "Hit tree " + count;
            item.current = 0.0f;
            item.target = count;
            item.completed = false;
            items.Push(item);

            item.eventName = "HitSnake";
            item.name = "Hit snake " + count;
            item.current = 0.0f;
            item.target = count;
            item.completed = false;
            items.Push(item);

            item.eventName = "HitPacman";
            item.name = "Hit pacman " + count;
            item.current = 0.0f;
            item.target = count;
            item.completed = false;
            items.Push(item);

            item.eventName = "HitFood";
            item.name = "Hit food " + count;
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