/* Tables and Racks
 * Contains:
 *		Tables
 *		Wooden tables
 *		Reinforced tables
 *		Racks
 */


/*
 * Tables
 */

/datum/table_recipe
	var/name = ""
	var/reqs[] = list()
	var/result_path
	var/tools[] = list()
	var/time = 0
	var/parts[] = list()
	var/chem_catalists[] = list()

/datum/table_recipe/IED
	name = "IED"
	result_path = /obj/item/weapon/grenade/iedcasing
	reqs = list(/obj/item/weapon/handcuffs/cable = 1,
				/obj/item/stack/cable_coil = 1,
				/obj/item/device/assembly/igniter = 1,
				/obj/item/weapon/reagent_containers/food/drinks/soda_cans = 1,
				/datum/reagent/fuel = 10)
	time = 80

/datum/table_recipe/stunprod
	name = "Stunprod"
	result_path = /obj/item/weapon/melee/baton/cattleprod
	reqs = list(/obj/item/weapon/handcuffs/cable = 1,
				/obj/item/stack/rods = 1,
				/obj/item/weapon/wirecutters = 1,
				/obj/item/weapon/cell = 1)
	time = 80
	parts = list(/obj/item/weapon/cell = 1)

/datum/table_recipe/ed209
	name = "ED209"
	result_path = /obj/machinery/bot/ed209
	reqs = list(/obj/item/robot_parts/robot_suit = 1,
				/obj/item/clothing/head/helmet = 1,
				/obj/item/clothing/suit/armor/vest = 1,
				/obj/item/robot_parts/l_leg = 1,
				/obj/item/robot_parts/r_leg = 1,
				/obj/item/stack/sheet/metal = 5,
				/obj/item/stack/cable_coil = 5,
				/obj/item/weapon/gun/energy/taser = 1,
				/obj/item/weapon/cell = 1,
				/obj/item/device/assembly/prox_sensor = 1,
				/obj/item/robot_parts/r_arm = 1)
	tools = list(/obj/item/weapon/weldingtool, /obj/item/weapon/screwdriver)
	time = 120

/datum/table_recipe/secbot
	name = "Secbot"
	result_path = /obj/machinery/bot/secbot
	reqs = list(/obj/item/device/assembly/signaler = 1,
				/obj/item/clothing/head/helmet = 1,
				/obj/item/weapon/melee/baton = 1,
				/obj/item/device/assembly/prox_sensor = 1,
				/obj/item/robot_parts/r_arm = 1)
	tools = list(/obj/item/weapon/weldingtool)
	time = 120

/datum/table_recipe/cleanbot
	name = "Cleanbot"
	result_path = /obj/machinery/bot/cleanbot
	reqs = list(/obj/item/weapon/reagent_containers/glass/bucket = 1,
				/obj/item/device/assembly/prox_sensor = 1,
				/obj/item/robot_parts/r_arm = 1)
	time = 80

/datum/table_recipe/floorbot
	name = "Floorbot"
	result_path = /obj/machinery/bot/floorbot
	reqs = list(/obj/item/weapon/storage/toolbox/mechanical = 1,
				/obj/item/stack/tile/plasteel = 1,
				/obj/item/device/assembly/prox_sensor = 1,
				/obj/item/robot_parts/r_arm = 1)
	time = 80

/datum/table_recipe/medbot
	name = "Medbot"
	result_path = /obj/machinery/bot/medbot
	reqs = list(/obj/item/device/healthanalyzer = 1,
				/obj/item/weapon/storage/firstaid = 1,
				/obj/item/device/assembly/prox_sensor = 1,
				/obj/item/robot_parts/r_arm = 1)
	time = 80

/datum/table_recipe/flamethrower
	name = "Flamethrower"
	result_path = /obj/item/weapon/flamethrower
	reqs = list(/obj/item/weapon/weldingtool = 1,
				/obj/item/device/assembly/igniter = 1,
				/obj/item/stack/rods = 2)
	tools = list(/obj/item/weapon/screwdriver)
	time = 20


/obj/structure/table
	name = "table"
	desc = "A square piece of metal standing on four metal legs. It can not move."
	icon = 'icons/obj/structures.dmi'
	icon_state = "table"
	density = 1
	anchored = 1.0
	layer = 2.8
	throwpass = 1	//You can throw objects over this, despite it's density.")
	var/parts = /obj/item/weapon/table_parts
	var/flipped = 0
	var/health = 100
	var/list/table_contents = list()
	var/busy = 0

