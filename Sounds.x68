THEME_REF   EQU 0
JUMP_REF    EQU 1
HIT_REF     EQU 2
COIN_REF    EQU 3
SWITCH_REF  EQU 4
LOAD_SOUND  EQU 74
PLAY_SOUND  EQU 77

LoadSounds:
    *LOAD EACH SOUND INTO DIRECTX MEMORY AND GIVE IT A REFERENCE NUMBER*
    move.l  #LOAD_SOUND, d0
    
    lea     hit, a1
    move.b  #HIT_REF, d1
    trap    #15

    move.l  #LOAD_SOUND, d0
    lea     jump, a1
    move.b  #JUMP_REF, d1
    trap    #15
        
    move.l  #LOAD_SOUND, d0
    lea     switch, a1
    move.b  #SWITCH_REF, d1
    trap    #15
    
    move.l  #LOAD_SOUND, d0
    lea     coin, a1
    move.b  #COIN_REF, d1
    trap    #15

    move.l  #LOAD_SOUND, d0
    
    lea     theme, a1
    move.b  #THEME_REF, d1
    trap    #15
    
    rts

PlayTheme:
    *PLAY THE THEME SOUND ON LOOP*
    move.l  #PLAY_SOUND, d0
    move.l  #1, d2
    move.b  #THEME_REF, d1
    trap    #15
    rts

PlaySound:
    *PLAY THE SOUND REFERENCED AT D1*
    move.l  #PLAY_SOUND, d0
    move.l  #0, d2
    trap    #15
    rts
 
StopTheme:
    *STOP THE THEME SOUND*
    move.l  #PLAY_SOUND, d0
    move.l  #2, d2
    move.b  #THEME_REF, d1
    trap    #15
    rts


PlayJumpSound:
    *MOVE JUMP REF INTO D1 AND CALL PLAY SOUND*
    move.b  #JUMP_REF, d1
    jsr     PlaySound
    rts

PlayDeathSound:
    *MOVE HIT REF INTO D1 AND CALL PLAY SOUND*
    move.b  #HIT_REF, d1
    jsr     PlaySound
    rts

PlaySwitchSound:
    *MOVE SWITCH REF INTO D1 AND CALL PLAY SOUND*
     
    move.b  #SWITCH_REF, d1
    jsr     PlaySound
    rts
   
PlayCoinSound:
    *MOVE COIN REF INTO D1 AND CALL PLAY SOUND*
    
    move.b  #COIN_REF, d1
    jsr     PlaySound
    rts


jump    dc.l    'Sounds\jump.wav', 0
hit     dc.l    'Sounds\hit.wav', 0
coin    dc.l    'Sounds\coin.wav', 0
switch  dc.l    'Sounds\switch.wav', 0
theme   dc.l    'Sounds\Tetris.wav', 0















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
