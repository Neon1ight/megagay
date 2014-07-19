/var/const/OPEN = 1
/var/const/CLOSED = 2

#define NORTHCOLD 1
#define NORTHHOT 2
#define SOUTHCOLD 4
#define SOUTHHOT 8
#define WESTCOLD 32
#define WESTHOT 64
#define EASTCOLD 128
#define EASTHOT 256
/* HAHA TOPY PASTAN
/proc/getTemperatureDifferential(var/turf/loc)
	var/mint=16777216;
	var/maxt= 0;
	for(var/dir in cardinal)
		var/turf/simulated/T=get_turf(get_step(loc,dir))
		var/ct=0
		if(T && istype(T) && T.zone)
			var/datum/gas_mixture/environment = T.return_air()
			ct = environment.temperature
		else
			if(istype(T,/turf/simulated))
				continue
		if(ct<mint)mint=ct
		if(ct>maxt)maxt=ct
	if(mint <= T20C - 20)
		return convert_temperature(mint)-convert_temperature(maxt)
	else
		return convert_temperature(maxt)-convert_temperature(mint)
*/
/proc/convert_k2c(var/temp)
	return ((temp - T0C)) // * 1.8) + 32

/proc/convert_c2k(var/temp)
	return ((temp + T0C)) // * 1.8) + 32

/proc/getCardinalTemperatures(var/turf/loc)
	var/list/temps = new/list(4)
	for(var/dir in cardinal)
		var/direction
		switch(dir)
			if(NORTH)
				direction = 1
			if(SOUTH)
				direction = 2
			if(EAST)
				direction = 3
			if(WEST)
				direction = 4
		var/turf/simulated/T=get_turf(get_step(loc,dir))
		if(T && istype(T) && T.zone)
			var/datum/gas_mixture/environment = T.return_air()
			temps[direction] = environment.temperature
		else
			if(istype(T, /turf/simulated))
				temps[direction] = T20C
			else
				temps[direction] = 0
	return temps

#define FIREDOOR_MAX_PRESSURE_DIFF 25 // kPa

/obj/machinery/door/firedoor
	name = "\improper Emergency Shutter"
	desc = "Emergency air-tight shutter, capable of sealing off breached areas."
	icon = 'icons/obj/doors/DoorHazard.dmi'
	icon_state = "door_open"
	req_one_access = list(access_atmospherics, access_engine_equip)
	opacity = 0
	density = 0

	var/blocked = 0
	var/pdiff_alert = 0
	var/pdiff = 0
	var/tdiff_alert = 0
	var/nextstate = null
	var/net_id
	var/list/areas_added
	var/list/users_to_open

/obj/machinery/door/firedoor/New()
	. = ..()
	for(var/obj/machinery/door/firedoor/F in loc)
		if(F != src)
			spawn(1)
				del src
			return .
	var/area/A = get_area(src)
	ASSERT(istype(A))

	A.all_doors.Add(src)
	areas_added = list(A)

	for(var/direction in cardinal)
		A = get_area(get_step(src,direction))
		if(istype(A) && !(A in areas_added))
			A.all_doors.Add(src)
			areas_added += A


/obj/machinery/door/firedoor/Destroy()
	for(var/area/A in areas_added)
		A.all_doors.Remove(src)
	. = ..()


/obj/machinery/door/firedoor/examine()
	set src in view()
	. = ..()
	if(pdiff >= FIREDOOR_MAX_PRESSURE_DIFF)
		usr << "<span class='warning'>WARNING: Current pressure differential is [pdiff]kPa!</span>"
	if(tdiff_alert)
		var/alerts
		var/list/temperatures = getCardinalTemperatures(src.loc)
		for(var/index = 1; index <= temperatures.len; index++)
			var/celsius = convert_k2c(temperatures[index])
			switch(index)
				if(1)
					alerts += "NORTH: "
					if(celsius >= 50 || celsius <= 0)
						alerts += "[celsius]"
					else
						alerts += "NORMAL"
				if(2)
					alerts += " SOUTH: "
					if(celsius >= 50 || celsius <= 0)
						alerts += "[celsius]"
					else
						alerts += "NORMAL"
				if(3)
					alerts += " EAST: "
					if(celsius >= 50 || celsius <= 0)
						alerts += "[celsius]"
					else
						alerts += "NORMAL"
				if(4)
					alerts += " WEST: "
					if(celsius >= 50 || celsius <= 0)
						alerts += "[celsius]"
					else
						alerts += "NORMAL"

		usr << "<span class='warning'>WARNING: Current temperatures are, [alerts] </span>"
	if( islist(users_to_open) && users_to_open.len)
		var/users_to_open_string = users_to_open[1]
		if(users_to_open.len >= 2)
			for(var/i = 2 to users_to_open.len)
				users_to_open_string += ", [users_to_open[i]]"
		usr << "These people have opened \the [src] during an alert: [users_to_open_string]."


