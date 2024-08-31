################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Devanshu Singhvi, 1007660700
# Student 2: Mohammad Modaser Mojadiddi, 1008038892
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
    
GRAY:
	.word 0x808080
WHITE:
	.word 0xffffff
RED:
	.word 0xff0000
GREEN:
	.word 0x00ff00
BLUE:
	.word 0x0000ff
BACKGROUND_COLOUR:
	.word 0x000000
INITIAL_BALL:
	.word 3648 # position
	.word 132  # movement
INITIAL_PADDLE:
	.word 4024 # position
HIGH_SCORE:
    .word 0 # ones
    .word 0 # tens
    .word 0 # hundreds
##############################################################################
# Mutable Data
##############################################################################
BALL:
	.word 3648 # position
	.word 132  # movement (-124 is diagonal top-right, -132 is diagonal top-left, 124 is diagonal bottom-left, 132 is diagonal bottom-right)
PADDLE:
	.word 4024 # position
SCORE:
    .word 0 # ones
    .word 0 # tens
    .word 0 # hundreds
LIVES:
	.word 3 # Lives
##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Brick Breaker game.
##############################################################################
# Game functions 
##############################################################################
main:
    # Initialize the game
    jal draw_black_screen
	jal draw_top
	jal draw_left
	jal draw_right
	jal draw_bricks
	jal draw_paddle
	jal draw_ball
	jal check_scores_current
	jal check_high_score
	jal draw_lives
	jal game_loop
	
game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
	lw $t0, ADDR_KBRD			# $t0 = base address for keyboard
	lw $t8, 0($t0)                  	# Load first word from keyboard
	beq $t8, 1, keyboard_input      	# If first word 1, key is pressed
	
    # 2a. Check for collisions
    jal check_collision
	
    # 2b. Update locations (paddle, ball)
	jal move_ball

    jal check_scores_current

	la $t1, SCORE
	lw $t2, 0($t1)
	lw $t3, 4($t1)
	lw $t4, 8($t1)
	
    # 4. Sleep
    li $v0, 32
	li $a0, 200
	syscall

    #5. Go back to 1
	b game_loop

##############################################################################
# Handling keyboard inputs 
##############################################################################
keyboard_input:
    # Getting the next keyboard input and calling the appropriate action if valid key 	
	addi $v0, $zero, -1
	lw $a0, 4($t0)                          # Load next word from keyboard
    
    # Depending on the button pressed its executed
	beq $a0, 0x61, a_pressed		# move paddle left
	beq $a0, 0x64, d_pressed		# move paddle right
	beq $a0, 0x70, p_pressed		# pause game
	beq $a0, 0x71, q_pressed		# quit game
	beq $a0, 0x72, r_pressed		# restart game
	
    # Backg to game_loop to get the next key	
    b game_loop

q_pressed:
    # Game ends 
    j exit
        
a_pressed:      
    # Moves the paddle to the left if not already at most left  
	jal move_paddle_left
    
d_pressed:
    # Moves the paddle to the right if not already at most right          
	jal move_paddle_right

p_pressed:
    # Pauses the game
	jal pause_loop

pause:
    # Getting the next keyboard input and calling the appropriate action if valid key 	
	addi $v0, $zero, -1
	lw $a0, 4($t0)                  # Load next word from keyboard
	beq $a0, 0x70, game_loop     	# check if the key p was pressed
	beq $a0, 0x71, q_pressed		# check if the key q was pressed
	beq $a0, 0x72, r_pressed		# check if the key r was pressed
	b pause_loop				# if anything else was pressed, keep the game paused

pause_loop: 
#   The game is paused during this loop unless a buttom is pressed
	lw $t0, ADDR_KBRD			# $t0 = base address for keyboard
	lw $t8, 0($t0)                  	# Load first word from keyboard
	beq $t8, 1, pause      			# If first word 1, key is pressed
	b pause_loop

r_pressed:
#   The ball, paddle and scores are re-initialised, and then the game is restarted
#   t1 stores the initial ball, and later paddle objects
#   t2 stores the initial position of ball, and later paddle objects
#   t3 stores the initial direction of ball
#   t4 stores the current BALL object, and later the PADDLE object

	la $t1, INITIAL_BALL 		# loads initial ball object
	lw $t2, 0($t1)				# loads the initial position into $t2
	lw $t3, 4($t1)				# loads the initial direction into $t3
	la $t4, BALL
	sw $t2, 0($t4)				# re-initialise position of BALL
	sw $t3, 4($t4)				# re-initialise direction of BALL
	
	la $t1, INITIAL_PADDLE
	lw $t2, 0($t1)				# loads the initial position into $t1
	la $t4, PADDLE
	sw $t2, 0($t4)				# re-initialise position of PADDLE

	# Reset the amount of lives	
	la $t1, LIVES
	lw $t7, 0($t1)
	addi $t7, $zero, 3
	sw $t7, 0($t1)	

	# finding the values of the current and high score
	li $t5, 10
	la $t1, HIGH_SCORE
	lw $t2, 0($t1)
	lw $t3, 4($t1)
	lw $t4, 8($t1)
	mult $t4, $t5
	mfhi $t4
	mult $t4, $t5
	mfhi $t4
	mult $t3, $t5
	mfhi $t3
	add $t6, $t2, $t3
	add $t6, $t6, $t4
	
	la $t1, SCORE
	lw $t2, 0($t1)
	lw $t3, 4($t1)
	lw $t4, 8($t1)
	mult $t4, $t5
	mfhi $t4
	mult $t4, $t5
	mfhi $t4
	mult $t3, $t5
	mfhi $t3
	add $t7, $t2, $t3
	add $t7, $t7, $t4
	
	# comparing scores
	blt $t6, $t7, update_high

    # resetting current score
	sw $zero, 0($t1)
	sw $zero, 4($t1)
	sw $zero, 8($t1)
	j main

