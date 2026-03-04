from __future__ import annotations

from dataclasses import dataclass, field
from random import Random
from time import time
from typing import Optional
from uuid import UUID, uuid5


_DIFFICULTY_WEIGHTS = {
    "victory_complexity": 0.35,
    "objective_scope": 0.20,
    "threat_profile": 0.20,
    "resource_signal": 0.15,
    "environmental_constraints": 0.10,
}

_DIFFICULTY_DESCRIPTORS = [
    (0.0, 0.2, "LOW CONFIDENCE OPERATION"),
    (0.2, 0.4, "UNSTABLE CONDITIONS"),
    (0.4, 0.6, "HIGH RISK ENGAGEMENT"),
    (0.6, 0.8, "SEVERE OPERATIONAL COMPLEXITY"),
    (0.8, 999.0, "EXTINCTION-LEVEL UNKNOWN"),
]

_BIOMES = [
    "RUINED URBAN",
    "ARID WASTELAND",
    "SUBTERRANEAN COMPLEX",
    "BIO-OVERGROWN ZONE",
    "ORBITAL DERELICT",
]

_ENVIRONMENTAL_TAGS = [
    "LOW VISIBILITY",
    "RADIATION",
    "BIOCONTAMINATION",
    "SIGNAL ECHO",
    "STRUCTURAL INSTABILITY",
]

_THREAT_TYPES = [
    "MUTATED ORGANICS",
    "AUTONOMOUS WAR MACHINES",
    "POST-HUMAN FACTIONS",
    "FERAL DEFENSE SYSTEMS",
    "UNKNOWN ANOMALY",
]

_THREAT_AGGRESSION = {
    "MUTATED ORGANICS": 0.55,
    "AUTONOMOUS WAR MACHINES": 0.75,
    "POST-HUMAN FACTIONS": 0.6,
    "FERAL DEFENSE SYSTEMS": 0.5,
    "UNKNOWN ANOMALY": 0.8,
}

_REWARD_ARCHETYPES = [
    "ARCHIVAL KNOWLEDGE",
    "SCHEMATICS",
    "LOST TECHNOLOGY",
    "BIOLOGICAL DATA",
    "CULTURAL RECORDS",
]

_VICTORY_MODIFIER_TYPES = [
    "TIME UNCERTAINTY",
    "FRAGMENTED INTEL",
    "SECONDARY OBJECTIVES",
    "SIGNAL DEGRADATION",
    "HIDDEN DEPENDENCIES",
]

_PRIMARY_VICTORY_TYPES = [
    "RECOVERY",
    "STABILIZATION",
    "CONTAINMENT",
    "NEUTRALIZATION",
]

_REWARD_STANDARD_UNLOCKS = {
    "ARCHIVAL KNOWLEDGE": [
        "RECON_SIGNAL_FILTER_V1",
        "ARCHIVE_LOSS_TOLERANCE +1",
    ],
    "SCHEMATICS": [
        "SECONDARY_OBJECTIVE_DETECTION",
    ],
    "LOST TECHNOLOGY": [
        "RECON_SIGNAL_FILTER_V1",
    ],
    "BIOLOGICAL DATA": [
        "SECONDARY_OBJECTIVE_DETECTION",
    ],
    "CULTURAL RECORDS": [
        "ARCHIVE_LOSS_TOLERANCE +1",
    ],
}

_PRIMARY_COMPLETION_THRESHOLD = 0.7
_UNKNOWN_FIELDS = [
    "region.similarity_hint",
    "threat_profile.dominant_threat",
    "threat_profile.secondary_threats",
    "victory_conditions.modifiers",
    "resource_profile.availability_index",
    "resource_profile.artifact_density_estimate",
    "reward_profile.archetype",
]

_SCENARIO_NAMESPACE = UUID("7fd16fa3-8fdd-4f26-9f5c-e4cf8b1a5f72")


@dataclass
class Region:
    region_id: str
    similarity_hint: Optional[str]


@dataclass
class Difficulty:
    score: float
    descriptor: str


