Config = {}

Config.Locale = 'pl_pl'

Config.SellDistance = 2.5
Config.TargetIcon = 'fas fa-hand-holding-usd'
Config.newTargetIcon = 'fas fa-hand-holding-usd'
Config.SellCooldown = 1 -- seconds
Config.MinSellAmount = 2
Config.MaxSellAmount = 15
Config.MaxPriceModifier = 1.5 -- keep it to one decimal point
Config.DealDuration = 5000 -- ms
Config.Prop = 'prop_coke_block_01'
Config.Bone = 'SKEL_L_Hand'
Config.Drugs = {
    -- ['name of the drug'] = price
    ['meth'] = 100,
    ['coke'] = 200,
    ['weed'] = 100
}

Config.BlacklistedPeds = {
    'u_m_m_bankman'
}

Config.EventType = {
    ['undercover_cop'] = 0.0,
    ['no_pay'] = 1.0,
    ['over_pay'] = 0.0,
    ['dissmisive'] = 0.0,
    ['normal'] = 0.0
}