##############################################################################
# Handling collisions 
##############################################################################
check_collision:
#   Individual checks for collision against sides, top, bottom and diagonal directions
	addi $sp, $sp, -4  			# move $sp to the next available location
	sw $ra, 0($sp)      			# push $ra to the stack
	jal check_left
	jal check_right
	jal check_top
	jal check_bottom
	# bgezal $v0, check_diagonal
	bgez $v0, check_diagonal
	# jal check_diagonal
	lw $ra, 0($sp)				# pop $ra from the stack
    addi $sp, $sp, 4			# restore $sp
	jr $ra

hit_brick:
	lw $t7, BLUE				# loads colour of a possible brick
	beq $a1, $t7, hit_brick_blue		# jumps back to checker

	lw $t8, GREEN				# loads colour of a possible brick
	beq $a1, $t8, hit_brick_green		# jumps back to checker

	lw $t9, RED				# loads colour of a possible brick
	beq $a1, $t9, hit_brick_red		# jumps back to checker

hit_brick_blue:
	lw $t5, BACKGROUND_COLOUR 	# loads the background colour
	sw $t5, 0($a2)
    # sound
    li $a0, 75
    li $a1, 250
    li $a2, 127
    li $a3, 150
    li $v0, 31
    syscall
	jr $ra

hit_brick_green:
	lw $t5, BLUE          		# loads the green colour
	sw $t5, 0($a2)
    # sound
    li $a0, 75
    li $a1, 250
    li $a2, 127
    li $a3, 150
    li $v0, 31
    syscall
	jr $ra

hit_brick_red:
	lw $t5, BLUE		 		# loads the blue colour
	sw $t5, 0($a2)
    # sound
    li $a0, 75
    li $a1, 250
    li $a2, 127
    li $a3, 150
    li $v0, 31
    syscall
	jr $ra

check_left:
#   Checks the left unit for collision
#   t0 stores the colour of the unit checking
#   t1 stores the location where to check
#   t2 stores the BALL object
#   t3 stores the current location of the BALL
#   t4 stores the current direction of the BALL
#   t5 stores background_colour
#   t6 stores white
	lw $t1, ADDR_DSPL
	la $t2, BALL 				# loads ball object
	lw $t3, 0($t2)				# loads the position into $t3
	lw $t4, 4($t2)				# loads the direction into $t4
	beq $t4, -124, check_end
	beq $t4, 132, check_end
	addi $t3, $t3, -4			# unit to the left
	add $t1, $t1, $t3			# stores the position of the unit to the left of the ball
	lw $t0, 0($t1)				# loads color of unit to the left of the ball

	lw $t5, BACKGROUND_COLOUR 		# loads the background colour
	beq $t0, $t5, check_end			# jumps back to check_collision if no collision on the left

	addi $t4, $t4, 8			# change direction to move towards the right side
	sw $t4, 4($t2)				# update direction of BALL

	lw $t6, WHITE				# loads colour of left wall to check collision against it
	beq $t0, $t6, check_end_collide		# jumps back to check_collision if collision against left wall

	addi $sp, $sp, -4  			# move $sp to the next available location
	sw $ra, 0($sp)      			# push $ra to the stack

	move $a1, $t0
	move $a2, $t1
	jal hit_brick
	jal increment_score

	lw $ra, 0($sp)				# pop $ra from the stack
    addi $sp, $sp, 4			# restore $sp

	j check_end_collide

check_right:
#   Checks the right unit for collision
#   t0 stores the colour of the unit checking
#   t1 stores the location where to check
#   t2 stores the BALL object
#   t3 stores the current location of the BALL
#   t4 stores the current direction of the BALL
#   t5 stores background_colour
#   t6 stores white
	lw $t1, ADDR_DSPL
	la $t2, BALL 				# loads ball object
	lw $t3, 0($t2)				# loads the position into $t3
	lw $t4, 4($t2)				# loads the direction into $t4
	beq $t4, 124, check_end
	beq $t4, -132, check_end
	addi $t3, $t3, 4			# unit to the right
	add $t1, $t1, $t3			# stores the position of the unit to the right of the ball
	lw $t0, 0($t1)				# loads color of unit to the right of the ball

	lw $t5, BACKGROUND_COLOUR 		# loads the background colour
	beq $t0, $t5, check_end			# jumps back to check_collision if no collision on the right

	addi $t4, $t4, -8			# change direction to move towards the left side
	sw $t4, 4($t2)				# update direction of BALL

	lw $t6, WHITE				# loads colour of right wall to check collision against it
	beq $t0, $t6, check_end_collide		# jumps back to check_collision if collision against right wall

	addi $sp, $sp, -4  			# move $sp to the next available location
	sw $ra, 0($sp)      			# push $ra to the stack

	move $a1, $t0
	move $a2, $t1
	jal hit_brick
	jal increment_score

	lw $ra, 0($sp)				# pop $ra from the stack
    addi $sp, $sp, 4			# restore $sp
    	
	j check_end_collide