/obj/structure/table/proc/update_adjacent()
	for(var/direction in list(1,2,4,8,5,6,9,10))
		if(locate(/obj/structure/table,get_step(src,direction)))
			var/obj/structure/table/T = locate(/obj/structure/table,get_step(src,direction))
			T.update_icon()

/obj/structure/table/New()
	..()
	for(var/obj/structure/table/T in src.loc)
		if(T != src)
			del(T)
	update_icon()
	update_adjacent()

/obj/structure/table/Del()
	update_adjacent()
	..()


/obj/structure/table/proc/destroy()
	new parts(loc)
	density = 0
	qdel(src)

/obj/structure/table/MouseDrop(atom/over)
	if(usr.stat || usr.lying || !Adjacent(usr) || (over != usr))
		return
	interact(usr)

/obj/structure/table/proc/check_contents(datum/table_recipe/R)
	check_table()
	main_loop:
		for(var/A in R.reqs)
			for(var/B in table_contents)
				if(ispath(B, A))
					if(table_contents[B] >= R.reqs[A])
						continue main_loop
			return 0
	for(var/A in R.chem_catalists)
		if(table_contents[A] < R.chem_catalists[A])
			return 0
	return 1

/obj/structure/table/proc/check_table()
	table_contents = list()
	for(var/obj/item/I in loc)
		if(istype(I, /obj/item/stack))
			var/obj/item/stack/S = I
			table_contents[I.type] += S.amount
		else
			if(istype(I, /obj/item/weapon/reagent_containers))
				for(var/datum/reagent/R in I.reagents.reagent_list)
					table_contents[R.type] += R.volume

			table_contents[I.type] += 1

/obj/structure/table/proc/check_tools(mob/user, datum/table_recipe/R)
	if(!R.tools.len)
		return 1
	var/list/possible_tools = list()
	for(var/obj/item/I in user.contents)
		if(istype(I, /obj/item/weapon/storage))
			for(var/obj/item/SI in I.contents)
				possible_tools += SI.type
		else
			possible_tools += I.type
	possible_tools += table_contents
	var/i = R.tools.len
	var/I
	for(var/A in R.tools)
		I = possible_tools.Find(A)
		if(I)
			possible_tools.Cut(I, I+1)
			i--
		else
			break
	return !i

/obj/structure/table/proc/construct_item(mob/user, datum/table_recipe/R)
	check_table()
	if(check_contents(R) && check_tools(user, R))
		if(do_after(user, R.time))
			if(!check_contents(R) || !check_tools(user, R))
				return 0
			var/list/parts = del_reqs(R)
			var/atom/movable/I = new R.result_path
			for(var/A in parts)
				if(istype(A, /obj/item))
					var/atom/movable/B = A
					B.loc = I
				else
					if(!I.reagents)
						I.reagents = new /datum/reagents()
					I.reagents.reagent_list.Add(A)
			I.CheckParts()
			I.loc = loc
			return 1
	return 0

/obj/structure/table/proc/del_reqs(datum/table_recipe/R)
	var/list/Deletion = list()
	var/amt
	for(var/A in R.reqs)
		amt = R.reqs[A]
		if(ispath(A, /obj/item/stack))
			var/obj/item/stack/S
			stack_loop:
				for(var/B in table_contents)
					if(ispath(B, A))
						while(amt > 0)
							S = locate(B) in loc
							if(S.amount >= amt)
								S.use(amt)
								break stack_loop
							else
								amt -= S.amount
								del(S)
		else if(ispath(A, /obj/item))
			var/obj/item/I
			item_loop:
				for(var/B in table_contents)
					if(ispath(B, A))
						while(amt > 0)
							I = locate(B) in loc
							Deletion.Add(I)
							amt--
						break item_loop
		else
			var/datum/reagent/RG = new A
			reagent_loop:
				for(var/B in table_contents)
					if(ispath(B, /obj/item/weapon/reagent_containers))
						var/obj/item/RC = locate(B) in loc
						if(RC.reagents.has_reagent(RG.id, amt))
							RC.reagents.remove_reagent(RG.id, amt)
							RG.volume = amt
							Deletion.Add(RG)
							break reagent_loop
						else if(RC.reagents.has_reagent(RG.id))
							Deletion.Add(RG)
							RG.volume += RC.reagents.get_reagent_amount(RG.id)
							amt -= RC.reagents.get_reagent_amount(RG.id)
							RC.reagents.del_reagent(RG.id)

	for(var/A in R.parts)
		for(var/B in Deletion)
			if(!istype(B, A))
				Deletion.Remove(B)
				del(B)
	return Deletion