@dataclass
class Setting:
    biome: str
    environmental_tags: list[str]


@dataclass
class ThreatProfile:
    dominant_threat: Optional[str]
    secondary_threats: list[str]
    signal_confidence: float


@dataclass
class VictoryModifier:
    type: str
    severity: float


@dataclass
class VictoryCondition:
    type: str
    target_descriptor: str
    completion_threshold: float


@dataclass
class VictoryConditions:
    primary: VictoryCondition
    modifiers: list[VictoryModifier]


@dataclass
class OptionalSubvictories:
    discovered: bool
    possible_types: list[str]


@dataclass
class ResourceProfile:
    availability_index: Optional[float]
    artifact_density_estimate: Optional[float]


@dataclass
class Uncertainty:
    unknown_fields: list[str]
    noise_level: float


@dataclass
class RewardScalingRules:
    base_multiplier: float
    secondary_weight: float
    partial_multiplier: float


@dataclass
class RewardProfile:
    archetype: Optional[str]
    scaling_rules: RewardScalingRules


@dataclass
class CampaignScenario:
    id: UUID
    seed: int
    region: Region
    difficulty: Difficulty
    setting: Setting
    threat_profile: ThreatProfile
    victory_conditions: VictoryConditions
    optional_subvictories: OptionalSubvictories
    resource_profile: ResourceProfile
    uncertainty: Uncertainty
    reward_profile: RewardProfile


@dataclass
class SecondaryVictories:
    achieved: list[str]
    failed: list[str]


@dataclass
class Losses:
    archive_loss: int
    structural_loss: bool


@dataclass
class ExtractedArtifacts:
    type_tags: list[str]
    integrity_scores: list[float]


@dataclass
class DerivedInsights:
    inferred_tech_lineages: list[str]
    historical_estimates: dict
    region_id: str
    difficulty_descriptor: str


@dataclass
class CampaignOutcome:
    scenario_id: UUID
    result: str
    primary_victory_completion: float
    secondary_victories: SecondaryVictories
    losses: Losses
    extracted_artifacts: ExtractedArtifacts
    derived_insights: DerivedInsights
    seed: int


@dataclass
class ArchiveEntry:
    category: str
    confidence: str
    notes: dict


@dataclass
class CampaignRecord:
    scenario_id: UUID
    region_id: str
    outcome: str
    difficulty_descriptor: str
    timestamp: int
    notes: dict


@dataclass
class HubState:
    seed: int
    capability_flags: dict
    unlocked_scenario_archetypes: set[str] = field(default_factory=set)
    unlocked_victory_modifiers: set[str] = field(default_factory=set)
    knowledge_archive: list[ArchiveEntry] = field(default_factory=list)
    campaign_history: list[CampaignRecord] = field(default_factory=list)

    def snapshot(self) -> dict:
        return {
            "seed": self.seed,
            "capability_flags": dict(self.capability_flags),
            "unlocked_scenario_archetypes": sorted(self.unlocked_scenario_archetypes),
            "unlocked_victory_modifiers": sorted(self.unlocked_victory_modifiers),
            "knowledge_archive": [
                {
                    "category": entry.category,
                    "confidence": entry.confidence,
                    "notes": entry.notes,
                }
                for entry in self.knowledge_archive
            ],
            "campaign_history": [
                {
                    "scenario_id": str(record.scenario_id),
                    "region_id": record.region_id,
                    "outcome": record.outcome,
                    "difficulty_descriptor": record.difficulty_descriptor,
                    "timestamp": record.timestamp,
                    "notes": record.notes,
                }
                for record in self.campaign_history
            ],
        }

    @classmethod
    def from_snapshot(cls, data: dict) -> "HubState":
        hub = cls(
            seed=int(data.get("seed", 0)),
            capability_flags=dict(data.get("capability_flags", {})),
            unlocked_scenario_archetypes=set(data.get("unlocked_scenario_archetypes", [])),
            unlocked_victory_modifiers=set(data.get("unlocked_victory_modifiers", [])),
        )
        hub.knowledge_archive = [
            ArchiveEntry(
                category=entry.get("category", "UNKNOWN"),
                confidence=entry.get("confidence", "PARTIAL"),
                notes=entry.get("notes", {}),
            )
            for entry in data.get("knowledge_archive", [])
        ]
        hub.campaign_history = [
            CampaignRecord(
                scenario_id=UUID(record.get("scenario_id", str(_SCENARIO_NAMESPACE))),
                region_id=record.get("region_id", "UNKNOWN"),
                outcome=record.get("outcome", "UNKNOWN"),
                difficulty_descriptor=record.get("difficulty_descriptor", "UNKNOWN"),
                timestamp=int(record.get("timestamp", 0)),
                notes=record.get("notes", {}),
            )
            for record in data.get("campaign_history", [])
        ]
        return hub


