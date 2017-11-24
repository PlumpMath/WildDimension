namespace AchievementsTrap {
    Array<Achievements::AchievementItem> GetAchievments()
    {
        Array<Achievements::AchievementItem> items;
        int count = 1;
        while(true) {
            Achievements::AchievementItem item;
            item.eventName = "GetTrap";
            item.name = "Get trap " + count;
            item.current = 0.0f;
            item.target = count;
            item.completed = false;
            items.Push(item);

            item.eventName = "TrapPacman";
            item.name = "Trap pacman " + count;
            item.current = 0.0f;
            item.target = count;
            item.completed = false;
            items.Push(item);

            item.eventName = "TrapSnake";
            item.name = "Trap pacman " + count;
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