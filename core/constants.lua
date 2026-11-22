local Constants = {}

Constants.Combat = {
    PLAYER_CRIT_CHANCE = 10,
    ENEMY_CRIT_CHANCE = 5,
    CRIT_MULTIPLIER = 2,
    DEFEND_MULTIPLIER = 0.5,
    MIN_DAMAGE = 1
}

Constants.Progression = {
    XP_BASE = 80,
    XP_SCALE = 1.30,
    HP_SCALE = 1.15,
    MANA_SCALE = 1.14,
    ATK_SCALE = 1.17,
    DEF_SCALE = 1.12
}

Constants.EnemyScaling = {
    HP_PER_WAVE = 0.08,
    ATK_PER_WAVE = 0.04,
    DEF_PER_WAVE = 0.03,
    REWARD_PER_WAVE = 0.10
}

Constants.Player = {
    BASE_HP = 50,
    BASE_MANA = 25,
    BASE_ATK = 1,
    BASE_DEF = 1,
    BASE_GOLD = 100
}

return Constants