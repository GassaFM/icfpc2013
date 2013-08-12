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
	string s;
	init ();

	auto treq = TrainRequest (3, []).toJSONValue;
	s = cast (string) post (address ~ "/train" ~ "?auth=" ~ auth,
	                        toJSON (&treq));
	writeln (s);
	auto tprob = TrainingProblem (s.parseJSON);

	auto p = new Expression (tprob.challenge);
	writeln (p);
	foreach (i; 100..105)
	{
		writefln ("P (0x%016X) = 0x%016X", i, p.evaluate (i));
	}

	auto ereq = EvalRequest (tprob.id, "",
	    map !(x => "0x%016X".format (x))
	        (iota (100, 105)).array).toJSONValue;
	s = cast (string) post (address ~ "/eval" ~ "?auth=" ~ auth,
	                        toJSON (&ereq));
	writeln (s);

	auto q = new Expression
	    ("(lambda (x) (%s x))".format (tprob.operators[0]));
	foreach (i; 100..105)
	{
		writefln ("Q (0x%016X) = 0x%016X", i, q.evaluate (i));
	}

	auto guess = Guess (tprob.id, q.toString ()).toJSONValue;
	s = cast (string) post (address ~ "/guess" ~ "?auth=" ~ auth,
	                        toJSON (&guess));
	writeln (s);
}
