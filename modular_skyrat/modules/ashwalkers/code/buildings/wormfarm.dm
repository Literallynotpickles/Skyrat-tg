/obj/structure/wormfarm
	name = "worm farm"
	desc = "A wonderfully dirty barrel where worms can have a happy little life."
	icon = 'modular_skyrat/modules/ashwalkers/icons/structures.dmi'
	icon_state = "wormbarrel"
	density = TRUE
	anchored = FALSE
	/// How many worms can the barrel hold
	var/max_worm = 10
	/// How many worms the barrel is currently holding
	var/current_worm = 0
	/// If the barrel is currently being used by someone
	var/in_use = FALSE
	// The cooldown between each worm "breeding"
	COOLDOWN_DECLARE(worm_timer)

/obj/structure/wormfarm/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)
	COOLDOWN_START(src, worm_timer, 1 MINUTES)

/obj/structure/wormfarm/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

//process is currently only used for making more worms
/obj/structure/wormfarm/process(seconds_per_tick)
	if(!COOLDOWN_FINISHED(src, worm_timer))
		return

	COOLDOWN_START(src, worm_timer, 1 MINUTES)

	if(current_worm < 2 || current_worm >= max_worm)
		return

	current_worm++

/obj/structure/wormfarm/examine(mob/user)
	. = ..()
	. += span_notice("<br>There are currently [current_worm]/[max_worm] worms in the barrel.")
	if(current_worm < max_worm)
		. += span_notice("You can place more worms in the barrel.")
	if(current_worm > 0)
		. += span_notice("You can get fertilizer by feeding the worms food.")

/obj/structure/wormfarm/attack_hand(mob/living/user, list/modifiers)
	if(in_use)
		balloon_alert(user, "currently in use")
		return ..()

	balloon_alert(user, "digging up worms")
	if(!do_after(user, 5 SECONDS, src))
		balloon_alert(user, "stopped digging")
		in_use = FALSE
		return ..()

	if(current_worm <= 0)
		balloon_alert(user, "no worms available")
		in_use = FALSE
		return ..()

	new /obj/item/food/bait/worm(get_turf(src))
	current_worm--
	in_use = FALSE

	return ..()

/obj/structure/wormfarm/attackby(obj/item/attacking_item, mob/user, params)
	//we want to check for worms first because they are a type of food as well...
	if(istype(attacking_item, /obj/item/food/bait/worm))
		if(current_worm >= max_worm)
			balloon_alert(user, "too many worms in the barrel")
			return

		qdel(attacking_item)
		balloon_alert(user, "worm released into barrel")
		current_worm++
		return

	//if it aint a worm, lets check for any other food items
	if(istype(attacking_item, /obj/item/food))
		if(in_use)
			balloon_alert(user, "currently in use")
			return
		in_use = TRUE

		balloon_alert(user, "feeding the worms")
		if(!do_after(user, 5 SECONDS, src))
			balloon_alert(user, "stopped feeding the worms")
			in_use = FALSE
			return

		// if someone has built multiple worm farms, I want to make sure they can't just use one singular piece of food for more than one barrel
		if(!attacking_item)
			in_use = FALSE
			return

		qdel(attacking_item)
		balloon_alert(user, "feeding complete")

		if(current_worm > 0)
			new /obj/item/worm_fertilizer(get_turf(src))

		in_use = FALSE
		return

	//it wasn't a worm, or a piece of food
	return ..()

//produced by feeding worms food and can be ground up for plant nutriment or used directly on ash farming
/obj/item/worm_fertilizer
	name = "worm fertilizer"
	desc = "When you fed your worms, you should have expected this."
	icon = 'modular_skyrat/modules/ashwalkers/icons/misc_tools.dmi'
	icon_state = "fertilizer"
	grind_results = list(/datum/reagent/plantnutriment/eznutriment = 3, /datum/reagent/plantnutriment/left4zednutriment = 3, /datum/reagent/plantnutriment/robustharvestnutriment = 3)
