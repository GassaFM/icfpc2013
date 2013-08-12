module status;

pragma (lib, "curl");

import std.json;
import std.net.curl;
import std.stdio;
import std.string;

immutable string address = "icfpc2013.cloudapp.net";
immutable string salt = "vpsH1H";
string auth;

void init ()
{
	auto f_in = File ("data/id.txt", "rt");
	auth = f_in.readln ().strip ();
	auth ~= salt;
}

void main ()
{
	init ();
	auto s = post (address ~ "/status" ~ "?auth=" ~ auth, "");
	writeln (s);
}
