
*Class Cross

*Using all the box variable offsets because it's the exact same setup - reference below*

*IS_ENABLED          EQU  0
*ITEM_TYPE           EQU  4 
*BOX_S_X             EQU  8 
*BOX_S_Y             EQU  10
*BOX_X1              EQU  14
*BOX_Y1              EQU  16
*BOX_X2              EQU  18
*BOX_Y2              EQU  20
*BOX_X3              EQU  22
*BOX_Y3              EQU  24
*BOX_X4              EQU  26
*BOX_Y4              EQU  28
*BOX_X1_O            EQU  30
*BOX_Y1_O            EQU  32
*BOX_X2_O            EQU  34
*BOX_Y2_O            EQU  36
*BOX_X3_O            EQU  38
*BOX_Y3_O            EQU  40
*BOX_X4_O            EQU  42
*BOX_Y4_O            EQU  44
*BOX_ANG             EQU  46
*BOX_ANG_FP          EQU  48
*BOX_Y_VEL           EQU  52
*BOX_WIDTH           EQU  56
*DIRECTION           EQU  57
*BOX_SIDE_HALF       EQU  58
**size - 60
*BOX_CLASS_SIZE      EQU  60

MIN_CROSS_HALF       EQU  95
MAX_CROSS_HALF       EQU  105


*DISTANCE_BELOW_BOTTOM_TO_KILL EQU 160<<8

*a0 is the location to spawn the cross*
*d0.w contains X offset, d1.l contains Y offset*


SpawnCross:
    *SPAWNS A CROSS AT THE GIVEN POSITION AND AT THE GIVEN MEMORY LOCATION*
    move.l  d0, -(sp)
    move.l  d1, -(sp)
    
    move.l  #MAX_CROSS_HALF, -(sp)
    move.l  #MIN_CROSS_HALF, -(sp)
    
    jsr     GetWordInRangeToD6              ;get random size
    
    add.l   #8, sp
    move.l  (sp)+, d1
    move.l  (sp)+, d0
    
    move.w  d6, BOX_SIDE_HALF(a0)           ;use it to set up the cross
    jsr     SetBoxParams                    ;overloading the box params function here for cross
 
    move.l  #1, ITEM_TYPE(a0)               ;but making type cross for main to identify and call update correctly
    move.b  DIRECTION(a0), d6
    move.l  #40, d5
    btst    #0, DIRECTION(a0)
    beq     AddOffset
    sub.w   d5, BOX_S_X(a0)
    rts
AddOffset
    add.w   d5, BOX_S_X(a0)
    rts
    
    
*a0 is the start of memory for the cross    
UpdateCross:
    *CHANGES ROTATION, POSITION AND VELOCITY OF CROSS AND REDRAWS*
    move.l  BOX_ANG_FP(a0), d0
    clr.l   d3
    
    move.w  (DELTA_TIME), d3
    
    mulu    #15, d3
    move.b  DIRECTION(a0), d4
    btst    #0, d4
    beq     NormalCrossRotation
    neg.l   d3                              ;reverse rotation
NormalCrossRotation
    add.l   d3, d0                          ;get new rotation
    move.l  d0, d1
    asr.l   #3, d1
    cmp.w   #360, d1
    blt     CheckCrossNeg
    sub.w   #360, d1
    sub.l   #360<<3, d0
CheckCrossNeg
    cmp.w   #0, d1
    bge     ResumeCrossRot
    add.w   #360, d1
    add.l   #360<<3, d0