/obj/structure/table/interact(mob/user)
	check_table()
	if(!table_contents.len)
		return
	var/dat = "<h3>Construction menu</h3>"
	dat += "<div class='statusDisplay'>"
	if(busy)
		dat += "Construction inprogress...</div>"
	else
		for(var/datum/table_recipe/R in table_recipes)
			if(check_contents(R))
				dat += "<A href='?src=\ref[src];make=\ref[R]'>[R.name]</A><BR>"
		dat += "</div>"

	var/datum/browser/popup = new(user, "table", "Table", 300, 300)
	popup.set_content(dat)
	popup.open()
	return

/obj/structure/table/Topic(href, href_list)
	if(usr.stat || !Adjacent(usr) || usr.lying)
		return
	if(href_list["make"])
		var/datum/table_recipe/TR = locate(href_list["make"])
		busy = 1
		interact(usr)
		if(construct_item(usr, TR))
			usr << "<span class='notice'>[TR.name] constructed.</span>"
		else
			usr << "<span class ='warning'>Construction failed.</span>"
		busy = 0
	attack_hand(usr)

/obj/structure/table/update_icon()
	if(flipped)
		var/type = 0
		var/tabledirs = 0
		for(var/direction in list(turn(dir,90), turn(dir,-90)) )
			var/obj/structure/table/T = locate(/obj/structure/table,get_step(src,direction))
			if (T && T.flipped)
				type++
				tabledirs |= direction
		var/base = "table"
		if (istype(src, /obj/structure/table/woodentable))
			base = "wood"
		if (istype(src, /obj/structure/table/reinforced))
			base = "rtable"

		icon_state = "[base]flip[type]"
		if (type==1)
			if (tabledirs & turn(dir,90))
				icon_state = icon_state+"-"
			if (tabledirs & turn(dir,-90))
				icon_state = icon_state+"+"
		return 1

	spawn(2) //So it properly updates when deleting
		var/dir_sum = 0
		for(var/direction in list(1,2,4,8,5,6,9,10))
			var/skip_sum = 0
			for(var/obj/structure/window/W in src.loc)
				if(W.dir == direction) //So smooth tables don't go smooth through windows
					skip_sum = 1
					continue
			var/inv_direction //inverse direction
			switch(direction)
				if(1)
					inv_direction = 2
				if(2)
					inv_direction = 1
				if(4)
					inv_direction = 8
				if(8)
					inv_direction = 4
				if(5)
					inv_direction = 10
				if(6)
					inv_direction = 9
				if(9)
					inv_direction = 6
				if(10)
					inv_direction = 5
			for(var/obj/structure/window/W in get_step(src,direction))
				if(W.dir == inv_direction) //So smooth tables don't go smooth through windows when the window is on the other table's tile
					skip_sum = 1
					continue
			if(!skip_sum) //means there is a window between the two tiles in this direction
				var/obj/structure/table/T = locate(/obj/structure/table,get_step(src,direction))
				if(T && !T.flipped)
					if(direction <5)
						dir_sum += direction
					else
						if(direction == 5)	//This permits the use of all table directions. (Set up so clockwise around the central table is a higher value, from north)
							dir_sum += 16
						if(direction == 6)
							dir_sum += 32
						if(direction == 8)	//Aherp and Aderp.  Jezes I am stupid.  -- SkyMarshal
							dir_sum += 8
						if(direction == 10)
							dir_sum += 64
						if(direction == 9)
							dir_sum += 128

		var/table_type = 0 //stand_alone table
		if(dir_sum%16 in cardinal)
			table_type = 1 //endtable
			dir_sum %= 16
		if(dir_sum%16 in list(3,12))
			table_type = 2 //1 tile thick, streight table
			if(dir_sum%16 == 3) //3 doesn't exist as a dir
				dir_sum = 2
			if(dir_sum%16 == 12) //12 doesn't exist as a dir.
				dir_sum = 4
		if(dir_sum%16 in list(5,6,9,10))
			if(locate(/obj/structure/table,get_step(src.loc,dir_sum%16)))
				table_type = 3 //full table (not the 1 tile thick one, but one of the 'tabledir' tables)
			else
				table_type = 2 //1 tile thick, corner table (treated the same as streight tables in code later on)
			dir_sum %= 16
		if(dir_sum%16 in list(13,14,7,11)) //Three-way intersection
			table_type = 5 //full table as three-way intersections are not sprited, would require 64 sprites to handle all combinations.  TOO BAD -- SkyMarshal
			switch(dir_sum%16)	//Begin computation of the special type tables.  --SkyMarshal
				if(7)
					if(dir_sum == 23)
						table_type = 6
						dir_sum = 8
					else if(dir_sum == 39)
						dir_sum = 4
						table_type = 6
					else if(dir_sum == 55 || dir_sum == 119 || dir_sum == 247 || dir_sum == 183)
						dir_sum = 4
						table_type = 3
					else
						dir_sum = 4
				if(11)
					if(dir_sum == 75)
						dir_sum = 5
						table_type = 6
					else if(dir_sum == 139)
						dir_sum = 9
						table_type = 6
					else if(dir_sum == 203 || dir_sum == 219 || dir_sum == 251 || dir_sum == 235)
						dir_sum = 8
						table_type = 3
					else
						dir_sum = 8
				if(13)
					if(dir_sum == 29)
						dir_sum = 10
						table_type = 6
					else if(dir_sum == 141)
						dir_sum = 6
						table_type = 6
					else if(dir_sum == 189 || dir_sum == 221 || dir_sum == 253 || dir_sum == 157)
						dir_sum = 1
						table_type = 3
					else
						dir_sum = 1
				if(14)
					if(dir_sum == 46)
						dir_sum = 1
						table_type = 6
					else if(dir_sum == 78)
						dir_sum = 2
						table_type = 6
					else if(dir_sum == 110 || dir_sum == 254 || dir_sum == 238 || dir_sum == 126)
						dir_sum = 2
						table_type = 3
					else
						dir_sum = 2 //These translate the dir_sum to the correct dirs from the 'tabledir' icon_state.
		if(dir_sum%16 == 15)
			table_type = 4 //4-way intersection, the 'middle' table sprites will be used.

		if(istype(src,/obj/structure/table/reinforced))
			switch(table_type)
				if(0)
					icon_state = "reinf_table"
				if(1)
					icon_state = "reinf_1tileendtable"
				if(2)
					icon_state = "reinf_1tilethick"
				if(3)
					icon_state = "reinf_tabledir"
				if(4)
					icon_state = "reinf_middle"
				if(5)
					icon_state = "reinf_tabledir2"
				if(6)
					icon_state = "reinf_tabledir3"
		else if(istype(src,/obj/structure/table/woodentable))
			switch(table_type)
				if(0)
					icon_state = "wood_table"
				if(1)
					icon_state = "wood_1tileendtable"
				if(2)
					icon_state = "wood_1tilethick"
				if(3)
					icon_state = "wood_tabledir"
				if(4)
					icon_state = "wood_middle"
				if(5)
					icon_state = "wood_tabledir2"
				if(6)
					icon_state = "wood_tabledir3"
		else
			switch(table_type)
				if(0)
					icon_state = "table"
				if(1)
					icon_state = "table_1tileendtable"
				if(2)
					icon_state = "table_1tilethick"
				if(3)
					icon_state = "tabledir"
				if(4)
					icon_state = "table_middle"
				if(5)
					icon_state = "tabledir2"
				if(6)
					icon_state = "tabledir3"
		if (dir_sum in list(1,2,4,8,5,6,9,10))
			dir = dir_sum
		else
			dir = 2

