# This file is not meant to be attached directly.
# It is a grab bag of examples for instrumenting runtime systems.

# Player damage:
# DevObservatory.log_event(&"player_damage", {
# 	"amount": amount,
# 	"source": source_name,
# 	"position": global_position
# })
# DevObservatory.increment(&"player_damage_events")
# DevObservatory.set_gauge(&"player_health", current_health)

# Player death:
# DevObservatory.log_event(&"player_death", {
# 	"cause": cause,
# 	"position": global_position
# })
# DevObservatory.increment(&"player_deaths")

# Projectile fired:
# DevObservatory.log_event(&"projectile_fired", {
# 	"weapon": weapon_id,
# 	"position": global_position,
# 	"facing": facing
# })
# DevObservatory.increment(&"shots_fired")

# Enemy state:
# DevObservatory.log_event(&"enemy_state_changed", {
# 	"enemy": name,
# 	"from": previous_state,
# 	"to": current_state
# })

# Repair complete:
# DevObservatory.log_event(&"repair_completed", {
# 	"target": repair_target_id,
# 	"sector": sector_id,
# 	"position": global_position
# })
# DevObservatory.increment(&"repairs_completed")
