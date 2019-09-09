/obj/item/
	name = "item"
	desc = "Oh my god it's an item."

	var/size = 1 //Size in.. uh...
	var/weight = 1 //Weight in kg

	var/value = 1 //Value in whatever currency this world uses.

	var/slowdown_mul_held = 1 //Slow down multiplier. Stacks multiplicatively or however you spell the damn word.
	var/slowdown_mul_worn = 1

	var/rarity = RARITY_COMMON

	var/is_container = FALSE //Setting this to true will open the below inventories on use.
	var/dynamic_inventory_count = 0
	var/container_max_size = 0 //This item has a container, how much should it be able to hold in each slot?
	var/container_max_weight = 0 //This item has a container, how much should it be able to carry in TOTAL?
	var/container_held_slots = 0 //How much each inventory slot can hold.
	var/container_blacklist = list()
	var/container_whitelist = list()

	var/list/obj/hud/inventory/inventories = list() //The inventory holders this object has

	icon_state = "inventory"
	var/icon_state_held_left = "held_left"
	var/icon_state_held_right = "held_right"
	var/icon_state_worn = "worn"

	var/worn_layer = 0

	var/item_slot = SLOT_NONE

	mouse_over_pointer = MOUSE_ACTIVE_POINTER

	var/no_held_draw = FALSE

	var/no_initial_blend = FALSE //Should we draw the initial icon when worn/held?

	var/slot_icons = FALSE //Set to true if the clothing is based on where it's slot is.

	var/ignore_other_slots = FALSE

	var/block_mul = list(
		ATTACK_TYPE_MELEE = 0,
		ATTACK_TYPE_RANGED = 0,
		ATTACK_TYPE_MAGIC = 0
	)

	var/parry_mul = list(
		ATTACK_TYPE_MELEE = 0,
		ATTACK_TYPE_RANGED = 0,
		ATTACK_TYPE_MAGIC = 0
	)

	var/soul_bound = FALSE

	var/has_quick_function = FALSE

	var/list/inventory_bypass = list()

	var/crafting_id = null

/obj/item/proc/quick(var/mob/living/advanced/caller,var/atom/object,location,control,params)
	return FALSE

/obj/item/can_be_attacked(var/atom/attacker)
	return FALSE

/obj/item/click_self(caller,location,control,params)

	if(!length(inventories))
		return FALSE

	var/mob/living/advanced/A = caller

	for(var/obj/hud/inventory/I in A.inventory)
		if(I in inventories)
			continue
		if(!(I.flags & FLAGS_HUD_INVENTORY))
			continue
		I.alpha = 0
		I.mouse_opacity = 0

	var/opening = FALSE

	for(var/i=1,i<=length(inventories),i++)
		var/obj/hud/inventory/I = inventories[i]
		I.update_owner(A)
		I.screen_loc = "CENTER+[i]-[(length(inventories)+1)/2],BOTTOM+1.25"
		if(opening || !I.alpha)
			animate(I,alpha=255,time=4)
			I.mouse_opacity = 2
			opening = TRUE
		else
			animate(I,alpha=0,time=4)
			I.mouse_opacity = 0
			opening = FALSE

	if(opening)
		for(var/obj/hud/button/B in A.buttons)
			if(B.type != /obj/hud/button/close_inventory) //TODO: Fix this shitcode
				continue
			B.alpha = 0
			B.mouse_opacity = 0

	for(var/obj/hud/button/B in A.buttons)
		if(B.type != /obj/hud/button/close_inventory) //TODO: Fix this shitcode
			continue

		B.screen_loc = "CENTER+[(length(inventories)+1)/2],BOTTOM+1.25"

		if(opening)
			animate(B,alpha=255,time=4)
			B.mouse_opacity = 2
		else
			animate(B,alpha=0,time=4)
			B.mouse_opacity = 0

		break

	return TRUE

