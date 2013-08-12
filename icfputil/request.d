module icfputil.request;

import core.sys.windows.windows;
import core.time;

immutable int NUM_REQUESTS = 5;
immutable int TIME = 20 + 1;

TickDuration request_ticks [NUM_REQUESTS];

void init_requests ()
{
	TickDuration cur = TickDuration.currSystemTick ();
	foreach (ref rt; request_ticks)
	{
		rt = cur;
	}
}

void wait_for_request ()
{
	while (true)
	{
		TickDuration cur = TickDuration.currSystemTick ();
		foreach (ref rt; request_ticks)
		{
			if (rt < cur)
			{
				rt = cur + TickDuration (cast (long) (TIME *
				    TickDuration.ticksPerSec));
				return;
			}
		}
		Sleep (100);
	}
}
