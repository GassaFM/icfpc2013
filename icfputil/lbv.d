module icfputil.lbv;

import std.algorithm;
import std.ascii;
import std.conv;
import std.exception;
import std.range;
import std.stdio;
import std.string;

import icfputil.common;

string consumeFront (ref string [] arr)
{
	enforce (!arr.empty);
	string res = arr.front ();
	arr.popFront ();
	return res;
}

final class Expression
{
	enum TYPE {NONE, PROGRAM, ZERO, ONE, ID, IF0, FOLD, OP1, OP2};
	enum KEYWORD {NONE, OPEN, CLOSE, LAMBDA, ZERO, ONE, IF0, FOLD, BONUS};
	static immutable string [] KEYWORD_NAME =
	    ["", "(", ")", "lambda", "0", "1", "if0", "fold"];
	enum OP1 {NONE, NOT, SHL1, SHR1, SHR4, SHR16};
	static immutable string [] OP1_NAME =
	    ["", "not", "shl1", "shr1", "shr4", "shr16"];
	enum OP2 {NONE, AND, OR, XOR, PLUS};
	static immutable string [] OP2_NAME =
	    ["", "and", "or", "xor", "plus"];
	static ulong [3] svalue;

	static bool is_op1 (string s)
	{
		foreach (op; OP1_NAME)
		{
			if (op == s)
			{
				return true;
			}
		}
		return false;
	}
	
	static bool is_shr (int op1)
	{
		return op1 >= OP1.SHR1;
	}

	static int op1_num (string s)
	{
		foreach (i, op; OP1_NAME)
		{
			if (op == s)
			{
				return i;
			}
		}
		enforce (false);
		return NA;
	}

	static bool is_op2 (string s)
	{
		foreach (op; OP2_NAME)
		{
			if (op == s)
			{
				return true;
			}
		}
		return false;
	}

	static int op2_num (string s)
	{
		foreach (i, op; OP2_NAME)
		{
			if (op == s)
			{
				return i;
			}
		}
		enforce (false);
		return NA;
	}

	int type;
	int op;
	Expression [] e;
	string [] id;
	Expression p;
	ulong [] value;
	bool use_svalue;
	uint mask;
	int sig;

	this ()
	{
		use_svalue = true;
	}

	this (ref string [] s, Expression par = null)
	{
		p = par;
		string cur;

		cur = s.consumeFront ();
		if (cur == KEYWORD_NAME[KEYWORD.ZERO])
		{
			type = TYPE.ZERO;
		}
		else if (cur == KEYWORD_NAME[KEYWORD.ONE])
		{
			type = TYPE.ONE;
		}
		else if (cur == KEYWORD_NAME[KEYWORD.OPEN])
		{
			cur = s.consumeFront ();
			if (cur == KEYWORD_NAME[KEYWORD.LAMBDA])
			{
				type = TYPE.PROGRAM;
				cur = s.consumeFront ();
				enforce (cur == KEYWORD_NAME[KEYWORD.OPEN]);
				cur = s.consumeFront ();
				id ~= cur;
				value ~= cast (ulong) NA;
				cur = s.consumeFront ();
				enforce (cur == KEYWORD_NAME[KEYWORD.CLOSE]);
				e ~= new Expression (s, this);
			}
			else if (cur == KEYWORD_NAME[KEYWORD.IF0])
			{
				type = TYPE.IF0;
				e ~= new Expression (s, this);
				e ~= new Expression (s, this);
				e ~= new Expression (s, this);
			}
			else if (cur == KEYWORD_NAME[KEYWORD.FOLD])
			{
				type = TYPE.FOLD;
				e ~= new Expression (s, this);
				e ~= new Expression (s, this);
				cur = s.consumeFront ();
				enforce (cur == KEYWORD_NAME[KEYWORD.OPEN]);
				cur = s.consumeFront ();
				enforce (cur == KEYWORD_NAME[KEYWORD.LAMBDA]);
				cur = s.consumeFront ();
				enforce (cur == KEYWORD_NAME[KEYWORD.OPEN]);
				cur = s.consumeFront ();
				id ~= cur;
				value ~= cast (ulong) NA;
				cur = s.consumeFront ();
				id ~= cur;
				value ~= cast (ulong) NA;
				cur = s.consumeFront ();
				enforce (cur == KEYWORD_NAME[KEYWORD.CLOSE]);
				e ~= new Expression (s, this);
				cur = s.consumeFront ();
				enforce (cur == KEYWORD_NAME[KEYWORD.CLOSE]);
			}
			if (type == TYPE.NONE)
			{
				foreach (op1, name; OP1_NAME)
				{
					if (cur == name)
					{
						type = TYPE.OP1;
						op = op1;
						e ~= new Expression (s, this);
						break;
					}
				}
			}
			if (type == TYPE.NONE)
			{
				foreach (op2, name; OP2_NAME)
				{
					if (cur == name)
					{
						type = TYPE.OP2;
						op = op2;
						e ~= new Expression (s, this);
						e ~= new Expression (s, this);
						break;
					}
				}
			}
			if (type == TYPE.NONE)
			{
				enforce (false);
			}
			cur = s.consumeFront ();
			enforce (cur == KEYWORD_NAME[KEYWORD.CLOSE]);
		}
		else
		{
			type = TYPE.ID;
			id ~= cur;
		}

		if (par is null)
		{
			enforce (type == TYPE.PROGRAM);
		}
	}

