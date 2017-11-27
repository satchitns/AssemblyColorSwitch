*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------

;universal stuff
PaintColorTrapCode              EQU 80
DrawPixelTrapCode               EQU 82


;DrawBitmap variables
DrawBitmapAddress               EQU 0
DrawBitmapX                     EQU 4
DrawBitmapY                     EQU 8
DrawBitmapWidth                 EQU 12
DrawBitmapHeight                EQU 16
DrawBitmapScreenX               EQU 20
DrawBitmapScreenY               EQU 24
PrintAbsolute                   EQU 28
BitmapOffsetToPixelOffet        EQU 10
BitmapOffsetToWidth             EQU 18
BitmapOffsetToHeight            EQU 22
BitmapOffsetToBitsPerPixel      EQU 28
BitmapOffsetToHeaderSize        EQU 14


DrawBitmap:

    clr.l   d0
    clr.l   d1
    clr.l   d2
    clr.l   d3
    clr.l   d4
    clr.l   d5
    clr.l   d6
    clr.l   d7
    
    addq.l  #4, sp ;adjusting so variable names can be reused
    move.l  DrawBitmapAddress(sp), a0 ;contains pointer to file (is also used to traverse the file)
    move.l  a0, a6
    move.l  BitmapOffsetToHeaderSize(a0), d0
    rol.w   #8, d0
    swap    d0
    rol.w   #8, d0 ;actual header size
    add.l   d0, a6
    add.l   #BitmapOffsetToHeaderSize, a6 ;contains pointer to color table
    
    *getting image-size into d0, d1
    move.l  BitmapOffsetToWidth(a0), d0 ;image width in px (little endian)
    move.l  BitmapOffsetToHeight(a0), d1 ;image height in px (little endian)
    move.w  BitmapOffsetToBitsPerPixel(a0), d3 ; bits per pixel
    rol.w   #8, d0
    swap    d0
    rol.w   #8, d0 ;actual image width
    
    rol.w   #8, d1
    swap    d1
    rol.w   #8, d1 ;actual image height
    
    rol.w   #8, d3 ;actual bits per pixel
    
    *offset to pixel data
    move.l  BitmapOffsetToPixelOffet(a0), d7 ;contains pixel offset(little endian) 
    rol.w   #8, d7
    swap    d7
    rol.w   #8, d7 ;contains actual offset
    add.l   d7, a0 ;setting a0 to location of first pixel in bmp (d7 is now free for use)
    
    *Y counter and Y bound
    move.l  DrawBitmapHeight(sp), a5 ; h
    move.l  a5, d2
    add.l   DrawBitmapScreenY(sp), d2 = ScreenY + h
    cmp.l   #1, PrintAbsolute(sp)
    bne.s   SkipAddY
    add.l   DrawBitmapY(sp), d2
SkipAddY
    addq.l  #1, a5 ;account for 0th row


    *X bound and X counter
    move.l  DrawBitmapScreenX(sp), a1 ;ScreenX
    cmp.l   #1, PrintAbsolute(sp)
    bne.s   SkipAddX
    add.l   DrawBitmapX(sp), a1 ;ScreenX + x (Can change to first version discussed in class by adding this line)
SkipAddX
    move.l  a1, a3 ;a3 = ScreenX 
    add.l   DrawBitmapWidth(sp), a1 ;ScreenX + w
    
    *startXoffset computation
    move.l  DrawBitmapX(sp), d7 
    move.l  d7, a6 ;d7 is startXOffset
    add.l   a6, d7
    add.l   a6, d7

    *endXoffset computation
    move.l  d0, d6
    sub.l   DrawBitmapX(sp), d6
    sub.l   DrawBitmapWidth(sp), d6 ;endoffset = (W - (x + w)) 
    move.l  d6, a6
    add.l   a6, d6
    add.l   a6, d6 ;endoffset = (W - (x + w))*3
    
    *row padding computation
    clr     d4
    move.l  d0, d3
    move.l  d3, a6
    add.l   a6, d3
    add.l   a6, d3
    divu    #4, d3 ; [R.Q]
    swap    d3  ; [Q.R]
    move.w  d3, d5 ;remainder
    cmp.l   #0, d5
    beq     SkipPad ;padding = 0
    addq.l  #4, d4
    sub.l   d5,d4 ;padding 
    
SkipPad
    add.l   d4, d6 ; endXoffset = (W - (x + w))*3 + padding
    
