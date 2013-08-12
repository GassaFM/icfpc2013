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
import icfputil.search_sets;
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
	t ~= uniform !(ulong) ();
	t ~= uniform !(ulong) ();
	t ~= cast (ulong) long.min;
	foreach (i; 4..64)
	{
		t ~= 1UL << (i << 2);
	}
	foreach (i; 0..10)
	{
		t ~= cast (ulong) i;
	}
	t ~= 0x0140_0000_0000_0000LU;
	t ~= 0x5000_0000_0000_0000LU;
	t ~= 0x0A00_0000_1000_0002LU;
	while (t.length < 256)
	{
		t ~= uniform !(ulong) ();
	}
/*
        t ~= 0x0000_0000_0000_0001LU;
        t ~= 0x0000_0000_0000_0020LU;
        t ~= 0x0000_0000_0001_0000LU;
        t ~= 0x0000_0001_0000_0000LU;
        t ~= 0x0001_0000_0000_0000LU;
        t ~= 0x8000_0000_0000_0000LU;
	while (t.length < 16)
	{
		t ~= uniform !(ulong) ();
	}
*/

	cur_pack_limit = initial_pack_limit;
	while (true)
	{
		GC.collect ();
		GC.minimize ();
		auto ereq = EvalRequest (cur_pstat.id, "",
		    map !(x => "0x%016X".format (x)) (t).array).toJSONValue;
		wait_for_request ();
		s = cast (string) post (address ~ "/eval" ~ "?auth=" ~ auth,
		                        toJSON (&ereq));
		auto eresp = EvalResponse (s.parseJSON);
		enforce (eresp.status == "ok");
		ulong [] ans = map !(x => parse_0x (x)) (eresp.outputs).array;
		writefln ("0x%016X 0x%016X ... 0x%016X", t[0], t[1], t[$ - 1]);
		writeln (eresp.outputs[0], " ", eresp.outputs[1],
		         " ... ", eresp.outputs[$ - 1]);

		Expression q;
		while (true)
		{
			q = search_sets (cur_pstat, t, ans);
			if (q !is null)
			{
				if (q.mask == 0 &&
				    cur_pack_limit == initial_pack_limit)
				{
					q = null;
				}
				else
				{
					break;
				}
			}
			cur_pack_limit *= pack_mult;
		}
		if (q.mask == 0)
		{
			writeln ("Dropped.");
			break;
		}
		writeln (q);
		writeln (q.toPrettyString ());

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
		enforce (gresp.status != "error");
		t = parse_0x (gresp.values[0]) ~ t[0..$ - 1];
	}
}

void work (string type, int size, int opSize, bool do_solve)
{
	string s;

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
		if (pstat.solved || !(pstat.timeLeft >= 300))
		{
			continue;
		}
		
		if (type == "simple")
		{
			if (pstat.opfolds > 0 || pstat.is_bonus)
			{
				continue;
			}
		}
		else if (type == "trivial")
		{
			if (pstat.opss > 0)
			{
				continue;
			}
		}
		else if (type == "fold")
		{
			if (!pstat.is_fold)
			{
				continue;
			}
		}
		else if (type == "tfold")
		{
			if (!pstat.is_tfold)
			{
				continue;
			}
		}
		else if (type == "bonus")
		{
			if (!pstat.is_bonus)
			{
				continue;
			}
		}
		else
		{
			enforce (false);
		}

		if (pstat.size <= size &&
		    pstat.operators.length <= opSize)
		{
			writeln (pstat);
			if (do_solve)
			{
				go (pstat);
			}
		}
	}
}

void train (string type, int size, int opSize)
{
	string s;

	while (true)
	{
		string str;
		if (type == "simple")
		{
			str = "";
		}
		else if (type == "fold")
		{
			str = "fold";
		}
		else if (type == "tfold")
		{
			str = "tfold";
		}
		else if (type == "bonus")
		{
			str = "";
			size = 42;
		}
		else if (type == "bonus2")
		{
			str = "";
			size = 137;
		}
		else
		{
			enforce (false);
		}

		auto treq = TrainRequest
		    (size, [str]).toJSONValue;
		wait_for_request ();
		s = cast (string) post
		    (address ~ "/train" ~ "?auth=" ~ auth,
		     toJSON (&treq));
		writeln (s);
		auto tprob = TrainingProblem (s.parseJSON);
		auto e = new Expression (tprob.challenge);
		writeln (e.toPrettyString ());
		auto pstat = ProbStat (Problem (tprob));
		go (pstat);
	}
}

void main (string [] args_main)
{
	string s;
	init ();
	init_requests ();
	
	while (true)
	{
		write ("Enter command: ");
		string [] args;
		if (args_main.length > 1)
		{
			args = args_main[1..$];
			args_main.length = 1;
		}
		else
		{
			args = readln ().split ();
		}
		if (!args || args == ["quit"])
		{
			break;
		}
		string command = args[0];
		string type = args[1];
		int size = to !(int) (args[2]);
		int opSize = 999;
		if (args.length > 3)
		{
			opSize = to !(int) (args[3]);
		}
		switch (command)
		{
			case "train":
				train (type, size, opSize);
				break;
			case "display":
				work (type, size, opSize, false);
				break;
			case "solve":
				work (type, size, opSize, true);
				break;
			default:
				enforce (false);
				break;
		}
		writeln ("Done.");
	}
}
