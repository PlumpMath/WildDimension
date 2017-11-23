namespace Helpers {
    
    float getWidthByPercentage(float percents)
    {
        float w = graphics.width;
        return w * percents;
    }

    float getHeightByPercentage(float percents)
    {
        float h = graphics.height;
        return h * percents;
    }

    float getRatio(float originalSize, float newSize)
    {
        return newSize / originalSize;
    }
}