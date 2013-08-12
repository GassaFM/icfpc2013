module icfputil.probstat;

import std.algorithm;
import std.json;
import std.range;
import std.stdio;
import std.string;

import icfputil.common;
import icfputil.icfplib;
import icfputil.lbv;

struct ProbStat
{
	Problem problem;
	alias problem this;
	int op1s;
	int op2s;
	int opss;
	int opfolds;
	int opSize;
	bool is_bonus;
	bool is_fold;
	bool is_tfold;

	this (int dummy)
	{
		opSize = operators.length;
		foreach (op; operators)
		{
			if (Expression.is_op1 (op))
			{
				op1s++;
			}
			else if (Expression.is_op2 (op))
			{
				op2s++;
			}
			else if (op == "bonus")
			{
				is_bonus = true;
			}
			else
			{
				opss++;
			}
			if (op == "fold" || op == "tfold")
			{
				opfolds++;
			}
			if (op == "fold")
			{
				is_fold = true;
			}
			if (op == "tfold")
			{
				is_tfold = true;
			}
		}
	}

	this (JSONValue value)
	{
		problem = Problem (value);
		this (0);
	}

	this (Problem new_problem)
	{
		problem = new_problem;
		this (0);
	}
}

void write_probstats_sorted (alias fun) (string f_name, ProbStat [] probstats)
{
	auto f_out = File (f_name, "wt");
	auto cur = probstats.filter !(x => !x.solved && x.timeLeft >= 0).array;
	cur.sort !(fun);
	f_out.writefln ("%(%s\n%)", cur);
}