/obj/item/clicked_by_object(var/mob/caller as mob,var/atom/object,location,control,params) //The src was clicked on by the object

	if(!is_container)
		return ..()

	if(is_inventory(object) && is_advanced(caller) && length(inventories) && get_dist(caller,src) <= 1)
		return click_self(caller,location,control,params)

	if(is_item(object))
		add_to_inventory(caller,object,TRUE)

	return 	..()

/obj/item/drop_on_object(var/atom/caller,var/atom/object)

	if(caller == object)
		return click_self(caller)

	return ..()

/obj/item/proc/add_to_inventory(var/mob/caller,var/obj/item/object,var/enable_messages = TRUE)

	if(!length(inventories))
		return FALSE

	var/added = FALSE

	if(object != src)
		for(var/obj/hud/inventory/I in inventories)
			if(I.add_object(object,FALSE))
				added = TRUE
				break

	if(enable_messages && caller)
		if(added)
			caller.to_chat(span("notice","You stuff \the [object] in your [src]."))
		else
			caller.to_chat(span("warning","You don't have enough inventory space to hold this!"))

	return added

/obj/item/New(var/desired_loc)

	for(var/i=1, i <= length(inventories), i++)
		var/obj/hud/inventory/new_inv = inventories[i]
		inventories[i] = new new_inv(src)

		if(container_held_slots)
			inventories[i].held_slots = container_held_slots
		if(container_max_size)
			inventories[i].max_size = container_max_size
		if(container_max_weight)
			inventories[i].max_weight = container_max_weight
		if(container_blacklist)
			inventories[i].item_blacklist = container_blacklist
		if(container_whitelist)
			inventories[i].item_whitelist = container_whitelist

	for(var/i=1, i <= dynamic_inventory_count, i++)
		var/obj/hud/inventory/dynamic/D = new(src)
		D.id = "dynamic_[i]"
		if(container_held_slots)
			D.held_slots = container_held_slots
		if(container_max_size)
			D.max_size = container_max_size
		if(container_max_weight)
			D.max_weight = container_max_weight
		inventories += D

	. = ..()

/obj/item/proc/update_owner(desired_owner)
	for(var/v in inventories)
		var/obj/hud/inventory/I = v
		I.update_owner(desired_owner)

/obj/item/proc/get_owner()
	if(is_inventory(src.loc))
		var/obj/hud/inventory/I = src.loc
		return I.owner

	return null

/obj/item/update_icon()
	..()
	if(is_inventory(src.loc))
		var/obj/hud/inventory/I = src.loc
		I.update_icon()

/obj/item/get_examine_text(var/mob/examiner)

	if(!is_advanced(examiner))
		return ..()

	. = ..()

	var/mob/living/advanced/A = examiner

	return . + get_damage_type_text(A)

obj/item/proc/do_automatic(caller,object,location,params)
	return TRUE

/obj/item/proc/on_pickup(var/atom/old_location,var/obj/hud/inventory/new_location) //When the item is picked up.

	if(is_container)
		for(var/obj/hud/inventory/I in inventories)
			I.update_owner(new_location.owner)

	return

/obj/item/proc/on_drop(var/obj/hud/inventory/old_inventory,var/atom/new_loc)
	return

/obj/item/proc/inventory_to_list()

	var/list/returning_list = list()

	for(var/obj/hud/inventory/I in inventories)
		if(length(I.held_objects) && I.held_objects[1])
			returning_list += I.held_objects[1]

	return returning_list


/obj/item/proc/can_be_held(var/mob/living/advanced/owner,var/obj/hud/inventory/I)
	return TRUE

/obj/item/proc/can_be_worn(var/mob/living/advanced/owner,var/obj/hud/inventory/I)
	return FALSE

/obj/item/proc/get_damage_type() //Information purposes only.
	return damage_type

/obj/item/proc/update_held_icon()

	if(is_inventory(src.loc))
		var/obj/hud/inventory/I = src.loc
		I.update_held_icon(src)

	return TRUE


/obj/item/proc/on_inventory_click(var/mob/caller as mob,location,control,params) //When the object is clicked on when it is in your inventory.
	return FALSE //Return false to do nothing and proceed with normal behavior. Return true to cancel normal behavior.