check_top:
#   Checks the top unit for collision
#   t0 stores the colour of the unit checking
#   t1 stores the location where to check
#   t2 stores the BALL object
#   t3 stores the current location of the BALL
#   t4 stores the current direction of the BALL
#   t5 stores background_colour
#   t6 stores white
	lw $t1, ADDR_DSPL
	la $t2, BALL 				# loads ball object
	lw $t3, 0($t2)				# loads the position into $t3
	lw $t4, 4($t2)				# loads the direction into $t4
	beq $t4, 124, check_end
	beq $t4, 132, check_end
	addi $t3, $t3, -128			# unit to the top
	add $t1, $t1, $t3			# stores the position of the unit to the top of the ball
	lw $t0, 0($t1)				# loads color of unit to the top of the ball

	lw $t5, BACKGROUND_COLOUR 		# loads the background colour
	beq $t0, $t5, check_end			# jumps back to check_collision if no collision on the top

	addi $t4, $t4, 256			# change direction to move towards the bottom side
	sw $t4, 4($t2)				# update direction of BALL

	lw $t6, WHITE				# loads colour of top wall to check collision against it
	beq $t0, $t6, check_end_collide		# jumps back to check_collision if collision against top wall

	addi $sp, $sp, -4  			    # move $sp to the next available location
	sw $ra, 0($sp)      			# push $ra to the stack

	move $a1, $t0
	move $a2, $t1
	jal hit_brick
	jal increment_score

	lw $ra, 0($sp)				# pop $ra from the stack
    addi $sp, $sp, 4			# restore $sp

	j check_end_collide

check_bottom:
#   Checks the bottom unit for collision
#   t0 stores the colour of the unit checking
#   t1 stores the location where to check
#   t2 stores the BALL object
#   t3 stores the current location of the BALL
#   t4 stores the current direction of the BALL
#   t5 stores background_colour
#   t6 stores white
	lw $t1, ADDR_DSPL
	la $t2, BALL 				# loads ball object
	lw $t3, 0($t2)				# loads the position into $t3
	lw $t4, 4($t2)				# loads the direction into $t4
	beq $t4, -124, check_end
	beq $t4, -132, check_end
	addi $t3, $t3, 128			# unit to the bottom
	add $t1, $t1, $t3			# stores the position of the unit to the bottom of the ball
	lw $t0, 0($t1)				# loads color of unit to the bottom of the ball
	
	bge $t3, 4224, life_end	    # checking if out of bounds is reached
	
	lw $t5, BACKGROUND_COLOUR 		# loads the background colour
	beq $t0, $t5, check_end			# jumps back to check_collision if no collision on the bottom
	
	addi $t4, $t4, -256			# change direction to move towards the top side
	sw $t4, 4($t2)				# update direction of BALL
	
	lw $t6, WHITE				# loads colour of paddle to check collision against it
	beq $t0, $t6, check_end_collide		# jumps back to check_collision if collision against bottom wall

	addi $sp, $sp, -4  			# move $sp to the next available location
	sw $ra, 0($sp)      			# push $ra to the stack

	move $a1, $t0
	move $a2, $t1
	jal hit_brick
	jal increment_score

	lw $ra, 0($sp)				# pop $ra from the stack
    addi $sp, $sp, 4			# restore $sp

	j check_end_collide

check_diagonal:
#   Checks the diagonal units for collision
#   t0 stores the colour of the unit checking
#   t1 stores the location where to check
#   t2 stores the BALL object
#   t3 stores the current location of the BALL
#   t4 stores the current direction of the BALL
#   t5 stores background_colour
#   t6 stores white
	lw $t1, ADDR_DSPL
	la $t2, BALL 				# loads ball object
	lw $t3, 0($t2)				# loads the position into $t3
	lw $t4, 4($t2)				# loads the direction into $t4
	add $t3, $t3, $t4			# unit in the diagonal direction
	add $t1, $t1, $t3			# stores the position of the unit to the diagonal of the ball
	lw $t0, 0($t1)				# loads color of unit to the diagonal of the ball

	lw $t5, BACKGROUND_COLOUR 		# loads the background colour
	beq $t0, $t5, check_end_collide		# jumps back to check_collision if no collision on the right
	
	neg $t4, $t4				# change direction to move towards the left side
	sw $t4, 4($t2)				# update direction of BALL

	lw $t6, WHITE				# loads colour of right wall to check collision against it
	beq $t0, $t6, check_end_collide		# jumps back to check_collision if collision against right wall

	addi $sp, $sp, -4  			# move $sp to the next available location
	sw $ra, 0($sp)      			# push $ra to the stack

	move $a1, $t0
	move $a2, $t1
	jal hit_brick
	jal increment_score

	lw $ra, 0($sp)				# pop $ra from the stack
    addi $sp, $sp, 4			# restore $sp

	j check_end_collide

check_end_collide:
	addi $v0, $zero, -1
	jr $ra
	
check_end:
	addi $v0, $zero, 1
    jr $ra

