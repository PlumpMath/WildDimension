#include "JSONParse.h"
#include <iostream>
#include <string>

JSONParse::JSONParse()
{
}


JSONParse::~JSONParse()
{
}

void JSONParse::getValue(rapidjson::Value& in, char* member, int& out)
{
	if (!in.HasMember(member)) {
		return;
	}
	if (in[member].IsString()) {
		try {
			out = std::stoi(in[member].GetString());
		}
		catch (std::exception& e) {
		}
	}
	else if (in[member].IsDouble()) {
		out = (int)in[member].GetDouble();
	}
	else if (in[member].IsInt()) {
		out = in[member].GetInt();
	}
	else {
		out = 0;
	}
}

void JSONParse::getValue(rapidjson::Value& in, char* member, std::string& out)
{
	if (!in.HasMember(member)) {
		return;
	}
	if (in[member].IsString()) {
		out = in[member].GetString();
	}
	else if (in[member].IsInt()) {
		out = std::to_string(in[member].GetInt());
	}
	else if (in[member].IsDouble()) {
		out = std::to_string(in[member].GetDouble());
	}
	else {
		out = "";
	}
}

void JSONParse::getValue(rapidjson::Value& in, char* member, float& out)
{
	if (!in.HasMember(member)) {
		return;
	}
	if (in[member].IsString()) {
		try {
			out = std::stof(in[member].GetString());
		}
		catch (std::exception& e) {
		}
	}
	else if (in[member].IsInt()) {
		out = (float)in[member].GetInt();
	}
	else if (in[member].IsDouble()) {
		out = in[member].GetDouble();
	}
	else {
		out = 0.0f;
	}
}
