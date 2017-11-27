 
*IS_ENABLED*            *defined in box obstacle*
POWERUP_TYPE            EQU 4
*S_X*                   *defined in box obstacle*
*S_Y*                   *defined in box obstacle*
SWITCHER_COLOR          EQU 14


SWITCHER_CLASS_SIZE     EQU 18


SWITCHER_WIDTH          EQU 20
SWITCHER_HEIGHT         EQU SWITCHER_WIDTH

DRAW_UNFILLED_ELLIPSE   EQU 91

SpawnSwitcher:
    *SPAWNS A COLOR SWITCHER AT THE GIVEN LOCATION WITH POSITION AND RANDOM COLOR, STORES VALUES STARTING AT A0*
    move.l  #1, IS_ENABLED(a0)      ;object is enabled
    move.l  #2, POWERUP_TYPE(a0)    
    sub.w   #SCORE_WIDTH/2, d0      ;d0 has the center point X, we need top left to draw circle
    sub.l   #SCORE_HEIGHT/2<<8, d1  ;d1 has the center point Y in 2^-8, we need top left to draw circle
    move.w  d0, BOX_S_X(a0)         
    move.l  d1, BOX_S_Y(a0)         ;once computed, move the X and Y into the memory location for this powerup
    move.l  a0, a1                  
    jsr     GetRandomColorInD6      
    move.l  a1, a0                  
    move.l  d6, SWITCHER_COLOR(a0)  
    rts
    
    
    
UpdateSwitcher:
    *UPDATES POSITION OF COLOR SWITCHER AND INCREMENTS SCORE ON COLLISION WITH BALL*
    
    *Clear Phase*
    move.l  #SET_PEN_WIDTH, d0
    move.l  #3, d1
    trap    #15                             ;set pen width to 3
    
    move.l  #SET_PEN_COLOR, d0
    move.l  NEUTRAL_COLOR, d1
    trap    #15                             ;set pen color to neutral
    
    move.l  #DRAW_UNFILLED_ELLIPSE, d0
    move.w  BOX_S_X(a0),d1
    
    move.l  BOX_S_Y(a0), d2
    asr.l   #8, d2
    
    
    move.w  d1, d3
    add.l   #(SWITCHER_WIDTH), d3
    move.l  d2, d4
    
    add.l   #(SWITCHER_HEIGHT), d4
    
    trap    #15                             ;pass the parameters for the ellipse and draw with neutral color
    
    btst    #0, ABOVE_MID                   ;check if switcher needs to scroll
    beq     SkipSwitcherMove
    
    *Update Phase*
    
    move.l BOX_S_Y(a0), d0             
    move.l BALL_Y_VEL, d1
    muls   (DELTA_TIME), d1
    
    move.l  d1, d2
     
    asr.l   #2, d2                          ;d2 = velocity * delta_time * 0.1
     
    add.l   d2, d1                          ;d1 = 1.1 * velocity * delta_time
     
    sub.l   d1, d0                          ;update position
     
    move.l  d0, BOX_S_Y(a0)                 ;save it
    
SkipSwitcherMove

    *Collision Check Phase*

    add.l   #(SWITCHER_HEIGHT+5)<<8, d0     
    cmp.l   BALLPOS_Y, d0                  ;comparing if the ball's top point has crossed the powerup's bottom point
    blt     NoSwitch
    jsr     UpdateColor                    ;if so, change ball color and destroy powerup
    rts
NoSwitch
    *Draw Phase*
     move.l  #SET_PEN_WIDTH, d0            ;set pen width to 3
     move.l  #3, d1
     trap    #15
     
     move.l  #SET_PEN_COLOR, d0            
     move.l  POWERUP_COLOR, d1
     
     trap    #15 

     move.l  #DRAW_UNFILLED_ELLIPSE, d0
     move.w  BOX_S_X(a0),d1
    
     move.l  BOX_S_Y(a0), d2
     asr.l   #8, d2
    
     move.w  d1, d3
     add.l   #(SCORE_WIDTH), d3
     move.l  d2, d4
    
     add.l   #(SCORE_HEIGHT), d4
    
     trap    #15                            ;draw the ellipse with the color and size
     
     move.l  #SET_PEN_WIDTH, d0
     move.l  #1, d1
     trap    #15                            ;restore pen size
     
     rts
    
    
UpdateColor:
    *INCREASES SCORE AND DELETES POWERUP*
    jsr     PlaySwitchSound                 ;play switch sound
    
    move.l  #SET_PEN_WIDTH, d0
    move.l  #1, d1          
    trap    #15                             ;restore pen size
    
    move.l  #0, IS_ENABLED(a0)              ;disabling powerup because it's taken
    move.l  SWITCHER_COLOR(a0), BALL_COLOR  ;giving ball the new color
    jsr     UpdateScore                     ;add one point
    rts































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
