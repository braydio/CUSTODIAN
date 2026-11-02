class Turret:
    def __init__(self, damage, effective_output=1.0):
        self.damage = damage
        self.effective_output = max(0.0, min(1.0, effective_output))
        self.base_fire_interval = 2.0
        self.cooldown = 0.0

    def activate(self, enemies):
        if self.effective_output <= 0.0:
            return
        if self.cooldown > 0.0:
            self.cooldown = max(0.0, self.cooldown - 1.0)
            return
        if self.effective_output < 0.2:
            self.cooldown = self.base_fire_interval
            return

        shot_damage = self.damage * self.effective_output
        for e in enemies:
            if e.alive:
                print(f"Turret fires at {e.name} for {shot_damage:.2f} damage")
                e.take_damage(shot_damage)
                self.cooldown = self.base_fire_interval / self.effective_output
                break  # first-come-first-served