/obj/machinery/door/firedoor/Bumped(atom/AM)
	if(p_open || operating)
		return
	if(!density)
		return ..()
	if(istype(AM, /obj/mecha))
		var/obj/mecha/mecha = AM
		if (mecha.occupant)
			var/mob/M = mecha.occupant
			if(world.time - M.last_bumped <= 10) return //Can bump-open one airlock per second. This is to prevent popup message spam.
			M.last_bumped = world.time
			attack_hand(M)
	return 0


/obj/machinery/door/firedoor/power_change()
	if(powered(ENVIRON))
		stat &= ~NOPOWER
	else
		stat |= NOPOWER
	return


/obj/machinery/door/firedoor/attack_hand(mob/user as mob)
	add_fingerprint(user)
	if(operating)
		return//Already doing something.

	if(blocked)
		user << "<span class='warning'>\The [src] is welded solid!</span>"
		return

	if(!allowed(user))
		user << "<span class='warning'>Access denied.</span>"
		return

	var/area/A = get_area(src)
	ASSERT(istype(A))
	if(A.master)
		A = A.master
	var/alarmed = A.air_doors_activated || A.fire

	var/answer = alert(user, "Would you like to [density ? "open" : "close"] this [src.name]?[ alarmed && density ? "\nNote that by doing so, you acknowledge any damages from opening this\n[src.name] as being your own fault, and you will be held accountable under the law." : ""]",\
	"\The [src]", "Yes, [density ? "open" : "close"]", "No")
	if(answer == "No")
		return
	if(user.stat || !user.canmove || user.stunned || user.weakened || user.paralysis || get_dist(src, user) > 1)
		user << "Sorry, you must remain able bodied and close to \the [src] in order to use it."
		return

	var/needs_to_close = 0
	if(density)
		if(alarmed)
			needs_to_close = 1
		spawn()
			open()
	else
		spawn()
			close()

	if(needs_to_close)
		spawn(50)
			if(alarmed)
				nextstate = CLOSED


/obj/machinery/door/firedoor/attackby(obj/item/weapon/C as obj, mob/user as mob)
	add_fingerprint(user)
	if(operating)
		return//Already doing something.
	if(istype(C, /obj/item/weapon/weldingtool))
		var/obj/item/weapon/weldingtool/W = C
		if(W.remove_fuel(0, user))
			blocked = !blocked
			user.visible_message("\red \The [user] [blocked ? "welds" : "unwelds"] \the [src] with \a [W].",\
			"You [blocked ? "weld" : "unweld"] \the [src] with \the [W].",\
			"You hear something being welded.")
			update_icon()
			return

	if(blocked)
		user << "\red \The [src] is welded solid!"
		return

	var/area/A = get_area_master(src)
	ASSERT(istype(A))
	if(A.master)
		A = A.master
	var/alarmed = A.air_doors_activated || A.fire

	if( istype(C, /obj/item/weapon/crowbar) || ( istype(C,/obj/item/weapon/twohanded/fireaxe) && C:wielded == 1 ) )
		if(operating)
			return

		if( blocked && istype(C, /obj/item/weapon/crowbar) )
			user.visible_message("\red \The [user] pries at \the [src] with \a [C], but \the [src] is welded in place!",\
			"You try to pry \the [src] [density ? "open" : "closed"], but it is welded in place!",\
			"You hear someone struggle and metal straining.")
			return

		user.visible_message("\red \The [user] starts to force \the [src] [density ? "open" : "closed"] with \a [C]!",\
				"You start forcing \the [src] [density ? "open" : "closed"] with \the [C]!",\
				"You hear metal strain.")
		if(do_after(user,30))
			if( istype(C, /obj/item/weapon/crowbar) )
				if( stat & (BROKEN|NOPOWER) || !density)
					user.visible_message("\red \The [user] forces \the [src] [density ? "open" : "closed"] with \a [C]!",\
					"You force \the [src] [density ? "open" : "closed"] with \the [C]!",\
					"You hear metal strain, and a door [density ? "open" : "close"].")
			else
				user.visible_message("\red \The [user] forces \the [ blocked ? "welded" : "" ] [src] [density ? "open" : "closed"] with \a [C]!",\
					"You force \the [ blocked ? "welded" : "" ] [src] [density ? "open" : "closed"] with \the [C]!",\
					"You hear metal strain and groan, and a door [density ? "open" : "close"].")
			var/needs_to_close = 0
			if(density)
				if(alarmed)
					needs_to_close = 1
				spawn(0)
					open()
			else
				spawn(0)
					close()
			if(needs_to_close)
				spawn(50)
					if(alarmed)
						nextstate = CLOSED
			return



	// CHECK PRESSURE
