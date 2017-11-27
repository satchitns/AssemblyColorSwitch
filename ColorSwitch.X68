START ORG $1000 

DRAWING_MODE            EQU 92
SET_OUTPUT_WINDOW       EQU 33
DOUBLE_BUFFERED_MODE    EQU 17
REPAINT_SCREEN          EQU 94
BALL_WIDTH              EQU 20
BALL_HEIGHT             EQU 20
SET_PEN_COLOR           EQU 80
SET_FILL_COLOR          EQU 81
SET_PEN_WIDTH           EQU 93
SET_FONT_PROPS          EQU 21
DRAW_PIXEL              EQU 23245242
DRAW_LINE_FROM_TO       EQU 84
DRAW_LINE_TO            EQU 85
DRAW_CIRCLE             EQU 88
KEY_TRAP                EQU 19
DRAW_STRING             EQU 95
TIME                    EQU 8
DEBOUNCETIME            EQU 200
GET_PIXEL               EQU 83
ALL_REGS                REG d0-d7/a0-a6
SCREEN_WIDTH            EQU 640
SCREEN_HEIGHT           EQU 480
COLOR_RED               EQU $003c00ff
COLOR_YELLOW            EQU $0000baff
COLOR_PURPLE            EQU $00ff006c
COLOR_BLUE              EQU $00ffba00
BALL_INIT_Y_POS         EQU 430<<8
FONT_SIZE               EQU 18

    *SCREEN SETUP*
    move.b  #SET_OUTPUT_WINDOW, d0
    move.l  #SCREEN_WIDTH*$10000+SCREEN_HEIGHT,D1        
    trap    #15
    
    *DOUBLE BUFFERED DRAWING*
    moveq.l	#DRAWING_MODE,d0
    moveq.l	#DOUBLE_BUFFERED_MODE,d1
  	trap    #15
  	
  	jsr     LoadSounds
  	
StartingPoint:
  	*DRAWING BACKGROUND ONCE*
    jsr	    DrawBackground
    
    jsr     GetRandomColorInD6
    move.l  d6, BALL_COLOR
    jsr     ClearObstacleAndPowerupLists
    *SPAWN FIRST OBSTACLE*
    lea     OBSTACLE_LIST, a0
    add.l   #1, OBSTACLE_COUNT
    move.w  BOX_S_X_INIT, d0
    move.l  BOX_S_Y_INIT, d1
    jsr     SpawnFirstBox
    
    *MAYBE SPAWN A POWERUP TOO* 
    move.w  BOX_S_X_INIT, SCORE_X
    move.l  BOX_S_Y_INIT, SCORE_Y
    jsr     RollDieToSpawnPowerup
    
    jsr     SmallDelay
    jsr     AddNewObstacle
    jsr     SmallDelay
    jsr     AddNewObstacle
    jsr     DrawInstructions
PreGame:
    *SET UP THE GAME*
    jsr     UpdateObstacles
    jsr     DrawBall
    jsr     DrawScore
    jsr     SwapBuffers

PreGameLoop:
    *LOOPS TILL INPUT IS RECEIVED*
    jsr     GetDeltaTime
    jsr     InstructionLoop
    jsr     SwapBuffers
    move.b  #KEY_TRAP, d0
    move.l  #' ', d1
    trap    #15
    btst    #0, d1
    beq     PreGameLoop
    
    jsr     ClearInstructions
    jsr     PlayTheme
    
    move.l  #TIME, d0
    trap    #15

    move.l  d1, (PREV_TIME)      ;setting up previous time for the first delta calculation
    
GameLoop:
    *MAIN GAME LOOP - RUNS EVERY FRAME OF THE GAME*
    jsr     GetDeltaTime
    jsr     DrawBgChunk
    jsr     UpdateObstacles
    jsr     UpdatePowerups
    jsr     UpdateSwitchers
    jsr     GetKeyUps
    jsr     GetInput
    jsr     UpdateBall      
    jsr     CheckCollision
    jsr     DrawBall   
    jsr     SwapBuffers
    bra.s   GameLoop
        
SwapBuffers:
    *SWAPS THE BUFFERS IN DOUBLE BUFFERED MODE*
	move.b  #REPAINT_SCREEN,d0
  	trap    #15
    rts  

ClearAllRegs:
    *CLEARS ALL DATA REGISTERS*
    clr.l   d0
    clr.l   d1
    clr.l   d2
    clr.l   d3
    clr.l   d4
    clr.l   d5
    clr.l   d6
    clr.l   d7
    rts
	    
