Right now, this is the end of your tactical combat:

summary = {
    "duration": duration,
    "spawned": 0,
    "killed": 0,
    "retreated": 0,
    "remaining": 0,
}
...
return summary


(from core/assault.py) 

Assault-Sim

And then in world_state/assaults.py, you do this:

summary = resolve_tactical(...)
...
return {
    "result": "repelled",
    "duration": summary["duration"],
    "spawned": summary["spawned"],
    "killed": summary["killed"],
    "retreated": summary["retreated"],
    "remaining": summary["remaining"],
}


This is a leaky abstraction for three reasons:

World logic must understand combat math

World code now “knows” what killed and retreated mean.

Raw counts do not express meaning

10 killed out of 10 ≠ 10 killed out of 50

You cannot tune consequences cleanly

Every future system would re-interpret these numbers differently.

What you actually need is semantic compression:

Combat → Interpretation → World consequence

That middle layer does not exist yet.

That middle layer is AssaultOutcome.

1️⃣ What AssaultOutcome is (and is not)

AssaultOutcome is NOT:

A combat log

A stats dump

A replay record

AssaultOutcome IS:

A verdict about the assault

A lens the world uses to decide consequences

A stable interface between combat and simulation

Think of it like a medical report:

You don’t give the world a cell count

You say: minor injury, critical trauma, near miss
