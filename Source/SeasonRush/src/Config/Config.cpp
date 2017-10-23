#include "Config/Config.h"
#include <iostream>
#include <fstream>
#include <rapidjson/document.h>
#include <rapidjson/reader.h>

using namespace std;

Config::Config():
_filename("Data/config.json")
{
    read();
}

Config::~Config()
{
    write();
}

void Config::read()
{
    string content;
    string line;
	ifstream infile;
	infile.open (_filename);

    while (getline(infile, line)) {
        content.append(line);
    }

    parse(content);

	infile.close();
}

void Config::parse(std::string content)
{
    rapidjson::Document json;

	json.Parse<rapidjson::ParseFlag::kParseDefaultFlags>(content.c_str());
	if (json.IsObject()) {
        if (json.HasMember("nickname")) {
            _configuration.nickname = json["nickname"].GetString();
        }
        if (json.HasMember("width")) {
            _configuration.width = json["width"].GetInt();
        }
        if (json.HasMember("height")) {
            _configuration.height = json["height"].GetInt();
        }
        if (json.HasMember("fullscreen")) {
            _configuration.fullscreen = json["fullscreen"].GetBool();
        }
        if (json.HasMember("api_url")) {
            _configuration.apiUrl = json["api_url"].GetString();
        }
        if (json.HasMember("web_url")) {
            _configuration.webUrl = json["web_url"].GetString();
        }
        if (json.HasMember("headless")) {
            _configuration.headless = json["headless"].GetBool();
        }
	}
}

const Configuration Config::getConfig()
{
    return _configuration;
}

void Config::write()
{
    ofstream tmp;
    tmp.open(_filename);
    tmp << "{\n";
    tmp << "\"nickname\":\"" << _configuration.nickname << "\",\n";
    tmp << "\"width\":" << _configuration.width << ",\n";
    tmp << "\"height\":" << _configuration.height << ",\n";
    tmp << "\"api_url\":\"" << _configuration.apiUrl << "\",\n";
    tmp << "\"web_url\":\"" << _configuration.webUrl << "\",\n";
    tmp << "\"fullscreen\":";
    if (_configuration.fullscreen) {
        tmp << "true";
    } else {
        tmp << "false";
    }
    tmp << ",\n";
    tmp << "\"headless\":";
    if (_configuration.headless) {
        tmp << "true";
    }
    else {
        tmp << "false";
    }

    tmp << "\n}\n";
    tmp.close();
}

void Config::setResolution(int width, int height)
{
	_configuration.width = width;
	_configuration.height = height;
}

void Config::setFullscreen(bool val)
{
	_configuration.fullscreen = val;
}

void Config::setNickname(std::string nickname)
{
    _configuration.nickname = nickname;
}