@dataclass
class RewardArchetype:
    unlocks: list[str]
    standardized_unlocks: list[str]
    archive_entries: list[str]


def _scenario_id_from_seed(seed: int) -> UUID:
    return uuid5(_SCENARIO_NAMESPACE, str(seed))


def _calculate_difficulty_score(inputs: dict) -> float:
    total = 0.0
    for key, weight in _DIFFICULTY_WEIGHTS.items():
        total += weight * inputs.get(key, 0.0)
    return max(0.0, min(total, 1.0))


def _map_difficulty_descriptor(score: float) -> str:
    for low, high, label in _DIFFICULTY_DESCRIPTORS:
        if low <= score < high:
            return label
    return _DIFFICULTY_DESCRIPTORS[-1][2]


def _generate_region(rng: Random) -> Region:
    region_id = f"RX-{rng.randint(100, 999)}{rng.choice(['A', 'B', 'C'])}"
    similarity_hint = rng.choice([None, "FRINGE", "CORE", "LEGACY", "FRAGMENTED"])
    return Region(region_id=region_id, similarity_hint=similarity_hint)


def _generate_setting(rng: Random) -> Setting:
    biome = rng.choice(_BIOMES)
    tags = rng.sample(_ENVIRONMENTAL_TAGS, k=rng.randint(1, 3))
    return Setting(biome=biome, environmental_tags=tags)


def _generate_threats(rng: Random) -> ThreatProfile:
    dominant = rng.choice(_THREAT_TYPES)
    secondary = rng.sample([t for t in _THREAT_TYPES if t != dominant], k=2)
    confidence = rng.uniform(0.35, 0.85)
    return ThreatProfile(
        dominant_threat=dominant,
        secondary_threats=secondary,
        signal_confidence=confidence,
    )


def _generate_victory_conditions(rng: Random) -> VictoryConditions:
    primary_type = rng.choice(_PRIMARY_VICTORY_TYPES)
    primary = VictoryCondition(
        type=primary_type,
        target_descriptor=f"{primary_type} TARGET",
        completion_threshold=rng.uniform(0.55, 0.8),
    )
    modifiers = [
        VictoryModifier(type=modifier, severity=rng.uniform(0.3, 0.8))
        for modifier in rng.sample(_VICTORY_MODIFIER_TYPES, k=rng.randint(1, 2))
    ]
    return VictoryConditions(primary=primary, modifiers=modifiers)


def _generate_optional_subvictories(rng: Random) -> OptionalSubvictories:
    types = rng.sample(_VICTORY_MODIFIER_TYPES, k=rng.randint(1, 3))
    return OptionalSubvictories(discovered=False, possible_types=types)


def _generate_resources(rng: Random) -> ResourceProfile:
    return ResourceProfile(
        availability_index=rng.uniform(0.2, 0.9),
        artifact_density_estimate=rng.uniform(0.1, 0.8),
    )


def _generate_uncertainty(rng: Random) -> Uncertainty:
    noise_level = rng.uniform(0.2, 0.8)
    unknown_count = max(1, int(noise_level * len(_UNKNOWN_FIELDS)))
    unknown_fields = rng.sample(_UNKNOWN_FIELDS, k=unknown_count)
    return Uncertainty(unknown_fields=unknown_fields, noise_level=noise_level)


