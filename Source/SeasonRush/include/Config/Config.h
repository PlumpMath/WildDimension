#pragma once
#include <string>

struct Configuration {
    Configuration():
    width(800),
    height(600),
    fullscreen(false),
    headless(false),
    webUrl("http://www.frameskippers.com/"),
    apiUrl("http://api.frameskippers.com/v1/")
    {}
    int width;
    int height;
    bool fullscreen;
    std::string webUrl;
    std::string apiUrl;
    bool headless;
    std::string nickname;
};

class Config
{
private:
    Config();
    ~Config();

    /**
     * Config file location
     */
    std::string _filename;

    /**
     * Configuration values
     */
    Configuration _configuration;

    /**
     * Read the config file
     */
    void read();

    /**
     * Parse the read config json
     */
    void parse(std::string content);

public:

    /**
     * Write latest config to file
     */
    void write();

    /**
	 * Returns singleton instance of this class
	 */
	static Config& instance()
	{
		static Config *instance = new Config;
		return *instance;
	}

	void setResolution(int width, int height);
	void setFullscreen(bool val);

    void setNickname(std::string nickname);

	const Configuration getConfig();
};