	this (string s)
	{
		string [] tokens;
		string cur;
		foreach (c; s)
		{
			if (isWhite (c))
			{
				tokens ~= cur;
				cur = "";
			}
			else if (isDigit (c) && cur.length == 0)
			{
				cur ~= c;
				tokens ~= cur;
				cur = "";
			}
			else if (isAlphaNum (c) || c == '_')
			{
				cur ~= c;
			}
			else
			{
				tokens ~= cur;
				cur = "";
				cur ~= c;
				tokens ~= cur;
				cur = "";
			}
		}
		tokens ~= cur;
		auto tokens_ne = tokens.filter !(x => x.length > 0).array;
		this (tokens_ne);
	}

	ulong evaluate (bool force = false)
	{
		if (!force && use_svalue && is_constant () && value.length > 0)
		{
			return value[0];
		}
		final switch (type)
		{
			case TYPE.PROGRAM:
				return e[0].evaluate ();
			case TYPE.ZERO:
				return 0;
			case TYPE.ONE:
				return 1;
			case TYPE.ID:
				if (use_svalue)
				{
					return svalue[id[0][0] - 'x'];
				}
				Expression cur = this;
				while (cur !is null)
				{
					foreach (pos, cvalue; cur.value)
					{
						if (cur.id[pos] == id[0])
						{
							return cvalue;
						}
					}
					cur = cur.p;
				}
				enforce (false);
				return cast (ulong) NA;
			case TYPE.IF0:
				auto cond = e[0].evaluate ();
				if (cond == 0)
				{
					return e[1].evaluate ();
				}
				else
				{
					return e[2].evaluate ();
				}
			case TYPE.FOLD:
				auto data = e[0].evaluate ();
				if (use_svalue)
				{
					svalue[2] = e[1].evaluate ();
					foreach (i; 0..8)
					{
						svalue[1] =
						    (data >> (i << 3)) & 0xFF;
						svalue[2] = e[2].evaluate ();
					}
					return svalue[2];
				}
				value[1] = e[1].evaluate ();
				foreach (i; 0..8)
				{
					value[0] = (data >> (i << 3)) & 0xFF;
					value[1] = e[2].evaluate ();
				}
				return value[1];
			case TYPE.OP1:
				final switch (op)
				{
					case OP1.NOT:
						return ~e[0].evaluate ();
					case OP1.SHL1:
						return e[0].evaluate () << 1;
					case OP1.SHR1:
						return e[0].evaluate () >> 1;
					case OP1.SHR4:
						return e[0].evaluate () >> 4;
					case OP1.SHR16:
						return e[0].evaluate () >> 16;
					case OP1.NONE:
						enforce (false);
						return cast (ulong) NA;
				}
			case TYPE.OP2:
				final switch (op)
				{
					case OP2.AND:
						return e[0].evaluate () &
						       e[1].evaluate ();
					case OP2.OR:
						return e[0].evaluate () |
						       e[1].evaluate ();
					case OP2.XOR:
						return e[0].evaluate () ^
						       e[1].evaluate ();
					case OP2.PLUS:
						return e[0].evaluate () +
						       e[1].evaluate ();
					case OP2.NONE:
						enforce (false);
						return cast (ulong) NA;
				}
			case TYPE.NONE:
				enforce (false);
				return cast (ulong) NA;
		}
	}
	
	ulong evaluate (ulong argument)
	{
		enforce (type == TYPE.PROGRAM);
		if (use_svalue)
		{
			svalue[0] = argument;
		}
		else
		{
			value[0] = argument;
		}
		return evaluate ();
	}

	bool is_constant ()
	{
		return (mask & ((1 << BASE_X) |
			        (1 << BASE_Y) |
			        (1 << BASE_Z))) == 0;
	}

