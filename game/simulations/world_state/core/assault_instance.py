# world_state/assault_instance.py


class AssaultInstance:
    """
    Represents a single major assault as a concrete object.

    This is produced by the world simulation and later resolved
    either abstractly (world pressure) or tactically (combat).
    """

    def __init__(
        self,
        faction_profile,
        target_sectors,
        threat_budget,
        start_time,
        *,
        readiness: float = 0.0,
        threat_scale: float = 1.0,
    ):
        self.faction_profile = faction_profile
        self.target_sectors = target_sectors  # list of SectorState
        self.base_threat_budget = max(10, int(threat_budget))
        readiness = max(0.0, min(1.0, float(readiness)))
        scaled = self.base_threat_budget * (1.1 - readiness) * max(0.1, float(threat_scale))
        self.threat_budget = max(10, int(round(scaled)))
        self.readiness = readiness
        self.start_time = start_time

        self.ticks_elapsed = 0
        self.resolved = False
        self.enemy_groups = self._build_enemy_groups()
        self.entry_phases = self._build_entry_phases()
        self.duration_ticks = max(10, 6 + len(self.entry_phases) * 2)

    def tick(self):
        self.ticks_elapsed += 1

    def _build_enemy_groups(self):
        primary = self._primary_enemy_type()
        secondary = self._secondary_enemy_type(primary)

        budget = max(10, int(self.threat_budget))
        groups = []
        group_index = 1

        while budget > 0:
            enemy_type = primary if group_index % 2 == 1 else secondary
            cost, hp, morale = self._enemy_costs(enemy_type)
            count = max(1, min(5, budget // cost))
            if count == 0:
                break
            groups.append(
                {
                    "group": group_index,
                    "enemy_type": enemy_type,
                    "count": count,
                    "hp": hp,
                    "morale": morale,
                    "label": f"{enemy_type.title()} Group {group_index}",
                }
            )
            budget -= count * cost
            group_index += 1

        return groups

    def _build_entry_phases(self):
        phases = []
        if not self.target_sectors:
            return phases

        wave_ticks = [0, 2, 5, 8]
        sector_names = [sector.name for sector in self.target_sectors]

        for index, group in enumerate(self.enemy_groups):
            tick = wave_ticks[index % len(wave_ticks)]
            sector = sector_names[index % len(sector_names)]
            phases.append({"tick": tick, "sector": sector, "group": group})

        return phases

    def spawn_at_tick(self, tick, sector_lookup):
        spawned = 0
        for phase in self.entry_phases:
            if phase["tick"] != tick:
                continue
            sector = sector_lookup.get(phase["sector"])
            if sector is None:
                continue
            group = phase["group"]
            for index in range(group["count"]):
                enemy = self._build_enemy(
                    group,
                    index=index + 1,
                    sector=sector,
                )
                if enemy is None:
                    continue
                sector.enemies.append(enemy)
                spawned += 1
        return spawned

    def _primary_enemy_type(self):
        ideology = (self.faction_profile or {}).get("ideology", "")
        if "Cult" in ideology or "Preservation" in ideology or "Continuity" in ideology:
            return "zealot"
        if "Iconoclast" in ideology:
            return "iconoclast"
        return "raider"

    def _secondary_enemy_type(self, primary):
        doctrine = (self.faction_profile or {}).get("doctrine", "")
        if "sabotage" in doctrine or "stealth" in doctrine:
            return "iconoclast"
        return "raider" if primary != "raider" else "zealot"

    def _enemy_costs(self, enemy_type):
        if enemy_type == "zealot":
            return 6, 18, 24
        if enemy_type == "iconoclast":
            return 8, 22, 20
        return 5, 16, 18

    def _build_enemy(self, group, index, sector):
        try:
            from game.simulations.assault.core.entities import Enemy
            from game.simulations.assault.core.enums import EnemyType
        except ImportError:
            return None

        type_map = {
            "zealot": EnemyType.ZEALOT,
            "iconoclast": EnemyType.ICONOCLAST,
            "raider": EnemyType.RAIDER,
        }
        enemy_type = type_map.get(group["enemy_type"], EnemyType.RAIDER)
        name = f"{group['label']} {index}"
        return Enemy(name, enemy_type, group["hp"], group["morale"], sector)

    def __str__(self):
        sector_names = ", ".join(s.name for s in self.target_sectors)
        return (
            f"AssaultInstance("
            f"Faction={self.faction_profile['label']}, "
            f"Threat={self.threat_budget}, "
            f"Sectors=[{sector_names}], "
            f"StartedAt={self.start_time})"
        )
