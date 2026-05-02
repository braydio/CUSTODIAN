unarmed_stance_right: 6 frames sprite at 48x64
    This is like, a combat ready state for unarmed attacks.
    The operator is facing right with a crouched stance
    There are 6 frames, the operator with a subtle breathing and slight vertical motion across frames
    Largest movement is the final frame with the operator at the lowest stance in the animation (3-4px vertical drop)
    Hands held just above waist height, rear hand slightly outstretched
    front hand in a defensive position -- this could be unarmed block loop could also be unarmed "combat ready" state animation
    6 Frames
    
melee_stance: 8 frames sprite at 48x64
    This is not quite a combat stance but it was made with a melee weapon prop.
    so it supports an equipped melee weapon held relaxedly in one hand
    Although it might be better used as a lead-in to unarmed block or otherwise directional action
    Animation frame 1 is slightly left-facing then frame 2 begins the rotation to face right
    Animation frame 4 rotation is complete and sprite is facing slightly right
    Frame 4-5 static, right facing, then frame 6 begins rotation back
    Frame 8 sprite is facing left again and static matches frame 1
    EXAMPLE: From facing neutral/down > face slightly right direction use frames 2-3-4 for most movement
    To animate a full Facing slgiht left > face slight right : frame 1-2-3-4 and for opposite ,5-6-7-8
    This could be a transitional animation maybe per above
