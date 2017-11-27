
*Class Box
IS_ENABLED          EQU  0
ITEM_TYPE           EQU  4 
BOX_S_X             EQU  8 
BOX_S_Y             EQU  10
BOX_X1              EQU  14
BOX_Y1              EQU  16
BOX_X2              EQU  18
BOX_Y2              EQU  20
BOX_X3              EQU  22
BOX_Y3              EQU  24
BOX_X4              EQU  26
BOX_Y4              EQU  28
BOX_X1_O            EQU  30
BOX_Y1_O            EQU  32
BOX_X2_O            EQU  34
BOX_Y2_O            EQU  36
BOX_X3_O            EQU  38
BOX_Y3_O            EQU  40
BOX_X4_O            EQU  42
BOX_Y4_O            EQU  44
BOX_ANG             EQU  46
BOX_ANG_FP          EQU  48
BOX_Y_VEL           EQU  52
BOX_WIDTH           EQU  56
DIRECTION           EQU  57
BOX_SIDE_HALF       EQU  58
*size - 60
BOX_CLASS_SIZE      EQU  60

MIN_BOX_HALF_LENGTH EQU  75
MAX_BOX_HALF_LENGTH EQU  105

MIN_BOX_WIDTH       EQU  9
MAX_BOX_WIDTH       EQU  12

DISTANCE_BELOW_BOTTOM_TO_KILL EQU 160<<8

*a0 is the location to spawn the box*
*d0.w contains X offset, d1.l contains Y offset*

SpawnFirstBox:
    *SPAWNS THE FIRST BOX WHICH IS ALWAYS OF MAX SIZE AND MIN WIDTH*
    move.w  #MAX_BOX_HALF_LENGTH, BOX_SIDE_HALF(a0) 
    jsr     SetBoxParams
    move.b  #MIN_BOX_WIDTH, BOX_WIDTH(a0)
    rts



SpawnBox:
    *SPAWNS A BOX AT THE GIVEN POSITION AND AT THE GIVEN MEMORY LOCATION*
    move.l  d0, -(sp)
    move.l  d1, -(sp)
    
    move.l  #MAX_BOX_HALF_LENGTH, -(sp)
    move.l  #MIN_BOX_HALF_LENGTH, -(sp)
    
    jsr     GetWordInRangeToD6              ;get random size
    
    add.l   #8, sp
    move.l  (sp)+, d1
    move.l  (sp)+, d0
    
    move.w  d6, BOX_SIDE_HALF(a0)           ;use it to set up the box
    jsr     SetBoxParams
    rts
    
SetBoxParams:
    move.l  IS_ENABLED_INIT, IS_ENABLED(a0) ;make the box enabled
    move.l  BOX_TYPE_INIT, ITEM_TYPE(a0)    ;item type is box
    
    move.w  d0, BOX_S_X(a0)
    move.l  d1, BOX_S_Y(a0)
    
    move.w  BOX_SIDE_HALF(a0), d4           ;+half-width
    move.w  d4, d5
    neg.w   d5                              ;-half-width
    
    move.w  d5, BOX_X1_O(a0)
    move.w  d5, BOX_Y1_O(a0)
    
    move.w  d4, BOX_X2_O(a0)
    move.w  d5, BOX_Y2_O(a0)
    
    move.w  d5, BOX_X3_O(a0)
    move.w  d4, BOX_Y3_O(a0)
    
    move.w  d4, BOX_X4_O(a0)
    move.w  d4, BOX_Y4_O(a0)
    
    move.l  #45, -(sp)
    move.l  #0, -(sp)
    jsr     GetWordInRangeToD6              ;get an angle from 0-45 degrees
    and.l   #$0000ffff, d6
    add.l   #8, sp
    asl.l   #3, d6                          ;multiply by 8 to get an angle out of 360
    move.w  d6, BOX_ANG(a0)
    
    asl.l   #4, d6
    move.l  d6, BOX_ANG_FP(a0)              ;floating point version of angle
    
    move.l  BOX_Y_VEL_INIT, BOX_Y_VEL(a0)   
    
    move.l  #MAX_BOX_WIDTH, -(sp)
    move.l  #MIN_BOX_WIDTH, -(sp)
    jsr     GetWordInRangeToD6              ;get a width in the given range
    addq.l  #8, sp
    
    move.b  d6, BOX_WIDTH(a0)
    
    jsr     GetRandomByteToD6
    btst    #1, d6
    bne     ReverseSpin
    move.b  #0, DIRECTION(a0)                  
    rts