def _select_reward_archetype(rng: Random) -> RewardProfile:
    return RewardProfile(
        archetype=rng.choice(_REWARD_ARCHETYPES),
        scaling_rules=RewardScalingRules(
            base_multiplier=1.0,
            secondary_weight=0.5,
            partial_multiplier=0.6,
        ),
    )


def _difficulty_inputs_from_scenario(
    scenario: CampaignScenario,
) -> dict:
    victory_complexity = min(1.0, (len(scenario.victory_conditions.modifiers) + 1) / 4)
    objective_scope = min(1.0, (1 + len(scenario.optional_subvictories.possible_types)) / 5)
    dominant = scenario.threat_profile.dominant_threat or "UNKNOWN ANOMALY"
    threat_profile = _THREAT_AGGRESSION.get(dominant, 0.6)
    threat_profile = (threat_profile + (1.0 - scenario.threat_profile.signal_confidence)) / 2
    availability = scenario.resource_profile.availability_index or 0.5
    scarcity = 1.0 - availability
    resource_signal = (scarcity + scenario.uncertainty.noise_level) / 2
    environmental = min(1.0, len(scenario.setting.environmental_tags) / 5)
    return {
        "victory_complexity": victory_complexity,
        "objective_scope": objective_scope,
        "threat_profile": threat_profile,
        "resource_signal": resource_signal,
        "environmental_constraints": environmental,
    }


def _mask_unknown_fields(scenario: CampaignScenario) -> CampaignScenario:
    unknowns = set(scenario.uncertainty.unknown_fields)
    region = scenario.region
    if "region.similarity_hint" in unknowns:
        region = Region(region_id=region.region_id, similarity_hint=None)

    threat = scenario.threat_profile
    if "threat_profile.dominant_threat" in unknowns:
        threat = ThreatProfile(
            dominant_threat=None,
            secondary_threats=threat.secondary_threats,
            signal_confidence=threat.signal_confidence,
        )
    if "threat_profile.secondary_threats" in unknowns:
        threat = ThreatProfile(
            dominant_threat=threat.dominant_threat,
            secondary_threats=[],
            signal_confidence=threat.signal_confidence,
        )

    victory = scenario.victory_conditions
    if "victory_conditions.modifiers" in unknowns:
        victory = VictoryConditions(primary=victory.primary, modifiers=[])

    resources = scenario.resource_profile
    if "resource_profile.availability_index" in unknowns:
        resources = ResourceProfile(
            availability_index=None,
            artifact_density_estimate=resources.artifact_density_estimate,
        )
    if "resource_profile.artifact_density_estimate" in unknowns:
        resources = ResourceProfile(
            availability_index=resources.availability_index,
            artifact_density_estimate=None,
        )

    reward_profile = scenario.reward_profile
    if "reward_profile.archetype" in unknowns:
        reward_profile = RewardProfile(
            archetype=None,
            scaling_rules=reward_profile.scaling_rules,
        )

    return CampaignScenario(
        id=scenario.id,
        seed=scenario.seed,
        region=region,
        difficulty=scenario.difficulty,
        setting=scenario.setting,
        threat_profile=threat,
        victory_conditions=victory,
        optional_subvictories=scenario.optional_subvictories,
        resource_profile=resources,
        uncertainty=scenario.uncertainty,
        reward_profile=reward_profile,
    )


def _probabilistic_value(value, recon_depth: int):
    if recon_depth >= 3:
        return value
    if value is None:
        return None
    if isinstance(value, float):
        return round(value * 5) / 5
    if isinstance(value, str):
        return f"LIKELY {value}"
    if isinstance(value, list):
        if value and isinstance(value[0], VictoryModifier):
            return [
                VictoryModifier(
                    type=f"LIKELY {modifier.type}",
                    severity=round(modifier.severity * 5) / 5,
                )
                for modifier in value
            ]
        return [f"LIKELY {entry}" for entry in value]
    return value


