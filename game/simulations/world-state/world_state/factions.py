import random

IDEOLOGIES = [
    ("Preservationists", "Preservationist", "reclaim archived knowledge"),
    ("Iconoclasts", "Iconoclast", "erase relic systems"),
    ("Cult Mechanists", "Cult Mechanist", "awaken machine relics"),
    ("Expansionists", "Expansionist", "seize operational territory"),
    ("Continuity Wardens", "Continuity Warden", "seal forbidden tech"),
    ("Reliquary Brokers", "Reliquary Broker", "extract tradable data"),
]

FORMS = [
    ("humans", "human"),
    ("post-humans", "post-human"),
    ("bio-engineered remnants", "bio-remnant"),
    ("autonomous warforms", "warform"),
    ("hybrid scavenger constructs", "scavenger-construct"),
    ("sleeper drones", "sleeper-drone"),
    ("void-wrecked crews", "void-crew"),
]

TECH_EXPRESSIONS = [
    ("crude kinetic weapons", "kinetic"),
    ("ritualized tech misuse", "ritual-tech"),
    ("reverse-engineered relics", "relic"),
    ("elegant but fragile systems", "elegant"),
    ("industrial scrap rigs", "industrial"),
    ("signal-weave interference", "signal"),
]

DOCTRINES = [
    ("attritional pressure", "attrition"),
    ("precision raids", "precision"),
    ("overwhelm in waves", "waves"),
    ("stealth and sabotage", "sabotage"),
    ("ritual siege", "ritual"),
    ("probe then withdraw", "probe"),
]

SIGNATURES = [
    ("static-chatter spikes", "chatter"),
    ("synchronized light cutouts", "blackout"),
    ("irradiated residue", "radiation"),
    ("cold-reactor traces", "cryogenic"),
    ("ion-scorched entry points", "ion"),
    ("magnetic dust trails", "magnetic"),
]

TARGET_PRIORITIES = [
    ("command relays", "command"),
    ("power conduits", "power"),
    ("fabrication lines", "fabrication"),
    ("sensor towers", "sensor"),
    ("data cores", "data"),
    ("fuel stores", "fuel"),
]


def _weighted_choice(rng, items):
    total = sum(weight for _, weight in items)
    roll = rng.uniform(0, total)
    upto = 0.0
    for item, weight in items:
        upto += weight
        if roll <= upto:
            return item
    return items[-1][0]


def build_faction_profile(rng=None):
    rng = rng or random

    ideology_full, ideology_short, ideology_goal = rng.choice(IDEOLOGIES)
    form_full, form_short = rng.choice(FORMS)
    tech_full, tech_short = rng.choice(TECH_EXPRESSIONS)
    doctrine_full, doctrine_short = rng.choice(DOCTRINES)
    signature_full, signature_short = rng.choice(SIGNATURES)

    aggression = _weighted_choice(
        rng,
        [
            ("low", 2),
            ("measured", 4),
            ("high", 3),
            ("feral", 1),
        ],
    )
    cohesion = _weighted_choice(
        rng,
        [
            ("fractured", 2),
            ("disciplined", 4),
            ("fanatical", 2),
        ],
    )
    target_full, target_short = rng.choice(TARGET_PRIORITIES)

    label = f"{ideology_short} {form_short} cell"
    return {
        "ideology": ideology_full,
        "ideology_short": ideology_short,
        "ideology_goal": ideology_goal,
        "form": form_full,
        "form_short": form_short,
        "tech_expression": tech_full,
        "tech_short": tech_short,
        "doctrine": doctrine_full,
        "doctrine_short": doctrine_short,
        "signature": signature_full,
        "signature_short": signature_short,
        "aggression": aggression,
        "cohesion": cohesion,
        "target_priority": target_full,
        "target_short": target_short,
        "label": label,
    }
