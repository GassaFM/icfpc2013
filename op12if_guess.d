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
import core.memory;

import icfputil.icfplib;
import icfputil.lbv;
import icfputil.probstat;
import icfputil.search;
import icfputil.request;

ulong parse_0x (string s)
{
	string cur = s.dup;
	cur = cur[2..$];
	ulong res = parse !(ulong) (cur, 16);
	return res;
}

void go (ref ProbStat cur_pstat)
{
	string s;
	writeln (cur_pstat.id);

	ulong [] t;
	foreach (i; 4..64)
	{
		t ~= 1UL << i;
	}
	foreach (i; 0..10)
	{
		t ~= cast (ulong) i;
	}
	t ~= cast (ulong) long.min;
	foreach (i; 71..256)
	{
		t ~= uniform !(ulong) ();
	}

	while (true)
	{
		GC.collect ();
		auto ereq = EvalRequest (cur_pstat.id, "",
		    map !(x => "0x%016X".format (x)) (t).array).toJSONValue;
		wait_for_request ();
		s = cast (string) post (address ~ "/eval" ~ "?auth=" ~ auth,
		                        toJSON (&ereq));
		auto eresp = EvalResponse (s.parseJSON);
		enforce (eresp.status == "ok");
		ulong [] ans = map !(x => parse_0x (x)) (eresp.outputs).array;
		writeln (eresp.outputs[0], " ... ", eresp.outputs[$ - 1]);

		auto q = search_op12if (cur_pstat, t, ans);

		auto guess = Guess (cur_pstat.id, q.toString ()).toJSONValue;
		wait_for_request ();
		s = cast (string) post (address ~ "/guess" ~ "?auth=" ~ auth,
		                        toJSON (&guess));
		writeln (s);
		auto gresp = GuessResponse (s.parseJSON);
		if (gresp.status == "win")
		{
			break;
		}
		t = parse_0x (gresp.values[0]) ~ t[0..$ - 1];
	}
}

void main (string [] args)
{
	string s;
	init ();
	init_requests ();
	
	ProbStat cur_pstat;
	if (args.length > 1 && (args[1] == "real" || args[1] == "display"))
	{
		wait_for_request ();
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
			if (!pstat.solved && pstat.timeLeft > 0 &&
			    pstat.opfolds == 0 && pstat.size <= 11 &&
			    pstat.operators.length <= 4)
			{
				cur_pstat = pstat;
				if (args[1] == "real")
				{
					go (cur_pstat);
				}
				else
				{
					writeln (pstat);
				}
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
			while (true)
			{
				auto treq = TrainRequest (9, [""]).toJSONValue;
				wait_for_request ();
				s = cast (string) post
				    (address ~ "/train" ~ "?auth=" ~ auth,
				     toJSON (&treq));
				writeln (s);
				auto tprob = TrainingProblem (s.parseJSON);
				auto temp = ProbStat (Problem (tprob));
				if (temp.opfolds == 0)
				{
					cur_pstat = temp;
					break;
				}
			}
			go (cur_pstat);
		}
	}
}
