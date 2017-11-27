
DRAW_RECTANGLE EQU 87

DrawScore:
    *DRAWS THE GAME SCORE ON THE SCREEN BASED ON THE MEMORY VALUES*
    
    *clearing the background of the score as  a rectangle*
    move.l  #SET_PEN_COLOR, d0
    move.l  NEUTRAL_COLOR, d1
    trap    #15
    move.l  #SET_FILL_COLOR, d0
    trap    #15
    move.l  #DRAW_RECTANGLE, d0
    move.w  LEFT_X, d1
    move.w  UPPER_Y, d2
    move.w  RIGHT_X, d3
    move.w  LOWER_Y, d4
    trap    #15
    clr.l   d5
    clr.l   d6
    clr.l   d1
  
ScoreLoop:
    *loops through each digit and prints it at proper offset*
    lea     SCORE_DIGITS, a0
    move.b  (a0, d6), d0                        ;load current digit into d0
    move.b  d0, CURRENT_DIGIT                   ;load it into current_digit
    lea     DIGIT_OFFSETS_X, a0                 ;load digit table address in a0
    move.l  d6, d7
    add.l   d6, d7                              ;multiply current digit value by 2 (offset is in words table)
    move.w  (a0, d7), CURRENT_DIGIT_OFFSET_X    ;get the current digit offset
    movem   ALL_REGS, -(sp)
    jsr     DrawDigit                           ;draw the digit
    movem   (sp)+, ALL_REGS
    addq.l  #1, d6                              ;go to the next digit
    cmp.l   #3, d6                              ;if we've drawn 3 digits, quit
    blt     ScoreLoop
    rts
    
 
    
DrawDigit:  
    *DRAWS ONE DIGIT ON SCREEN AT GIVEN OFFSET*
    lea     SEVEN_SEG_TABLE, a0
    move.b  CURRENT_DIGIT, d0
    move.b  (a0, d0), d0                        ;get the seven segment code for current digit
    move.l  #7, d1
    lea     LINE_TABLE_X1, a0
    lea     LINE_TABLE_Y1, a1
    lea     LINE_TABLE_X2, a2
    lea     LINE_TABLE_Y2, a3                   ;set up the loop
DigitLoop
    btst    d1, d0                              ;if the current line needs to be drawn for the digit
    beq     NextSegment
    move.l  d1, d2
    add.l   d1, d2                              ;multiply the line code by 2 for word table
    move.w  (a0, d2), START_X                   ;get each coordinate for the line from each table
    move.w  (a1, d2), START_Y
    move.w  (a2, d2), END_X
    move.w  (a3, d2), END_Y
    movem   ALL_REGS, -(sp)
    jsr     DrawLine                            ;draw the line
    movem   (sp)+, ALL_REGS
NextSegment
    subq.l  #1, d1                              ;move to the next line
    cmp.l   #-1, d1                             ;if all lines have been checked, quit
    beq.s   FinishDrawingDigit
    bra.s   DigitLoop
FinishDrawingDigit
    rts




DrawLine:
    *DRAWS A LINE FROM POINT A TO POINT B AT GIVEN OFFSET*
    
    move.l  #SET_PEN_COLOR, d0
    move.l  DIGIT_COLOR, d1
    trap    #15 
    clr.l   d1
    clr.l   d2
    clr.l   d3
    clr.l   d4
    clr.l   d5
    clr.l   d6
    move.w  CURRENT_DIGIT_OFFSET_X, d5
    move.w  DIGIT_OFFSET_Y, d6
    
    move.l  #DRAW_LINE_FROM_TO, d0
    
    move.w  START_X, d1
    add.w   d5, d1
    
    move.w  START_Y, d2
    add.w   d6, d2
    
    move.w  END_X, d3
    add.w   d5, d3
    
    move.w  END_Y, d4
    add.w   d6, d4
    
    trap    #15
    rts

ResetScore:
    *RESETS CURRENT SCORE AND PRINTED SCORE TO 000*
    lea     SCORE_DIGITS, a0
    move.b  #0, 0(a0)
    move.b  #0, 1(a0)
    move.b  #0, 2(a0)
    lea     END_DIGITS, a0
    move.b  #0, 0(a0)
    move.b  #0, 1(a0)
    move.b  #0, 2(a0)

    rts
    
SEVEN_SEG_TABLE:
    dc.b $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F

LINE_TABLE_X1:
    dc.w -5,5,5,5,-5,-5,-5
    
LINE_TABLE_Y1:
    dc.w -10,-10,0,10,10,0,0
    
LINE_TABLE_X2: 
    dc.w 5,5,5,-5,-5,-5,5
    
LINE_TABLE_Y2: 
    dc.w -10,0,10,10,0,-10,0
    
DIGIT_OFFSETS_X:
    dc.w 55,40,25
    
DIGIT_OFFSET_Y         dc.w  30
LEFT_X                 dc.w  0
RIGHT_X                dc.w  61
UPPER_Y                dc.w  0
LOWER_Y                dc.w  41
CURRENT_DIGIT_OFFSET_X dc.w  40
CURRENT_DIGIT          dc.b  0
SCORE_DIGITS:
                       dc.b 0, 0, 0
START_X                dc.w  0
END_X                  dc.w  0
START_Y                dc.w  0
END_Y                  dc.w  0
DIGIT_COLOR            dc.l  $009cf7ff
    


















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
