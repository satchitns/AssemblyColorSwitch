ALL_REG                 REG     D0-D7/A0-A6
GET_TIME_COMMAND        EQU     8

RANGE_MIN               EQU     0
RANGE_MAX               EQU     4


GetWordInRangeToD6:
        *RETURNS A WORD IN  THE SPECIFIED RANGE IN D6.W*
        jsr             GetRandomByteToD6       ;d6.b contains random number
        addq.l          #4, sp
        move.l          RANGE_MIN(sp), d0
        move.l          RANGE_MAX(sp), d1 
        sub.l           d0, d1                  ;getting range
        divu            d1, d6                  ;d6 = random/range
        swap            d6                      ;d6.w = remainder (0 to range -1)
        and.l           #$0000ffff, d6
        add.l           d0, d6                  ;d6.w = range_min to range_max - 1
        subq.l          #4, sp
        rts 
            
            
GetRandomByteToD6:
        *GETS SYSTEM TIME AND RETURNS THE LOWER BYTE IN D6.B*
        move.b          #GET_TIME_COMMAND,d0
        TRAP            #15
        clr.l           d6
        move.b          d1, d6                  
        rts
        
        
GetRandomColorInD6:
        *STORES A COLOR THAT ISNT EQUAL TO CURRENT COLOR IN D6*
        move.l          ALREADY_SET, d4                 
        btst            #0, d4                          ;if the  color was already set by a triangle, return that color
        beq             ProceedGettingColor
        move.l          SET_COLOR, d6
        move.l          #0, ALREADY_SET                 ;the already set color has been acquired, so set that flag to false
        rts
ProceedGettingColor
        lea             COLOR_ARRAY, a0
GetColor:
        jsr             GetRandomByteToD6
        divu            #4, d6
        swap            d6
        and.l           #$0000ffff, d6
        move.l          d6, d7
        mulu            #4, d6
        move.l          (a0, d6.w), d6
        cmp.l           LAST_COLOR, d6                  ;if the color is not the same as the last  color spawned, we can return it
        bne             ReturnRandomColor
DamageControl
        jsr             GetRandomByteToD6               ;if not, we take the previous or next color randomly
        btst            #2, d6
        beq             AddOne
SubOne
        subq.l          #1, d7  
        cmp.l           #0, d7
        bge             ProceedWithDamageControl        ;color table overflow check
        move.l          #3, d7
        bra.s           ProceedWithDamageControl
AddOne
        addq.l          #1, d7
        cmp.l           #3, d7
        ble             ProceedWithDamageControl        ;color table overflow check

        move.l          #0, d7
ProceedWithDamageControl
        mulu            #4, d7                          ;multiply by 4 to get the actual color table pointer
        move.l          (a0, d7.w), d6                  ;get the color into d6
ReturnRandomColor
        move.l          d6, LAST_COLOR                  ;save the current color as last color and return
        rts

RANDOMVAL       ds.l    1
TEMPRANDOMLONG  ds.l    1
LAST_COLOR      dc.l    1
ALREADY_SET     dc.l    0
SET_COLOR       dc.l    0


























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
