 
   
UpdateObstacles:
     *LOOPS THROUGH OBSTACLES AND CALLS THEIR UPDATE FUNCTIONS*
     
     *if an obstacle has gone offscreen, spawn a new one*
     cmp.l  #3, OBSTACLE_COUNT
     beq    ContinueUpdatingObstacles
     jsr    AddNewObstacle
     
ContinueUpdatingObstacles
     lea    OBSTACLE_LIST, a0           ;load start of obstacle list to a0
     move.l #3, d7                      ;we only have 3 active elements at any given  time
ObstacleUpdateLoop
     cmp.l  #0, d7
     beq    FinishUpdatingObstacles     ;if  done, quit the loop
     
     cmp.l  #1, (a0)                    ;if the obstacle is alive, update it
     bne    NextObstacle            
     move.l ITEM_TYPE(a0), d6           ;get the item  type 
     lea    UPDATE_TABLE, a1            
     asl.l  #2, d6                      ;shifting type by 2 to point to the right item in the update table (longs)
     move.l (a1, d6), a2                ;use the item type to offset into the update table for the right update function
     
     move.l d7, -(sp)
     
     jsr    (a2)                        ;jump to the function we found
     
     move.l (sp)+, d7
NextObstacle
     add.l  #TRIANGLE_CLASS_SIZE, a0    ;fetch next element
     subq.l #1, d7                      ;decrement pointer
     bra.s  ObstacleUpdateLoop
     
FinishUpdatingObstacles
    jsr     ClearAllRegs    
    rts

   
AddNewObstacle:
    lea     OBSTACLE_LIST, a0
    move.l  #$7FFFFFFF,d5               ;smallest Y to be stored here
    move.l  #3, d3
    
    *Find the lowest Y value (highest point on screen)*
FindSmallestYLoop
    cmp.l   #0, d3
    beq     AfterSmallestYLoop
    cmp.l   #0, (a0)                    ;if item is disabled, skip it
    beq     NextItemY
    cmp.l   BOX_S_Y(a0), d5             ;else compare Y and update lowest Y
    ble     NextItemY
    move.l  BOX_S_Y(a0), d5
NextItemY
    add.l   #TRIANGLE_CLASS_SIZE, a0
    subq.l  #1, d3
    bra.s   FindSmallestYLoop
    
AfterSmallestYLoop
    *Set the new Y to be beyond the highest point
    sub.l   OBSTACLE_GAP, d5
    move.l  #3, d3
    lea     OBSTACLE_LIST, a0
    
    *find the free spot in the obstacle list*
FindSpotLoop    
    cmp.l   #0, d3
    beq     QuitAddingObstacle
    cmp.l   #0, (a0)                    ;if the item is disabled, we've found our spot
    bne     FindNextSpot
    *add new obstacle*
    clr.l   d0
    move.w  BOX_S_X_INIT, d0            ;the X position stays the same, so load it up
    move.l  d5, d1                      ;store the Y computed earlier in d1
    
    move.w  d0, SCORE_X                 
    move.l  d1, SCORE_Y                 ;save the values for spawning score
    
    move.w  d0, SWITCHER_X
    move.l  d1, SWITCHER_Y              ;save the values for spawning switcher
    
    move.l  OBSTACLE_GAP, d4
    asr.l   #1, d4                      ;divide the gap by 2
    add.l   d4, SWITCHER_Y              ;switcher needs to spawn at the halfway point between two obstacles
    
    movem.l  ALL_REGS, -(sp)
    
    move.l  #3, -(sp)
    move.l  #0, -(sp)
    
    jsr     GetWordInRangeToD6          ;get a number between 0 and 3 exclusive
    
    add.l   #8, sp
    
    move.w  d6, TEMP_RANDOM             ;save it away
    
    movem.l (sp)+, ALL_REGS
    clr.l   d6
    move.w  TEMP_RANDOM,  d6            ;we now have our item type
    asl.l   #2, d6                      ;multiply by 4 to get offset into the spawn table (longs)
    lea     SPAWN_TABLE, a1
    add.l   d6, a1                      ;add the offset to get the right spawn function
    move.l  (a1), a2
    jsr     (a2)                        ;call the right spawn function
    
    add.l   #1, OBSTACLE_COUNT          
    
    bra.s   AfterFindSpotLoop
    
FindNextSpot
    add.l   #TRIANGLE_CLASS_SIZE, a0
    subq.l  #1, d3
    bra     FindSpotLoop    