##############################################################################
# Handling ball out of bounds
##############################################################################
life_end:
#t0,t1 will have variable location
#t7 will be used to decrement it
#t2,t3,t4 will be used to move the ball and paddle to original position

	# Decrementing the amount of lives	
	la $t0, LIVES
	lw $t7, 0($t0)
	addi $t7, $t7, -1
	sw $t7, 0($t0)	
	
	# Removing old ball and paddle
	addi $sp, $sp, -4	# Move stack pointer to empty location and storing ra
	sw $ra, 0($sp)
	jal remove_ball
	jal remove_paddle
	lw $ra, 0($sp)		# Pop $ra off the stack
	addi $sp, $sp, 4	# Move the stack pointer back


	# Setting ball location to original location
	la $t2, INITIAL_BALL
	lw $t3, 0($t2)
	lw $t4, 4($t2)
	la $t5, BALL
	sw $t3, 0($t5) 
	sw $t4, 4($t5) 

	# Setting paddle location to original location
	la $t2, INITIAL_PADDLE
	lw $t3, 0($t2)
	la $t4, PADDLE
	sw $t3, 0($t4)
	
	# redrawing new paddle	
	addi $sp, $sp, -4	# Move stack pointer to empty location and storing ra
	sw $ra, 0($sp)
	jal draw_paddle		# Drawing hunderds digit
	lw $ra, 0($sp)		# Pop $ra off the stack
	addi $sp, $sp, 4	# Move the stack pointer back
	
	# Undrawing a life
	addi $sp, $sp, -4	# Move stack pointer to empty location and storing ra
	sw $ra, 0($sp)
	jal remove_lives
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	# Exiting game if all lives done
	blez $t7, exit_call
	
	b game_loop

# Function to draw lives	
draw_lives:
#t0 has color
#t7 has location to draw
	lw $t7, ADDR_DSPL
	lw $t0, GREEN
	addi $t7,$t7,116
	#sw $t0, 0($t7)
	sw $t0, 4($t7)
	
	addi $t7,$t7,256
	#sw $t0, 0($t7)
	sw $t0, 4($t7)
	
	addi $t7,$t7,256
	#sw $t0, 0($t7)
	sw $t0, 4($t7)
	
	jr $ra
	
#Undrawing lives
#Function that checks which life symbol to remove
remove_lives:
#t7 will have the value of LIVES
	addi $sp, $sp, -4	# Move stack pointer to empty location and storing $ra
	sw $ra, 0($sp)
	beq $t7,2,remove_one
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	addi $sp, $sp, -4	# Move stack pointer to empty location and storing $ra
	sw $ra, 0($sp)
	beq $t7,1,remove_two
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	addi $sp, $sp, -4	# Move stack pointer to empty location and storing $ra
	sw $ra, 0($sp)
	beq $t7,0,remove_three
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
#Undrawing a life symbol
remove_one:
	lw $t2, ADDR_DSPL
	lw $t0, BACKGROUND_COLOUR
	addi $t2,$t2,512
	addi $t2,$t2,116
	sw $t0, 4($t2)
	jr $ra
remove_two:
	lw $t8, ADDR_DSPL
	lw $t0, BACKGROUND_COLOUR
	addi $t8,$t8,256
	addi $t8,$t8,116
	sw $t0, 4($t8)
	jr $ra
remove_three:
	lw $t8, ADDR_DSPL
	lw $t0, BACKGROUND_COLOUR
	addi $t8,$t8,116
	sw $t0, 4($t8)
	jr $ra	

##############################################################################
# Handling Score drawings 
##############################################################################

increment_score:
# t4 will have the score variable location
# t5,t2,t3 will have the ones, tens, hundreds digit of score
	la $t4, SCORE
	lw $t5, 0($t4)
	lw $t2, 4($t4)
	lw $t3, 8($t4)
	beq $t5, 9, check_ones	# If the ones digit is 9
	
	# Increment and update score
	addi $t5, $t5, 1		
	sw $t5, 0($t4)
	jr $ra

update_high:
#   Updates the high score if score is greater than high score
	la $t0, HIGH_SCORE	
	la $t1, SCORE
	lw $t2, 0($t1)
	lw $t3, 4($t1)
	lw $t4, 8($t1)
	sw $t2, 0($t0)
	sw $t3, 4($t0)
	sw $t4, 8($t0)
    # resetting current score
	sw $zero, 0($t1)
	sw $zero, 4($t1)
	sw $zero, 8($t1)
	j main

check_ones:
	beq $t2, 9, check_tens		# If the tens digit is 9
	
	# Increment and update score
	addi $t2, $t2, 1
	sw $t2, 4($t4)
	addi $t5, $t5, -9
	sw $t5, 0($t4)
	jr $ra

check_tens:
	# Increment and update score
	addi $t3, $t3, 1
	sw $t3, 8($t4)
	addi $t2, $t2, -9
	sw $t2, 4($t4)
	addi $t5, $t5, -9
	sw $t5, 0($t4)
	jr $ra

check_scores_current:
    la $t4, SCORE
    lw $t0, ADDR_DSPL
    j check_scores

check_high_score:    
    la $t4, HIGH_SCORE
    lw $t0, ADDR_DSPL
    addi $t0, $t0, 48
    lw $t1, WHITE
    sw $t1, 0($t0)
    sw $t1, 128($t0)
    sw $t1, 256($t0)
    sw $t1, 384($t0)
    sw $t1, 512($t0)
    addi $t0, $t0, 8
    j check_scores

check_scores:
# t4 will have the score variable location
# t5 will have the digits as it changes
# t0 will have the location do draw the numbers
# t1 will have the colour
	lw $t5, 8($t4)
	lw $t1, BACKGROUND_COLOUR
	
	addi $sp, $sp, -4	# Move stack pointer to empty location and storing ra
	sw $ra, 0($sp)
	jal undraw_score	# Function to erase older score display
	lw $ra, 0($sp)		# Pop $ra off the stack
	addi $sp, $sp, 4	# Move the stack pointer back	

	lw $t1, RED
	addi $sp, $sp, -4	# Move stack pointer to empty location and storing ra
	sw $ra, 0($sp)
	jal check		# Drawing hunderds digit
	lw $ra, 0($sp)		# Pop $ra off the stack
	addi $sp, $sp, 4	# Move the stack pointer back
	
	addi $t0, $t0, 16
	lw $t5, 4($t4)
	
	addi $sp, $sp, -4	# Move stack pointer to empty location and storing ra
	sw $ra, 0($sp)
	jal check		# drawing tens digit
	lw $ra, 0($sp)		# Pop $ra off the stack
	addi $sp, $sp, 4	# Move the stack pointer back
	
	addi $t0, $t0, 16
	lw $t5, 0($t4)
	
	addi $sp, $sp, -4	# Move stack pointer to empty location and storing ra
	sw $ra, 0($sp)
	jal check		# drawing ones digit
	lw $ra, 0($sp)		# Pop $ra off the stack
	addi $sp, $sp, 4	# Move the stack pointer back
	
	jr $ra

