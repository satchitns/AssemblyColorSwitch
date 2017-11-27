AddForceToBall:
    *ADDS A LARGE UPWARD FORCE TO THE BALL*
    jsr      PlayJumpSound
    move.l  (JUMP_FORCE),  d0
    move.l  d0, (BALL_Y_VEL)
    rts
        
UpdateBall:
    *UPDATES THE BALL'S POSITION AND VELOCITY*
    move.l  (BALLPOS_Y), d0
    move.l  (BALL_Y_VEL_ADJUSTED), d1   
    muls    (DELTA_TIME), d1                          
    add.l   d1, d0                      
    move.l  d0, (BALLPOS_Y)                         ;getting adjusted velocity * delta time and adding it to position 
      
    move.l  (GRAVITY), d0
    add.l   d0, (BALL_Y_VEL)                        ;acceleration due to gravity on actual velocity
    
    btst    #0, ABOVE_MID                           ;checks if ball was above threshold height last frame
    beq     CheckIfAbove          
    jsr     CheckIfBelowMid                         ;if it was, check if ball is below the threshold this frame
    bra.s   SkipAboveCheck                          ;if not, just keep going
    
CheckIfAbove
    jsr     CheckIfAboveMid                         ;checks if ball is above threshold height this frame
SkipAboveCheck

    move.l  (BALL_Y_VEL), (BALL_Y_VEL_ADJUSTED)     ;move actual velocity to adjusted velocity
    btst    #0, (ABOVE_MID)         
    beq     ReturnUpdateBall                        ;if ball isn't above threshold this frame, return
    
    move.l  (BALL_Y_VEL), d6                        ;else adjust velocity to facilitate scrolling   
    muls    #11, d6
    divs    #20, d6
    and.l   #$0000ffff, d6                          ;clearing remainder of divison
    move.l  d6, (BALL_Y_VEL_ADJUSTED)               ;adjusted velocity = 11/20*actual velocity
    
ReturnUpdateBall
    rts
    
        
CheckIfAboveMid:
    *IF BALL JUST WENT ABOVE A THRESHOLD, SETS ABOVE_MID TO TRUE SO THAT OBSTACLES CAN SCROLL DOWN*
    cmp.l   #((SCREEN_HEIGHT/2)<<8 + 50<<8),BALLPOS_Y  ;compare ball position with threshold
    bge     ReturnCheck      
    
    move.l  BALL_Y_VEL, d1
    cmp.l   #0, d1                                  ;check that ball is going up
    bgt     ReturnCheck
    
    move.b  #1, (ABOVE_MID)                         ;if true, set above mid
    
ReturnCheck
    rts
 
    
    
    
CheckIfBelowMid:
    *CHECKS IF BALL CAME BACK BELOW THE THRESHOLD AND CLEARS ABOVE_MID IF SO*
    
    move.l  BALL_Y_VEL, d3
    cmp.l   #0, d3
    
    blt     ReturnBelowMid
    
    move.b  #0, (ABOVE_MID)
ReturnBelowMid
    rts



DrawBall:
    *DRAWS THE BALL AT THE CURRENT POSITION WITH CURRENT COLOR*
    move.l  BALL_COLOR, d1
    move.l  #SET_PEN_COLOR, d0
    trap    #15
    move.l  #SET_FILL_COLOR, d0
    trap    #15
   
    move.l  (BALLPOS_X), d1
    
    move.l  d1, d3
    add.l   #BALL_WIDTH, d3
    sub.l   #1, d3
    
    move.l  (BALLPOS_Y), d2
    asr.l   #8, d2                        ;bring Y position back to 2^0 land
    
    move.l  d2, d4
    add.l   #BALL_HEIGHT, d4
    sub.l   #1, d4
    
    move.l  #DRAW_CIRCLE, d0
    
    trap    #15
    
    rts     