def _generate_full_scenario(hub: HubState, seed: int) -> CampaignScenario:
    rng = Random(seed)
    scenario = CampaignScenario(
        id=_scenario_id_from_seed(seed),
        seed=seed,
        region=_generate_region(rng),
        difficulty=Difficulty(score=0.0, descriptor=""),
        setting=_generate_setting(rng),
        threat_profile=_generate_threats(rng),
        victory_conditions=_generate_victory_conditions(rng),
        optional_subvictories=_generate_optional_subvictories(rng),
        resource_profile=_generate_resources(rng),
        uncertainty=_generate_uncertainty(rng),
        reward_profile=_select_reward_archetype(rng),
    )

    inputs = _difficulty_inputs_from_scenario(scenario)
    score = _calculate_difficulty_score(inputs)
    scenario.difficulty = Difficulty(score=score, descriptor=_map_difficulty_descriptor(score))

    return scenario


def generate_campaign_offer(hub: HubState, seed: int) -> CampaignScenario:
    return _mask_unknown_fields(_generate_full_scenario(hub, seed))


def generate_campaign_offers(hub: HubState, seed: int, count: int = 3) -> list[CampaignScenario]:
    rng = Random(seed)
    offers = []
    for _ in range(max(1, count)):
        offers.append(generate_campaign_offer(hub, rng.randint(1, 1_000_000)))
    return offers


def apply_recon(hub: HubState, scenario: CampaignScenario) -> CampaignScenario:
    recon_depth = int(hub.capability_flags.get("recon_depth", 0))
    if recon_depth <= 0 or not scenario.uncertainty.unknown_fields:
        return scenario

    truth = _generate_full_scenario(hub, scenario.seed)
    unknown_fields = list(scenario.uncertainty.unknown_fields)
    remove_count = min(recon_depth, len(unknown_fields))
    resolved_fields = set(unknown_fields[:remove_count])
    remaining_fields = unknown_fields[remove_count:]

    region = scenario.region
    if "region.similarity_hint" in resolved_fields:
        region = Region(
            region_id=region.region_id,
            similarity_hint=_probabilistic_value(truth.region.similarity_hint, recon_depth),
        )

    threat = scenario.threat_profile
    if "threat_profile.dominant_threat" in resolved_fields:
        threat = ThreatProfile(
            dominant_threat=_probabilistic_value(truth.threat_profile.dominant_threat, recon_depth),
            secondary_threats=threat.secondary_threats,
            signal_confidence=threat.signal_confidence,
        )
    if "threat_profile.secondary_threats" in resolved_fields:
        threat = ThreatProfile(
            dominant_threat=threat.dominant_threat,
            secondary_threats=_probabilistic_value(truth.threat_profile.secondary_threats, recon_depth),
            signal_confidence=threat.signal_confidence,
        )

    victory = scenario.victory_conditions
    if "victory_conditions.modifiers" in resolved_fields:
        victory = VictoryConditions(
            primary=victory.primary,
            modifiers=_probabilistic_value(truth.victory_conditions.modifiers, recon_depth),
        )

    resources = scenario.resource_profile
    if "resource_profile.availability_index" in resolved_fields:
        resources = ResourceProfile(
            availability_index=_probabilistic_value(truth.resource_profile.availability_index, recon_depth),
            artifact_density_estimate=resources.artifact_density_estimate,
        )
    if "resource_profile.artifact_density_estimate" in resolved_fields:
        resources = ResourceProfile(
            availability_index=resources.availability_index,
            artifact_density_estimate=_probabilistic_value(
                truth.resource_profile.artifact_density_estimate, recon_depth
            ),
        )

    reward_profile = scenario.reward_profile
    if "reward_profile.archetype" in resolved_fields:
        reward_profile = RewardProfile(
            archetype=_probabilistic_value(truth.reward_profile.archetype, recon_depth),
            scaling_rules=reward_profile.scaling_rules,
        )

    noise_level = max(0.0, scenario.uncertainty.noise_level - 0.1 * recon_depth)
    uncertainty = Uncertainty(unknown_fields=remaining_fields, noise_level=noise_level)

    optional_subvictories = scenario.optional_subvictories
    if hub.capability_flags.get("subvictory_detection"):
        optional_subvictories = OptionalSubvictories(
            discovered=True,
            possible_types=optional_subvictories.possible_types,
        )

    return CampaignScenario(
        id=scenario.id,
        seed=scenario.seed,
        region=region,
        difficulty=scenario.difficulty,
        setting=scenario.setting,
        threat_profile=threat,
        victory_conditions=victory,
        optional_subvictories=optional_subvictories,
        resource_profile=resources,
        uncertainty=uncertainty,
        reward_profile=reward_profile,
    )