check:
	# Checks what is the score digit equal to
	beq $t5,0,draw_zero
	beq $t5,1,draw_one
	beq $t5,2,draw_two
	beq $t5,3,draw_three
	beq $t5,4,draw_four
	beq $t5,5,draw_five
	beq $t5,6,draw_six
	beq $t5,7,draw_seven
	beq $t5,8,draw_eight
	beq $t5,9,draw_nine
	
undraw_score:
	# This function is used to remove the old score by drawing eight which uses all pixels
	addi $sp, $sp, -4	# Move stack pointer to empty location and storing ra
	sw $ra, 0($sp)
	jal draw_eight
	lw $ra, 0($sp)		# Pop $ra off the stack
	addi $sp, $sp, 4	# Move the stack pointer back
	
	addi $t0, $t0, 16
	addi $sp, $sp, -4	# Move stack pointer to empty location and storing ra
	sw $ra, 0($sp)
	jal draw_eight
	lw $ra, 0($sp)		# Pop $ra off the stack
	addi $sp, $sp, 4	# Move the stack pointer back
	
	addi $t0, $t0, 16
	addi $sp, $sp, -4	# Move stack pointer to empty location and storing ra
	sw $ra, 0($sp)
	jal draw_eight
	lw $ra, 0($sp)		# Pop $ra off the stack
	addi $sp, $sp, 4	# Move the stack pointer back
	addi $t0, $t0, -32
	jr $ra

##############################################################################
# Handling requests to move paddle 
##############################################################################
move_paddle_left:
    # t0 stores the paddle word location
    # t2 stores another paddle word location instance   
    # t4 stores the exact pixel address of the paddle currently
    

	#lw $t1, ADDR_DSPL
	la $t2, PADDLE
	lw $t4, 0($t2)

	beq $t4, 3972, end_move_paddle_left 	# Checking if near the left end and if so doing nothing

    jal remove_paddle # Removing the old paddle
	
	# Moving the paddle				
	la $t0, PADDLE
	addi $t4, $t4,-4  # moving it a pixel left by adding -4 
	sw $t4, 0($t0)    # updating the location variable
    jal draw_paddle   # drawing new paddle

    b game_loop	# back to game_loop
	
	
end_move_paddle_left:
	b game_loop
	
move_paddle_right:
    # t0 stores the paddle word location
    # t2 stores another paddle word location instance   
    # t4 stores the exact pixel address of the paddle currently
	
	#lw $t1, ADDR_DSPL
	la $t2, PADDLE
	lw $t4, 0($t2)
	
	beq $t4, 4072, end_move_paddle_left	# Checking if near the right end and if so doing nothing

    jal remove_paddle	# removing the old paddle 
	
	# Moving the paddle				
	la $t0, PADDLE
	addi $t4, $t4,4 	# moving the paddle to the right a pixel by adding 4
	sw $t4, 0($t0)         # updating paddle location
    jal draw_paddle		# drawing new paddle

    b game_loop	# back to game_loop
	
	
end_move_paddle_right:
	b game_loop
	
##############################################################################
# Handling drawing ball and paddle requests 
##############################################################################
draw_ball:
#   Draw a GRAY 1 unit ball on the display using the
#   location in the BALL object.
#   t0 stores the colour gray
#   t1 stores the location where to draw
#   t2 stores the BALL object
#   t3 stores the current location of the BALL
	lw $t1, ADDR_DSPL
	lw $t0, GRAY
	la $t2, BALL 				# loads ball object
	lw $t3, 0($t2)				# loads the position into $t3
	add $t1, $t1, $t3
	sw $t0, 0($t1)
	jr $ra

draw_paddle:
#   Draw a WHITE 5x1 paddle on the display using the
#   location in the PADDLE object.
#   t0 stores the colour white
#   t1 stores the location where to draw
#   t2 stores the PADDLE object
#   t3 stores the current location of the PADDLE
	lw $t1, ADDR_DSPL
	la $t2, PADDLE
	lw $t3, 0($t2)
	add $t1, $t1, $t3
	lw $t0, WHITE
	sw $t0, 0($t1)
	sw $t0, 4($t1)
	sw $t0, 8($t1)
	sw $t0, 12($t1)
	sw $t0, 16($t1)
	jr $ra

remove_paddle:
#   Erase the WHITE 5x1 paddle on the display using the
#   location in the PADDLE object.
#   t0 stores the background colour
#   t1 stores the location where to draw
#   t2 stores the PADDLE object
#   t3 stores the current location of the PADDLE
	lw $t1, ADDR_DSPL
	la $t2, PADDLE
	lw $t3, 0($t2)
	add $t1, $t1, $t3
	lw $t0, BACKGROUND_COLOUR
	sw $t0, 0($t1)
	sw $t0, 4($t1)
	sw $t0, 8($t1)
	sw $t0, 12($t1)
	sw $t0, 16($t1)
	jr $ra