ResumeCrossRot
    move.w  d1, BOX_ANG(a0) 
    move.l  d0, BOX_ANG_FP(a0)
    jsr     ClearCross                      ;clear previous cross
    
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
    move.w  ROT_LINE_Y(sp), BOX_Y3(a0)

    move.w  BOX_X4_O(a0), ROT_LINE_X(sp)
    move.w  BOX_Y4_O(a0), ROT_LINE_Y(sp)    ;saving rotated values

    
    jsr     RotatePoint                     ;rotating fourth point

    
    move.l  a1, a0    
    
    move.w  ROT_LINE_X(sp), BOX_X4(a0)
    move.w  ROT_LINE_Y(sp), BOX_Y4(a0)      ;saving rotated values

    
    add.l   #6, sp
    
    btst    #0, ABOVE_MID                   ;check if box needs to scroll
    beq     SkipCrossVelocity
    
    *VELOCITY PHASE*
    
    move.l  BOX_S_Y(a0), d0             
    move.l  BALL_Y_VEL, d1
    muls    (DELTA_TIME), d1
     
    move.l  d1, d2
     
    asr.l   #2, d2                          ;d2 = velocity * delta_time * 0.1
     
    add.l   d2, d1                          ;d1 = 1.1 * velocity * delta_time
     
    sub.l   d1, d0                          ;update position
     
    move.l  d0, BOX_S_Y(a0)
    
    *DESTROY CHECK*
    move.l  #SCREEN_HEIGHT<<8, d5
    add.l   #DISTANCE_BELOW_BOTTOM_TO_KILL, d5
    cmp.l   d5, d0                         ;if position is below the bottom, delete cross
    blt     SkipCrossVelocity
    jsr     DeleteBox     
     
SkipCrossVelocity

    *DRAWING PHASE - CROSS IS DRAWN AS FOUR LINES OF DIFFERENT COLORS*
    
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
    
    move.w  BOX_S_X(a0), d1
    
    move.w  d5, d2
    
    move.w  BOX_X1(a0), d3
    add.w   BOX_S_X(a0), d3
    
    move.w  BOX_Y1(a0), d4
    add.w   d5, d4
    
    trap    #15
    
    move.l  #SET_PEN_COLOR, d0
    move.l  4(a1), d1
    trap    #15 
    
    move.l  #DRAW_LINE_FROM_TO, d0

    clr.l   d1
    clr.l   d2
    clr.l   d3
    
    move.w  BOX_S_X(a0), d1
    
    move.w  d5, d2

    move.w  BOX_X2(a0), d3
    add.w   BOX_S_X(a0), d3
    
    move.w  BOX_Y2(a0), d4
    add.w   d5, d4

    
    trap    #15
    
    move.l  #SET_PEN_COLOR, d0
    move.l  8(a1), d1
    trap    #15 
    
    move.l  #DRAW_LINE_FROM_TO, d0

    clr.l   d1
    clr.l   d2
    
    move.w  BOX_S_X(a0), d1
    
    move.w  d5, d2

    move.w  BOX_X3(a0), d3
    add.w   BOX_S_X(a0), d3
    
    move.w  BOX_Y3(a0), d4
    add.w   d5, d4


    trap    #15
    
    move.l  #SET_PEN_COLOR, d0
    move.l  12(a1), d1
    
    trap    #15 
    
    
    move.l  #DRAW_LINE_FROM_TO, d0

    clr.l   d2
    clr.l   d1
    
    move.w  BOX_S_X(a0), d1
    
    move.w  d5, d2

    move.w  BOX_X4(a0), d3
    add.w   BOX_S_X(a0), d3
    
    move.w  BOX_Y4(a0), d4
    add.w   d5, d4

    
    trap    #15


    move.b  #SET_PEN_WIDTH, d0
    move.b  #1, d1
    trap    #15
    rts
    
    
ClearCross:
    *CLEARS THE PREVIOUS DRAW OF THE BOX ON SCREEN BY DRAWING FOUR LINES*
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
    
    move.w   BOX_S_X(a0), d1
    
    move.w  d5, d2
    
    move.w  BOX_X1(a0), d3
    add.w   BOX_S_X(a0), d3
    
    move.w  BOX_Y1(a0), d4
    add.w   d5, d4
    
    trap    #15

    move.w  BOX_X2(a0), d3
    add.w   BOX_S_X(a0), d3
    
    move.w  BOX_Y2(a0), d4
    add.w   d5, d4
    trap    #15
    
    move.w  BOX_X3(a0), d3
    add.w   BOX_S_X(a0), d3
    
    move.w  BOX_Y3(a0), d4
    add.w   d5, d4

    trap    #15
    
    move.w  BOX_X4(a0), d3
    add.w   BOX_S_X(a0), d3
    
    move.w  BOX_Y4(a0), d4
    add.w   d5, d4
  
    trap    #15
    
    move.b  #SET_PEN_WIDTH, d0
    move.b  #1, d1
    trap    #15
    
    rts

























































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
