from .config import (
    CHAIN_CHANCE,
    CRITICAL_SECTORS,
    EVENT_CHANCE_BASE,
    EVENT_CHANCE_MAX,
    EVENT_CHANCE_PER_THREAT,
    HANGAR_EVENT_CHANCE_BONUS,
    SECTOR_TAGS,
)
from .assault_ledger import AssaultTickRecord, append_record
from .detection import detection_probability
from .event_records import EventInstance
from .effects import add_global_effect, add_sector_effect
from .factions import build_faction_profile
from .power_load import blackout_event_chance_bonus, blackout_event_weight_multiplier


class AmbientEvent:
    def __init__(
        self,
        key,
        name,
        category,
        min_threat,
        weight,
        cooldown,
        sector_filter,
        effect,
        chains=None,
    ):
        self.key = key
        self.name = name
        self.category = category
        self.min_threat = min_threat
        self.weight = weight
        self.cooldown = cooldown
        self.sector_filter = sector_filter
        self.effect = effect
        self.chains = chains or []

    def can_trigger(self, state, sector):
        if state.ambient_threat < self.min_threat:
            return False
        if self.sector_filter is not None and not self.sector_filter(sector):
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


def power_blackout(state, sector):
    surveillance_level = int(state.policies.surveillance_coverage)
    mitigation = 1.0 - (surveillance_level * 0.08)
    mitigation = max(0.6, mitigation)
    before_power = sector.power
    sector.alertness += 0.6
    sector.power = max(0.4, sector.power - (0.2 * mitigation))
    add_sector_effect(sector, "power_drain", severity=1.4 * mitigation, decay=0.04)
    if state.assault_trace_enabled:
        append_record(
            state,
            AssaultTickRecord(
                tick=state.time,
                targeted_sector=sector.id,
                target_weight=0.0,
                assault_strength=0.0,
                defense_mitigation=0.0,
                failure_triggered=False,
                note=f"BLACKOUT:POWER_DELTA={before_power:.2f}->{sector.power:.2f}",
            ),
        )


def structural_fatigue(state, sector):
    sector.damage += 0.4
    sector.alertness += 0.5
    add_sector_effect(sector, "structural_fatigue", severity=1.6, decay=0.03)


def coolant_leak(state, sector):
    sector.damage += 0.2
    sector.alertness += 0.7
    add_sector_effect(sector, "coolant_leak", severity=1.3, decay=0.03)


def signal_blackout(state, sector):
    surveillance_level = int(state.policies.surveillance_coverage)
    severity_mult = max(0.65, 1.0 - (surveillance_level * 0.07))
    sector.alertness += 0.8
    add_sector_effect(sector, "sensor_blackout", severity=1.5 * severity_mult, decay=0.04)
    add_global_effect(state, "signal_interference", severity=1.2 * severity_mult, decay=0.03)


def doctrine_panic(state, sector):
    sector.alertness += 1.0
    add_sector_effect(sector, "alertness_residue", severity=1.1, decay=0.02)
    add_global_effect(state, "supply_strain", severity=1.0, decay=0.02)


def quiet_signal(_state, _sector):
    return


def microfracture_detected(state, sector):
    sector.damage += 0.2
    sector.alertness += 0.4
    add_sector_effect(sector, "structural_fatigue", severity=1.1, decay=0.02)


def thermal_intake_anomaly(state, sector):
    sector.damage += 0.15
    sector.alertness += 0.5
    add_sector_effect(sector, "coolant_leak", severity=1.0, decay=0.02)


def radiation_burst_unknown(state, sector):
    sector.alertness += 0.6
    add_global_effect(state, "signal_interference", severity=0.8, decay=0.02)


def fabrication_queue_delay(state, sector):
    sector.alertness += 0.5
    add_global_effect(state, "supply_strain", severity=0.9, decay=0.02)


def archive_checksum_mismatch(state, sector):
    sector.alertness += 0.7
    if sector.name == "ARCHIVE":
        sector.damage += 0.2


def defense_grid_recalibration(state, sector):
    sector.alertness += 0.6
    sector.power = max(0.6, sector.power - 0.1)