GetDeltaTime:
    *SUBTRACTS PREV_TIME FROM CURRENT_TIME TO GET DELTA TIME*
    move.l  #TIME, d0
    trap    #15
    move.l  d1, d0
    sub.l   (PREV_TIME), d1
    move.w  d1, (DELTA_TIME)
    move.l  d0, (PREV_TIME)
    rts
        
GetKeyUps:
    *SETS KEY_PRESSED TO 0 IF INPUT KEY WAS NOT PRESSED LAST FRAME*
    move.l  #KEY_TRAP, d0
    move.l  #' ', d1
    trap    #15
    btst.l  #0, d1
    bne     EndKeyUp
    move.l  #0, (KEY_PRESSED)
EndKeyUp
    rts     
        
GetInput:
    *READS INPUT KEY AND ADDS FORCE TO BALL IF PRESSED*
    
    *debounce logic
    move.l  (DELTA_TIME), d0
    add.l   d0, (TIME_SINCE_LAST_KEY)
    cmp.l   #DEBOUNCETIME, (TIME_SINCE_LAST_KEY)
    ble     Done
    
ProceedGettingInput
    *check if key was pressed last frame
    cmp.l   #0, (KEY_PRESSED)
    bne     Done
    
    *check if key was  pressed this frame, and add force to ball
    move.b  #KEY_TRAP, d0
    move.l  #' ', d1
    trap    #15
    btst    #0, d1
    beq     done
    move.l  #0, (TIME_SINCE_LAST_KEY)
    move.l  #1, (KEY_PRESSED)
    jsr     AddForceToBall
Done
    rts
        
        
DrawBackground:
    *DRAWS THE BACKGROUND BITMAP*
    movem.l ALL_REGS, -(sp)
    
    sub.l   #32, sp
    
    *moving all the argument values into stack
    move.l  #Background, DrawBitmapAddress(sp)
    move.l  #0, DrawBitmapX(sp)
    move.l  #0, DrawBitmapY(sp)
    move.l  #SCREEN_WIDTH, DrawBitmapWidth(sp)
    move.l  #SCREEN_HEIGHT, DrawBitmapHeight(sp)
    move.l  #0, DrawBitmapScreenX(sp)
    move.l  #0, DrawBitmapScreenY(sp)
    move.l  #0, PrintAbsolute(sp)
    
    jsr     DrawBitmap
    
    add.l   #32, sp
    
    movem.l (sp)+, ALL_REGS
    
    rts
    
     
     
EndGame:
    *PERFORMS END-GAME CLEANUP AND DRAWS INFO*
    jsr     PlayDeathSound
    move.l  #$00c6c6c6, BALL_COLOR
    jsr     DrawBall                        ;draw the ball in light grey 
    move.l  #SET_FILL_COLOR, d0
    move.l  #$00FFFFFF, d1                  ;set the text bg to be white
    trap    #15
    
    move.l  #SET_FONT_PROPS, d0             ;set font properties
    move.l  NEUTRAL_COLOR, d1               ;draw the text in neutral
    move.l  FONT_PROP, d2                   ;move  predefined properties in
    trap    #15
    
    lea     END_DIGITS, a0
    lea     SCORE_DIGITS, a1
    
    add.b   #$30, (a0)                      ;change to ascii 0
    move.b  2(a1), d0
    add.b   d0, (a0)                        ;move first score digit into last display digit
    
    add.b   #$30, 1(a0)                     ;change to ascii 0
    move.b  1(a1), d0
    add.b   d0, 1(a0)                       ;move 2nd score digit to 2nd display digit
    
    add.b   #$30, 2(a0)                     ;change to ascii 0
    move.b  (a1), d0
    add.b   d0, 2(a0)                       ;move the last score digit to the first display digit
    
    move.l  #DRAW_STRING, d0
    move.w  MESSAGE_X, d1
    move.w  MESSAGE_Y, d2
    lea     EndMessage, a1                  ;draw the game over + score message
    trap    #15
    
    
    movem.l ALL_REGS, -(sp)

    jsr     CheckHighScore                  ;check if we got the high score

    movem.l (sp)+, ALL_REGS
    
    add.w   #FONT_SIZE, d2
    add.w   #FONT_SIZE, d2
    lea     HighScoreMessage, a1        
    trap    #15                             ;print the previous high score anyway
    
    cmp.l   #0, IS_HIGH_SCORE               ;if we got high score, mention that
    beq     GoToRestart
    
    add.w   #FONT_SIZE, d2
    add.w   #FONT_SIZE, d2
    
    movem.l d1-d2, -(sp)
    
    move.l  #SET_FONT_PROPS, d0
    move.l  #$000000ff, d1
    move.l  FONT_PROP, d2                   ;we want high score message to be in red
    
    trap    #15
    
    movem.l (sp)+, d1-d2

    move.l  #DRAW_STRING, d0
    lea     IsHighScoreMessage, a1          ;print the message
    trap    #15
    
