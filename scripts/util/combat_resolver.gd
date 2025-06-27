class_name CombatResolver

var combat_ratios_table = {
	'1:3': [],
	'1:2': [],
	'1:1': [],
	'2:1': [],
	'3:1': [],
	'4:1': [],
	'5:1': [],
}

func resolve(battle: Battle):
	var attacker = battle.attacker
	var defender = battle.defender
	
	var attacker_AP = attacker.units.reduce(func(acc, unit: ArmyUnit): return acc + unit.attack_power, 0)
	var defender_AP = defender.units.reduce(func(acc, unit: ArmyUnit): return acc + unit.attack_power, 0)
	
	# round to nearest int
	var ratio  = str(round(attacker_AP)) + ":" + str(round(defender_AP))
	
	print('Result ratio: ', ratio)
	# Todo:
	# Create the tables above for the different ratios, you will want an outcome to affect the 2 sides, or depends on the luck
	# Remove the progress bar when combat is resolved 
	# decide on modifiers
