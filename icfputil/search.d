module icfputil.search;

import std.algorithm;
import std.exception;
import std.json;
import std.range;
import std.stdio;
import std.string;
import core.memory;

import icfputil.common;
import icfputil.lbv;
import icfputil.probstat;

static Expression search_op1 (ProbStat probstat, ulong [] a, ulong [] b)
{
	Expression res;
	bool inner_recur (string s, string t, int d)
	{
		if (d == 0)
		{
			Expression cur = new Expression (s ~ " x" ~ t);
			foreach (i, x; a)
			{
				auto y = cur.evaluate (x);
				if (y != b[i])
				{
					writefln ("%3d: 0x%016X != 0x%016X",
					          i, y, b[i]);
					return false;
				}
			}
			res = cur;
			return true;
		}

		foreach (op; probstat.operators)
		{
			if (inner_recur (s ~ "(" ~ op, ")" ~ t, d - 1))
			{
				return true;
			}
		}
		return false;
	}

	inner_recur ("(lambda(x)", ")", cast (int) probstat.size - 2);
	enforce (res !is null);

	return res;
}

static Expression search_op12 (ProbStat probstat, ulong [] a, ulong [] b)
{
	int lim = cast (int) probstat.size;
	string [] [] pack = new string [] [lim];
	pack[1] = [" x", " 0", " 1"];
	foreach (i; 2..lim)
	{
		foreach (op; probstat.operators)
		{
			if (Expression.is_op1 (op))
			{
				foreach (comp; pack[i - 1])
				{
					pack[i] ~= "(" ~ op ~ comp ~ ")";
				}
			}
			else if (Expression.is_op2 (op))
			{
				foreach (j; 1..i - 1)
				{
					int k = i - j - 1;
					foreach (comp1; pack[j])
					{
						foreach (comp2; pack[k])
						{
							pack[i] ~= "(" ~
							    op ~ comp1 ~
							    comp2 ~ ")";
						}
					}
				}
			}
			else
			{
				enforce (false);
			}
		}
		writefln ("pack[%s].length = %s", i, pack[i].length);
	}

	foreach (comp; pack[lim - 1])
	{
		debug {writeln (comp);}
		Expression cur =
		    new Expression ("(lambda(x)" ~ comp ~ ")");
		bool ok = true;
		foreach (i, x; a)
		{
			auto y = cur.evaluate (x);
			if (y != b[i])
			{
				debug {writefln ("%3d: 0x%016X != 0x%016X",
				                 i, y, b[i]);}
				ok = false;
				break;
			}
		}
		if (ok)
		{
			return cur;
		}
	}

	enforce (false);
	return null;
}

static Expression search_op12if (ProbStat probstat, ulong [] a, ulong [] b)
{
	int lim = cast (int) probstat.size;
	string [] [] pack = new string [] [lim];
	pack[1] = [" x", " 0", " 1"];
	foreach (i; 2..lim)
	{
		foreach (op; probstat.operators)
		{
			if (Expression.is_op1 (op))
			{
				foreach (comp; pack[i - 1])
				{
					pack[i] ~= "(" ~ op ~ comp ~ ")";
				}
			}
			else if (Expression.is_op2 (op))
			{
				foreach (j; 1..i - 1)
				{
					int k = i - j - 1;
					foreach (comp1; pack[j])
					{
						foreach (comp2; pack[k])
						{
							pack[i] ~= "(" ~
							    op ~ comp1 ~
							    comp2 ~ ")";
						}
					}
				}
			}
			else if (op == "if0")
			{
				foreach (j; 1..i - 2)
				{
					foreach (k; 1..i - j - 1)
					{
						int l = i - j - k - 1;
						assert (l >= 1);
						foreach (comp1; pack[j])
						{
							foreach (comp2; pack[k])
							{
								foreach (comp3; pack[l])
								{
									pack[i] ~=
									    "(" ~
									    op ~
									    comp1 ~
									    comp2 ~
									    comp3 ~
									    ")";
								}
							}
						}
					}
				}
			}
			else
			{
				enforce (false);
			}
		}
		writefln ("pack[%s].length = %s", i, pack[i].length);
		if (pack[i].length > 100_000)
		{
			GC.collect ();
			GC.minimize ();
		}

		foreach (comp; pack[i])
		{
			debug {writeln (comp);}
			Expression cur =
			    new Expression ("(lambda(x)" ~ comp ~ ")");
			bool ok = true;
			foreach (j, x; a)
			{
				auto y = cur.evaluate (x);
				if (y != b[j])
				{
					debug {writefln
					           ("%3d: 0x%016X != 0x%016X",
					            j, y, b[j]);}
					ok = false;
					break;
				}
			}
			if (ok)
			{
				return cur;
			}
		}
	}

	enforce (false);
	return null;
}

static Expression search_tfold (ProbStat probstat, ulong [] a, ulong [] b)
{
	int lim = cast (int) probstat.size - 2;
	string [] [] pack = new string [] [lim];
	pack[1] = [" y", " z", " 0", " 1"];
	foreach (i; 2..lim)
	{
		foreach (op; probstat.operators)
		{
			if (Expression.is_op1 (op))
			{
				foreach (comp; pack[i - 1])
				{
					pack[i] ~= "(" ~ op ~ comp ~ ")";
				}
			}
			else if (Expression.is_op2 (op))
			{
				foreach (j; 1..i - 1)
				{
					int k = i - j - 1;
					foreach (comp1; pack[j])
					{
						foreach (comp2; pack[k])
						{
							pack[i] ~= "(" ~
							    op ~ comp1 ~
							    comp2 ~ ")";
						}
					}
				}
			}
			else if (op == "if0")
			{
				foreach (j; 1..i - 2)
				{
					foreach (k; 1..i - j - 1)
					{
						int l = i - j - k - 1;
						assert (l >= 1);
						foreach (comp1; pack[j])
						{
							foreach (comp2; pack[k])
							{
								foreach (comp3; pack[l])
								{
									pack[i] ~=
									    "(" ~
									    op ~
									    comp1 ~
									    comp2 ~
									    comp3 ~
									    ")";
								}
							}
						}
					}
				}
			}
			else if (op != "tfold")
			{
				enforce (false);
			}
		}
		writefln ("pack[%s].length = %s", i, pack[i].length);
		if (pack[i].length > 100_000)
		{
			GC.collect ();
			GC.minimize ();
		}

		foreach (comp; pack[i])
		{
			debug {writeln (comp);}
			Expression cur = new Expression
			 ("(lambda(x)(fold x 0(lambda(y z)" ~ comp ~ ")))");
			bool ok = true;
			foreach (j, x; a)
			{
				auto y = cur.evaluate (x);
				if (y != b[j])
				{
					debug {writefln
					           ("%3d: 0x%016X != 0x%016X",
					            j, y, b[j]);}
					ok = false;
					break;
				}
			}
			if (ok)
			{
				return cur;
			}
		}
	}

	enforce (false);
	return null;
}