GoToRestart
    movem.l d1-d2, -(sp)
    
    move.l  #SET_FONT_PROPS, d0
    move.l  NEUTRAL_COLOR, d1
    move.l  FONT_PROP, d2
    
    trap    #15                             ;setting the color back to neutral
    
    movem.l (sp)+, d1-d2
    
    move.l  #DRAW_STRING, d0
    add.w   #FONT_SIZE, d2
    add.w   #FONT_SIZE, d2
    lea     RestartMessage, a1              ;print restart helper
    trap    #15
    jsr     SwapBuffers                     ;draw all this stuff on screen
    jsr     StopTheme                       ;stop the main theme 
    
EndLoop
    *LOOPS TILL INPUT IS RECEIVED*
    move.b  #KEY_TRAP, d0
    move.l  #'R', d1
    trap    #15
    btst    #0, d1
    beq     EndLoop
    
Restart
    *SET ALL VARIABLES TO DEFAULT VALUES AND GO TO START*
    move.l  #0, OBSTACLE_LIST
    move.l  #BALL_INIT_Y_POS, BALLPOS_Y
    move.l  #0, BALL_Y_VEL
    move.l  #0, BALL_Y_VEL_ADJUSTED
    move.l  #0, KEY_PRESSED
    move.b  #0, ABOVE_MID
    move.l  #0, SCORE
    move.w  #300, MESSAGE_Y
    move.l  #0, IS_HIGH_SCORE
    jsr     ClearObstacleAndPowerupLists
    jsr     ResetScore
    jmp     StartingPoint
   
CheckHighScore:
    *COMPARES CURRENT SCORE WITH HIGH SCORE AND UPDATES HIGH SCORE AND FLAG IF NECESSARY*
    move.l  SCORE, d2
    cmp.l   HIGH_SCORE, d2
    ble     EndHighScoreCheck
    *if high score*
    move.l  d2, HIGH_SCORE
    move.l  #1, IS_HIGH_SCORE
    lea     HIGH_SCORE_DIGITS, a0
    lea     END_DIGITS, a1
    move.b  (a1)+, (a0)+
    move.b  (a1)+, (a0)+
    move.b  (a1), (a0)
EndHighScoreCheck
    rts
    
    
    
SmallDelay:
    *CREATES A SMALL DELAY*
    move.l  #$7FFF, d0
DelayLoop:
    sub.l   #1, d0
    beq     QuitDelay
    bra     DelayLoop
QuitDelay
    rts


InstructionLoop:
    *BLINKS THE INSTRUCTIONS BETWEEN GLOWING AND NOT*
    clr.l   d0
    move.w  DELTA_TIME, d0
    add.l   d0, ELAPSED_INS_TIME
    cmp.l   #50, ELAPSED_INS_TIME
    blt     QuitIns
    not.l   GLOW
    move.l  #0, ELAPSED_INS_TIME
QuitIns
    jsr     DrawInstructions
    rts

DrawInstructions:
    *DRAW THE VERSION OF THE INSTRUCTION BITMAP DECIDED BY THE GLOW FLAG*
    movem.l ALL_REGS, -(sp)
    
    sub.l   #32, sp
    
    *moving all the argument values into stack
    btst    #0, GLOW
    beq     Normal
    move.l  #InstructionsGlow, DrawBitmapAddress(sp)
    bra.s   AfterNormal
Normal
    move.l  #Instructions, DrawBitmapAddress(sp)