AfterFindSpotLoop
    *once an obstacle is spawned, potentially spawn a score inside it and spawn a switcher below it*
    jsr     RollDieToSpawnPowerup
    jsr     AppendSwitcher
QuitAddingObstacle
    rts


UpdatePowerups:
    *CALL THE UPDATE POWERUP FUNCTION FOR EACH POWERUP IN THE LIST*
    lea     SCORE_POWERUP_LIST, a0
    move.l  #3, d7
PowerupUpdateLoop:
    cmp.l   #0, d7
    beq     ReturnFromUpdatePowerup
    cmp.l   #1, (a0)
    bne     NextPowerup
    jsr     UpdateScorePowerup
NextPowerup
    add.l   #SCORE_CLASS_SIZE, a0
    subq.l  #1, d7
    bra.s   PowerupUpdateLoop
ReturnFromUpdatePowerup
    rts    
    
    
UpdateSwitchers:
    *CALL THE UPDATE SWITCHER FUNCTION FOR EACH SWITCHER IN THE LIST*
    lea     SWITCHER_LIST, a0
    move.l  #3, d7
SwitcherUpdateLoop:
    cmp.l   #0, d7
    beq     ReturnFromUpdateSwitchers
    cmp.l   #1, (a0)
    bne     NextSwitcher
    jsr     UpdateSwitcher
NextSwitcher
    add.l   #SWITCHER_CLASS_SIZE, a0
    subq.l  #1, d7
    bra.s   SwitcherUpdateLoop
ReturnFromUpdateSwitchers
    rts    

RollDieToSpawnPowerup:
    *2 in 3 CHANCE OF SPAWNING POWERUP AT CURRENT SCORE X AND Y*
    jsr     GetRandomByteToD6
    btst    #1, d6
    bne     ProceedSpawning
    btst    #0, d6
    beq     ReturnRoll                   ;2 in 3 chance 
ProceedSpawning 
    lea     SCORE_POWERUP_LIST, a0
    move.l  #3, d7
FindPowerupSpotLoop
    cmp.l   #0, d7
    beq     ReturnRoll
    cmp.l   #0, (a0)
    bne     FindNextPowerupSpot
    
    *SPOT IS FOUND - ADD NEW POWERUP*
    
    move.w  SCORE_X, d0
    move.l  SCORE_Y, d1
    jsr     SpawnScorePowerup
    
    bra.s ReturnRoll
    
FindNextPowerupSpot
    add.l   #SCORE_CLASS_SIZE, a0
    subq.l  #1, d7
    bra.s   FindPowerupSpotLoop
    
ReturnRoll
    rts


AppendSwitcher:
    *SPAWNS A SWITCHER AT CURRENT SWITCHER X AND SWITCHER Y*
    lea     SWITCHER_LIST, a0
    move.l  #3, d7
FindSwitcherSpotLoop
    cmp.l   #0, d7
    beq     ReturnSwitcher
    cmp.l   #0, (a0)
    bne     FindNextSwitcherSpot
    
    *SPOT IS FOUND - ADD NEW SWITCHER*
    move.w  SWITCHER_X, d0
    move.l  SWITCHER_Y, d1
    jsr     SpawnSwitcher
    bra.s   ReturnSwitcher
    
FindNextSwitcherSpot
    add.l   #SWITCHER_CLASS_SIZE, a0
    subq.l  #1, d7
    bra.s   FindSwitcherSpotLoop
ReturnSwitcher
    rts


ClearObstacleAndPowerupLists:
    *CLEARS THE IS_ENABLED VALUE OF ALL ITEMS IN ALL LISTS, MAKING THEM EMPTY*
    lea     OBSTACLE_LIST, a0
    move.l  #0, (a0)
    add.l   #TRIANGLE_CLASS_SIZE, a0
    move.l  #0, (a0)
    add.l   #TRIANGLE_CLASS_SIZE, a0
    move.l  #0, (a0)
    
    lea     SCORE_POWERUP_LIST, a0
    move.l  #0, (a0)
    add.l   #SCORE_CLASS_SIZE, a0
    move.l  #0, (a0)
    add.l   #SCORE_CLASS_SIZE, a0
    move.l  #0, (a0)
    
    lea     SWITCHER_LIST, a0
    move.l  #0, (a0)
    add.l   #SWITCHER_CLASS_SIZE, a0
    move.l  #0, (a0)
    add.l   #SWITCHER_CLASS_SIZE, a0
    move.l  #0, (a0)

    rts


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