move_ball:
#   Erases the BALL from its current position and updates its
#   location in the BALL object by using its direction and current position.
#   t0 stores the BALL object
#   t3 stores the updated location of the BALL
#   t4 stoes the current direction of the BALL
	addi $sp, $sp, -4  			# move $sp to the next available location
	sw $ra, 0($sp)      			# push $ra to the stack
	jal remove_ball
	la $t0, BALL 				# loads ball object stores it in $t0
	lw $t4, 4($t0)				# loads the direction into $t4
	add $t3, $t3, $t4			# sets $t3 to new position
	sw $t3, 0($t0)
	jal draw_ball
	lw $ra, 0($sp)				# pop $ra from the stack
    addi $sp, $sp, 4			# restore $sp
    jr $ra

remove_ball:
#   Erase the BALL on the display using the
#   location in the BALL object.
#   t0 stores the background colour
#   t1 stores the location where to draw
#   t2 stores the BALL object
#   t3 stores the current location of the BALL
	lw $t1, ADDR_DSPL
	la $t2, BALL
	lw $t3, 0($t2)
	add $t1, $t1, $t3
	lw $t0, BACKGROUND_COLOUR
	sw $t0, 0($t1)
	jr $ra

##############################################################################
# Drawing the bricks 
##############################################################################
draw_bricks:
# t0 will store the colour of the row
# t1 will store the location of the right corner of the row
	lw $t1, ADDR_DSPL	# Getting the top corner address
	addi $t1, $t1, 772	# Skipping six rows
	
	lw $t0, RED		# Getting the colour 
	addi $sp, $sp, -4	# Move stack pointer to empty location and storing ra
	sw $ra, 0($sp)
	jal draw_row
	lw $ra, 0($sp)		# Pop $ra off the stack
	addi $sp, $sp, 4	# Move the stack pointer back
    
	# New row
	lw $t0, GREEN	        # Getting the colour
	addi $t1, $t1, 8
	addi $sp, $sp, -4	# Move stack pointer to empty location and storing ra		
	sw $ra, 0($sp)
	jal draw_row
	lw $ra, 0($sp)		# Pop $ra off the stack
	addi $sp, $sp, 4	# Move the stack pointer back

	# New row
	lw $t0, BLUE	        # Getting the colour
	addi $t1, $t1, 8
	addi $sp, $sp, -4	# Move stack pointer to empty location and storing ra		
	sw $ra, 0($sp)
	jal draw_row
	lw $ra, 0($sp)		# Pop $ra off the stack
	addi $sp, $sp, 4	# Move the stack pointer back
	
# adding more space to a1 so a row is skipped
	addi $t1, $t1, 128

#New Row
	lw $t0, RED		# Getting the colour
	addi $t1, $t1, 8
	addi $sp, $sp, -4	# Move stack pointer to empty location and storing ra		
	sw $ra, 0($sp)
	jal draw_row
	lw $ra, 0($sp)		# Pop $ra off the stack
	addi $sp, $sp, 4	# Move the stack pointer back
	
# adding more space to a1 so a row is skipped
	addi $t1, $t1, 128

#New Row
	lw $t0, BLUE		# Getting the colour
	addi $t1, $t1, 8
	addi $sp, $sp, -4	# Move stack pointer to empty location and storing ra		
	sw $ra, 0($sp)
	jal draw_row
	lw $ra, 0($sp)		# Pop $ra off the stack
	addi $sp, $sp, 4	# Move the stack pointer back
	
	jr $ra

draw_row:
    # t0 has the colour
    # t1 has the location of the pixel to start drawing at
    # t2 stores the ending number for the loop
    # t5 stores the loop counter 
    
	add $t2, $zero, 120	# 120 will be how long the row is
	add $t5, $zero, $zero	# setting the loop counter to 0

draw_row_loop:
	beq $t2, $t5, end_draw_row	# looping until all the row pixels are drawn
	sw $t0, 0($t1)			# drawing the pixel at t1 with colour t0
	addi $t1, $t1, 4		# incrementing the location
	addi $t5, $t5, 4		# incrementing the counter
	j draw_row_loop			# re iterating

end_draw_row:
	jr $ra

##############################################################################
# Drawing the walls 
##############################################################################
draw_top:
   # t1 will have the 128 a constant used in the loop
   # t3 will have the pointer where to draw
   # t4 will have the colour
   # t5 will have loop counter
	add $t1, $zero, 128			# the value to compare to once loop reaches end of row
	lw $t3, ADDR_DSPL			# Getting the address of the top left corner
	addi $t3, $t3, 640			# Adding 640 to it to skip 5 rows
	lw $t4, WHITE				# setting the colour to white
	add $t5, $zero, $zero			# loop counter

draw_top_loop:
	beq $t5, $t1, end_draw_top		# loop until whole row is drawn
	sw $t4, 0($t3)				# drawing
	addi $t3, $t3, 4			# incrementing location to draw
	addi $t5, $t5, 4			# incrementing counter
	j draw_top_loop				# re iterating

end_draw_top:
	jr $ra

draw_left:
# t1 will have the 3840 a constant used in the loop
# t3 will have the pointer where to draw
# t4 will have the colour
# t5 will have loop counter
	add $t1, $zero, 26			# the value to compare to once loop reaches end of row
	lw $t3, ADDR_DSPL			# Getting the address of the top left corner
	addi $t3, $t3, 640			# Adding 640 to it to skip 5 rows
	lw $t4, WHITE				# setting the colour to white
	add $t5, $zero, $zero			# loop counter