/obj/structure/table/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
			return
		if(2.0)
			if (prob(50))
				qdel(src)
				return
		if(3.0)
			if (prob(25))
				destroy()
		else
	return


/obj/structure/table/blob_act()
	if(prob(75))
		destroy()

/obj/structure/table/attack_paw(mob/user)
	if(M_HULK in user.mutations)
		user.say(pick(";RAAAAAAAARGH!", ";HNNNNNNNNNGGGGGGH!", ";GWAAAAAAAARRRHHH!", "NNNNNNNNGGGGGGGGHH!", ";AAAAAAARRRGH!" ))
		visible_message("<span class='danger'>[user] smashes the [src] apart!</span>")
		destroy()


/obj/structure/table/attack_alien(mob/user)
	visible_message("<span class='danger'>[user] slices [src] apart!</span>")
	destroy()

/obj/structure/table/attack_animal(mob/living/simple_animal/user)
	if(user.environment_smash)
		visible_message("<span class='danger'>[user] smashes [src] apart!</span>")
		destroy()



/obj/structure/table/attack_hand(mob/user)
	if(M_HULK in user.mutations)
		visible_message("<span class='danger'>[user] smashes [src] apart!</span>")
		user.say(pick(";RAAAAAAAARGH!", ";HNNNNNNNNNGGGGGGH!", ";GWAAAAAAAARRRHHH!", "NNNNNNNNGGGGGGGGHH!", ";AAAAAAARRRGH!" ))
		destroy()
	else
		..()

