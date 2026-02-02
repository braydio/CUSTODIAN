from core.entities import Enemy
from core.sectors import Sector
from core.enums import EnemyType, SectorType
from core.defenses import Turret
from core.assault import resolve_assault

terminal = Sector("Terminal", SectorType.PERIPHERAL)
terminal.defenses.append(Turret(damage=5))

terminal.enemies.append(Enemy("Zealot A", EnemyType.ZEALOT, 20, 30, terminal))
terminal.enemies.append(Enemy("Zealot B", EnemyType.ZEALOT, 20, 30, terminal))
terminal.enemies.append(Enemy("Holy Man", EnemyType.ZEALOT, 15, 15, terminal))

resolve_assault([terminal])