draw_left_loop:
	beq $t5, $t1, end_draw_left		# looping until the whole left wall drawn
	sw $t4, 0($t3)				# drawing
	addi $t3, $t3, 128			# incrementing location by a row
	addi $t5, $t5, 1			# incrementing loop counter
	j draw_left_loop			# re iterating

end_draw_left:
	lw $t4, GREEN				# Drawing the last pixel in green
	sw $t4, 0($t3)
	jr $ra

draw_right:
# t1 will have the 3836 a constant used in the loop
# t3 will have the pointer where to draw
# t4 will have the colour
# t5 will have loop counter
	add $t1, $zero, 26			# the value to compare to once loop reaches end of row
	lw $t3, ADDR_DSPL			# Getting the address of the top left corner
	addi $t3, $t3, 892			# Adding 892 to it to get to the starting position of right wall
	lw $t4, WHITE				# setting the colour to white
	add $t5, $zero, 1			# loop counter

draw_right_loop:
	beq $t5, $t1, end_draw_right		# looping until the whole right wall drawn
	sw $t4, 0($t3)				# drawing
	addi $t3, $t3, 128			# incrementing location by a row
	addi $t5, $t5, 1			# incrementing loop counter
	j draw_right_loop			# re iterating 

end_draw_right:
	lw $t4, RED				# drawing the last pixel in red
	sw $t4, 0($t3)
	jr $ra

##############################################################################
# Functions to draw numbers, letters and a black screen
##############################################################################
draw_zero:
#t0 will have the starting location
#t1 will have the colour
    sw $t1, 0($t0)
    sw $t1, 4($t0)
    sw $t1, 8($t0)
    sw $t1, 128($t0)
    sw $t1, 136($t0)
    sw $t1, 256($t0)
    sw $t1, 264($t0)
    sw $t1, 384($t0)
    sw $t1, 392($t0)
    sw $t1, 512($t0)
    sw $t1, 516($t0)
    sw $t1, 520($t0)
    jr $ra

draw_one:
#t0 will have the starting location
#t1 will have the colour
    sw $t1, 8($t0)
    sw $t1, 136($t0)
    sw $t1, 264($t0)
    sw $t1, 392($t0)
    sw $t1, 520($t0)
    jr $ra

draw_two:
#t0 will have the starting location
#t1 will have the colour
    sw $t1, 0($t0)
    sw $t1, 4($t0)
    sw $t1, 8($t0)
    sw $t1, 136($t0)
    sw $t1, 256($t0)
    sw $t1, 260($t0)
    sw $t1, 264($t0)
    sw $t1, 384($t0)
    sw $t1, 512($t0)
    sw $t1, 516($t0)
    sw $t1, 520($t0)
    jr $ra

draw_three:
#t0 will have the starting location
#t1 will have the colour
    sw $t1, 0($t0)
    sw $t1, 4($t0)
    sw $t1, 8($t0)
    sw $t1, 136($t0)
    sw $t1, 256($t0)
    sw $t1, 260($t0)
    sw $t1, 264($t0)
    sw $t1, 392($t0)
    sw $t1, 512($t0)
    sw $t1, 516($t0)
    sw $t1, 520($t0)
    jr $ra

draw_four:
#t0 will have the starting location
#t1 will have the colour
    sw $t1, 0($t0)
    sw $t1, 8($t0)
    sw $t1, 128($t0)
    sw $t1, 136($t0)
    sw $t1, 256($t0)
    sw $t1, 260($t0)
    sw $t1, 264($t0)
    sw $t1, 392($t0)
    sw $t1, 520($t0)
    jr $ra

draw_five:
#t0 will have the starting location
#t1 will have the colour
    sw $t1, 0($t0)
    sw $t1, 4($t0)
    sw $t1, 8($t0)
    sw $t1, 128($t0)
    sw $t1, 256($t0)
    sw $t1, 260($t0)
    sw $t1, 264($t0)
    sw $t1, 392($t0)
    sw $t1, 512($t0)
    sw $t1, 516($t0)
    sw $t1, 520($t0)
    jr $ra

draw_six:
#t0 will have the starting location
#t1 will have the colour
    sw $t1, 0($t0)
    sw $t1, 4($t0)
    sw $t1, 8($t0)
    sw $t1, 128($t0)
    sw $t1, 256($t0)
    sw $t1, 260($t0)
    sw $t1, 264($t0)
    sw $t1, 384($t0)
    sw $t1, 392($t0)
    sw $t1, 512($t0)
    sw $t1, 516($t0)
    sw $t1, 520($t0)
    jr $ra

draw_seven:
#t0 will have the starting location
#t1 will have the colour
    sw $t1, 0($t0)
    sw $t1, 4($t0)
    sw $t1, 8($t0)
    sw $t1, 136($t0)
    sw $t1, 264($t0)
    sw $t1, 392($t0)
    sw $t1, 520($t0)
    jr $ra

draw_eight:
#t0 will have the starting location
#t1 will have the colour
    sw $t1, 0($t0)
    sw $t1, 4($t0)
    sw $t1, 8($t0)
    sw $t1, 128($t0)
    sw $t1, 136($t0)
    sw $t1, 256($t0)
    sw $t1, 260($t0)
    sw $t1, 264($t0)
    sw $t1, 384($t0)
    sw $t1, 392($t0)
    sw $t1, 512($t0)
    sw $t1, 516($t0)
    sw $t1, 520($t0)
    jr $ra