/obj/structure/table/attack_tk() // no telehulk sorry
	return

/obj/structure/table/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(air_group || (height==0)) return 1
	if(istype(mover,/obj/item/projectile))
		return (check_cover(mover,target))
	if(istype(mover) && mover.checkpass(PASSTABLE))
		return 1
	if (flipped)
		if (get_dir(loc, target) == dir)
			return !density
		else
			return 1
	return 0

//checks if projectile 'P' from turf 'from' can hit whatever is behind the table. Returns 1 if it can, 0 if bullet stops.
/obj/structure/table/proc/check_cover(obj/item/projectile/P, turf/from)
	var/turf/cover = flipped ? get_turf(src) : get_step(loc, get_dir(from, loc))
	if (get_dist(P.starting, loc) <= 1) //Tables won't help you if people are THIS close
		return 1
	if (get_turf(P.original) == cover)
		var/chance = 20
		if (ismob(P.original))
			var/mob/M = P.original
			if (M.lying)
				chance += 20				//Lying down lets you catch less bullets
		if(flipped)
			if(get_dir(loc, from) == dir)	//Flipped tables catch mroe bullets
				chance += 20
			else
				return 1					//But only from one side
		if(prob(chance))
			health -= P.damage/2
			if (health > 0)
				visible_message("<span class='warning'>[P] hits \the [src]!</span>")
				return 0
			else
				visible_message("<span class='warning'>[src] breaks down!</span>")
				destroy()
				return 1
	return 1

/obj/structure/table/CheckExit(atom/movable/O as mob|obj, target as turf)
	if(istype(O) && O.checkpass(PASSTABLE))
		return 1
	if (flipped)
		if (get_dir(loc, target) == dir)
			return !density
		else
			return 1
	return 1

/obj/structure/table/MouseDrop_T(obj/O as obj, mob/user as mob)
	if ((!( istype(O, /obj/item/weapon) ) || user.get_active_hand() != O))
		return
	if(isrobot(user))
		return
	user.drop_item()
	if (O.loc != src.loc)
		step(O, get_dir(O, src))
	return


/obj/structure/table/attackby(obj/item/W as obj, mob/user as mob)
	if (istype(W, /obj/item/weapon/grab) && get_dist(src,user)<2)
		var/obj/item/weapon/grab/G = W
		if (istype(G.affecting, /mob/living))
			var/mob/living/M = G.affecting
			if (G.state < 2)
				if(user.a_intent == "harm")
					if (prob(15))	M.Weaken(5)
					M.apply_damage(8,def_zone = "head")
					visible_message("\red [G.assailant] slams [G.affecting]'s face against \the [src]!")
					playsound(src.loc, 'sound/weapons/tablehit1.ogg', 50, 1)
				else
					user << "\red You need a better grip to do that!"
					return
			else
				G.affecting.loc = src.loc
				G.affecting.Weaken(5)
				visible_message("\red [G.assailant] puts [G.affecting] on \the [src].")
			del(W)
			return

	if (istype(W, /obj/item/weapon/wrench))
		user << "\blue Now disassembling table"
		playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
		if(do_after(user,50))
			destroy()
		return

	if(isrobot(user))
		return

	if(istype(W, /obj/item/weapon/melee/energy/blade))
		var/datum/effect/effect/system/spark_spread/spark_system = new /datum/effect/effect/system/spark_spread()
		spark_system.set_up(5, 0, src.loc)
		spark_system.start()
		playsound(src.loc, 'sound/weapons/blade1.ogg', 50, 1)
		playsound(src.loc, "sparks", 50, 1)
		for(var/mob/O in viewers(user, 4))
			O.show_message("\blue The [src] was sliced apart by [user]!", 1, "\red You hear [src] coming apart.", 2)
		destroy()

	user.drop_item(src)
	return

