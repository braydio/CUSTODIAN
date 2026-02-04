# world_state/assault_outcome.py


class AssaultOutcome:
    """
    Interpreted result of a resolved assault.

    This object translates raw combat results into
    semantic signals the world simulation can act on.
    """

    def __init__(
        self,
        *,
        threat_budget,
        duration,
        spawned,
        killed,
        retreated,
        remaining,
    ):
        self.threat_budget = threat_budget
        self.duration = duration
        self.spawned = spawned
        self.killed = killed
        self.retreated = retreated
        self.remaining = remaining

        self.attacker_loss_ratio = self._calc_attacker_loss_ratio()
        self.defender_pressure = self._calc_defender_pressure()
        self.intensity = self._classify_intensity()
        self.penetration = self._classify_penetration()

    # -------------------------
    # Derived metrics
    # -------------------------

    def _calc_attacker_loss_ratio(self):
        if self.spawned == 0:
            return 0.0
        return (self.killed + self.retreated) / self.spawned

    def _calc_defender_pressure(self):
        """
        Rough proxy for how long and how hard the defenders
        were under stress.
        """
        return self.duration * (1.0 - self.attacker_loss_ratio)

    # -------------------------
    # Semantic classifications
    # -------------------------

    def _classify_intensity(self):
        """
        How hard the assault was overall.
        """
        if self.threat_budget < 40:
            return "low"
        if self.threat_budget < 80:
            return "medium"
        return "high"

    def _classify_penetration(self):
        """
        How much of the assault actually 'got through'.
        """
        if self.remaining == 0:
            return "none"
        if self.attacker_loss_ratio >= 0.7:
            return "partial"
        return "severe"

    # -------------------------
    # Convenience helpers
    # -------------------------

    def was_clean_defense(self):
        return self.penetration == "none"

    def was_costly_defense(self):
        return self.penetration in {"partial", "severe"}

    def __str__(self):
        return (
            f"AssaultOutcome("
            f"intensity={self.intensity}, "
            f"penetration={self.penetration}, "
            f"attacker_loss_ratio={self.attacker_loss_ratio:.2f})"
        )
