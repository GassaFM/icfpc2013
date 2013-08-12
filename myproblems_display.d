module myproblems_display;
// old version

pragma (lib, "curl");

import std.algorithm;
import std.json;
import std.net.curl;
import std.stdio;
import std.string;

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

void main ()
{
	init ();
	string s;
	try
	{
		auto f_in = File (problems_file, "rt");
		s = f_in.readln ().strip ();
	}
	catch (Exception e)
	{
		s = cast (string)
		    post (address ~ "/myproblems" ~ "?auth=" ~ auth, "");
		auto f_out = File (problems_file, "wt");
		f_out.writeln (s);
	}
	auto t = parseJSON (s);
	foreach (c; t.array)
	{
		auto co = c.object;
		writef ("id = \"%s\", ", co["id"].str);
		writef ("size = %2d, ", co["size"].integer);
		writef ("operators = %s",
		       map !(x => x.str) (co["operators"].array));
		if ("solved" in co)
		{
			writef ("solved = %s",
			        cast (bool) (co["solved"].integer));
		}
		if ("timeLeft" in co)
		{
			writef ("timeLeft = %s", (co["timeLeft"].integer));
		}
		writeln;
	}
}