/obj/structure/table/proc/straight_table_check(var/direction)
	var/turf/left = get_step(src,turn(direction,90))
	var/turf/right = get_step(src,turn(direction,-90))
	var/turf/next = get_step(src,direction)
	if(locate(/obj/structure/table,left) || locate(/obj/structure/table,right))
		return 0
	var/obj/structure/table/T = locate(/obj/structure/table, next)
	if (istype(T,/obj/structure/table/reinforced/))
		var/obj/structure/table/reinforced/R = T
		if (R.status == 2)
			return 0
	if (!T)
		return 1
	else
		return T.straight_table_check(direction)

/obj/structure/table/verb/do_flip()
	set name = "Flip table"
	set desc = "Flips a non-reinforced table"
	set category = "Object"
	set src in oview(1)

	if (issilicon(usr))
		usr << "<span class='notice'>You need hands for this.</span>"
		return
	if (isobserver(usr))
		usr << "<span class='notice'>No haunting outside halloween.</span>n"
		return
	if(!flip(get_cardinal_dir(usr,src)))
		usr << "<span class='notice'>It won't budge.</span>"
	else
		usr.visible_message("<span class='warning'>[usr] flips \the [src]!</span>")
		return

/obj/structure/table/proc/do_put()
	set name = "Put table back"
	set desc = "Puts flipped table back"
	set category = "Object"
	set src in oview(1)

	if (!unflip())
		usr << "<span class='notice'>It won't budge.</span>"
		return


/obj/structure/table/proc/flip(var/direction)
	if (flipped)
		return 0

	if( !straight_table_check(turn(direction,90)) || !straight_table_check(turn(direction,-90)) )
		return 0

	verbs -=/obj/structure/table/verb/do_flip
	verbs +=/obj/structure/table/proc/do_put

	var/list/targets = list(get_step(src,dir),get_step(src,turn(dir, 45)),get_step(src,turn(dir, -45)))
	for (var/atom/movable/A in get_turf(src))
		if (!A.anchored)
			spawn(0)
				A.throw_at(pick(targets),1,1)

	dir = direction
	if(dir != NORTH)
		layer = 5
	flipped = 1
	flags |= ON_BORDER
	for(var/D in list(turn(direction, 90), turn(direction, -90)))
		if(locate(/obj/structure/table,get_step(src,D)))
			var/obj/structure/table/T = locate(/obj/structure/table,get_step(src,D))
			T.flip(direction)
	update_icon()
	update_adjacent()

	return 1

/obj/structure/table/proc/unflip()
	if (!flipped)
		return 0

	var/can_flip = 1
	for (var/mob/A in oview(src,0))//src.loc)
		if (istype(A))
			can_flip = 0
	if (!can_flip)
		return 0

	verbs -=/obj/structure/table/proc/do_put
	verbs +=/obj/structure/table/verb/do_flip

	layer = initial(layer)
	flipped = 0
	flags &= ~ON_BORDER
	for(var/D in list(turn(dir, 90), turn(dir, -90)))
		if(locate(/obj/structure/table,get_step(src,D)))
			var/obj/structure/table/T = locate(/obj/structure/table,get_step(src,D))
			T.unflip()
	update_icon()
	update_adjacent()

	return 1

/*
 * Wooden tables
 */
/obj/structure/table/woodentable
	name = "wooden table"
	desc = "Do not apply fire to this. Rumour says it burns easily."
	icon_state = "wood_table"
	parts = /obj/item/weapon/table_parts/wood
	health = 50