/obj/machinery/door/firedoor/process()
	..()

	if(density)
		pdiff = getOPressureDifferential(get_turf(src))


		var/changed = 0
		if(pdiff >= FIREDOOR_MAX_PRESSURE_DIFF)
			if(!pdiff_alert)
				pdiff_alert = 1
				changed = 1 // update_icon()
		else
			if(pdiff_alert)
				pdiff_alert = 0
				changed = 1 // update_icon()
		var/list/temperatures = getCardinalTemperatures(src.loc)
		var/oldtdiff = tdiff_alert
		for(var/index = 1; index <= temperatures.len; index++)
			var/celsius = convert_k2c(temperatures[index])
			switch(index)
				if(1)
					if(celsius >= 50)
						tdiff_alert |= NORTHHOT
					else if(celsius <= 0)
						tdiff_alert |= NORTHCOLD
				if(2)
					if(celsius >= 50)
						tdiff_alert |= SOUTHHOT
					else if(celsius <= 0)
						tdiff_alert |= SOUTHCOLD
				if(3)
					if(celsius >= 50)
						tdiff_alert |= EASTHOT
					else if(celsius <= 0)
						tdiff_alert |= EASTCOLD
				if(4)
					if(celsius >= 50)
						tdiff_alert |= WESTHOT
					else if(celsius <= 0)
						tdiff_alert |= WESTCOLD

		if(oldtdiff != tdiff_alert)
			changed = 1
		if(changed)
			update_icon()

/obj/machinery/door/firedoor/proc/latetoggle()
	if(operating || stat & NOPOWER || !nextstate)
		return
	switch(nextstate)
		if(OPEN)
			nextstate = null
			open()
		if(CLOSED)
			nextstate = null
			close()
	return

/obj/machinery/door/firedoor/close()
	..()
	latetoggle()
	layer = 3.1

/obj/machinery/door/firedoor/open()
	..()
	latetoggle()
	layer = 2.6



/obj/machinery/door/firedoor/door_animate(animation)
	switch(animation)
		if("opening")
			flick("door_opening", src)
		if("closing")
			flick("door_closing", src)
	return


/obj/machinery/door/firedoor/update_icon()
	overlays = 0
	if(density)
		icon_state = "door_closed"
		if(blocked)
			overlays += "welded"
		if(pdiff_alert)
			overlays += "palert"
		if(tdiff_alert)
			if(tdiff_alert & NORTHCOLD)
				overlays += "calert_north"
			if(tdiff_alert & NORTHHOT)
				overlays += "halert_north"
			if(tdiff_alert & SOUTHCOLD)
				overlays += "calert_south"
			if(tdiff_alert & SOUTHHOT)
				overlays += "halert_south"
			if(tdiff_alert & WESTCOLD)
				overlays += "calert_west"
			if(tdiff_alert & WESTHOT)
				overlays += "halert_west"
			if(tdiff_alert & EASTCOLD)
				overlays += "calert_east"
			if(tdiff_alert & EASTHOT)
				overlays += "halert_east"
	else
		icon_state = "door_open"
		if(blocked)
			overlays += "welded_open"
	return


/obj/machinery/door/firedoor/border_only
//These are playing merry hell on ZAS.  Sorry fellas :(
/*
	icon = 'icons/obj/doors/edge_Doorfire.dmi'
	glass = 1 //There is a glass window so you can see through the door
			  //This is needed due to BYOND limitations in controlling visibility
	heat_proof = 1
	air_properties_vary_with_direction = 1

	CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
		if(istype(mover) && mover.checkpass(PASSGLASS))
			return 1
		if(get_dir(loc, target) == dir) //Make sure looking at appropriate border
			if(air_group) return 0
			return !density
		else
			return 1

	CheckExit(atom/movable/mover as mob|obj, turf/target as turf)
		if(istype(mover) && mover.checkpass(PASSGLASS))
			return 1
		if(get_dir(loc, target) == dir)
			return !density
		else
			return 1


	update_nearby_tiles(need_rebuild)
		if(!air_master) return 0

		var/turf/simulated/source = loc
		var/turf/simulated/destination = get_step(source,dir)

		update_heat_protection(loc)

		if(istype(source)) air_master.tiles_to_update += source
		if(istype(destination)) air_master.tiles_to_update += destination
		return 1
*/

/obj/machinery/door/firedoor/multi_tile
	icon = 'icons/obj/doors/DoorHazard2x1.dmi'
	width = 2


/obj/machinery/door/firedoor/multi_tile/triple
	icon = 'icons/obj/doors/DoorHazard3x1.dmi'
	width = 3

//used in the AStar algorithm to determinate if the turf the door is on is passable
/obj/machinery/door/firedoor/CanAStarPass()
	return !density

#undef NORTHCOLD
#undef NORTHHOT
#undef SOUTHCOLD
#undef SOUTHHOT
#undef WESTCOLD
#undef WESTHOT
#undef EASTCOLD
#undef EASTHOT
