pragma (lib, "curl");

import std.algorithm;
import std.json;
import std.net.curl;
import std.range;
import std.stdio;
import std.string;

import icfputil.icfplib;
import icfputil.lbv;

void main ()
{
	init ();
	auto treq = TrainRequest (-1, []).toJSONValue;
	auto s = cast (string) post (address ~ "/train" ~ "?auth=" ~ auth,
	                             toJSON (&treq));
	writeln (s);
	auto tprob = TrainingProblem (s.parseJSON);
	auto p = new Expression (tprob.challenge);
	writeln (p);
}