DrawBgChunk:
    *DRAWS THE CHUNK  OF THE BITMAP BEHIND THE BALL*
    movem.l ALL_REGS, -(sp)
    
    move.l  (BALLPOS_Y), d0
    
    asr.l   #8, d0
    
    sub.l   #32, sp
    
    move.l  #Background, DrawBitmapAddress(sp)
    move.l  (BALLPOS_X), DrawBitmapX(sp)
    move.l  d0, DrawBitmapY(sp)
    move.l  #(BALL_WIDTH), DrawBitmapWidth(sp)
    move.l  #(BALL_HEIGHT), DrawBitmapHeight(sp)
    move.l  #0, DrawBitmapScreenX(sp)
    move.l  #0, DrawBitmapScreenY(sp)
    move.l  #1, PrintAbsolute(sp)
    
    jsr     DrawBitmap
    
    add.l   #32, sp
    
    movem.l (sp)+, ALL_REGS
    
    rts

CheckCollision:
     *CHECKS FOR PIXEL COLLISION AT 8 POINTS AROUND THE BALL*
     move.l (BALLPOS_X), d6
     move.l (BALLPOS_Y), d7
     asr.l  #8, d7 
     
     move.l #GET_PIXEL, d0
     move.l d6, d1
     move.l d7, d2
     add.l  #10, d1                 ;top mid pixel
     trap   #15
     cmp.l  (BALL_COLOR), d0
     beq    ProceedFirst
     cmp.l  (NEUTRAL_COLOR), d0     ;if the pixel is not the color of ball or background, game over
     bne    EndGame
ProceedFirst:
     move.l #GET_PIXEL, d0
     add.l  #19, d2                 ;bot mid pixel
     trap   #15
     cmp.l  (BALL_COLOR), d0
     beq    ProceedSecond
     cmp.l (NEUTRAL_COLOR), d0
     bne    EndGame
ProceedSecond:
     move.l #GET_PIXEL, d0
     move.l d6, d1
     move.l d7, d2
     add.l  #10, d2                 ;left mid pixel
     trap   #15
     cmp.l  (BALL_COLOR), d0
     beq    ProceedThird
     cmp.l  (NEUTRAL_COLOR), d0
     bne    EndGame
ProceedThird:
     move.l #GET_PIXEL, d0
     add.l  #19, d1                 ;right mid pixel
     trap   #15
     cmp.l  (BALL_COLOR), d0
     beq    ProceedFourth
     cmp.l  (NEUTRAL_COLOR), d0
     bne    EndGame
ProceedFourth:
     move.l d6, d1
     move.l d7, d2
     add.l  #5, d1
     add.l  #5, d2                  ;north-west pixel
     move.l #GET_PIXEL, d0
     trap   #15
     cmp.l  (BALL_COLOR), d0
     beq    ProceedFifth
     cmp.l  (NEUTRAL_COLOR), d0
     bne    EndGame
ProceedFifth:
     add.l  #10, d1                 ;north-east pixel 
     move.l #GET_PIXEL, d0
     trap   #15
     cmp.l  (BALL_COLOR), d0
     beq    ProceedSixth
     cmp.l  (NEUTRAL_COLOR), d0 
     bne    EndGame
ProceedSixth:  
     move.l d6, d1
     move.l d7, d2
     add.l  #5, d1
     add.l  #15, d2                 ;south-west pixel
     move.l #GET_PIXEL, d0
     trap   #15
     cmp.l  (BALL_COLOR), d0
     beq    ProceedSeventh
     cmp.l  (NEUTRAL_COLOR), d0
     bne    EndGame
ProceedSeventh:
     add.l  #10, d1                 ;south-east pixel
     move.l #GET_PIXEL, d0
     trap   #15
     cmp.l  (BALL_COLOR), d0
     beq    ProceedEighth
     cmp.l  (NEUTRAL_COLOR), d0
     bne    EndCall
ProceedEighth:
     rts
EndCall:    
     jsr    EndGame



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
