///Datum for basic mobs to define what they can attack.
/datum/targetting_datum

///Returns true or false depending on if the target can be attacked by the mob
/datum/targetting_datum/proc/can_attack(mob/living/living_mob, atom/target, vision_range)
	return

///Returns something the target might be hiding inside of
/datum/targetting_datum/proc/find_hidden_mobs(mob/living/living_mob, atom/target)
	var/atom/target_hiding_location
	if(istype(target.loc, /obj/structure/closet) || istype(target.loc, /obj/machinery/disposal) || istype(target.loc, /obj/machinery/sleeper))
		target_hiding_location = target.loc
	return target_hiding_location

/datum/targetting_datum/basic
	/// When we do our basic faction check, do we look for exact faction matches?
	var/check_factions_exactly = FALSE
	/// Minimum status to attack living beings
	var/stat_attack = CONSCIOUS
	///Whether we care for seeing the target or not
	var/ignore_sight = FALSE

/datum/targetting_datum/basic/can_attack(mob/living/living_mob, atom/the_target, vision_range)
	var/datum/ai_controller/basic_controller/our_controller = living_mob.ai_controller

	if(isnull(our_controller))
		return FALSE

	if(isturf(the_target) || isnull(the_target)) // bail out on invalids
		return FALSE

	if(isobj(the_target.loc))
		var/obj/container = the_target.loc
		if(container.resistance_flags & INDESTRUCTIBLE)
			return FALSE

	if(ismob(the_target)) //Target is in godmode, ignore it.
		if(living_mob.loc == the_target)
			return FALSE // We've either been eaten or are shapeshifted, let's assume the latter because we're still alive
		var/mob/M = the_target
		if(M.status_flags & GODMODE)
			return FALSE

	if(!ignore_sight && !can_see(living_mob, the_target, vision_range)) //Target has moved behind cover and we have lost line of sight to it
		return FALSE

	if(living_mob.see_invisible < the_target.invisibility) //Target's invisible to us, forget it
		return FALSE

	if(isturf(living_mob.loc) && isturf(the_target.loc) && living_mob.z != the_target.z) // z check will always fail if target is in a mech or pawn is shapeshifted or jaunting
		return FALSE

	if(isliving(the_target)) //Targeting vs living mobs
		var/mob/living/living_target = the_target
		if(faction_check(our_controller, living_mob, living_target))
			return FALSE
		if(living_target.stat > stat_attack)
			return FALSE

		return TRUE

	if(ismecha(the_target)) //Targeting vs mechas
		var/obj/vehicle/sealed/mecha/M = the_target
		for(var/occupant in M.occupants)
			if(can_attack(living_mob, occupant)) //Can we attack any of the occupants?
				return TRUE

	if(istype(the_target, /obj/machinery/porta_turret)) //Cringe turret! kill it!
		var/obj/machinery/porta_turret/P = the_target
		if(P.in_faction(living_mob)) //Don't attack if the turret is in the same faction
			return FALSE
		if(P.has_cover && !P.raised) //Don't attack invincible turrets
			return FALSE
		if(P.machine_stat & BROKEN) //Or turrets that are already broken
			return FALSE
		return TRUE

	return FALSE

/// Returns true if the mob and target share factions
/datum/targetting_datum/basic/proc/faction_check(datum/ai_controller/controller, mob/living/living_mob, mob/living/the_target)
	if (controller.blackboard[BB_ALWAYS_IGNORE_FACTION] || controller.blackboard[BB_TEMPORARILY_IGNORE_FACTION])
		return FALSE
	return living_mob.faction_check_mob(the_target, exact_match = check_factions_exactly)

/// Subtype more forgiving for items.
/// Careful, this can go wrong and keep a mob hyper-focused on an item it can't lose aggro on
/datum/targetting_datum/basic/allow_items

/datum/targetting_datum/basic/allow_items/can_attack(mob/living/living_mob, atom/the_target, vision_range)
	. = ..()
	if(isitem(the_target))
		// trust fall exercise
		return TRUE

/// Subtype which searches for mobs of a size relative to ours
/datum/targetting_datum/basic/of_size
	/// If true, we will return mobs which are smaller than us. If false, larger.
	var/find_smaller = TRUE
	/// If true, we will return mobs which are the same size as us.
	var/inclusive = TRUE

/datum/targetting_datum/basic/of_size/can_attack(mob/living/owner, atom/target, vision_range)
	if(!isliving(target))
		return FALSE
	. = ..()
	if(!.)
		return FALSE

	var/mob/living/mob_target = target
	if(inclusive && owner.mob_size == mob_target.mob_size)
		return TRUE
	if(owner.mob_size > mob_target.mob_size)
		return find_smaller
	return !find_smaller

// This is just using the default values but the subtype makes it clearer
/datum/targetting_datum/basic/of_size/ours_or_smaller

/datum/targetting_datum/basic/of_size/larger
	find_smaller = FALSE
	inclusive = FALSE

/datum/targetting_datum/basic/attack_until_dead
	stat_attack = HARD_CRIT

/datum/targetting_datum/basic/attack_even_if_dead
	stat_attack = DEAD
