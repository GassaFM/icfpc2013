module icfputil.search_bonus;

import std.algorithm;
import std.exception;
import std.json;
import std.random;
import std.range;
import std.stdio;
import std.string;
import std.typecons;
import core.memory;

import icfputil.common;
import icfputil.lbv;
import icfputil.probstat;

immutable int NUM_ARGS = 4;

int initial_pack_limit = 1_000_000;
int pack_mult = 20_000;
int cur_pack_limit;
int cur_hash_limit = 100_000;
bool use_zero = true;
bool reduce_over_vars = true;

ulong [] asaved;
ulong [] bsaved;
ulong [] bwhich;
Expression res1;
Expression res2;
Expression res3;
int phase;

static Expression search_bonus_op
    (ProbStat probstat, ulong [] a, ulong [] b, int lo)
{
	writeln ("phase = ", phase);
	int lim = cast(int) probstat.size;
	enforce (probstat.is_bonus);
	lim = 9;

	int [] op1set;
	int [] op2set;
	bool have_not = false;
	foreach (op; probstat.operators)
	{
		if (op == "not")
		{
			have_not = true;
		}
	}
	foreach (op; probstat.operators)
	{
		if (Expression.is_op1 (op))
		{
			op1set ~= Expression.op1_num (op);
		}
		else if (Expression.is_op2 (op))
		{
			op2set ~= Expression.op2_num (op);
		}
	}
	if (phase == 3 && !have_not)
	{
		op1set ~= Expression.op1_num ("not");
	}

	bool [ulong] constants;

	alias ulong [NUM_ARGS] ulongs;
	ulongs args;
	foreach (i, ref v; args)
	{
		if (i == 0)
		{
			v = 0;
		}
		else if (i == 1)
		{
			v = 0xFFFF_FFFF_FFFF_FFFFLU;
		}
		else
		{
			v = uniform !(ulong) ();
		}
	}
	bool [ulongs] values_over_x;

	int sig = 0;

	void sign (Expression e)
	{
		e.sig = sig;
		sig++;
	}

	Expression [] [] pack = new Expression [] [lim];
	auto e0 = new Expression ();
	e0.type = Expression.TYPE.ZERO;
	e0.mask = 1 << BASE_0;
	sign (e0);
	constants[0LU] = true;
	auto e1 = new Expression ();
	e1.type = Expression.TYPE.ONE;
	e1.mask = 1 << BASE_1;
	sign (e1);
	constants[1LU] = true;
	auto ex = new Expression ();
	ex.type = Expression.TYPE.ID;
	ex.id = ["x"];
	ex.mask = 1 << BASE_X;
	sign (ex);
	values_over_x[args] = true;
	auto ey = new Expression ();
	ey.type = Expression.TYPE.ID;
	ey.id = ["y"];
	ey.mask = 1 << BASE_Y;
	sign (ey);
	auto ez = new Expression ();
	ez.type = Expression.TYPE.ID;
	ez.id = ["z"];
	ez.mask = 1 << BASE_Z;
	sign (ez);
	pack[1] ~= ex;
	pack[1] ~= e1;
	if (use_zero)
	{
		pack[1] ~= e0;
	}

	Expression res;

	int constants_num = 2;
	int constants_dup = 0;
	int values_over_x_num = 1;
	int values_over_x_dup = 0;
	int processed = 0;

	foreach (i; 2..lim)
	{
		void process (Expression comp, bool toadd = true)
		{
			sign (comp);
			if (comp.is_constant ())
			{
				auto cur_value = comp.evaluate_constant ();
				if (cur_value in constants)
				{
					constants_dup++;
					return;
				}
				else
				{
					if (constants.length < cur_hash_limit)
					{
						constants[cur_value] = true;
					}
					constants_num++;
				}
			}
			else if (reduce_over_vars && comp.is_over_x () &&
			         !(comp.mask & ((1 << BASE_IF0) |
			                        (1 << BASE_FOLD))))
			{
				ulongs cur_values;
				foreach (i, v; args)
				{
					cur_values[i] =
					    comp.evaluate_over_x (v);
				}
				if (cur_values in values_over_x)
				{
					values_over_x_dup++;
					return;
				}
				else
				{
					if (values_over_x.length <
					    cur_hash_limit)
					{
						values_over_x[cur_values] =
						    true;
					}
					values_over_x_num++;
				}
			}
			debug {writeln (comp);}

			if (toadd)
			{
				pack[i] ~= comp;
			
				processed++;
				if (processed == ((processed >> 20) << 20))
				{
					writefln ("[%s]", processed);
					stdout.flush ();
				}
			}

			Expression temp;
			if (phase == 3)
			{
				auto and1 = new Expression ();
				and1.type = Expression.TYPE.OP2;
				and1.op = Expression.OP2.AND;
				and1.e = [comp, e1];
				and1.mask =
				    comp.mask |
				    e1.mask |
				    1 << (BASE_OP2 + and1.op);

				auto eif0 = new Expression ();
				eif0.type = Expression.TYPE.IF0;
				eif0.e = [and1, res1.e[0], res2.e[0]];
				eif0.mask =
				    and1.mask |
				    res1.mask |
				    res2.mask |
				    (1 << BASE_IF0);

				temp = eif0;
			}
			else
			{
				temp = comp;
			}
			auto prog = new Expression ();
			prog.type = Expression.TYPE.PROGRAM;
			prog.id = ["x"];
			prog.e = [temp];
			prog.mask = temp.mask;
			sign (prog);
			int num_matches = 0;
			foreach (j, x; a)
			{
				auto y = prog.evaluate (x);
				num_matches += (y == b[j]);
			}
			bool ok = (num_matches >= lo);
			if (ok)
			{
				writefln ("ok %s", num_matches);
				if (phase == 1)
				{
					asaved = [];
					bsaved = [];
					bwhich = [];
					foreach (j, x; a)
					{
						auto y = prog.evaluate (x);
						bool ok2 = (y == b[j]);
						bwhich ~= ok2;
						if (!ok2)
						{
							asaved ~= x;
							bsaved ~= b[j];
						}
					}
				}
				res = prog;
			}
		}

		foreach (op1; op1set)
		{
			foreach (comp; pack[i - 1])
			{
				// no double not
				if (op1 == Expression.OP1.NOT &&
				    comp.type == Expression.TYPE.OP1 &&
				    comp.op == Expression.OP1.NOT)
				{
					continue;
				}

				// no shr on constants
				if (Expression.is_shr (op1) &&
				    (comp.type == Expression.TYPE.ZERO ||
				     comp.type == Expression.TYPE.ONE))
				{
					continue;
				}

				// no shl on zero
				if (op1 == Expression.OP1.SHL1 &&
				    comp.type == Expression.TYPE.ZERO)
				{
					continue;
				}

				// shrs in non-decreasing order
				if (Expression.is_shr (op1) &&
				    comp.type == Expression.TYPE.OP1 &&
				    Expression.is_shr (comp.op) &&
				    comp.op < op1)
				{
					continue;
				}

				auto eop1 = new Expression ();
				eop1.type = Expression.TYPE.OP1;
				eop1.op = op1;
				eop1.e = [comp];
				eop1.mask =
				    comp.mask |
				    (1 << (BASE_OP1 + op1));
				process (eop1);
				if (res)
				{
					return res;
				}
			}
		}

		foreach (op2; op2set)
		{
			foreach (j; 1..i - 1)
			{
				int k = i - j - 1;
				// symmetric optimization
				if (j > k)
				{
					break;
				}

				foreach (ind1, comp1; pack[j])
				{
					// no same operator at the left
					if (comp1.type ==
					        Expression.TYPE.OP2 &&
					    comp1.op == op2)
					{
						continue;
					}

					// no zero argument
					if (comp1.type ==
					        Expression.TYPE.ZERO)
					{
						continue;
					}

					foreach (ind2, comp2; pack[k])
					{
						// no zero argument
						if (comp2.type ==
						        Expression.TYPE.ZERO)
						{
							continue;
						}

						// symmetric optimization
						if (j == k && ind2 > ind1)
						{
							break;
						}

						// no equal except for plus
						if (op2 !=
						        Expression.OP2.PLUS &&
						    comp1.sig == comp2.sig)
						{
							continue;
						}

						// order multiple arguments
						if (comp2.type ==
						        Expression.TYPE.OP2 &&
						    comp2.op == op2 &&
						    comp2.e[0].sig < comp1.sig)
						{
							continue;
						}

						auto eop2 = new Expression ();
						eop2.type =
						    Expression.TYPE.OP2;
						eop2.op = op2;
						eop2.e = [comp1, comp2];
						eop2.mask =
						    comp1.mask |
						    comp2.mask |
						    (1 << (BASE_OP2 + op2));
						process (eop2);
						if (res)
						{
							return res;
						}
					}
				}
			}
		}

/*
		if (probstat.is_bonus)
		{
			foreach (j; 1..i + 1) foreach (k; 1..i + 1) foreach (l; 1..i + 1)
			{
				if (i > 2 && j != i && k != i && l != i)
				{
					continue;
				}

				foreach (comp1; pack[j])
				{
					if (!(comp1.mask & (1 << BASE_X)))
					{
						continue;
					}
					foreach (comp2; pack[k])
					{
						if (!(comp2.mask & (1 << BASE_X)))
						{
							continue;
						}
						foreach (comp3; pack[l])
						{
							if (!(comp3.mask & (1 << BASE_X)))
							{
								continue;
							}

							auto and1 = new Expression ();
							and1.type = Expression.TYPE.OP2;
							and1.op = Expression.OP2.AND;
							and1.e = [comp1, e1];
							and1.mask = 1 << (BASE_OP2 + and1.op);
							and1.mask |= 1 << BASE_1;
							
							auto eif0 =
							    new Expression ();
							eif0.type =
							    Expression.TYPE.IF0;
							eif0.e =
							    [and1,
							     comp2,
							     comp3];
							eif0.mask =
							    and1.mask |
							    comp2.mask |
							    comp3.mask |
							    (1 << BASE_IF0);

							process (eif0, false);
							if (res)
							{
								return res;
							}
						}
					}
				}
			}
		}
*/

		writefln ("[%s] pack %s, length %s, const +%s -%s, " ~
		          "overx +%s -%s",
		          processed, i, pack[i].length,
		          constants_num, constants_dup,
		          values_over_x_num, values_over_x_dup);
		if (pack[i].length > 100_000)
		{
			GC.collect ();
			GC.minimize ();
		}
	}

//	enforce (false);
	return null;
}

static Expression search_bonus (ProbStat probstat, ulong [] a, ulong [] b)
{
	res1 = null;
	res2 = null;
	res3 = null;
	phase = 1;
	res1 = search_bonus_op (probstat, a, b, 110);
	if (res1 is null)
	{
		return null;
	}
//	res1 = search_bonus_op (probstat, a, b, a.length - (a.length >> 1));
	phase = 2;
	res2 = search_bonus_op (probstat, asaved, bsaved, asaved.length);
	if (res2 is null)
	{
		return null;
	}
	phase = 3;
	res3 = search_bonus_op (probstat, a, b, a.length);
//	res3 = search_bonus_op (probstat, a, bwhich, a.length);
	return res3;
}