AfterNormal
    move.l  #0, DrawBitmapX(sp)
    move.l  #0, DrawBitmapY(sp)
    move.l  #234, DrawBitmapWidth(sp)
    move.l  #72, DrawBitmapHeight(sp)
    move.l  #203, DrawBitmapScreenX(sp)
    move.l  #250, DrawBitmapScreenY(sp)
    move.l  #0, PrintAbsolute(sp)
    
    jsr     DrawBitmap
    
    add.l   #32, sp
    
    movem.l (sp)+, ALL_REGS
    
    rts
    
ClearInstructions:
    *CLEAR THE PREVIOUS IMAGE OF THE INSTRUCTION WITH A GREY RECT*
    movem.l ALL_REGS, -(sp)
    
    sub.l   #32, sp
   
    move.l  #Background, DrawBitmapAddress(sp)

    move.l  #203, DrawBitmapX(sp)
    move.l  #250, DrawBitmapY(sp)
    move.l  #234, DrawBitmapWidth(sp)
    move.l  #72, DrawBitmapHeight(sp)
    move.l  #0, DrawBitmapScreenX(sp)
    move.l  #0, DrawBitmapScreenY(sp)
    move.l  #1, PrintAbsolute(sp)
    
    jsr     DrawBitmap
    
    add.l   #32, sp
    
    movem.l (sp)+, ALL_REGS
    
    rts
    
    
    INCLUDE "BallHandler.x68"
    INCLUDE "ObjectHandler.x68"
    INCLUDE "ScorePowerup.x68"
    INCLUDE "BoxObstacle.x68"
    INCLUDE "CrossObstacle.x68"
    INCLUDE "TriangleObstacle.x68"
    INCLUDE "Bitmap.x68"
    INCLUDE "Rotation.x68"
    INCLUDE "SevenSegment.x68"
    INCLUDE "RandomNumbers.x68"
    INCLUDE "Switcher.x68"
    INCLUDE "Sounds.x68"
    
    
BALLPOS_X               dc.l (SCREEN_WIDTH-BALL_WIDTH)/2
BALLPOS_Y               dc.l BALL_INIT_Y_POS
BALL_Y_VEL              dc.l 0
BALL_Y_VEL_ADJUSTED     dc.l 0
BALL_COLOR              dc.l 0
NEUTRAL_COLOR           dc.l $001b1b1b
ABOVE_MID               dc.b 0
FILLER                  dc.b 0

JUMP_FORCE              dc.l -1100          ;magic values 1300, 10
DELTA_TIME              dc.w 0  
GRAVITY                 dc.l 8
TIME_SINCE_LAST_KEY     dc.l 10000
PREV_TIME               dc.l 0
KEY_PRESSED             dc.l 0

Background              incbin "Bitmaps/Background.bmp"

ELAPSED_INS_TIME        dc.l 0
Instructions            incbin  "Bitmaps/Instructions.bmp" 
InstructionsGlow        incbin  "Bitmaps/InstructionsGlow.bmp"
GLOW                    dc.l $FFFFFFFF


OBSTACLE_LIST           ds.l 300
SCORE_POWERUP_LIST      ds.l 100
SWITCHER_LIST           ds.l 100

OBSTACLE_COUNT          dc.l 0
OBSTACLE_TYPE_HANDLERS  dc.l 0
OBSTACLE_GAP            dc.l 470<<8

SCORE_X                 ds.w 1
SCORE_Y                 ds.l 1

SWITCHER_X              ds.w 1
SWITCHER_Y              ds.l 1

COLOR_ARRAY             dc.l COLOR_RED, COLOR_BLUE, COLOR_YELLOW, COLOR_PURPLE

SPAWN_TABLE             dc.l SpawnBox,  SpawnCross, SpawnTriangle
UPDATE_TABLE            dc.l UpdateBox, UpdateCross, UpdateTriangle

TEMP_RANDOM             ds.w 1

MESSAGE_X               dc.w 170
MESSAGE_Y               dc.w 300

EndMessage              dc.b 'GG! Your score: '
END_DIGITS              dc.b 0, 0, 0, 0
HighScoreMessage        dc.b '  High Score: '
HIGH_SCORE_DIGITS       dc.b '000'
HighScoreMessageEnd     dc.b '  ', 0
RestartMessage          dc.b '  Hit R to restart ', 0
IsHighScoreMessage      dc.b '  New High Score!  ', 0
HIGH_SCORE              dc.l 0
SCORE                   dc.l 0
IS_HIGH_SCORE           dc.l 0 

FONT_PROP              dc.b 0, FONT_SIZE, 0, 0

     ;last one is used to null terminate end string

	END START




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
