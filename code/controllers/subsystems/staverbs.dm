// File contains:
// - statverbs subsystem
// - statverb datum defenation
// - statverb related atom code

SUBSYSTEM_DEF(statverbs)
	name = "statverbs"
	flags = SS_NO_INIT|SS_NO_FIRE

	var/list/all_verbs = list()

/datum/controller/subsystem/statverbs/proc/call_verb(user, target, path, tmp_name)
	var/datum/statverb/SV
	if(isnull(all_verbs[path]))
		all_verbs[path]= new path
	SV = all_verbs[path]
	SV.try_action(user, target, tmp_name)


// Statverb datum //
/datum/statverb
	var/name
	var/required_stat = STAT_MEC
	var/base_range = RANGE_ADJACENT	//maximum distance or RANGE_ADJACENT
	var/minimal_stat = 0


/datum/statverb/proc/try_action(mob/living/user, atom/target, saved_name = "target")
	if(!istype(user))
		return
	if(!(target in view(user)))
		to_chat(user, SPAN_WARNING("You're too far from [saved_name]"))
		return FALSE

	if(base_range == RANGE_ADJACENT)
		if(!target.Adjacent(user))
			to_chat(user, SPAN_WARNING("You should be adjacent to [target]"))
			return FALSE
	else
		if(get_dist(user, target) > base_range)
			to_chat(user, SPAN_WARNING("You're too far from [target]"))
			return FALSE

	if(user.stats.getStat(required_stat) < minimal_stat)
		to_chat(user, SPAN_WARNING("You're not skilled enough in [required_stat]"))
		return FALSE

	action(user, target)

/datum/statverb/proc/action(mob/user, atom/target)



// Atom part //
/atom
	var/list/statverbs

/atom/Initialize()
	. = ..()
	initalize_statverbs()

/atom/Destroy()
	. = ..()
	if(statverbs)
		statverbs.Cut()

/atom/proc/initalize_statverbs()
	var/list/paths = statverbs
	statverbs = new
	for(var/path in paths)
		add_statverb(path)

/atom/proc/add_statverb(path)
	if(!statverbs)
		statverbs = new
	var/datum/statverb/SV = path
	statverbs[initial(SV.required_stat)] = path

/atom/proc/remove_statverb(path)
	statverbs -= path



/atom/proc/show_stat_verbs()
	if(statverbs && statverbs.len)
		. = "Apply: "
		for(var/stat in statverbs)
			. += " <a href='?src=\ref[src];statverb=[stat];obj_name=[src]'>[stat]</a>"

/atom/Topic(href, href_list)
	. = ..()
	if(.)
		return
	if(href_list["statverb"])
		SSstatverbs.call_verb(usr, src, src.statverbs[href_list["statverb"]], href_list["obj_name"])


// Example

/turf/simulated/floor/initalize_statverbs()
	if(flooring && (flooring.flags & TURF_REMOVE_CROWBAR))
		add_statverb(/datum/statverb/remove_plating)

/datum/statverb/remove_plating
	name = "Remove plating"
	required_stat = STAT_ROB
	minimal_stat  = STAT_LEVEL_ADEPT

/datum/statverb/remove_plating/action(mob/user, turf/simulated/floor/target)
	if(target.flooring && target.flooring.flags & TURF_REMOVE_CROWBAR)
		user.visible_message(
			SPAN_DANGER("[user] grabbed the edges of [target] with their hands!"),
			"You grab the edges of [target] with your hands"
		)
		if(do_mob(user, target, target.flooring.removal_time * 3))
			user.visible_message(
				SPAN_DANGER("[user] roughly tore plating off from [target]!"),
				"You tore the plating off from [target]"
			)
			target.make_plating(FALSE)
		else
			var/target_name = target ? "[target]" : "the floor"
			user.visible_message(
				SPAN_DANGER("[user] stopped tearing the plating off from [target_name]!"),
				"You stop tearing plating off from [target_name]"
			)

/obj/machinery/computer/rdconsole/initalize_statverbs()
	if(access_research_equipment in req_access)
		add_statverb(/datum/statverb/hack_console)

/datum/statverb/hack_console
	name = "Hack console"
	required_stat = STAT_COG
	minimal_stat  = STAT_LEVEL_ADEPT

/datum/statverb/hack_console/action(mob/user, obj/machinery/computer/rdconsole/target)
	if(target.hacked == 1)
		user.visible_message(
			SPAN_WARNING("[target] is already hacked!")
		)
		return
	if(target.hacked == 0)
		var/timer = 220 - (user.stats.getStat(STAT_COG) * 2)
		var/datum/repeating_sound/keyboardsound = new(30, timer, 0.15, target, "keyboard", 80, 1)
		user.visible_message(
			SPAN_DANGER("[user] begins hacking into [target]!"),
			"You start hacking the access requirement on [target]"
		)
		if(do_mob(user, target, timer))
			keyboardsound.stop()
			keyboardsound = null
			target.req_access.Cut()
			target.hacked = 1
			user.visible_message(
				SPAN_DANGER("[user] breaks the access encryption on [target]!"),
				"You break the access encryption on [target]"
			)
		else
			keyboardsound.stop()
			keyboardsound = null
			var/target_name = target ? "[target]" : "the research console"
			user.visible_message(
				SPAN_DANGER("[user] stopped hacking into [target_name]!"),
				"You stop hacking into [target_name]."
			)

