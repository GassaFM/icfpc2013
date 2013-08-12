pragma (lib, "curl");

import std.algorithm;
import std.conv;
import std.exception;
import std.json;
import std.net.curl;
import std.random;
import std.range;
import std.stdio;
import std.string;
import core.sys.windows.windows;

import icfputil.icfplib;
import icfputil.lbv;
import icfputil.probstat;
import icfputil.search;

void main (string [] args)
{
	string s;
	init ();

	ProbStat cur_pstat;
	if (args.length > 1 && args[1] == "real")
	{
		s = cast (string)
		    post (address ~ "/myproblems" ~ "?auth=" ~ auth, "");
		auto t = parseJSON (s);
	
		auto problems = new Problem [0];
		foreach (c; t.array)
		{
			problems ~= Problem (c);
		}
		auto probstats = map !(x => ProbStat (x)) (problems).array;

		foreach (pstat; probstats)
		{
			if (!pstat.solved && pstat.op2s + pstat.opss == 0)
			{
				cur_pstat = pstat;
				break;
			}
		}
		if (cur_pstat == ProbStat.init)
		{
			return;
		}
	}
	else
	{
		while (true)
		{
			auto treq = TrainRequest (4, []).toJSONValue;
			s = cast (string) post
			    (address ~ "/train" ~ "?auth=" ~ auth,
			     toJSON (&treq));
			writeln (s);
			auto tprob = TrainingProblem (s.parseJSON);
			auto temp = ProbStat (Problem (tprob));
			if (temp.op2s + temp.opss == 0)
			{
				cur_pstat = temp;
				break;
			}
			Sleep (5_000);
		}
	}
	writeln (cur_pstat.id);

	ulong [] t;
	foreach (i; 0..256)
	{
		t ~= uniform !(ulong) ();
	}
	auto ereq = EvalRequest (cur_pstat.id, "",
	    map !(x => "0x%016X".format (x)) (t).array).toJSONValue;
	s = cast (string) post (address ~ "/eval" ~ "?auth=" ~ auth,
	                        toJSON (&ereq));
	auto eresp = EvalResponse (s.parseJSON);
	enforce (eresp.status == "ok");
	ulong [] ans;
	foreach (r; eresp.outputs)
	{
		string cur = r.dup;
		cur = cur[2..$];
		ans ~= parse !(ulong) (cur, 16);
	}
/*
	ulong [] ans = map !(x => parse !(ulong) (new string (x[2..$]), 16))
	               (eresp.outputs).array;
*/
	writeln (eresp.outputs[0], " ... ", eresp.outputs[$ - 1]);

	auto q = search_op1 (cur_pstat, t, ans);

	auto guess = Guess (cur_pstat.id, q.toString ()).toJSONValue;
	s = cast (string) post (address ~ "/guess" ~ "?auth=" ~ auth,
	                        toJSON (&guess));
	writeln (s);
}