EVENT_CATEGORIES = {
    "QUIET": {"weight": 0.35, "min_threat": 0.0},
    "ENVIRONMENTAL": {"weight": 0.20, "min_threat": 0.8},
    "INFRASTRUCTURE": {"weight": 0.15, "min_threat": 1.5},
    "RECON": {"weight": 0.15, "min_threat": 1.0},
    "HOSTILE": {"weight": 0.15, "min_threat": 2.0},
}

EVENT_KEY_TO_CATEGORY = {
    "perimeter_probe": "RECON",
    "sabotage_charge": "HOSTILE",
    "conduit_cut": "HOSTILE",
    "power_blackout": "INFRASTRUCTURE",
    "structural_fatigue": "ENVIRONMENTAL",
    "coolant_leak": "ENVIRONMENTAL",
    "fuel_fire": "HOSTILE",
    "tunnel_infiltration": "HOSTILE",
    "sensor_jam": "RECON",
    "signal_blackout": "RECON",
    "data_siphon": "HOSTILE",
    "doctrine_panic": "HOSTILE",
    "goal_breach": "HOSTILE",
    "quiet_perimeter_stable": "QUIET",
    "quiet_night_cycle": "QUIET",
    "quiet_atmospheric": "QUIET",
    "microfracture_detected": "ENVIRONMENTAL",
    "thermal_intake_anomaly": "ENVIRONMENTAL",
    "radiation_burst_unknown": "ENVIRONMENTAL",
    "fabrication_queue_delay": "INFRASTRUCTURE",
    "archive_checksum_mismatch": "INFRASTRUCTURE",
    "defense_grid_recalibration": "INFRASTRUCTURE",
}


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
        "key": "power_blackout",
        "min_threat": 1.6,
        "weight": 2,
        "cooldown": 20,
        "tags": {"power", "maintenance", "terminal"},
        "effect": power_blackout,
        "name_template": "{label} induced blackout",
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
    {
        "key": "quiet_perimeter_stable",
        "min_threat": 0.0,
        "weight": 2,
        "cooldown": 8,
        "effect": quiet_signal,
        "name_template": "Perimeter stable. No external movement.",
    },
    {
        "key": "quiet_night_cycle",
        "min_threat": 0.0,
        "weight": 1,
        "cooldown": 10,
        "effect": quiet_signal,
        "name_template": "Night cycle nominal. All sectors reporting.",
    },
    {
        "key": "quiet_atmospheric",
        "min_threat": 0.0,
        "weight": 1,
        "cooldown": 12,
        "effect": quiet_signal,
        "name_template": "Atmospheric processors cycling within tolerance.",
    },
    {
        "key": "microfracture_detected",
        "min_threat": 1.2,
        "weight": 2,
        "cooldown": 24,
        "tags": {"hangar", "storage", "gateway"},
        "effect": microfracture_detected,
        "name_template": "Microfracture detected in sector plating",
        "chain_templates": ["Plating resonance increasing"],
    },
    {
        "key": "thermal_intake_anomaly",
        "min_threat": 1.0,
        "weight": 2,
        "cooldown": 22,
        "tags": {"power", "hangar", "fabrication"},
        "effect": thermal_intake_anomaly,
        "name_template": "Thermal anomaly in intake systems",
        "chain_templates": ["Cooling control rerouting"],
    },
    {
        "key": "radiation_burst_unknown",
        "min_threat": 1.8,
        "weight": 1,
        "cooldown": 30,
        "tags": {"comms", "archive", "gateway"},
        "effect": radiation_burst_unknown,
        "name_template": "Radiation burst. Origin unknown.",
        "chain_templates": ["Sensor noise floor elevated"],
    },
    {
        "key": "fabrication_queue_delay",
        "min_threat": 1.6,
        "weight": 2,
        "cooldown": 24,
        "tags": {"fabrication", "storage"},
        "effect": fabrication_queue_delay,
        "name_template": "Fabrication queue delay. Resource contention.",
        "chain_templates": ["Output targets slipping"],
    },
    {
        "key": "archive_checksum_mismatch",
        "min_threat": 1.8,
        "weight": 1,
        "cooldown": 30,
        "tags": {"archive", "comms", "command"},
        "effect": archive_checksum_mismatch,
        "name_template": "Archive checksum mismatch detected",
        "chain_templates": ["Integrity audit flagged"],
    },
    {
        "key": "defense_grid_recalibration",
        "min_threat": 1.6,
        "weight": 2,
        "cooldown": 22,
        "tags": {"defense", "power"},
        "effect": defense_grid_recalibration,
        "name_template": "Defense grid recalibrating",
        "chain_templates": ["Targeting baseline recomputed"],
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
                key=archetype["key"],
                name=name,
                category=EVENT_KEY_TO_CATEGORY.get(archetype["key"], "HOSTILE"),
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
    update_event_context(state)
    selected = select_ambient_event(state)
    if selected is None:
        return
    event, sector = selected

    detection_chance = detection_probability(0.7, state)
    detected = state.rng.random() < detection_chance
    if detected:
        print(f"[Event] {event.name} in {sector.name}")
    else:
        print("[Event] Unattributed signal anomaly")
    event.effect(state, sector)
    sector.last_event = event.name if detected else "Signal anomaly"
    state.event_cooldowns[(event.name, sector.name)] = state.time
    state.tick_events.append(
        EventInstance(
            tick=state.time,
            event_key=event.key,
            event_name=sector.last_event,
            sector=sector.name,
            detected=bool(detected),
        )
    )
    if event.category == "HOSTILE":
        state.ticks_since_hostile = 0

    for chained_name in event.chains:
        if state.rng.random() < CHAIN_CHANCE:
            if detected:
                print(f"  -> Consequence: {chained_name}")


def update_event_context(state) -> None:
    state.ticks_since_assault += 1
    if state.last_assault_tick is not None:
        state.ticks_since_assault = max(0, state.time - state.last_assault_tick)
    elif state.current_assault is not None or state.in_major_assault:
        state.ticks_since_assault = 0

    state.ticks_since_hostile += 1


def _aggregate_power_percent(state) -> float:
    if not state.sectors:
        return 0.0
    avg_power = sum(sector.power for sector in state.sectors.values()) / len(state.sectors)
    return max(0.0, min(100.0, avg_power * 100.0))


def compute_category_weights(state) -> dict[str, float]:
    weights: dict[str, float] = {}
    for category, config in EVENT_CATEGORIES.items():
        if state.ambient_threat < config["min_threat"]:
            continue
        weight = float(config["weight"])

        if state.ticks_since_assault < 5 and category in {"ENVIRONMENTAL", "QUIET"}:
            weight *= 1.4
        if _aggregate_power_percent(state) < 40.0 and category == "INFRASTRUCTURE":
            weight *= 1.5
        if state.ticks_since_hostile > 25 and category == "RECON":
            weight *= 1.5
        if state.last_event_category == category:
            weight *= 0.25

        if weight > 0:
            weights[category] = weight

    total = sum(weights.values())
    if total <= 0:
        return {}
    return {category: value / total for category, value in weights.items()}


def filter_recent_events(candidates, recent_events):
    filtered = []
    recent_names = set(recent_events)
    for event, sector in candidates:
        if event.name not in recent_names:
            filtered.append((event, sector))
    return filtered if filtered else candidates


def select_ambient_event(state):
    candidates = []
    events = build_event_catalog(state)
    category_weights = compute_category_weights(state)
    if not category_weights:
        return None

    chance = EVENT_CHANCE_BASE + state.ambient_threat * EVENT_CHANCE_PER_THREAT
    hangar = state.sectors.get("HANGAR")
    if hangar and hangar.damage >= 1.0:
        chance += HANGAR_EVENT_CHANCE_BONUS
    chance += blackout_event_chance_bonus(state)
    chance = min(chance, EVENT_CHANCE_MAX)
    if state.rng.random() > chance:
        return None

    categories = list(category_weights.keys())
    category_values = [category_weights[category] for category in categories]
    selected_category = state.rng.choices(categories, weights=category_values, k=1)[0]

    for sector in state.sectors.values():
        for event in events:
            if event.category != selected_category:
                continue
            if event.can_trigger(state, sector):
                candidates.append((event, sector))

    candidates = filter_recent_events(candidates, state.recent_events)
    if not candidates:
        return None

    weighted = []
    for event, sector in candidates:
        weight = int(event.weight)
        if event.key == "power_blackout":
            weight *= blackout_event_weight_multiplier(state)
        weighted.extend([(event, sector)] * max(1, weight))

    event, sector = state.rng.choice(weighted)
    state.recent_events.append(event.name)
    state.last_event_category = selected_category
    return event, sector
