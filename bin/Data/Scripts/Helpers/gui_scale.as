namespace Helpers {
    
    float getWidthByPercentage(float percents)
    {
        float w = graphics.width;
        if (w == 0) {
            w = 1280;
        }
        return w * percents;
    }

    float getHeightByPercentage(float percents)
    {
        float h = graphics.height;
        if (h == 0) {
            h = 720;
        }
        return h * percents;
    }

    float getRatio(float originalSize, float newSize)
    {
        return newSize / originalSize;
    }
}