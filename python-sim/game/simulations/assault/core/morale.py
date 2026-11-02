def should_retreat(enemy):
    return enemy.morale <= 10 and enemy.alive
