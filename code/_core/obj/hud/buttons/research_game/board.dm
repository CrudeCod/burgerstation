/obj/hud/button/research/board
	name = "research"
	desc = "Yes, this is research."

	icon = 'icons/hud/game_border.dmi'
	icon_state = "game_border"

	screen_loc = "LEFT,BOTTOM"

	var/list/pieces = new/list(RESEARCH_BOARD_SIZE,RESEARCH_BOARD_SIZE)

	var/list/cleared_pieces = list()

	var/points = 0

	var/time_left = 600

	var/obj/hud/button/research/info/time/linked_time
	var/obj/hud/button/research/info/score/linked_score
	var/obj/hud/button/research/info/text/linked_text

	var/game_initialized = FALSE
	var/init_x = 1
	var/init_y = 1

/obj/hud/button/research/board/think()

	. = ..()

	if(!game_initialized)
		var/obj/hud/button/research/piece/P = new
		P.update_owner(owner)
		P.x_p = init_x
		P.y_p = init_y
		src.pieces[init_x][init_y] = P
		P.linked_board = src
		P.initialize_colors()
		P.update_icon()
		P.update_piece()
		init_x++
		if(init_x > RESEARCH_BOARD_SIZE)
			init_x = 1
			init_y++
			if(init_y > RESEARCH_BOARD_SIZE)
				game_initialized = TRUE
				linked_text.maptext = "<center><font size='3'>Start!</font></center>"
				spawn(20)
					animate(linked_text,alpha=0,time = 10)

	else
		time_left--

		if(linked_time)
			linked_time.maptext = "<center>Time:<br>[get_clock_time(CEILING(time_left/10,1))]</center>"
			if(time_left <= 100)
				linked_time.color = "#FF0000"
				if(time_left <= 50 && !(time_left % 2))
					linked_time.color = "#000000"
			else
				linked_time.color = "#FFFFFF"
			if(time_left <= 0)
				linked_text.alpha = 255
				linked_text.maptext = "<center><font size=10>TIMES UP!</font><br>Final Score: [points].</center>"
				return FALSE

	return .

/obj/hud/button/research/board/proc/add_points(var/points_to_add)
	points += points_to_add
	time_left += (points_to_add)*10
	if(linked_score)
		linked_score.maptext = "<center>Score:<br>[points]</center>"
		if(points_to_add > 2)
			linked_text.alpha = 255
			linked_text.maptext = "<center><font size=5>Well done!</font></center>"
			spawn(20)
				animate(linked_text,alpha=0,time = 10)

	return TRUE

/obj/hud/button/research/board/Destroy()

	for(var/x_pos=1,x_pos<=RESEARCH_BOARD_SIZE,x_pos++)
		for(var/y_pos=1,y_pos<=RESEARCH_BOARD_SIZE,y_pos++)
			var/obj/hud/button/research/piece/P = pieces[x_pos][y_pos]
			if(P)
				qdel(P)
			P = null
		pieces[x_pos].Cut()
	pieces.Cut()

	qdel(linked_time)
	linked_time = null

	qdel(linked_score)
	linked_score = null

	qdel(linked_text)
	linked_text = null

	return ..()

/obj/hud/button/research/board/update_owner(var/desired_owner)

	. = ..()


	if(linked_time)
		linked_time.update_owner(desired_owner)
		if(desired_owner == null)
			qdel(linked_time)
			linked_time = null
	else if(desired_owner != null)
		linked_time = new
		linked_time.update_owner(desired_owner)

	if(linked_score)
		linked_score.update_owner(desired_owner)
		if(desired_owner == null)
			qdel(linked_score)
			linked_score = null
	else if(desired_owner != null)
		linked_score = new
		linked_score.update_owner(desired_owner)

	if(linked_text)
		linked_text.update_owner(desired_owner)
		if(desired_owner == null)
			qdel(linked_text)
			linked_text = null
	else if(desired_owner != null)
		linked_text = new
		linked_text.update_owner(desired_owner)

	if(desired_owner)
		/*
		for(var/x_pos=1,x_pos<=RESEARCH_BOARD_SIZE,x_pos++)
			for(var/y_pos=1,y_pos<=RESEARCH_BOARD_SIZE,y_pos++)
				var/obj/hud/button/research/piece/P = new
				P.update_owner(desired_owner)
				P.x_p = x_pos
				P.y_p = y_pos
				src.pieces[x_pos][y_pos] = P
				P.linked_board = src
		for(var/x_pos=1,x_pos<=RESEARCH_BOARD_SIZE,x_pos++)
			for(var/y_pos=1,y_pos<=RESEARCH_BOARD_SIZE,y_pos++)
				var/obj/hud/button/research/piece/P = src.pieces[x_pos][y_pos]
				P.initialize_colors()
				P.update_icon()
				P.update_piece()
		*/
		start_thinking(src)
	else
		stop_thinking(src)







	return .