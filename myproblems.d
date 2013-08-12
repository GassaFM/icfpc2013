module icfputil.myproblems;

pragma (lib, "curl");

import std.algorithm;
import std.json;
import std.net.curl;
import std.range;
import std.stdio;
import std.string;

import icfputil.icfplib;
import icfputil.probstat;

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
	auto problems = new Problem [0];
	foreach (c; t.array)
	{
		problems ~= Problem (c);
	}
	write_problems_sorted !("a.size < b.size") ("by_size.txt", problems);
	auto probstats = map !(x => ProbStat (x)) (problems).array;
	write_probstats_sorted !("a.op2s + a.opss < b.op2s + b.opss")
	                       ("by_opsize.txt", probstats);
	write_probstats_sorted
	    !("a.opss < b.opss || (a.opss == b.opss && a.size < b.size)")
	    ("by_op12size.txt", probstats);
	write_probstats_sorted
	    !("a.opfolds < b.opfolds || (a.opfolds == b.opfolds && " ~
	      "a.size < b.size)")
	    ("by_op12if.txt", probstats);
	write_probstats_sorted
	    !("(a.is_fold < b.is_fold || (a.is_fold == b.is_fold && " ~
	      "(a.is_tfold < b.is_tfold || (a.is_tfold == b.is_tfold && " ~
	      "(a.is_bonus < b.is_bonus || (a.is_bonus == b.is_bonus && " ~
	      "(a.size < b.size)))))))")
	    ("by_sort.txt", probstats);
}
