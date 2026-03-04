class Sector:
    def __init__(self, name, sector_type):
        self.name = name
        self.type = sector_type
        self.enemies = []
        self.defenses = []

    def has_hostiles(self):
        return any(e.alive for e in self.enemies)
