module icfputil.icfplib;

import std.algorithm;
import std.json;
import std.range;
import std.stdio;
import std.string;

import icfputil.common;

immutable string address = "icfpc2013.cloudapp.net";
immutable string salt = "vpsH1H";
immutable string data_path = "data/";
immutable string id_file = data_path ~ "id.txt";
immutable string problems_file = data_path ~ "problems.txt";
string auth;

void init ()
{
	auto f_in = File (id_file, "rt");
	auth = f_in.readln ().strip ();
	auth ~= salt;
}

struct Problem
{
	static immutable double TIME_FREE = 300.0 + 1.0;
	string id;
	long size;
	string [] operators;
	bool solved = false;
	double timeLeft = TIME_FREE;
	
	this (this)
	{
		operators = operators.dup;
	}

	this (string new_id, long new_size, string [] new_operators)
	{
		id = new_id;
		size = new_size;
		operators = new_operators.dup;
	}

	this (TrainingProblem tp)
	{
		this (tp.id, tp.size, tp.operators);
	}

	this (JSONValue value)
	{
		auto obj = value.object;
		this (obj["id"].str,
		      obj["size"].integer,
		      obj["operators"].array.map !(x => x.str).array);
		if ("solved" in obj)
		{
			solved = obj["solved"].type == JSON_TYPE.TRUE;
		}
		if ("timeLeft" in obj)
		{
			timeLeft = obj["timeLeft"].floating;
		}
	}
}

void write_problems_sorted (alias fun) (string f_name, Problem [] problems)
{
	auto f_out = File (f_name, "wt");
	auto cur = problems.filter !(x => !x.solved && x.timeLeft >= 0).array;
	cur.sort !(fun);
	f_out.writefln ("%(%s\n%)", cur);
}

JSONValue JSONObject (JSONValue [string] aa)
{
	JSONValue res;
	res.type = JSON_TYPE.OBJECT;
	foreach (key, value; aa)
	{
		res.object[key] = value;
	}
	return res;
}

JSONValue JSONArray (JSONValue [] arr)
{
	JSONValue res;
	res.type = JSON_TYPE.ARRAY;
	foreach (value; arr)
	{
		res.array ~= value;
	}
	return res;
}

JSONValue JSONString (string value)
{
	JSONValue res;
	res.type = JSON_TYPE.STRING;
	res.str = value;
	return res;
}

JSONValue JSONInteger (long value)
{
	JSONValue res;
	res.type = JSON_TYPE.INTEGER;
	res.integer = value;
	return res;
}

struct EvalRequest
{
	string id;
	string program;
	string [] arguments;

	this (this)
	{
		arguments = arguments.dup;
	}

	JSONValue toJSONValue ()
	{
		JSONValue [string] aa;
		if (id.length > 0)
		{
			aa["id"] = id.JSONString;
		}
		if (program.length > 0)
		{
			aa["program"] = program.JSONString;
		}
		aa["arguments"] = arguments.map !(x => JSONString (x))
		                           .array.JSONArray;
		return JSONObject (aa);
	}
}

struct EvalResponse
{
	string status;
	string [] outputs;
	string message;

	this (this)
	{
		outputs = outputs.dup;
	}

	this (JSONValue value)
	{
		auto obj = value.object;
		status = obj["status"].str;
		if ("outputs" in obj)
		{
			outputs = obj["outputs"].array
			                        .map !(x => x.str)
			                        .array;
		}
		if ("message" in obj)
		{
			message = obj["message"].str;
		}
	}
}

struct Guess
{
	string id;
	string program;

	JSONValue toJSONValue ()
	{
		JSONValue [string] aa;
		aa["id"] = id.JSONString;
		aa["program"] = program.JSONString;
		return JSONObject (aa);
	}
}

struct GuessResponse
{
	string status;
	string [] values;
	string message;
	bool lightning;

	this (this)
	{
		values = values.dup;
	}

	this (JSONValue value)
	{
		auto obj = value.object;
		status = obj["status"].str;
		if ("values" in obj)
		{
			values = obj["values"].array
			                      .map !(x => x.str)
			                      .array;
		}
		if ("message" in obj)
		{
			message = obj["message"].str;
		}
		if ("lightning" in obj)
		{
			lightning = obj["lightning"].type == JSON_TYPE.TRUE;
		}
	}
}

struct TrainRequest
{
	long size;
	string [] operators;

	this (this)
	{
		operators = operators.dup;
	}

	JSONValue toJSONValue ()
	{
		JSONValue [string] aa;
		if (size != NA)
		{
			aa["size"] = size.JSONInteger;
		}
		if (operators == [""])
		{
			aa["operators"] = [].JSONArray;
		}
		else if (operators.length > 0)
		{
			aa["operators"] = operators.map !(x => JSONString (x))
		                                   .array.JSONArray;
		}
		return JSONObject (aa);
	}
}

struct TrainingProblem
{
	string challenge;
	string id;
	long size;
	string [] operators;

	this (this)
	{
		operators = operators.dup;
	}

	this (JSONValue value)
	{
		auto obj = value.object;
		challenge = obj["challenge"].str;
		id = obj["id"].str;
		size = obj["size"].integer;
		operators = obj["operators"].array
		                            .map !(x => x.str)
		                            .array;
	}
}
