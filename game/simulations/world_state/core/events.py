import random

from .config import (
    CHAIN_CHANCE,
    CRITICAL_SECTORS,
    EVENT_CHANCE_BASE,
    EVENT_CHANCE_MAX,
    EVENT_CHANCE_PER_THREAT,
    HANGAR_EVENT_CHANCE_BONUS,
    SECTOR_TAGS,
)
from .effects import add_global_effect, add_sector_effect
from .factions import build_faction_profile


class AmbientEvent:
    def __init__(
        self,
        name,
        min_threat,
        weight,
        cooldown,
        sector_filter,
        effect,
        chains=None,
    ):
        self.name = name
        self.min_threat = min_threat
        self.weight = weight
        self.cooldown = cooldown
        self.sector_filter = sector_filter
        self.effect = effect
        self.chains = chains or []

    def can_trigger(self, state, sector):
        if state.ambient_threat < self.min_threat:
            return False
        if not self.sector_filter(sector):
            return False
        last = state.event_cooldowns[(self.name, sector.name)]
        return state.time - last >= self.cooldown


def probe_perimeter(state, sector):
    sector.alertness += 0.4
    sector.occupied = True


def trip_explosive(state, sector):
    sector.damage += 0.6
    sector.alertness += 0.8
    sector.power = max(0.5, sector.power - 0.2)
    state.ambient_threat += 0.3


def wiring_sabotage(state, sector):
    sector.damage += 0.4
    sector.power = max(0.3, sector.power - 0.3)
    sector.alertness += 1.0
    if state.assault_timer:
        state.assault_timer = max(6, state.assault_timer - 4)


def fuel_fire(state, sector):
    sector.damage += 1.2
    sector.alertness += 2.0
    state.ambient_threat += 0.8


def tunnel_infiltration(state, sector):
    sector.alertness += 1.5
    sector.occupied = True


def sensor_jam(state, sector):
    sector.alertness += 0.9
    sector.power = max(0.4, sector.power - 0.2)
    state.ambient_threat += 0.2


def data_siphon(state, sector):
    sector.alertness += 1.4
    state.ambient_threat += 0.5
    if sector.name in CRITICAL_SECTORS:
        sector.damage += 0.3


def goal_sector_breach(state, sector):
    sector.damage += 0.8
    sector.alertness += 1.6
    state.ambient_threat += 0.6


def power_brownout(state, sector):
    sector.alertness += 0.6
    sector.power = max(0.4, sector.power - 0.2)
    add_sector_effect(sector, "power_drain", severity=1.4, decay=0.04)


def structural_fatigue(state, sector):
    sector.damage += 0.4
    sector.alertness += 0.5
    add_sector_effect(sector, "structural_fatigue", severity=1.6, decay=0.03)


def coolant_leak(state, sector):
    sector.damage += 0.2
    sector.alertness += 0.7
    add_sector_effect(sector, "coolant_leak", severity=1.3, decay=0.03)


def signal_blackout(state, sector):
    sector.alertness += 0.8
    add_sector_effect(sector, "sensor_blackout", severity=1.5, decay=0.04)
    add_global_effect(state, "signal_interference", severity=1.2, decay=0.03)


def doctrine_panic(state, sector):
    sector.alertness += 1.0
    add_sector_effect(sector, "alertness_residue", severity=1.1, decay=0.02)
    add_global_effect(state, "supply_strain", severity=1.0, decay=0.02)


def _sector_has_any(sector, tags):
    sector_tags = SECTOR_TAGS.get(sector.name, set())
    return bool(sector_tags.intersection(tags))


def _build_sector_filter(tags=None, min_damage=None, max_power=None):
    def _filter(sector):
        if tags and not _sector_has_any(sector, tags):
            return False
        if min_damage is not None and sector.damage < min_damage:
            return False
        if max_power is not None and sector.power > max_power:
            return False
        return True

    return _filter


