
*Class Triangle 

*some offsets are used from box class

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
COLOR_1              EQU  26
*BOX_X1_O            EQU  30
*BOX_Y1_O            EQU  32
*BOX_X2_O            EQU  34
*BOX_Y2_O            EQU  36
*BOX_X3_O            EQU  38
*BOX_Y3_O            EQU  40
COLOR_2              EQU  42
*BOX_ANG             EQU  46
*BOX_ANG_FP          EQU  48
*BOX_Y_VEL           EQU  52
*BOX_WIDTH           EQU  56
*DIRECTION           EQU  57
*BOX_SIDE_HALF       EQU  58
COLOR_3              EQU  60
*size - 60
TRIANGLE_CLASS_SIZE  EQU  64

MIN_TRIANGLE_HALF    EQU  95
MAX_TRIANGLE_HALF    EQU  115

*MIN_BOX_WIDTH       EQU  9
*MAX_BOX_WIDTH       EQU  12

*DISTANCE_BELOW_BOTTOM_TO_KILL EQU 160<<8

*a0 is the location to spawn the triangle*
*d0.w contains X offset, d1.l contains Y offset*


SpawnTriangle:
    *SPAWNS A TRIANGLE AT THE GIVEN POSITION AND AT THE GIVEN MEMORY LOCATION*
    move.l  d0, -(sp)
    move.l  d1, -(sp)
    
    move.l  #MAX_TRIANGLE_HALF, -(sp)
    move.l  #MIN_TRIANGLE_HALF, -(sp)
    
    jsr     GetWordInRangeToD6              ;get random size
    
    add.l   #8, sp
    move.l  (sp)+, d1
    move.l  (sp)+, d0
    
    move.w  d6, BOX_SIDE_HALF(a0)           ;use it to set up the triangle 
    jsr     SetTriangleParams
    rts
    
SetTriangleParams:
    move.l  IS_ENABLED_INIT, IS_ENABLED(a0)         ;make the triangle enabled
    move.l  TRIANGLE_TYPE_INIT, ITEM_TYPE(a0)       ;item type is triangle 
    
    move.w  d0, BOX_S_X(a0)
    move.l  d1, BOX_S_Y(a0)
    
    move.w  BOX_SIDE_HALF(a0), d4           ;+half-width
    move.w  d4, d5
    neg.w   d5                              ;-half-width
    
    movem.l ALL_REGS, -(sp)
    
    move.w  #60, ANGLE  
    jsr     GetSinAtD7                      ;getting sine 60 at d7
    
    move.w  d7, TEMP_SINE                   ;storing it away in temp_sine
    
    movem.l (sp)+, ALL_REGS
    
    move.w  d4, d6                          ;half-width
    
    mulu    TEMP_SINE, d6                   ;h/2 = a/2 * sin60 (equilateral triangle)
    
    asr.l   #8, d6  
    asr.l   #6, d6                          ;bring h/2  to 2^0 from 2^-14 form (sine was in 2^-14)
    
    move.w  d6, d7                          ;d7 = +h/2
    
    neg.w   d6                              ;d6 = -h/2
    
    move.w  #0, BOX_X1_O(a0)
    move.w  d6, BOX_Y1_O(a0)                ;0, -h/2 (top point)
    
    move.w  d5, BOX_X2_O(a0)
    move.w  d7, BOX_Y2_O(a0)                ;-a/2, h/2 (bottom left)
    
    move.w  d4, BOX_X3_O(a0)
    move.w  d7, BOX_Y3_O(a0)                ;a/2, h/2 (bottom right)
    
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
    
    *SET COLORS CAREFULLY
    
    movem.l ALL_REGS, -(sp)
    
    jsr     GetRandomColorInD6              ;get one color that has to be there
    move.l  d6, TEMP_COLOR_STORAGE
    
    movem.l (sp)+, ALL_REGS  
    
    move.l  TEMP_COLOR_STORAGE, d6  
    
    move.l  #1, ALREADY_SET                 ;set so that the switcher that spawns below this will grab this color
    move.l  d6, SET_COLOR    
    move.l  d6, COLOR_1(a0)
    
    lea     COLOR_ARRAY, a2
    move.l  #0, d4
