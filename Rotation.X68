
ROT_ANGLE   EQU  0
ROT_LINE_X  EQU  2
ROT_LINE_Y  EQU  4
ANGLE       dc.w 0

RotatePoint:
    *ROTATES A POINT THROUGH A GIVEN ANGLE*
    addq.l  #4, sp
    move.w  ROT_ANGLE(sp), ANGLE
    subq.l  #4, sp
    bsr     GetSinAtD7
    move.w  d7, d6              ;d6 = sina
    bsr     GetCosAtD7          ;d7 = cosa
    add.l   #4, sp
    move.w  ROT_LINE_X(sp), d2  ;x
    move.w  ROT_LINE_Y(sp), d3  ;y
    muls.w  d7, d2              ;d2 = xcosa
    muls.w  d6, d3              ;d3 = ysina
    move.w  ROT_LINE_X(sp), d4  ;x
    move.w  ROT_LINE_Y(sp), d5  ;y
    muls.w  d6, d4              ;d4 = xsina
    muls.w  d7, d5              ;d5 = ycosa
    sub.l   d3, d2              ;x' = xcosa - ysina
    add.l   d4, d5              ;y' = ycosa + xsina
    
    asl.l   #2, d2              ;bringing x' to 2^-16 land
    clr.w   d2                  ;clearing the floating point data
    swap    d2                  ;bringing x' to 2^-8 land
    asl.l   #2, d5
    clr.w   d5
    swap    d5
	move.w  d2, ROT_LINE_X(sp)  ;moving x' back into stack
	move.w  d5, ROT_LINE_Y(sp)  ;moving y' back into stack
	subq.l  #4, sp
	rts
	
GetCosAtD7:
    *GET COSINE OF ANGLE INTO D7*
    clr.l   d1
    move.w  ANGLE, d1
    add.w   #90, d1             ;cos theta  =  sin(90 + theta)
    cmp.w   #360, d1
    blt     DoSin
    sub.w   #360, d1            ;check for range and bring it back to 0-360
DoSin
    bsr     GetSinAtD7SkipStart ;get the sine
    rts
    
GetSinAtD7:
    *GET SINE OF ANGLE INTO D7*
    clr.l   d1
    move.w  ANGLE, d1
GetSinAtD7SkipStart:
    lea     (SINE_TABLE), a0
    cmp.w   #360, d1
    blt     NinetyCheck
    sub.w   #360, d1              ;if angle is over 360, bring it back to first quadrant
NinetyCheck
	cmp.w   #90, d1
	bgt     OneEightyCheck
	lsl.l   #1, d1                ;shifting because sine table is in words
    move.w  (a0, d1.w), d7
    bra.s   ReturnSin             ;sin theta 
OneEightyCheck
    cmp.w   #180, d1
    bgt     TwoSeventyCheck
    move.w  #180, d0
    sub.w   d1, d0
    lsl.l   #1, d0                ;shifting because sine table is in words
    move.w  (a0, d0.w), d7        ;sin (180 - theta) = sin theta
    bra.s   ReturnSin
TwoSeventyCheck
    cmp.w   #270, d1
    bgt     LastAngleCase
    sub.w   #180, d1
    lsl.l   #1, d1
    move.w  (a0, d1.w), d7        ;shifting because sine table is in words
    neg.w   d7                    ;sin(theta - 180) = - sin theta
    bra.s   ReturnSin
LastAngleCase
    move.w  #360, d0
    sub.w   d1, d0
    lsl.l   #1, d0                ;shifting because sine table is in words
    move.w  (a0, d0.w), d7        ;sin(360 - theta) = - sin theta
    neg.w   d7
ReturnSin
    rts
    

SINE_TABLE:  ;0 thru 90 degrees in 2^-14 land
    dc.w    0,285,571,857,1142,1427,1712,1996,2280,2563
    dc.w    2845,3126,3406,3685,3963,4240,4516,4790,5062,5334
    dc.w    5603,5871,6137,6401,6663,6924,7182,7438,7691,7943
    dc.w    8192,8438,8682,8923,9161,9397,9630,9860,10086,10310
    dc.w    10531,10748,10963,11173,11381,11585,11785,11982,12175,12365
    dc.w    12550,12732,12910,13084,13254,13420,13582,13740,13894,14043
    dc.w    14188,14329,14466,14598,14725,14848,14967,15081,15190,15295
    dc.w    15395,15491,15582,15668,15749,15825,15897,15964,16025,16082
    dc.w    16135,16182,16224,16261,16294,16321,16344,16361,16374,16381
    dc.w    16384
    























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
