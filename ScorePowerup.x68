 
*IS_ENABLED*            *defined in box obstacle*
POWERUP_TYPE            EQU 4
*S_X*                   *defined in box obstacle*
*S_Y*                   *defined in box obstacle*
SCORE_WIDTH             EQU 20
SCORE_HEIGHT            EQU SCORE_WIDTH

SCORE_CLASS_SIZE        EQU 14

TRIANGLE_HALF_SIZE      EQU SCORE_WIDTH/2
SpawnScorePowerup:
    *SPAWNS A SCORE POWERUP AT THE GIVEN LOCATION WITH POSITION, STORES VALUES STARTING AT A0*
    move.l  #1, IS_ENABLED(a0)
    move.l  #1, POWERUP_TYPE(a0)
    move.w  d0, BOX_S_X(a0)
    move.l  d1, BOX_S_Y(a0)
    rts
    
    
    
UpdateScorePowerup:
    *UPDATES POSITION OF SCORE POWERUP AND INCREMENTS SCORE ON COLLISION WITH BALL*
    
    *Clear Phase*
    move.l  #SET_PEN_COLOR, d0
    move.l  NEUTRAL_COLOR, d1
    trap    #15
    jsr     DrawTriangle                    ;clear the powerup by drawing a neutral color triangle
    
    btst    #0, ABOVE_MID                   ;check if powerup needs to scroll
    beq     SkipScoreMove
    
    *Update Phase*
    
    move.l BOX_S_Y(a0), d0             
    move.l BALL_Y_VEL, d1
    muls   (DELTA_TIME), d1
    
    move.l  d1, d2
     
    asr.l   #2, d2                          ;d2 = velocity * delta_time * 0.1
     
    add.l   d2, d1                          ;d1 = 1.1 * velocity * delta_time
     
    sub.l   d1, d0                          ;update position
     
    move.l  d0, BOX_S_Y(a0)
    
SkipScoreMove

    *Collision Check Phase*

    add.l   #(SCORE_HEIGHT)<<8, d0
    cmp.l   BALLPOS_Y, d0                   ;if ball Y intersects score bitmap, update score
    blt     NoCollision
    jsr     PlayCoinSound
    jsr     UpdateScore
    
NoCollision
    *Draw Phase*
     
     move.l  #SET_PEN_COLOR, d0
     move.l  POWERUP_COLOR, d1
     trap    #15 
     jsr     DrawTriangle                   ;draw triangle, but now with filled color
     rts
    
    
UpdateScore:
    *INCREASES SCORE AND DELETES POWERUP*
    move.l  #0, IS_ENABLED(a0)              ;disabling powerup because it's taken
    lea     SCORE_DIGITS, a1                ;3 digit score storage
    move.b  0(a1), d0
    move.b  1(a1), d1
    move.b  2(a1), d2
    addq.b  #1, d0
    cmp.b   #10, d0                         ;if units place overflows, add to tens place
    blt.s   FinishUpdate
    move.b  #0,  d0
    addq.b  #1,  d1 
    cmp.l   #10, d1                         ;if tens place overflows, add to hundreds plcae
    blt     FinishUpdate
    move.b  #0, d1
    addq.b  #1, d2
FinishUpdate
    move.b  d0, 0(a1)
    move.b  d1, 1(a1)
    move.b  d2, 2(a1)                       ;move the updated scores to memory
    
    
    *STORING THE SCORE AS ONE NUMBER*
    clr.l   d2
    clr.l   d1
    move.b  0(a1), d1
    add.l   d1, d2
    clr.l   d1
    move.b  1(a1), d1 
    mulu    #10, d1
    add.l   d1, d2
    clr.l   d1
    move.b  2(a1), d1
    mulu    #100, d1
    add.l   d1, d2
    move.l  d2, SCORE
    
    jsr DrawScore                           ;update the seven segment display
    rts
    
    
    
DrawTriangle:
     *DRAWS A TRIANGLE OF SET COLOR AT CURRENT POSITION BY DRAWING 3 LINES*
     
     move.l  #SET_PEN_WIDTH, d0
     move.l  #3, d1
     trap    #15                            ;setting pen width to 3
     
     move.l  #DRAW_LINE_FROM_TO, d0
     
     move.w  BOX_S_X(a0), d5                ;d5 = CenterX 
     move.l  BOX_S_Y(a0), d6
     asr.l   #8, d6                         ;d6 = CenterY in 2^0 form
     
     movem.l ALL_REGS, -(sp)
     
     move.w  #60, ANGLE
     jsr     GetSinAtD7                     ;d7 = sin 60
     
     move.w  d7, TEMP_SINE                  ;store it in temp_sine
     
     movem.l (sp)+, ALL_REGS
     
     move.w  #TRIANGLE_HALF_SIZE, d7        ;get half the side 
     mulu    TEMP_SINE, d7                  ;h/2 = a/2 * sin 60 (equilateral triangle)
     asr.l   #8, d7
     
     asr.l   #6, d7                         ;sin was in 2^-14 land, shift product back

                                            ;d7 = h/2
     move.w  #-TRIANGLE_HALF_SIZE, d1
     add.w   d5, d1                         ;offset from center X
     
     move.w  d7, d2
     add.w   d6, d2                         ;offset from center Y
     
     move.w  #TRIANGLE_HALF_SIZE, d3
     add.w   d5, d3
     
     move.w  d2, d4
     
     trap    #15
     
     move.w  d5, d1
     
     neg.w   d7                             ;-h/2 for the top point
     move.w  d7, d2
     add.w   d6, d2
     
     trap #15
     
     move.w #-TRIANGLE_HALF_SIZE, d3
     add.w  d5, d3
     
     neg.w  d7
     move.w d7,  d4
     add.w  d6, d4
     
     trap #15
     
     move.l  #SET_PEN_WIDTH, d0
     move.l  #1, d1
     trap    #15                            ;restore pen width

     rts





POWERUP_COLOR   dc.l    $00ffffff


















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
