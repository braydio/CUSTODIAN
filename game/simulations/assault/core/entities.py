class Enemy:
    def __init__(self, name, enemy_type, hp, morale, sector):
        self.name = name
        self.type = enemy_type
        self.hp = hp
        self.morale = morale
        self.sector = sector
        self.alive = True

    def take_damage(self, dmg):
        self.hp -= dmg
        self.morale -= dmg * 0.5
        print(
            f"{self.name} takes {dmg} damage " f"(HP={self.hp}, Morale={self.morale})"
        )
        if self.hp <= 0:
            self.alive = False
            print(f"{self.name} is killed")