/obj/structure/table/woodentable/attackby(obj/item/I as obj, mob/user as mob)

	if (istype(I, /obj/item/stack/tile/grass))
		del(I)
		new /obj/structure/table/woodentable/poker( src.loc )
		del(src)
		visible_message("<span class='notice'>[user] adds the grass to the wooden table</span>")


	if (istype(I, /obj/item/weapon/grab))
		var/obj/item/weapon/grab/G = I
		if(G.affecting.buckled)
			user << "<span class='notice'>[G.affecting] is buckled to [G.affecting.buckled]!</span>"
			return
		if(G.state < GRAB_AGGRESSIVE)
			user << "<span class='notice'>You need a better grip to do that!</span>"
			return
		if(!G.confirm())
			return
		G.affecting.loc = src.loc
		G.affecting.Weaken(5)
		visible_message("\red [G.assailant] puts [G.affecting] on the table.")
		del(I)
		return
	if (istype(I, /obj/item/weapon/wrench))
		user << "\blue Now disassembling the wooden table"
		playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
		sleep(50)
		new /obj/item/weapon/table_parts/wood( src.loc )
		playsound(src.loc, 'sound/items/Deconstruct.ogg', 50, 1)
		del(src)
		return

	if(isrobot(user))
		return
	if(istype(I, /obj/item/weapon/melee/energy/blade))
		var/datum/effect/effect/system/spark_spread/spark_system = new /datum/effect/effect/system/spark_spread()
		spark_system.set_up(5, 0, src.loc)
		spark_system.start()
		playsound(src.loc, 'sound/weapons/blade1.ogg', 50, 1)
		playsound(src.loc, "sparks", 50, 1)
		for(var/mob/O in viewers(user, 4))
			O.show_message("\blue The wooden table was sliced apart by [user]!", 1, "\red You hear wood coming apart.", 2)
		new /obj/item/weapon/table_parts/wood( src.loc )
		del(src)
		return

	user.drop_item(src)
	//if(W && W.loc)	W.loc = src.loc
	return 1

/obj/structure/table/woodentable/poker //No specialties, Just a mapping object.
	name = "gambling table"
	desc = "A seedy table for seedy dealings in seedy places."
	icon_state = "pokertable"


/obj/structure/table/woodentable/poker/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if (istype(W, /obj/item/weapon/grab))
		var/obj/item/weapon/grab/G = W
		if(G.affecting.buckled)
			user << "<span class='notice'>[G.affecting] is buckled to [G.affecting.buckled]!</span>"
			return
		if(G.state < GRAB_AGGRESSIVE)
			user << "<span class='notice'>You need a better grip to do that!</span>"
			return
		if(!G.confirm())
			return
		G.affecting.loc = src.loc
		G.affecting.Weaken(5)
		visible_message("\red [G.assailant] puts [G.affecting] on the table.")
		del(W)
		return
	if (istype(W, /obj/item/weapon/wrench))
		user << "\blue Now disassembling the wooden table"
		playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
		sleep(50)
		new /obj/item/weapon/table_parts/wood( src.loc )
		new /obj/item/stack/tile/grass( src.loc)
		playsound(src.loc, 'sound/items/Deconstruct.ogg', 50, 1)
		del(src)
		return

	if(isrobot(user))
		return
	if(istype(W, /obj/item/weapon/melee/energy/blade))
		var/datum/effect/effect/system/spark_spread/spark_system = new /datum/effect/effect/system/spark_spread()
		spark_system.set_up(5, 0, src.loc)
		spark_system.start()
		playsound(src.loc, 'sound/weapons/blade1.ogg', 50, 1)
		playsound(src.loc, "sparks", 50, 1)
		for(var/mob/O in viewers(user, 4))
			O.show_message("\blue The wooden table was sliced apart by [user]!", 1, "\red You hear wood coming apart.", 2)
		new /obj/item/weapon/table_parts/wood( src.loc )
		new /obj/item/stack/tile/grass( src.loc)
		del(src)
		return

	user.drop_item(src)
	return 1


/*
 * Reinforced tables
 */
/obj/structure/table/reinforced
	name = "reinforced table"
	desc = "A version of the four legged table. It is stronger."
	icon_state = "reinf_table"
	health = 200
	var/status = 2
	parts = /obj/item/weapon/table_parts/reinforced