draw_nine:
#t0 will have the starting location
#t1 will have the colour
    sw $t1, 0($t0)
    sw $t1, 4($t0)
    sw $t1, 8($t0)
    sw $t1, 128($t0)
    sw $t1, 136($t0)
    sw $t1, 256($t0)
    sw $t1, 260($t0)
    sw $t1, 264($t0)
    sw $t1, 392($t0)
    sw $t1, 512($t0)
    sw $t1, 516($t0)
    sw $t1, 520($t0)
    jr $ra

draw_game_over:
    lw $t0, ADDR_DSPL
    lw $t1, WHITE
    addi $t0, $t0, 1312
    # draw G
    sw $t1, 0($t0)
    sw $t1, 4($t0)
    sw $t1, 8($t0)
    sw $t1, 128($t0)
    sw $t1, 256($t0)
    sw $t1, 384($t0)
    sw $t1, 392($t0)
    sw $t1, 512($t0)
    sw $t1, 516($t0)
    sw $t1, 520($t0)
    
    addi $t0, $t0, 16
    # draw A
    sw $t1, 4($t0)
    sw $t1, 128($t0)
    sw $t1, 136($t0)
    sw $t1, 256($t0)
    sw $t1, 264($t0)
    sw $t1, 384($t0)
    sw $t1, 388($t0)
    sw $t1, 392($t0)
    sw $t1, 512($t0)
    sw $t1, 520($t0)

    addi $t0, $t0, 16
    # draw M
    sw $t1, 0($t0)
    sw $t1, 8($t0)
    sw $t1, 128($t0)
    sw $t1, 132($t0)
    sw $t1, 136($t0)
    sw $t1, 256($t0)
    sw $t1, 264($t0)
    sw $t1, 384($t0)
    sw $t1, 392($t0)
    sw $t1, 512($t0)
    sw $t1, 520($t0)

    addi $t0, $t0, 16
    # draw E
    sw $t1, 0($t0)
    sw $t1, 4($t0)
    sw $t1, 8($t0)
    sw $t1, 128($t0)
    sw $t1, 256($t0)
    sw $t1, 260($t0)
    sw $t1, 264($t0)
    sw $t1, 384($t0)
    sw $t1, 512($t0)
    sw $t1, 516($t0)
    sw $t1, 520($t0)

    addi $t0, $t0, 720
    # draw O
    sw $t1, 4($t0)
    sw $t1, 128($t0)
    sw $t1, 136($t0)
    sw $t1, 256($t0)
    sw $t1, 264($t0)
    sw $t1, 384($t0)
    sw $t1, 392($t0)
    sw $t1, 516($t0)

    addi $t0, $t0, 16
    # draw V
    sw $t1, 0($t0)
    sw $t1, 8($t0)
    sw $t1, 128($t0)
    sw $t1, 136($t0)
    sw $t1, 256($t0)
    sw $t1, 264($t0)
    sw $t1, 384($t0)
    sw $t1, 392($t0)
    sw $t1, 516($t0)

    addi $t0, $t0, 16
    # draw E
    sw $t1, 0($t0)
    sw $t1, 4($t0)
    sw $t1, 8($t0)
    sw $t1, 128($t0)
    sw $t1, 256($t0)
    sw $t1, 260($t0)
    sw $t1, 264($t0)
    sw $t1, 384($t0)
    sw $t1, 512($t0)
    sw $t1, 516($t0)
    sw $t1, 520($t0)

    addi $t0, $t0, 16
    # draw R
    sw $t1, 0($t0)
    sw $t1, 4($t0)
    sw $t1, 8($t0)
    sw $t1, 128($t0)
    sw $t1, 136($t0)
    sw $t1, 256($t0)
    sw $t1, 260($t0)
    sw $t1, 264($t0)
    sw $t1, 384($t0)
    sw $t1, 388($t0)
    sw $t1, 512($t0)
    sw $t1, 520($t0)
    jr $ra

draw_black_screen:
#   Draws a black screen by nested loops
#   t0 loops over number of rows
#   t1 loops over number of columns
#   t2 stores background colour
#   t3 stores the location
    addi $t0, $zero, 32
    lw $t2, BACKGROUND_COLOUR
    lw $t3, ADDR_DSPL

draw_black_screen_outer_loop:
    beq $t0, $zero, draw_black_screen_end
    addi $t0, $t0, -1
    addi $t1, $zero, 32
    j draw_black_screen_inner_loop

draw_black_screen_inner_loop:
    beq $t1, $zero, draw_black_screen_outer_loop
    sw $t2, 0($t3)
    addi $t3, $t3, 4
    addi $t1, $t1, -1
    j draw_black_screen_inner_loop

draw_black_screen_end:
    jr $ra

exit:
	li $v0, 10              	# terminate the program gracefully
	syscall

exit_call:
    jal draw_black_screen
    jal draw_game_over
    li $a0, 75
    li $a1, 1000
    li $a2, 121
    li $a3, 100
    li $v0, 31
    syscall
    b exit_loop

exit_pause:
    # Getting the next keyboard input and calling the appropriate action if valid key 	
	addi $v0, $zero, -1
	lw $a0, 4($t0)                  # Load next word from keyboard
	beq $a0, 0x71, exit    		    # check if the key q was pressed
	beq $a0, 0x72, r_pressed		# check if the key r was pressed
	b exit_loop			         	# if anything else was pressed, keep the game paused

exit_loop: 
#   The game is paused during this loop unless a buttom is pressed
	lw $t0, ADDR_KBRD			# $t0 = base address for keyboard
	lw $t8, 0($t0)                  	# Load first word from keyboard
	beq $t8, 1, exit_pause      		# If first word 1, key is pressed
	b exit_loop