ReverseSpin
    move.b  #1, DIRECTION(a0)
    rts
    
*a0 is the start of memory for the box    
UpdateBox:
    *CHANGES ROTATION, POSITION AND VELOCITY OF BOX AND REDRAWS*
    move.l  BOX_ANG_FP(a0), d0
    clr.l   d3
    
    move.w  (DELTA_TIME), d3
    
    mulu    #10, d3
    move.b  DIRECTION(a0), d4
    btst    #0, d4
    beq     NormalRotation
    neg.l   d3                              ;reverse rotation
NormalRotation
    add.l   d3, d0                          ;get new rotation
    move.l  d0, d1
    asr.l   #3, d1
    cmp.w   #360, d1
    blt     CheckNeg
    sub.w   #360, d1
    sub.l   #360<<3, d0
CheckNeg
    cmp.w   #0, d1
    bge     ResumeRot
    add.w   #360, d1
    add.l   #360<<3, d0
ResumeRot
    move.w  d1, BOX_ANG(a0) 
    move.l  d0, BOX_ANG_FP(a0)
    jsr     ClearBox                        ;clear previous box
    *ROTATION PHASE*
    
    move.b  #SET_PEN_WIDTH, d0
    move.b  BOX_WIDTH(a0), d1
    trap    #15
    
    sub.l   #6, sp
    
    move.w  BOX_ANG(a0), ROT_ANGLE(sp)
    move.w  BOX_X1_O(a0), ROT_LINE_X(sp)
    move.w  BOX_Y1_O(a0), ROT_LINE_Y(sp)
    
    move.l  a0, a1
    
    jsr     RotatePoint                     ;rotating first point
    
    move.l  a1, a0
    
    move.w  ROT_LINE_X(sp), BOX_X1(a0)
    move.w  ROT_LINE_Y(sp), BOX_Y1(a0)      ;saving rotated values
    
    move.w  BOX_X2_O(a0), ROT_LINE_X(sp)
    move.w  BOX_Y2_O(a0), ROT_LINE_Y(sp)
    
    jsr     RotatePoint                     ;rotating second point

    
    move.l  a1, a0
    
    move.w  ROT_LINE_X(sp), BOX_X2(a0)
    move.w  ROT_LINE_Y(sp), BOX_Y2(a0)      ;saving rotated values
  
    move.w  BOX_X3_O(a0), ROT_LINE_X(sp)
    move.w  BOX_Y3_O(a0), ROT_LINE_Y(sp)    

    
    jsr     RotatePoint                     ;rotating third point

    
    move.l  a1, a0    
    
    move.w  ROT_LINE_X(sp), BOX_X3(a0)
    move.w  ROT_LINE_Y(sp), BOX_Y3(a0)      ;saving rotated values

    move.w  BOX_X4_O(a0), ROT_LINE_X(sp)
    move.w  BOX_Y4_O(a0), ROT_LINE_Y(sp)    

    
    jsr     RotatePoint                     ;rotating fourth point

    
    move.l  a1, a0    
    
    move.w  ROT_LINE_X(sp), BOX_X4(a0)
    move.w  ROT_LINE_Y(sp), BOX_Y4(a0)      ;saving rotated values

    
    add.l   #6, sp
    
    btst    #0, ABOVE_MID                   ;check if box needs to scroll
    beq     SkipVelocity
    
    *VELOCITY PHASE*
    
     move.l BOX_S_Y(a0), d0             
     move.l BALL_Y_VEL, d1
     muls   (DELTA_TIME), d1
     
     move.l d1, d2
     
     asr.l  #2, d2                          ;d2 = velocity * delta_time * 0.1
     
     add.l  d2, d1                          ;d1 = 1.1 * velocity * delta_time
     
     sub.l  d1, d0                          ;update position
     
     move.l d0, BOX_S_Y(a0)
     
     *DESTROY CHECK*
     move.l #SCREEN_HEIGHT<<8, d5
     add.l  #DISTANCE_BELOW_BOTTOM_TO_KILL, d5
     cmp.l  d5, d0                         ;if position is below the bottom, delete box
     blt    SkipVelocity
     jsr    DeleteBox     
