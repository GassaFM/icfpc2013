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

	s = cast (string)
	    post (address ~ "/myproblems" ~ "?auth=" ~ auth, "");
	auto t = parseJSON (s);

	auto problems = new Problem [0];
	foreach (c; t.array)
	{
		problems ~= Problem (c);
	}

	Problem cur_prob;
	foreach (prob; problems)
	{
		if (prob.size == 3 && !prob.solved)
		{
			cur_prob = prob;
			break;
		}
	}
	if (cur_prob == Problem.init)
	{
		return;
	}
	writeln (cur_prob.id);
	auto ereq = EvalRequest (cur_prob.id, "",
	    map !(x => "0x%016X".format (x))
	        (iota (100, 105)).array).toJSONValue;
	s = cast (string) post (address ~ "/eval" ~ "?auth=" ~ auth,
	                        toJSON (&ereq));
	writeln (s);

	auto q = new Expression
	    ("(lambda (x) (%s x))".format (cur_prob.operators[0]));
	foreach (i; 100..105)
	{
		writefln ("Q (0x%016X) = 0x%016X", i, q.evaluate (i));
	}

	auto guess = Guess (cur_prob.id, q.toString ()).toJSONValue;
	s = cast (string) post (address ~ "/guess" ~ "?auth=" ~ auth,
	                        toJSON (&guess));
	writeln (s);
}