FindColorLoop
    *loop to find the chosen color in the color array*
    cmp.l   #4, d4
    beq     AfterFindColorLoop
    move.l  d4, d5
    asl.l   #2, d5
    cmp.l   (a2, d5), d6
    beq     AfterFindColorLoop
    addq.l  #1, d4
    bra.s   FindColorLoop
AfterFindColorLoop

    *choose two more colors for the triangle relative to the current color*
FirstColor
    move.l  d4, d5
    subq.l  #1, d5
    cmp.l   #0, d5
    bge     SecondColor
    move.l  #3, d5
SecondColor
    move.l  d5, d3
    subq.l  #1, d3
    cmp.l   #0, d3
    bge     AfterSecondColor
    move.l  #3, d3
AfterSecondColor
    asl.l   #2, d5
    move.l  (a2, d5), COLOR_2(a0)
    asl.l   #2, d3
    move.l  (a2, d3), COLOR_3(a0)
    
    *DONE SETTING COLORS*
    
    move.l  #MAX_BOX_WIDTH, -(sp)
    move.l  #MIN_BOX_WIDTH, -(sp)
    jsr     GetWordInRangeToD6              ;get a width in the given range
    addq.l  #8, sp
    
    move.b  d6, BOX_WIDTH(a0)
    
    *randomize spin*
    jsr     GetRandomByteToD6
    btst    #2, d6
    bne     ReverseTriangleSpin
    move.b  #0, DIRECTION(a0)                  
    rts
ReverseTriangleSpin
    move.b  #1, DIRECTION(a0)
    rts
    
*a0 is the start of memory for the box*    
UpdateTriangle:
    *CHANGES ROTATION, POSITION AND VELOCITY OF TRIANGLE AND REDRAWS*
    move.l  BOX_ANG_FP(a0), d0
    clr.l   d3
    
    move.w  (DELTA_TIME), d3
    
    mulu    #10, d3
    move.b  DIRECTION(a0), d4
    btst    #0, d4
    beq     NormalTriangleRotation
    neg.l   d3                              ;reverse rotation
NormalTriangleRotation
    add.l   d3, d0                          ;get new rotation
    move.l  d0, d1
    asr.l   #3, d1
    cmp.w   #360, d1
    blt     CheckTriangleNeg
    sub.w   #360, d1
    sub.l   #360<<3, d0
CheckTriangleNeg
    cmp.w   #0, d1
    bge     ResumeTriangleRot
    add.w   #360, d1
    add.l   #360<<3, d0
ResumeTriangleRot
    move.w  d1, BOX_ANG(a0) 
    move.l  d0, BOX_ANG_FP(a0)
    jsr     ClearTriangle                   ;clear previous box
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

    
    add.l   #6, sp
    
    btst    #0, ABOVE_MID                   ;check if box needs to scroll
    beq     SkipTriangleVelocity
    
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
     cmp.l  d5, d0                         ;if position is below the bottom, delete triangle
     blt    SkipTriangleVelocity
     jsr    DeleteBox                      ;overloading 
     
SkipTriangleVelocity
    *DRAWING PHASE - draws a triangle as three lines of different color*
    
    move.l  #SET_PEN_COLOR, d0
    move.l  COLOR_1(a0), d1
    
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
    move.l  COLOR_2(a0), d1
    trap    #15 
    
    clr.l   d1
    clr.l   d2
    clr.l   d3
    
    move.l  #DRAW_LINE_TO, d0
    move.w  BOX_X3(a0), d1
    add.w   BOX_S_X(a0), d1
    
    move.w  BOX_Y3(a0), d2
    add.w   d5, d2
    
    trap    #15
    
    move.l  #SET_PEN_COLOR, d0
    move.l  COLOR_3(a0), d1
    trap    #15 
    
    clr.l   d1
    clr.l   d2
    
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
    
        
ClearTriangle:
    *CLEARS THE PREVIOUS DRAW OF THE TRIANGLE ON SCREEN - 3 LINES OF NEUTRAL COLOR*
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


TRIANGLE_TYPE_INIT       dc.l 2
TEMP_COLOR_STORAGE       ds.l 1
TEMP_SINE                ds.w 1


















































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