EVENT_ARCHETYPES = [
    {
        "key": "perimeter_probe",
        "min_threat": 0.2,
        "weight": 4,
        "cooldown": 12,
        "tags": {"gate", "approach", "perimeter"},
        "effect": probe_perimeter,
        "name_template": "{label} perimeter probe",
        "chain_templates": ["{label} tunnel movement detected"],
    },
    {
        "key": "sabotage_charge",
        "min_threat": 1.2,
        "weight": 3,
        "cooldown": 18,
        "tags": {"maintenance", "yard", "hangar", "service"},
        "effect": trip_explosive,
        "name_template": "{label} sabotage charge",
        "chain_templates": ["Secondary fires in adjacent conduit"],
    },
    {
        "key": "conduit_cut",
        "min_threat": 3.0,
        "weight": 2,
        "cooldown": 22,
        "tags": {"power", "fuel", "maintenance", "service"},
        "max_power": 0.85,
        "effect": wiring_sabotage,
        "name_template": "{label} conduit cut ({tech})",
        "chain_templates": ["Backup grid drops", "Signal relays desync"],
    },
    {
        "key": "power_brownout",
        "min_threat": 1.6,
        "weight": 2,
        "cooldown": 20,
        "tags": {"power", "maintenance", "terminal"},
        "effect": power_brownout,
        "name_template": "{label} induced brownout",
        "chain_templates": ["Auto-turret cycle stutters"],
    },
    {
        "key": "structural_fatigue",
        "min_threat": 2.2,
        "weight": 2,
        "cooldown": 24,
        "tags": {"hangar", "maintenance", "yard"},
        "min_damage": 0.2,
        "effect": structural_fatigue,
        "name_template": "{label} structural fatigue surge",
        "chain_templates": ["Brace supports buckling"],
    },
    {
        "key": "coolant_leak",
        "min_threat": 2.6,
        "weight": 2,
        "cooldown": 26,
        "tags": {"fuel", "power", "hangar"},
        "effect": coolant_leak,
        "name_template": "{label} coolant leak",
        "chain_templates": ["Thermal alarms trip"],
    },
    {
        "key": "fuel_fire",
        "min_threat": 4.5,
        "weight": 1,
        "cooldown": 40,
        "tags": {"fuel"},
        "effect": fuel_fire,
        "name_template": "{label} ignition in fuel stores",
        "chain_templates": ["Containment seals breach"],
    },
    {
        "key": "tunnel_infiltration",
        "min_threat": 3.5,
        "weight": 2,
        "cooldown": 30,
        "tags": {"tunnels"},
        "effect": tunnel_infiltration,
        "name_template": "{label} tunnel breach",
        "chain_templates": ["Service access compromised"],
    },
    {
        "key": "sensor_jam",
        "min_threat": 2.0,
        "weight": 2,
        "cooldown": 20,
        "tags": {"radar", "sensor", "tower"},
        "effect": sensor_jam,
        "name_template": "{label} sensor jamming",
        "chain_templates": ["Command uplink flickers"],
    },
    {
        "key": "signal_blackout",
        "min_threat": 3.2,
        "weight": 1,
        "cooldown": 34,
        "tags": {"command", "radar", "sensor", "tower"},
        "effect": signal_blackout,
        "name_template": "{label} signal blackout",
        "chain_templates": ["Fallback protocols engaged"],
    },
    {
        "key": "data_siphon",
        "min_threat": 4.0,
        "weight": 1,
        "cooldown": 32,
        "tags": {"command", "terminal", "data"},
        "effect": data_siphon,
        "name_template": "{label} data siphon attempt",
        "chain_templates": ["Archive checksum mismatch"],
    },
    {
        "key": "doctrine_panic",
        "min_threat": 4.2,
        "weight": 1,
        "cooldown": 36,
        "tags": {"command", "terminal"},
        "effect": doctrine_panic,
        "name_template": "{label} doctrine panic burst",
        "chain_templates": ["Field teams hesitate"],
    },
    {
        "key": "goal_breach",
        "min_threat": 5.0,
        "weight": 1,
        "cooldown": 45,
        "tags": {"goal", "construction"},
        "effect": goal_sector_breach,
        "name_template": "{label} incursion at goal sector",
        "chain_templates": ["Reconstruction line locked"],
    },
]


def build_event_catalog(state):
    if state.event_catalog is not None:
        return state.event_catalog

    profile = state.faction_profile or build_faction_profile()
    state.faction_profile = profile

    label = profile["label"]
    tech = profile["tech_short"]

    events = []
    for archetype in EVENT_ARCHETYPES:
        name = archetype["name_template"].format(label=label, tech=tech)
        chains = [
            template.format(label=label, tech=tech)
            for template in archetype.get("chain_templates", [])
        ]
        sector_filter = _build_sector_filter(
            tags=archetype.get("tags"),
            min_damage=archetype.get("min_damage"),
            max_power=archetype.get("max_power"),
        )
        events.append(
            AmbientEvent(
                name=name,
                min_threat=archetype["min_threat"],
                weight=archetype["weight"],
                cooldown=archetype["cooldown"],
                sector_filter=sector_filter,
                effect=archetype["effect"],
                chains=chains,
            )
        )

    state.event_catalog = events
    return events


def maybe_trigger_event(state):
    candidates = []
    events = build_event_catalog(state)
    for sector in state.sectors.values():
        for event in events:
            if event.can_trigger(state, sector):
                candidates.append((event, sector))

    if not candidates:
        return

    chance = EVENT_CHANCE_BASE + state.ambient_threat * EVENT_CHANCE_PER_THREAT
    hangar = state.sectors.get("HANGAR")
    if hangar and hangar.damage >= 1.0:
        chance += HANGAR_EVENT_CHANCE_BONUS
    chance = min(chance, EVENT_CHANCE_MAX)
    if random.random() > chance:
        return

    weighted = []
    for event, sector in candidates:
        weighted.extend([(event, sector)] * event.weight)

    event, sector = random.choice(weighted)

    print(f"[Event] {event.name} in {sector.name}")
    event.effect(state, sector)
    sector.last_event = event.name
    state.event_cooldowns[(event.name, sector.name)] = state.time

    for chained_name in event.chains:
        if random.random() < CHAIN_CHANCE:
            print(f"  -> Consequence: {chained_name}")