def _reward_archetype_from_outcome(outcome: CampaignOutcome) -> str:
    tags = [tag.upper() for tag in outcome.extracted_artifacts.type_tags]
    if any("BIO" in tag for tag in tags):
        return "BIOLOGICAL DATA"
    if any("SCHEMATIC" in tag for tag in tags):
        return "SCHEMATICS"
    if any("TECH" in tag for tag in tags):
        return "LOST TECHNOLOGY"
    if any("CULTURAL" in tag for tag in tags):
        return "CULTURAL RECORDS"
    return "ARCHIVAL KNOWLEDGE"


def _reward_definition(archetype: str) -> RewardArchetype:
    standardized = _REWARD_STANDARD_UNLOCKS.get(archetype, [])
    return RewardArchetype(
        unlocks=[],
        standardized_unlocks=standardized,
        archive_entries=[archetype],
    )


def apply_campaign_outcome(hub: HubState, outcome: CampaignOutcome) -> HubState:
    archetype = _reward_archetype_from_outcome(outcome)
    reward = _reward_definition(archetype)
    primary_completion = outcome.primary_victory_completion
    rng = Random(outcome.seed)

    if outcome.result == "COMPLETE" and primary_completion >= _PRIMARY_COMPLETION_THRESHOLD:
        for unlock in reward.standardized_unlocks:
            if unlock.startswith("ARCHIVE_LOSS_TOLERANCE"):
                hub.capability_flags["archive_loss_tolerance"] = (
                    hub.capability_flags.get("archive_loss_tolerance", 0) + 1
                )
            else:
                hub.unlocked_scenario_archetypes.add(unlock)
        for category in reward.archive_entries:
            hub.knowledge_archive.append(
                ArchiveEntry(category=category, confidence="CONFIRMED", notes={})
            )

    elif outcome.result == "PARTIAL":
        if rng.random() < 0.5 * primary_completion:
            for unlock in reward.standardized_unlocks:
                if unlock.startswith("ARCHIVE_LOSS_TOLERANCE"):
                    hub.capability_flags["archive_loss_tolerance"] = (
                        hub.capability_flags.get("archive_loss_tolerance", 0) + 1
                    )
                else:
                    hub.unlocked_scenario_archetypes.add(unlock)
        for category in reward.archive_entries:
            hub.knowledge_archive.append(
                ArchiveEntry(category=category, confidence="PARTIAL", notes={})
            )

    elif outcome.result == "FAILURE":
        loss = int(outcome.losses.archive_loss)
        hub.capability_flags["archive_loss_tolerance"] = max(
            0, hub.capability_flags.get("archive_loss_tolerance", 0) - loss
        )

    elif outcome.result == "ABANDONED":
        loss = int(outcome.losses.archive_loss)
        hub.capability_flags["archive_loss_tolerance"] = max(
            0, hub.capability_flags.get("archive_loss_tolerance", 0) - loss
        )

    if outcome.secondary_victories.achieved:
        secondary_value = len(outcome.secondary_victories.achieved) * 0.5 * primary_completion
        if secondary_value >= 0.5:
            hub.capability_flags["subvictory_detection"] = True

    hub.campaign_history.append(
        CampaignRecord(
            scenario_id=outcome.scenario_id,
            region_id=outcome.derived_insights.region_id,
            outcome=outcome.result,
            difficulty_descriptor=outcome.derived_insights.difficulty_descriptor,
            timestamp=int(time()),
            notes={"secondary_value": primary_completion},
        )
    )

    return hub