InitialPointerOffset
    move.l  d0, d5 ; d5 = W
    move.l  d5, a6
    add.l   a6, d5
    add.l   a6, d5 ; d5 = W*3
    add.l   d4, d5 ; d5 = W*3 + padding (padding can now be overwritten)
    move.l  d1, d4
    sub.l   DrawBitmapY(sp), d4
    sub.l   DrawBitmapHeight(sp), d4
    move.l  d5, a6 
    mulu    d4, d5
    add.l   d5, a0 ;setting a0 to the first pixel we need (in file order)
    
    move.l  a5, d5
OuterLoop
    subq.l  #1, d5 ; go down a row
    beq     AfterLoop
    subq.l  #1, d2
    *init X Counter
    move.l  a3, a4 ; ScreenX + X
    move.l  a1, d4
    sub.l   a4, d4
    asr.l   #2, d4 ; div by 4
    addq.l  #1, d4
    add.l   d7, a0 
    move    a0, d0
    btst    #0, d0
    beq     Loop
OddBoundary 
    cmp.l   a1, a4
    bge     AfterInnerLoop

    *fetching pixel
    clr.w   d1
    move.b  (a0)+, d1
    swap    d1
    move.w  (a0)+, d1

    *setting color
    move.l  #PaintColorTrapCode, d0
    trap    #15
    
    *drawing pixel
    move.l  #DrawPixelTrapCode, d0
    move.w  a4, d1 
    trap    #15
    addq.l  #1, a4

Loop
    subq.l  #1, d4
    ble.s   AfterChunkLoop
    *fetching pixel 1
    move.l  (a0)+, d1
    clr.w   d3
    move.b  d1, d3
    clr.b   d1
    ror.l   #8, d1
    *setting color
    move.l  #PaintColorTrapCode, d0
    trap    #15
    
    *drawing pixel 1
    move.l  #DrawPixelTrapCode, d0
    move.w  a4, d1 
    trap    #15
    addq.l  #1, a4
    *fetching pixel 2
Pixel2
    move.w  d3, d1
    swap    d1
    move.w  (a0)+,d1
    *setting color
    move.l  #PaintColorTrapCode, d0
    trap    #15
    
    *drawing pixel 2
    move.l  #DrawPixelTrapCode, d0
    move.w  a4, d1 
    trap    #15
    addq.l  #1, a4
    *fetching pixel 3
Pixel3
    move.l  (a0)+, d1
    clr.w   d3
    move.b  d1, d3
    clr.b   d1
    ror.l   #8, d1
    *setting color
    move.l  #PaintColorTrapCode, d0
    trap    #15
    
    *drawing pixel 3
    move.l  #DrawPixelTrapCode, d0
    move.w  a4, d1 
    trap    #15
    addq.l  #1, a4
    *fetching pixel 4
Pixel4
    move.w  d3, d1
    swap    d1
    move.w  (a0)+,d1
    
    *setting color
    move.l  #PaintColorTrapCode, d0
    trap    #15
    
    *drawing pixel 4
    move.l  #DrawPixelTrapCode, d0
    move.w  a4, d1 
    trap    #15
    addq.l  #1, a4
    bra.s   Loop

AfterChunkLoop
BytesLoop
EvenPart
    cmp.l   a1, a4
    bge     AfterInnerLoop
    *fetching pixel
    clr.l   d1
    move.w  (a0)+, d1
    asl.l   #8, d1
    move.b  (a0)+, d1
    *setting color
    move.l  #PaintColorTrapCode, d0
    trap    #15
 
    *drawing pixel
    move.l  #DrawPixelTrapCode, d0
    move.w  a4, d1 
    trap    #15
    addq.l  #1, a4

OddPart
    cmp.l   a1, a4
    bge     AfterInnerLoop
    *fetching pixel
    clr.w   d1
    move.b  (a0)+, d1
    swap    d1
    move.w  (a0)+, d1
    
    *setting color
    move.l  #PaintColorTrapCode, d0
    trap    #15
    
    *drawing pixel
    move.l  #DrawPixelTrapCode, d0
    move.w  a4, d1 
    trap    #15
    addq.l  #1, a4
    bra.s   AfterChunkLoop

AfterInnerLoop
    add.l   d6, a0 ;end offset is added to a0
    bra     OuterLoop
    
AfterLoop
    subq.l  #4, sp ;undoing convinience-add
    rts    



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