SkipVelocity
    *DRAWING PHASE - DRAWS A BOX AS FOUR LINES OF DIFFERENT COLOR*
    lea COLOR_ARRAY, a1
    
    move.l  #SET_PEN_COLOR, d0
    move.l  (a1), d1
    
    trap    #15 
    
    move.l  #DRAW_LINE_FROM_TO, d0
    clr.l   d1
    clr.l   d2
    clr.l   d3
    move.l  BOX_S_Y(a0), d5
    asr.l   #8, d5
    
    move.w  BOX_X1(a0), d1
    add.w   BOX_S_X(a0), d1
    
    move.w  BOX_Y1(a0), d2
    add.w   d5, d2
    
    move.w  BOX_X2(a0), d3
    add.w   BOX_S_X(a0), d3
    
    move.w  BOX_Y2(a0), d4
    add.w   d5, d4
    
    trap    #15
    
    move.l  #SET_PEN_COLOR, d0
    move.l  4(a1), d1
    trap    #15 
    
    clr.l   d1
    clr.l   d2
    clr.l   d3
    
    move.l  #DRAW_LINE_TO, d0
    move.w  BOX_X4(a0), d1
    add.w   BOX_S_X(a0), d1
    
    move.w  BOX_Y4(a0), d2
    add.w   d5, d2
    
    trap    #15
    
    move.l  #SET_PEN_COLOR, d0
    move.l  8(a1), d1
    trap    #15 
    
    clr.l   d1
    clr.l   d2
    
    move.l  #DRAW_LINE_TO, d0
    
    move.w  BOX_X3(a0), d1
    add.w   BOX_S_X(a0), d1
    
    move.w  BOX_Y3(a0), d2
    add.w   d5, d2

    trap    #15
    
    move.l  #SET_PEN_COLOR, d0
    move.l  12(a1), d1
    
    trap    #15 
    
    clr.l   d2
    clr.l   d1
    
    move.l  #DRAW_LINE_TO, d0
    
    move.w  BOX_X1(a0), d1
    add.w   BOX_S_X(a0), d1
    
    move.w  BOX_Y1(a0), d2
    add.w   d5, d2
    
    trap    #15


    move.b  #SET_PEN_WIDTH, d0
    move.b  #1, d1
    trap    #15
    rts
    
    
DeleteBox:
    *EFFECTIVELY DELETES THE BOX*
    move.l  #0, IS_ENABLED(a0)      ;is_enabled = 0, it's ok to overwrite, and updates are stopped
    subq.l  #1, OBSTACLE_COUNT      ;there is now one less obstacle in the play area
    rts
    
    
ClearBox:
    *CLEARS THE PREVIOUS DRAW OF THE BOX ON SCREEN BY DRAWING FOUR NEUTRAL LINES*
    move.b  #SET_PEN_WIDTH, d0
    move.b  BOX_WIDTH(a0), d1
    trap    #15
    move.l  #SET_PEN_COLOR, d0
    move.l  NEUTRAL_COLOR, d1
    trap    #15 
    clr.l   d1
    clr.l   d2
    clr.l   d3
    clr.l   d4
    
    move.l  BOX_S_Y(a0), d5
    asr.l   #8, d5
    
    move.l  #DRAW_LINE_FROM_TO, d0
    move.w  BOX_X1(a0), d1
    add.w   BOX_S_X(a0), d1
    
    move.w  BOX_Y1(a0), d2
    add.w   d5, d2
    
    move.w  BOX_X2(a0), d3
    add.w   BOX_S_X(a0), d3
    
    move.w  BOX_Y2(a0), d4
    add.w   d5, d4
    
    trap    #15
    
    move.l  #DRAW_LINE_TO, d0
    move.w  BOX_X4(a0), d1
    add.w   BOX_S_X(a0), d1
    
    move.w  BOX_Y4(a0), d2
    add.w   d5, d2
    
    trap    #15
    
    move.w  BOX_X3(a0), d1
    add.w   BOX_S_X(a0), d1
    
    move.w  BOX_Y3(a0), d2
    add.w   d5, d2
    
    trap    #15
    
    move.w  BOX_X1(a0), d1
    add.w   BOX_S_X(a0), d1
    
    move.w  BOX_Y1(a0), d2
    add.w   d5, d2
    
    trap    #15
    
    move.b  #SET_PEN_WIDTH, d0
    move.b  #1, d1
    trap    #15
    rts


IS_ENABLED_INIT     dc.l 1 
BOX_TYPE_INIT       dc.l 0

BOX_S_X_INIT        dc.w SCREEN_WIDTH/2
BOX_S_Y_INIT        dc.l 0<<8 

BOX_ANG_INIT        dc.w 1 
BOX_ANG_FP_INIT     dc.l 1<<4 
BOX_Y_VEL_INIT      dc.l 0 
BOX_WIDTH_INIT      dc.b 10 
BOX_FILLER_INIT     dc.b 0 



































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
