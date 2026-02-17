"""Structured assault introspection ledger."""

from dataclasses import dataclass, field


@dataclass
class AssaultTickRecord:
    tick: int
    targeted_sector: str
    target_weight: float
    assault_strength: float
    defense_mitigation: float
    building_destroyed: str | None = None
    failure_triggered: bool = False
    note: str | None = None


@dataclass
class AssaultLedger:
    active: bool = False
    ticks: list[AssaultTickRecord] = field(default_factory=list)


def append_record(state, record: AssaultTickRecord) -> None:
    state.assault_ledger.active = True
    state.assault_ledger.ticks.append(record)
    if len(state.assault_ledger.ticks) > 2000:
        del state.assault_ledger.ticks[:-2000]
