from game.simulations.assault.core.assault import resolve_assault
from game.simulations.assault.core.defenses import Turret
from game.simulations.assault.core.entities import Enemy
from game.simulations.assault.core.enums import EnemyType, SectorType
from game.simulations.assault.core.sectors import Sector

terminal = Sector("Terminal", SectorType.PERIPHERAL)
terminal.defenses.append(Turret(damage=5))

terminal.enemies.append(Enemy("Zealot A", EnemyType.ZEALOT, 20, 30, terminal))
terminal.enemies.append(Enemy("Zealot B", EnemyType.ZEALOT, 20, 30, terminal))
terminal.enemies.append(Enemy("Holy Man", EnemyType.ZEALOT, 15, 15, terminal))

resolve_assault([terminal])
