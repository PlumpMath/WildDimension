#pragma once

#include <rapidjson/document.h>
#include <string>

class JSONParse
{
public:
	JSONParse();
	~JSONParse();

	/**
	* Get integer value out from the json
	* in - json object
	* member - name of the member we which to get
	* out - reference to an object where we want to store retrieved value
	*/
	static void getValue(rapidjson::Value& in, char* member, int& out);

	/**
	* Get integer value out from the json
	* in - json object
	* member - name of the member we which to get
	* out - reference to an object where we want to store retrieved value
	*/
	static void getValue(rapidjson::Value& in, char* member, std::string& out);

	/**
	* Get integer value out from the json
	* in - json object
	* member - name of the member we which to get
	* out - reference to an object where we want to store retrieved value
	*/
	static void getValue(rapidjson::Value& in, char* member, float& out);
};

