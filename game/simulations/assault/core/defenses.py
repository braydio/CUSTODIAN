class Turret:
    def __init__(self, damage):
        self.damage = damage

    def activate(self, enemies):
        for e in enemies:
            if e.alive:
                print(f"Turret fires at {e.name} for {self.damage} damage")
                e.take_damage(self.damage)
                break  # first-come-first-served