	bool is_over_x ()
	{
		return (mask & ((1 << BASE_X) |
			        (1 << BASE_Y) |
			        (1 << BASE_Z))) == (1 << BASE_X);
	}

	ulong evaluate_constant ()
	{
		enforce (is_constant ());
		if (value.length > 0)
		{
			return value[0];
		}
		ulong res = evaluate (true);
		value = [res];
		return res;
	}

	ulong evaluate_over_x (ulong argument)
	{
		enforce (is_over_x ());
		enforce (use_svalue);
		svalue[0] = argument;
		return evaluate ();
	}

	override string toString () const
	{
		string [] res;
		final switch (type)
		{
			case TYPE.PROGRAM:
				res ~= KEYWORD_NAME[KEYWORD.OPEN];
				res ~= KEYWORD_NAME[KEYWORD.LAMBDA];
				res ~= KEYWORD_NAME[KEYWORD.OPEN];
				res ~= id[0];
				res ~= KEYWORD_NAME[KEYWORD.CLOSE];
				res ~= e[0].toString ();
				res ~= KEYWORD_NAME[KEYWORD.CLOSE];
				break;
			case TYPE.ZERO:
				res ~= KEYWORD_NAME[KEYWORD.ZERO];
				break;
			case TYPE.ONE:
				res ~= KEYWORD_NAME[KEYWORD.ONE];
				break;
			case TYPE.ID:
				res ~= id[0];
				break;
			case TYPE.IF0:
				res ~= KEYWORD_NAME[KEYWORD.OPEN];
				res ~= KEYWORD_NAME[KEYWORD.IF0];
				res ~= e[0].toString ();
				res ~= e[1].toString ();
				res ~= e[2].toString ();
				res ~= KEYWORD_NAME[KEYWORD.CLOSE];
				break;
			case TYPE.FOLD:
				res ~= KEYWORD_NAME[KEYWORD.OPEN];
				res ~= KEYWORD_NAME[KEYWORD.FOLD];
				res ~= e[0].toString ();
				res ~= e[1].toString ();
				res ~= KEYWORD_NAME[KEYWORD.OPEN];
				res ~= KEYWORD_NAME[KEYWORD.LAMBDA];
				res ~= KEYWORD_NAME[KEYWORD.OPEN];
				res ~= id[0];
				res ~= id[1];
				res ~= KEYWORD_NAME[KEYWORD.CLOSE];
				res ~= e[2].toString ();
				res ~= KEYWORD_NAME[KEYWORD.CLOSE];
				res ~= KEYWORD_NAME[KEYWORD.CLOSE];
				break;
			case TYPE.OP1:
				res ~= KEYWORD_NAME[KEYWORD.OPEN];
				res ~= OP1_NAME[op];
				res ~= e[0].toString ();
				res ~= KEYWORD_NAME[KEYWORD.CLOSE];
				break;
			case TYPE.OP2:
				res ~= KEYWORD_NAME[KEYWORD.OPEN];
				res ~= OP2_NAME[op];
				res ~= e[0].toString ();
				res ~= e[1].toString ();
				res ~= KEYWORD_NAME[KEYWORD.CLOSE];
				break;
			case TYPE.NONE:
				enforce (false);
				break;
		}
		string res_str;
		foreach (c; res)
		{
			res_str ~= ' ';
			res_str ~= c;
		}
		return res_str [1..$];
	}

	string toPrettyString () const
	{
		string res;
		final switch (type)
		{
			case TYPE.PROGRAM:
				res ~= "f (%s) = %s".format (id[0],
				       e[0].toPrettyString ());
				break;
			case TYPE.ZERO:
				res ~= "0";
				break;
			case TYPE.ONE:
				res ~= "1";
				break;
			case TYPE.ID:
				res ~= id[0];
				break;
			case TYPE.IF0:
				res ~= "(ifzero %s then %s else %s)"
				    .format (e[0].toPrettyString (),
				             e[1].toPrettyString (),
				             e[2].toPrettyString ());
				break;
			case TYPE.FOLD:
				res ~= ("(fold %s init %s with " ~
				        "g (%s, %s) = %s)").format
				    (e[0].toPrettyString (),
				     e[1].toPrettyString (),
				     id[0],
				     id[1],
				     e[2].toPrettyString ());
				break;
			case TYPE.OP1:
				res ~= OP1_NAME[op] ~ " " ~
				       e[0].toPrettyString;
				break;
			case TYPE.OP2:
				res ~= "(%s %s %s)"
				       .format (e[0].toPrettyString,
				                OP2_NAME[op],
				                e[1].toPrettyString);
				break;
			case TYPE.NONE:
				enforce (false);
				break;
		}
		return res;
	}
}
