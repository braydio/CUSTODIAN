import random

IDEOLOGIES = [
    ("Preservationists", "Preservationist"),
    ("Iconoclasts", "Iconoclast"),
    ("Cult Mechanists", "Cult Mechanist"),
    ("Expansionists", "Expansionist"),
]

FORMS = [
    ("humans", "human"),
    ("post-humans", "post-human"),
    ("bio-engineered remnants", "bio-remnant"),
    ("autonomous warforms", "warform"),
    ("hybrid scavenger constructs", "scavenger-construct"),
]

TECH_EXPRESSIONS = [
    ("crude kinetic weapons", "kinetic"),
    ("ritualized tech misuse", "ritual-tech"),
    ("reverse-engineered relics", "relic"),
    ("elegant but fragile systems", "elegant"),
]


def build_faction_profile(rng=None):
    rng = rng or random
    ideology_full, ideology_short = rng.choice(IDEOLOGIES)
    form_full, form_short = rng.choice(FORMS)
    tech_full, tech_short = rng.choice(TECH_EXPRESSIONS)

    label = f"{ideology_short} {form_short} cell"
    return {
        "ideology": ideology_full,
        "ideology_short": ideology_short,
        "form": form_full,
        "form_short": form_short,
        "tech_expression": tech_full,
        "tech_short": tech_short,
        "label": label,
    }