/obj/structure/table/reinforced/flip(var/direction)
	if (status == 2)
		return 0
	else
		return ..()

/obj/structure/table/reinforced/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if (istype(W, /obj/item/weapon/weldingtool))
		var/obj/item/weapon/weldingtool/WT = W
		if(WT.remove_fuel(0, user))
			if(src.status == 2)
				user << "\blue Now weakening the reinforced table"
				playsound(src.loc, 'sound/items/Welder.ogg', 50, 1)
				if (do_after(user, 50))
					if(!src || !WT.isOn()) return
					user << "\blue Table weakened"
					src.status = 1
			else
				user << "\blue Now strengthening the reinforced table"
				playsound(src.loc, 'sound/items/Welder.ogg', 50, 1)
				if (do_after(user, 50))
					if(!src || !WT.isOn()) return
					user << "\blue Table strengthened"
					src.status = 2
			return
		return

	if (istype(W, /obj/item/weapon/wrench))
		if(src.status == 2)
			return

	..()

/*
 * Racks
 */
/obj/structure/rack
	name = "rack"
	desc = "Different from the Middle Ages version."
	icon = 'icons/obj/objects.dmi'
	icon_state = "rack"
	density = 1
	flags = FPRINT
	anchored = 1.0
	throwpass = 1	//You can throw objects over this, despite it's density.
	var/parts = /obj/item/weapon/rack_parts

/obj/structure/rack/proc/destroy()
	new parts(loc)
	density = 0
	del(src)

/obj/structure/rack/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
		if(2.0)
			qdel(src)
			if(prob(50))
				new /obj/item/weapon/rack_parts(src.loc)
		if(3.0)
			if(prob(25))
				qdel(src)
				new /obj/item/weapon/rack_parts(src.loc)

/obj/structure/rack/blob_act()
	if(prob(75))
		del(src)
		return
	else if(prob(50))
		new /obj/item/weapon/rack_parts(src.loc)
		del(src)
		return

/obj/structure/rack/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(air_group || (height==0)) return 1
	if(src.density == 0) //Because broken racks -Agouri |TODO: SPRITE!|
		return 1
	if(istype(mover) && mover.checkpass(PASSTABLE))
		return 1
	else
		return 0

/obj/structure/rack/MouseDrop_T(obj/O as obj, mob/user as mob)
	if ((!( istype(O, /obj/item/weapon) ) || user.get_active_hand() != O))
		return
	if(isrobot(user))
		return
	user.drop_item()
	if (O.loc != src.loc)
		step(O, get_dir(O, src))
	return

/obj/structure/rack/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if (istype(W, /obj/item/weapon/wrench))
		new /obj/item/weapon/rack_parts( src.loc )
		playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
		del(src)
		return
	if(isrobot(user))
		return
	user.drop_item()
	if(W && W.loc)	W.loc = src.loc
	return

/obj/structure/rack/meteorhit(obj/O as obj)
	del(src)


/obj/structure/table/attack_hand(mob/user)
	if(M_HULK in user.mutations)
		visible_message("<span class='danger'>[user] smashes [src] apart!</span>")
		user.say(pick(";RAAAAAAAARGH!", ";HNNNNNNNNNGGGGGGH!", ";GWAAAAAAAARRRHHH!", "NNNNNNNNGGGGGGGGHH!", ";AAAAAAARRRGH!" ))
		destroy()


/obj/structure/rack/attack_paw(mob/user)
	if(M_HULK in user.mutations)
		user.say(pick(";RAAAAAAAARGH!", ";HNNNNNNNNNGGGGGGH!", ";GWAAAAAAAARRRHHH!", "NNNNNNNNGGGGGGGGHH!", ";AAAAAAARRRGH!" ))
		visible_message("<span class='danger'>[user] smashes [src] apart!</span>")
		destroy()


/obj/structure/rack/attack_alien(mob/user)
	visible_message("<span class='danger'>[user] slices [src] apart!</span>")
	destroy()


/obj/structure/rack/attack_animal(mob/living/simple_animal/user)
	if(user.environment_smash)
		visible_message("<span class='danger'>[user] smashes [src] apart!</span>")
		destroy()

/obj/structure/rack/attack_tk() // no telehulk sorry
	return
