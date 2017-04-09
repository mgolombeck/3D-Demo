********************************
*           3D-DEMO            *
*                              *
*      BY MARC GOLOMBECK       *
*                              *
*   VERSION 1.1 / 09.04.2017   *
*                              *
* NEEDS THE FOLLOWING DATA     *
* ALREADY LOADED INTO MEMORY:  *
*                              *
* $7000: SIN/COS-TABLE         *
* $7200: POINT AND LINE DATA   *
* $7400: SHAPE TABLE           *
*                              *
* CONTROL JOYSTICK & KEYBOARD  *
*                              *
* PDL(0/1/2): ROTATION+ZOOM    *
* PBN(0/1/2): RESET/STOP/EXIT  *
*                              *
* KEYS 1-5: LOAD 3D-OBJECTS 1  *
*           TO 5 FROM DISK     *
* KEYS +/-: ALTERNATIVE ZOOM   *
*           IF NO PDL(2)       *
*           AVAILABLE          *
*                              *
********************************
*
               ORG   $6000
*
HGR2           EQU   $F3D8      ; SWITCH TO HIRES2
HGR            EQU   $F3E2      ; SWITCH TO HIRES1
HCLR           EQU   $F3F2      ; CLEAR HIRES SCREEN TO BLACK1
HCOLOR         EQU   $F6F0      ; SET HCOLOR
HPOSN          EQU   $F411      ; SET HIRES-CURSOR NO DRAW
HPLOT          EQU   $F457      ; DRAW HIRES-PIXEL
HLIN           EQU   $F53A      ; DRAW HIRES-LINE
PREAD          EQU   $FB1E      ; READ PADDLES
WAIT           EQU   $FCA8      ; WAIT-ROUTINE
PB0            EQU   $C061      ; PUSH-BUTTON 0
PB1            EQU   $C062      ; PUSH-BUTTON 1
PB2            EQU   $C063      ; PUSH-BUTTON 2
HOME           EQU   $FC58      ; CLEAR SCREEN
COUT           EQU   $FDED      ; PRINT CHARACTER
KYBD           EQU   $C000      ; READ KEYBOARD
STROBE         EQU   $C010      ; CLEAR KEYBOARD
SHNUM          EQU   $F730      ; GET ADRESS OF SHAPE NUMBER
SHDRAW         EQU   $F605      ; DRAW SHAPE ON SCREEN
*
SINTAB         EQU   $7000      ; BASE ADRESS OF SINE TABLE
COSTAB         EQU   $7040      ; BASE ADRESS OF COSINE TABLE
NUMPNT         EQU   $7200      ; NUMBER OF POINTS TO DRAW
TABLE          EQU   $7201      ; BASE ADRESS FOR POINT TABLE
SHTAB          EQU   $7400      ; BASE ADRESS OF SHAPES-68
SHTABPTR       EQU   $E8        ; POINTER TO SHAPE-TABLE
*
XTRANS         EQU   $8B        ; TRANSLATION TO SCREEN CENTER
YTRANS         EQU   $5F
ZTRANS         EQU   $FE        ; MOVE 3D OBJECT FROM CAMERA
*
RADIUS         EQU   $30F       ; CIRCLE RADIUS
TXTPTR         EQU   $06        ; POINTER FOR TEXT OUTPUT
PTR            EQU   $08        ; POINTER FOR DOS COMMAND
LOOPCNTY       EQU   $FA        ; Y-ROT-COUNTER
ROTSPDY        EQU   $FB        ; Y-ROTATIONAL SPEED
LOOPCNTX       EQU   $FC        ; X-ROT-COUNTER
ROTSPDX        EQU   $FD        ; X-ROTATIONAL SPEED
PNTCNT         EQU   $09        ; WHICH POINT TO DRAW?
JOYCNT         EQU   $30C       ; COUNTER FOR JOYSTICK REQUEST
SCALING        EQU   $FF        ; SCALING
XDRAW          EQU   $300       ; X-POSITION FOR DRAW
YDRAW          EQU   $302       ; Y-POSITION FOR DRAW
XDRAWO         EQU   $304       ; OLD POSITION X
YDRAWO         EQU   $306       ; OLD POSITION Y
XDRAW2         EQU   $308       ; UNDRAW CURSOR X
YDRAW2         EQU   $30A       ; UNDRAW CURSOR Y
ASCR           EQU   $30B       ; ACTIVE SCREEN TO DRAW
*
ENTRY          JSR   SETUP      ; SETUP GRAPHIC
*
TABLESET       JSR   WLCMTXT    ; SHOW WELCOME MESSAGE
*
INILOOP        LDA   #$00       ; INIT LOOP
               STA   LOOPCNTY   ; CURRENT Y-STEP
               LDA   #$10
               STA   LOOPCNTX   ; CURRENT X-STEP
*
* READ PADDELS
*
LOOP           INC   JOYCNT     ; MAIN LOOP STARTS HERE
               LDA   JOYCNT
               CMP   #$03
               BCC   READ1      ; LESS THAN 3 CYCLES
               LDA   #$00       ; READ PADDLE EVERY 3 CYCLES
               STA   JOYCNT
*
PREAD0         LDX   #$00       ; VARY Y-ROT SPEED
               JSR   PREAD      ; PADDLE (0)
               CPY   #$64
               BCC   INCSPDY    ; DECREASE SPEED
               CPY   #$9B
               BCS   DECSPDY    ; INCREASE SPEED
               BCC   PREAD1     ; 256-STEP CIRCLE LOOP
*
DECSPDY        LDA   ROTSPDY    ; DECREASE ANGLE
               CMP   #$01
               BCC   READ1      ; LOOPCNT STILL POSITIVE
               DEC   ROTSPDY
               JMP   PREAD1     ; JUMP TO NEXT COMMAND
INCSPDY        LDA   ROTSPDY    ; DECREASE WAIT COUNTER
               CMP   #$15
               BCS   PREAD1     ; MAXIMUM 10
               INC   ROTSPDY
*
PREAD1         LDX   #$01       ; VARY X-ROT SPEED
               JSR   PREAD      ; PADDLE (1)
               CPY   #$64
               BCC   DECSPDX    ; DECREASE SPEED
               CPY   #$9B
               BCS   INCSPDX    ; INCREASE SPEED
               BCC   PREAD2     ; 256-STEP CIRCLE LOOP
*
DECSPDX        LDA   ROTSPDX    ; DECREASE ANGLE
               CMP   #$01
               BCC   PREAD2     ; LOOPCNT STILL POSITIVE
               DEC   ROTSPDX
               JMP   PREAD2     ; JUMP TO NEXT COMMAND
INCSPDX        LDA   ROTSPDX    ; DECREASE WAIT COUNTER
               CMP   #$15
               BCS   PREAD2     ; MAXIMUM 10
               INC   ROTSPDX
*
*
PREAD2         LDX   #$02       ; VARY X-ROT SPEED
               JSR   PREAD      ; PADDLE (1)
               CPY   #$64
               BCC   DECZTRS    ; DECREASE SPEED
               CPY   #$9B
               BCS   INCZTRS    ; INCREASE SPEED
               BCC   READ1      ; 256-STEP CIRCLE LOOP
*
INCZTRS        LDA   ZTRANS     ; DECREASE ZTRANS
               CMP   #$40
               BCC   READ1      ; LOOPCNT STILL POSITIVE
               DEC   ZTRANS
               JMP   READ1      ; JUMP TO NEXT COMMAND
DECZTRS        LDA   ZTRANS     ; DECREASE WAIT COUNTER
               CMP   #$57
               BCS   READ1      ; MAXIMUM 10
               INC   ZTRANS
*
READ1          CLC              ; CALC NEXT STEP
               LDA   LOOPCNTY
               ADC   ROTSPDY    ; ADD NEXT STEP
               ADC   #$F6       ; ACCU = ACCU - 10
               STA   LOOPCNTY
               CLC
               LDA   LOOPCNTX
               ADC   ROTSPDX    ; ADD NEXT STEP
               ADC   #$F6       ; ACCU = ACCU - 10
               STA   LOOPCNTX
*
               JSR   INITPNTS   ; CALC NEW POINT POSITIONS
               JSR   UDRWLNS    ; UNDRAW LINES
*
* READ KEYBOARD FOR LOADING NEW OBJECTS
*
               LDA   KYBD
               CMP   #$80
               BCC   NOKEY      ; NO KEY IS PRESSED
KEY1           CMP   #$B1       ; KEY '1' IS PRESSED
               BNE   KEY2
               JSR   LOAD1      ; LOAD OBJECT 1
               JMP   ENDKEY     ; DONE
KEY2           CMP   #$B2       ; KEY '2' IS PRESSED
               BNE   KEY3
               JSR   LOAD2
               JMP   ENDKEY     ; DONE
KEY3           CMP   #$B3       ; KEY '3' IS PRESSED
               BNE   KEY4
               JSR   LOAD3
               JMP   ENDKEY
KEY4           CMP   #$B4       ; KEY '4' IS PRESSED
               BNE   KEY5
               JSR   LOAD4
               JMP   ENDKEY
KEY5           CMP   #$B5       ; KEY '5' IS PRESSED
               BNE   KEYPLUS
               JSR   LOAD5
               JMP   ENDKEY
KEYPLUS        CMP   #$AB       ; KEY '+' IS PRESSED
               BNE   KEYMINUS
               LDA   STROBE
               JMP   INCZTRS    ; INCREASE ZOOM
KEYMINUS       CMP   #$AD       ; KEY '-' IS PRESSED
               BNE   NOKEY      ; NO VALID KEY WAS PRESSED
               LDA   STROBE
               JMP   DECZTRS
ENDKEY         LDA   STROBE     ; CLEAR STROBE
               JSR   SETUP
               JSR   WLCMTXT    ; WRITE WELCOME MESSAGE ON SCREEN
               JSR   INITPNTS
*
NOKEY          JSR   DRWLNS     ; DRAW LINES
*
* CHECK PUSHBUTTONS
*
               LDA   PB1        ; PUSHBUTTON 1 PRESSED?
               BMI   END        ; EXIT PROGRAM!
               LDA   PB2        ; PUSHBUTTON 2 PRESSED?
               BPL   PB0CHK     ; NO -> CHECK PB0
               LDA   #$0A       ; STOP ROTATION IMMEDIATELY
               STA   ROTSPDY    ; RESET Y-ROT SPEED = 0
               STA   ROTSPDX    ; RESET X-ROT SPEED = 0
PB0CHK         LDA   PB0        ; PUSHBUTTON 0 PRESSED?
               BPL   GOLOOP     ; NO -> DO NEXT LOOP
               LDA   #$00       ; RESET ASPECT
               STA   LOOPCNTX   ; BACK TO INIT POS
               STA   LOOPCNTY
*
GOLOOP         JMP   LOOP       ; START AGAIN
*
END            LDA   #$00
               STA   $C051      ; SWITCH TO TEXT
               STA   $C052
               STA   $C054
               JSR   HOME       ; CLEAR SCREEN
               JMP   $03D0      ; DOS WARM START NO RTS HERE!
*
* SETUP GRAPHICS
*
SETUP          LDA   #$00
               STA   $C050      ; SWITCH ON GRAPHICS
               STA   $C057      ; SWITCH TO HIRES
               LDA   #32
               STA   $E6        ; DRAW ON 1
               STA   $C055      ; SHOW 2
               JSR   HCLR       ; CLEAR HGR
               JSR   DRAWBOX    ; DRAW BOX ON HIRES 1
               LDA   #64
               STA   $E6        ; DRAW ON 2
               STA   $C054
               JSR   HCLR       ; CLEAR HGR2
               JSR   DRAWBOX    ; DRAW BOX ON HIRES 2
               LDA   #$03       ; INIT HCOLOR = 3
               JSR   HCOLOR
               LDA   #$0A       ; INITIAL RADIUS
               STA   RADIUS
               STA   ROTSPDX    ; INITIAL X-ROT SPEED = 0
               LDA   #$0F
               STA   ROTSPDY    ; INITIAL Y-ROT SPEED = 1
               LDA   #$01
               STA   ASCR       ; DRAW ON HIRES 1
               STA   JOYCNT     ; SET JOYSTICK REQUEST COUNTER
               LDA   #$50       ; SCALING
               STA   SCALING
               LDA   #$50
               STA   ZTRANS     ; MOVE OBJECT AWAY FROM CAMERA
               LDA   #<SHTAB    ; SET ADRESS FOR SHAPE-TABLE
               STA   SHTABPTR
               LDA   #>SHTAB
               STA   SHTABPTR+1
               RTS
*
********************************
* UNDRAW LINES                 *
********************************
*
UDRWLNS        LDA   #$00
* JSR HCLR
* JSR DRAWBOX
* JSR WLCMTXT
* RTS
*
               STA   PNTCNT
               LDX   #$00       ; DELETE OLD LINES
               JSR   HCOLOR
UGETPNT2       LDA   PNTCNT
               ASL
               ASL
               ASL
               ASL              ; X = CNTR*16
               TAX
               LDA   $E6        ; WHICH SCREEN?
               CMP   #$20       ; SCREEN 1?
               BEQ   UDRW2      ; YES -> SKIP 6 BYTES
               INX              ; SKIP 9 BYTES -> SCREEN 2
               INX
               INX
UDRW2          INX
               INX
               INX
               INX
               INX
               INX
               LDA   TABLE,X    ; GET OLD XPOS LO-BYTE
               STA   XDRAW
               INX
               LDA   TABLE,X    ; GET OLD XPOS HI-BYTE
               STA   XDRAW+1
               INX
               LDA   TABLE,X    ; GET OLD YPOS
               STA   YDRAW
               INX
               LDA   $E6        ; WHICH SCREEN?
               CMP   #$40       ; SCREEN 2?
               BEQ   EVLPNTS2   ; YES -> EVAL POINTS NOW
               INX              ; NO -> SKIP 3 BYTES
               INX
               INX
*
* EVALUATE POINTS TO DRAW TO
*
EVLPNTS2       LDA   #$04
               STA   MAXDRAW    ; NUMBER OF LINES TO DRAW
UDRWNXT        LDA   TABLE,X
               BEQ   UNXTPNT    ; NOTHING MORE TO DRAW
               TAY              ; SUBTRACT 1 TO GET CORREC
               DEY              ; POINT NUMBER
               TYA
               ASL              ; CALC BASE ADRESS OF POINT TO
               ASL              ; DRAW TO
               ASL
               ASL
               TAY              ; Y = POINNUMBER * 16
               LDA   $E6        ; WHICH SCREEN?
               CMP   #$20       ; SCREEN 1?
               BEQ   UDRW1      ; YES -> SKIP 6 BYTES
               INY              ; SKIP 9 BYTES FOR SCREEN 2
               INY
               INY
UDRW1          INY
               INY
               INY
               INY
               INY
               INY
               LDA   TABLE,Y    ; READ OUT POINTS TO DRAW TO
               STA   XTO
               INY
               LDA   TABLE,Y
               STA   XTO+1
               INY
               LDA   TABLE,Y
               STA   YTO
*
               STX   XREGSAVE   ; SAVE X-REG ON STACK
               LDX   XDRAW
               LDY   XDRAW+1
               LDA   YDRAW
               JSR   HPOSN      ; POSITION CURSOR
               LDA   XTO
               LDX   XTO+1
               LDY   YTO
               JSR   HLIN       ; DRAW LINE
               LDX   XREGSAVE    ; RESTORE X-REG
               DEC   MAXDRAW    ; MAXIMUM NUMBER OF LINES
               BEQ   UNXTPNT    ; REACHED? IF YES NEXT POINT
               INX              ; INC X-REG TO NEXT POINT
               BNE   UDRWNXT    ; DRAW NEXT LINE
*
*
UNXTPNT        INC   PNTCNT
               LDA   PNTCNT
               CMP   NUMPNT
               BCS   UDRWEND    ; ALL DONE
               JMP   UGETPNT2
UDRWEND        RTS
*

*
********************************
* DRAW LINES                   *
********************************
*
DRWLNS         LDA   #$00
               STA   PNTCNT
               LDA   ASCR
               CMP   #$01
               BEQ   DRWSCR1
               BNE   SETCLR
DRWSCR1        LDA   #32
* STA $E6 ; DRAW ON 1
* STA $C055 ; SHOW 2
SETCLR         LDX   #$03       ; HCOLOR = 3
               JSR   HCOLOR
GETPNT2        LDA   PNTCNT
               ASL
               ASL
               ASL
               ASL              ; X = CNTR*16
               TAX
               INX              ; SKIP 3 BYTES
               INX
               INX
               LDA   TABLE,X    ; GET XPOS LO-BYTE
               STA   XDRAW
               INX
               LDA   TABLE,X    ; GET XPOS HI-BYTE
               STA   XDRAW+1
               INX
               LDA   TABLE,X    ; GET YPOS
               STA   YDRAW
               INX
               LDA   $E6        ; WHICH SCREEN?
               CMP   #$20       ; SCREEN 1?
               BEQ   SVOLD      ; YES -> WRITE TO OLDPOS1
               INX              ; NO -> SKIP 3 BYTES
               INX              ; WRITE TO OLDPOS2
               INX
SVOLD          LDA   XDRAW      ; SAVE AS OLD-POS
               STA   TABLE,X
               INX
               LDA   XDRAW+1
               STA   TABLE,X
               INX
               LDA   YDRAW
               STA   TABLE,X
               INX
               LDA   $E6        ; WHICH SCREEN?
               CMP   #$40       ; SCREEN 2?
               BEQ   EVLPNTS    ; YES -> EVAL POINTS NOW
               INX              ; NO -> SKIP 3 BYTES
               INX
               INX
*
* EVALUATE POINTS TO DRAW TO
*
EVLPNTS        LDA   #$04
               STA   MAXDRAW    ; NUMBER OF LINES TO DRAW
DRWNXT         LDA   TABLE,X
               BEQ   NXTPNT     ; NOTHING MORE TO DRAW
               TAY              ; SUBTRACT 1 TO GET CORREC
               DEY              ; POINT NUMBER
               TYA
               ASL              ; CALC BASE ADRESS OF POINT TO
               ASL              ; DRAW TO
               ASL
               ASL
               TAY              ; Y = POINNUMBER * 16
               INY              ; SKIP 3 BYTES
               INY
               INY
               LDA   TABLE,Y    ; READ OUT POINTS TO DRAW TO
               STA   XTO
               INY
               LDA   TABLE,Y
               STA   XTO+1
               INY
               LDA   TABLE,Y
               STA   YTO
*
               STX   XREGSAVE   ; SAVE X-REG ON STACK
               LDX   XDRAW
               LDY   XDRAW+1
               LDA   YDRAW
               JSR   HPOSN      ; POSITION CURSOR
               LDA   XTO
               LDX   XTO+1
               LDY   YTO
               JSR   HLIN       ; DRAW LINE
               LDX   XREGSAVE    ; RESTORE X-REG
               DEC   MAXDRAW    ; MAXIMUM NUMBER OF LINES
               BEQ   NXTPNT     ; REACHED? IF YES NEXT POINT
               INX              ; INC X-REG TO NEXT POINT
               BNE   DRWNXT     ; DRAW NEXT LINE
*
NXTPNT         INC   PNTCNT
               LDA   PNTCNT
               CMP   NUMPNT
               BCS   DRWEND     ; ALL DONE
               JMP   GETPNT2
DRWEND         LDA   ASCR       ; DISPLAY DRAW-SCREEN
               CMP   #$02
               BEQ   DISP2      ; SHOW SCREEN 2
               LDA   #64
               STA   $E6        ; DRAW ON 2
               STA   $C054      ; SWITCH TO SCREEN1
               INC   ASCR       ; ASCR = 2
               BNE   DRWEND2
DISP2          STA   $C055      ; SWITCH TO SCREEN2
               LDA   #32
               STA   $E6        ; DRAW ON 1
               DEC   ASCR       ; ASCR = 1
DRWEND2        RTS
*
XTO            DS    2          ; DRAW TO X-POS
YTO            DS    1          ; DRAW TO Y-POS
MAXDRAW        DS    1          ; MAXIMUM LINES TO DRAW
XREGSAVE       DS    1          ; TEMPORARY SAVE FOR X-REG
*
*
********************************
* INIT POINT POSITIONS         *
********************************
*
               CYC              ; PRINT CYCLES
*
INITPNTS       LDA   #$00
               STA   PNTCNT
GETPNT         LDA   PNTCNT
               ASL
               ASL
               ASL
               ASL              ; X = CNTR*16
               TAX
               LDA   TABLE,X    ; GET XPOS
               STA   XPOS
               INX
               LDA   TABLE,X    ; GET YPOS
               STA   YPOS
               INX
               LDA   TABLE,X    ; GET ZPOS
               STA   ZPOS
*
* EVAL SIN/COS-TAB
*
               LDX   LOOPCNTX   ; INITIAL POS
               LDA   SINTAB,X   ; GET SINUS FOR X
               STA   SAX
               LDA   COSTAB,X   ; GET COSINUS FOR X
               STA   CAX
               LDX   LOOPCNTY   ; INITIAL POS
               LDA   SINTAB,X   ; GET SINUS FOR Y
               STA   SAY
               LDA   COSTAB,X   ; GET COSINUS FOR Y
               STA   CAY
               LDA   SAX        ; SINXSINY = SINX * SINY
               STA   MATOR
               LDA   SAY
               STA   MKAND
               JSR   MULT
               STY   SINXSINY   ; ONLY HI-BYTE
               LDA   SAX        ; SINXCOSY = SINX * COSY
               STA   MATOR
               LDA   CAY
               STA   MKAND
               JSR   MULT
               STY   SINXCOSY   ; ONLY HI-BYTE
               LDA   CAX        ; COSXSINY = COSX * SINY
               STA   MATOR
               LDA   SAY
               STA   MKAND
               JSR   MULT
               STY   COSXSINY
               LDA   CAX        ; COSXCOSY = COSX * COSY
               STA   MATOR
               LDA   CAY
               STA   MKAND
               JSR   MULT
               STY   COSXCOSY
               LDA   CAX        ; COSXONE = COSX * $7F (= 1)
               STA   MATOR
               LDA   #$7F
               STA   MKAND
               JSR   MULT
               STY   COSXONE
               LDA   SAX        ; SINXONE = SINX * $7F (= 1)
               STA   MATOR
               LDA   #$7F
               STA   MKAND
               JSR   MULT
               STY   SINXONE
               LDA   CAY        ; COSYONE = COSX * $7F (= 1)
               STA   MATOR
               LDA   #$7F
               STA   MKAND
               JSR   MULT
               STY   COSYONE
               LDA   SAY        ; SINYONE = SINX * $7F (= 1)
               STA   MATOR
               LDA   #$7F
               STA   MKAND
               JSR   MULT
               STY   SINYONE
*
* ROTATE AROUND X AND Y
*
               LDA   XPOS       ; RX = X * COS(Y) + Z * SIN(Y)
               STA   MATOR
               LDA   COSYONE
               STA   MKAND
               JSR   MULT
               STA   PX1
               STY   PX1+1
               LDA   ZPOS
               STA   MATOR
               LDA   SINYONE
               STA   MKAND
               JSR   MULT
               STA   PX2
               STY   PX2+1
               CLC              ; ADD
               LDA   PX1
               ADC   PX2
               STA   RX
               LDA   PX1+1
               ADC   PX2+1
               STA   RX+1       ; SAVE HI-BYTE AS XPOS
*
               LDA   ZPOS       ; RZ = Z * C(X)C(Y) + Y * S(X)
               STA   MATOR      ;      - X * C(X)S(Y)
               LDA   COSXCOSY
               STA   MKAND
               JSR   MULT
               STA   PX1
               STY   PX1+1
               LDA   YPOS
               STA   MATOR
               LDA   SINXONE
               STA   MKAND
               JSR   MULT
               STA   PX2
               STY   PX2+1
               LDA   XPOS
               STA   MATOR
               LDA   COSXSINY
               STA   MKAND
               JSR   MULT
               STA   PX3
               STY   PX3+1
               CLC              ; ADD
               LDA   PX1
               ADC   PX2
               STA   RZ
               LDA   PX1+1
               ADC   PX2+1
               STA   RZ+1
               SEC              ; SUB
               LDA   RZ
               SBC   PX3
               STA   RZ
               LDA   RZ+1
               SBC   PX3+1
               CLC              ; ADD ZTRANS
               ADC   ZTRANS
               STA   RZ+1
*
               LDA   ZPOS       ; RY = X * S(X)S(Y) + Y * C(X)
               STA   MATOR      ;    - Z * S(X)C(Y)
               LDA   SINXCOSY
               STA   MKAND
               JSR   MULT
               STA   PX1
               STY   PX1+1
               LDA   YPOS
               STA   MATOR
               LDA   COSXONE
               STA   MKAND
               JSR   MULT
               STA   PX2
               STY   PX2+1
               LDA   XPOS
               STA   MATOR
               LDA   SINXSINY
               STA   MKAND
               JSR   MULT
               STA   PX3
               STY   PX3+1
               CLC              ; ADD
               LDA   PX3
               ADC   PX2
               STA   RY
               LDA   PX3+1
               ADC   PX2+1
               STA   RY+1
               SEC              ; SUB
               LDA   RY
               SBC   PX1
               STA   RY
               LDA   RY+1
               SBC   PX1+1
               STA   RY+1       ; SAVE HI-BYTE AS ZPOS
*

*
* PERFORM SCALING AND TRANSLATION
*
               LDA   SCALING    ; SCX = SCALE * RX
               STA   MATOR
               LDA   RX+1       ; ONLY HI-BYTE!
               STA   MKAND
               JSR   UMULT
               STA   SCX
               STY   SCX+1
*
               LDA   SCX+1      ; QX = SCX / RZ
               LDY   SCX
               LDX   RZ+1       ; ONLY HI-BYTE
               JSR   DIVI
               STY   QX
*
               LDA   SCALING    ; SCY = SCALE * RY
               STA   MATOR
               LDA   RY+1       ; ONLY HI-BYTE!
               STA   MKAND
               JSR   UMULT
               STA   SCY
               STY   SCY+1
*
               LDA   SCY+1      ; QY = SCY / RZ
               LDY   SCY
               LDX   RZ+1       ; ONLY HI-BYTE
               JSR   DIVI
               STY   QY
*
               CLC              ; XD = QX + XT
               LDA   QX
               ADC   #XTRANS
               STA   XD
               LDA   #$00
               STA   XD+1
               LDA   QX
               BMI   CALCYD     ; IF QX < 0 THEN NO CARRY-ADD
               LDA   #$00
               ADC   #$00       ; ADD CARRY BIT
               STA   XD+1
CALCYD         CLC              ; YD = QY + YT
               LDA   QY
               ADC   #YTRANS
               STA   YD         ; ONLY 1 BYTE HERE, NO CARRY!
*
* WRITE DATA BACK TO TABLE
*
WRTPNT         LDA   PNTCNT
               ASL
               ASL
               ASL
               ASL              ; X = CNTR*16
               TAX
               INX
               INX
               INX              ; SKIP 3 BYTES
               LDA   XD         ; SAVE XDRAW POSITION
               STA   TABLE,X
               INX
               LDA   XD+1
               STA   TABLE,X
               INX
               LDA   YD         ; SAVE YDRAW POSITION
               STA   TABLE,X
*
               INC   PNTCNT
               LDA   PNTCNT
               CMP   NUMPNT
               BCS   INITEND    ; ALL DONE
               JMP   GETPNT
INITEND        RTS
*
               CYC   OFF
*
XPOS           DS    1
YPOS           DS    1
ZPOS           DS    1
XD             DS    2
YD             DS    2
SAX            DS    1
CAX            DS    1
SAY            DS    1
CAY            DS    1
PX1            DS    2          ; INTERMEDIATE RESULTS
PY1            DS    2
PZ1            DS    2
PX2            DS    2
PY2            DS    2
PZ2            DS    2
PX3            DS    2
RX             DS    2
RY             DS    2
RZ             DS    2
SCX            DS    2
SCY            DS    2
QX             DS    1
QY             DS    1
SINXSINY       DS    1
SINXCOSY       DS    1
COSXSINY       DS    1
COSXCOSY       DS    1
COSXONE        DS    1
SINXONE        DS    1
COSYONE        DS    1
SINYONE        DS    1
*
********************************
* DRAW BOX AROUND HIRES SCREEN *
********************************
*
DRAWBOX        LDX   #$03
               JSR   HCOLOR
               LDA   #$00
               TAY
               TAX
               JSR   HPLOT
               LDA   #23
               LDX   #01
               JSR   HLIN
*
               LDA   #23
               LDX   #01
               LDY   #$BF
               JSR   HLIN
*
               LDA   #$00
               LDX   #$00
               LDY   #$BF
               JSR   HLIN
*
               LDA   #$00
               TAY
               TAX
               JSR   HLIN
*
               LDY   #00
               LDX   #00
               LDA   #12
               JSR   HPOSN
*
               LDA   #23
               LDX   #01
               LDY   #12
               JSR   HLIN
               RTS
*
********************************
*SIGNED  DIVISION 16 BIT/8 BIT *
********************************
*
               CYC
*
DIVI           STY   DEND       ;
               STA   DEND+1
               STX   DOR

               LDX   #$00
DECHK          LDA   DEND+1     ; DIVIDEND NEG?
               BPL   DORCHK
               INX              ; INC X-REG FOR NEG SIGN
               LDA   DEND
               SEC              ; TWO'S COMPLEMENT
               SBC   #$01
               EOR   #$FF
               STA   DEND
               LDA   DEND+1
               SBC   #$00
               EOR   #$FF
               STA   DEND+1
DORCHK         LDA   DOR        ; DIVISOR NEG?
               BPL   DIVIGO
               INX              ; INC X-REG FOR NEG SIGN
               SEC              ; TWO'S COMPLEMENT
               SBC   #$01
               EOR   #$FF
               STA   DOR
*
DIVIGO         LDA   DEND+1     ; TOO LARGE OR ZERO?
               CMP   DOR        ; CMP HI-BYTE WITH DOR!
               BCS   DIVERR     ; YES -> ERROR!
               LDY   #$08       ; 8 LOOPS
DLOOP          ASL   DEND       ; DOUBLE SHIFT DIVIDEND
               ROL              ; DEND+1 STILL IN ACCU!
               BCS   DSUBTR     ; SUBTRACTION WHEN CARRY IS SET
               CMP   DOR
               BCC   DCONT
DSUBTR         SBC   DOR
               INC   DEND
DCONT          DEY
               BNE   DLOOP
*
* STORE RESULTS
*
               STA   DOR        ; MOVE REMAINDER IN DOR
               CLC              ; NO ERROR -> CLEAR CARRY
               CPX   #$01       ; NEG SIGN FOR RESULT?
               BNE   DIVEND     ; NO, SIGN IS POSITIVE -> END
               EOR   #$FF       ; TWO'S COMPLEMENT  OF ACCU
               CLC
               ADC   #$01
               STA   DOR
               LDA   DEND
               EOR   #$FF
               ADC   #$01
               STA   DEND
               LDA   DOR        ; DOR = REMAINDER
DIVEND         LDY   DEND       ; DEND = QUOTIENT
               RTS
DIVERR         LDY   #$00       ; RETURN 0 AS RESULT
               RTS
*
               CYC   OFF
*
DEND           DS    2
DOR            DS    1
*
********************************
* 8-BIT UNSIGNED MULTIPL       *
********************************
*
               CYC
*
UMULT          LDX   #$00       ; INITIALISE MSIGN = 0
UMKCHK         LDA   MKAND      ; MKAND NEG?
               BPL   UMTCHK
               INX              ; INC X-REG FOR NEG SIGN
               EOR   #$FF
               TAY
               INY
               STY   MKAND
UMTCHK         LDA   MATOR      ; MATOR NEG?
UMULTGO        LDA   #$00
               LDY   #$07       ; LOOP 8 TIMES
               ASL   MATOR
UMLOOP         ASL
               ROL   MATOR
               BCC   UMCONT
               CLC
               ADC   MKAND
               BCC   UMCONT
               INC   MATOR
UMCONT         DEY
               BNE   UMLOOP
*
* STORE RESULTS
*
               STA   MKAND      ; MKAND = LO-BYTE
               DEX              ; NEG SIGN FOR RESULT?
               BNE   UMEND      ; NO SIGN IS POSITIVE -> END
               EOR   #$FF       ; TWO'S COMPLEMENT  OF ACCU
               CLC
               ADC   #$01
               STA   MKAND
               LDA   MATOR
               EOR   #$FF
               ADC   #$00
               STA   MATOR
               TAY
               LDA   MKAND      ; MKAND = LO-BYTE
               RTS
UMEND          LDY   MATOR      ; MATOR = HI-BYTE
               RTS
*
               CYC   OFF
*
*
********************************
* 8-BIT SIGNED MULTIPLY        *
********************************
*
               CYC
*
MULT           LDX   #$00       ; INITIALISE MSIGN = 0
MKCHK          LDA   MKAND      ; MKAND NEG?
               BPL   MTCHK
               INX
               EOR   #$FF       ; INC X-REG FOR NEG SIGN
               TAY              ; TWO'S COMPLEMENT
               INY
               STY   MKAND
MTCHK          LDA   MATOR      ; MATOR NEG?
               BPL   MULTGO
               INX
               EOR   #$FF
               TAY              ; INC X-REG FOR NEG SIGN
               INY
               STY   MATOR
MULTGO         LDA   #$00
               LDY   #$06       ; LOOP 8 TIMES
               ASL   MATOR
               ROL   MATOR
               BCC   MCONT0
               LDA   MKAND
MLOOP          ASL
MCONT0         ROL   MATOR
               BCC   MCONT
               CLC
               ADC   MKAND
               BCC   MCONT
               INC   MATOR
MCONT          DEY
               BNE   MLOOP
*
* STORE RESULTS
*
               STA   MKAND      ; MKAND = LO-BYTE
               DEX              ; NEG SIGN FOR RESULT?
               BNE   MEND       ; NO SIGN IS POSITIVE -> END
               EOR   #$FF       ; TWO'S COMPLEMENT  OF ACCU
               CLC
               ADC   #$01
               STA   MKAND
               LDA   MATOR
               EOR   #$FF
               ADC   #$00
               STA   MATOR
               TAY
               LDA   MKAND      ; MKAND = LO-BYTE
               RTS
MEND           LDY   MATOR      ; MATOR = HI-BYTE
               RTS
*
               CYC   OFF
*
MKAND          DS    1
MATOR          DS    1
MSIGN          DS    1
*
********************************
* WELCOME MESSAGE              *
********************************
*
* PRINT OUT WELCOME TEXT AS SHAPES ON SCREEN
*
WLCMTXT        LDX   #$03
               JSR   HCOLOR
               STX   $F9        ; SET ROT = 0
               LDA   #$01
               STA   $E7        ; SET SCALE = 1
               LDX   #$00
TXTLOOP        LDA   TXTDAT,X
               BEQ   TLP2       ; STOP WHEN $00 IS READ
               STA   SHPDUMP    ; SAVE SHAPE-NUMBER
               STX   XREGDUMP   ; SAVE X-REG COUNTER STATUS
               TXA              ; MOVE CHAR POSITION TO ACCU
               ASL              ; CHAR-POS * 8 PIXEL
               ASL              ; EACH CHAR NEEDS 8 PIXEL
               ASL              ; SPACING
               CLC
               ADC   #26        ; ADD X-OFFSET
               TAX              ; MOVE X-POS TO X-REG
               STX   SHXPOS     ; SAVE SHAPE X-POS
               LDY   #$00       ; HIGH-BYTE = 0
               LDA   #09        ; Y-OFFSET FOR TEXT OUTPUT
               JSR   HPOSN      ; POSITION THE CURSOR

               LDX   SHPDUMP    ; RETRIEVE SHAPE-NUMBER
               JSR   SHNUM      ; GET SHAPE ADRESS
               LDA   #32        ; DRAW ON SCREEN 1
               STA   $E6
               LDA   #$00       ; SET ROT = 0
               JSR   SHDRAW     ; DRAW SHAPE

               LDX   SHXPOS     ; GET SHAPE X-POS
               LDY   #$00       ; HIGH-BYTE = 0
               LDA   #09        ; Y-OFFSET FOR TEXT OUTPUT
               JSR   HPOSN      ; POSITION THE CURSOR
               LDX   SHPDUMP    ; RETRIEVE SHAPE-NUMBER
               JSR   SHNUM      ; GET SHAPE ADRESS
               LDA   #64        ; DRAW ON SCREEN 2
               STA   $E6
               LDA   #$00       ; SET ROT = 0
               JSR   SHDRAW     ; DRAW SHAPE

               LDX   XREGDUMP
               INX
               BNE   TXTLOOP

TLP2           LDX   #$00
TXTLOOP2       LDA   TXTDAT2,X
               BEQ   SUDONE     ; STOP WHEN $00 IS READ
               STA   SHPDUMP    ; SAVE SHAPE-NUMBER
               STX   XREGDUMP   ; SAVE X-REG COUNTER STATUS
               TXA              ; MOVE CHAR POSITION TO ACCU
               ASL              ; CHAR-POS * 8 PIXEL
               ASL              ; EACH CHAR NEEDS 8 PIXEL
               ASL              ; SPACING
               CLC
               ADC   #18        ; ADD X-OFFSET
               TAX              ; MOVE X-POS TO X-REG
               STX   SHXPOS     ; SAVE SHAPE X-POS
               LDY   #$00       ; HIGH-BYTE = 0
               LDA   #188       ; Y-OFFSET FOR TEXT OUTPUT
               JSR   HPOSN      ; POSITION THE CURSOR

               LDX   SHPDUMP    ; RETRIEVE SHAPE-NUMBER
               JSR   SHNUM      ; GET SHAPE ADRESS
               LDA   #32        ; DRAW ON SCREEN 1
               STA   $E6
               LDA   #$00       ; SET ROT = 0
               JSR   SHDRAW     ; DRAW SHAPE

               LDX   SHXPOS     ; GET SHAPE X-POS
               LDY   #$00       ; HIGH-BYTE = 0
               LDA   #188       ; Y-OFFSET FOR TEXT OUTPUT
               JSR   HPOSN      ; POSITION THE CURSOR
               LDX   SHPDUMP    ; RETRIEVE SHAPE-NUMBER
               JSR   SHNUM      ; GET SHAPE ADRESS
               LDA   #64        ; DRAW ON SCREEN 2
               STA   $E6
               LDA   #$00       ; SET ROT = 0
               JSR   SHDRAW     ; DRAW SHAPE

               LDX   XREGDUMP
               INX
               BNE   TXTLOOP2
SUDONE         RTS
*
* TEXT MESSAGES WHEN LOADING 3D-OBJECTS
*
TXTOB1         LDA   #<TXTDAT3  ; SET ADRESS FOR MESSAGE
               STA   TXTPTR
               LDA   #>TXTDAT3
               STA   TXTPTR+1
               JSR   DLTTXT
               JMP   PRTTXT     ; PRINT MESSAGE
*
TXTOB2         LDA   #<TXTDAT4  ; SET ADRESS FOR MESSAGE
               STA   TXTPTR
               LDA   #>TXTDAT4
               STA   TXTPTR+1
               JSR   DLTTXT
               JMP   PRTTXT     ; PRINT MESSAGE
*
TXTOB3         LDA   #<TXTDAT5  ; SET ADRESS FOR MESSAGE
               STA   TXTPTR
               LDA   #>TXTDAT5
               STA   TXTPTR+1
               JSR   DLTTXT
               JMP   PRTTXT     ; PRINT MESSAGE
*
TXTOB4         LDA   #<TXTDAT6  ; SET ADRESS FOR MESSAGE
               STA   TXTPTR
               LDA   #>TXTDAT6
               STA   TXTPTR+1
               JSR   DLTTXT
               JMP   PRTTXT     ; PRINT MESSAGE
*
TXTOB5         LDA   #<TXTDAT7  ; SET ADRESS FOR MESSAGE
               STA   TXTPTR
               LDA   #>TXTDAT7
               STA   TXTPTR+1
               JSR   DLTTXT
               JMP   PRTTXT     ; PRINT MESSAGE
*
PRTTXT         LDY   #$00
               LDX   #$03
               JSR   HCOLOR     ; SET HCOLOR = 3
TXTLOOP3       LDA   (TXTPTR),Y
               BEQ   TXTDONE    ; STOP WHEN $00 IS READ
               STA   SHPDUMP    ; SAVE SHAPE-NUMBER
               STY   YREGDUMP   ; SAVE X-REG COUNTER STATUS
               TYA              ; MOVE CHAR POSITION TO ACCU
               ASL              ; CHAR-POS * 8 PIXEL
               ASL              ; EACH CHAR NEEDS 8 PIXEL
               ASL              ; SPACING
               CLC
               ADC   #18        ; ADD X-OFFSET
               TAY              ; MOVE X-POS TO Y-REG
               TAX              ; ALSO TO X-REG
               STY   SHXPOS     ; SAVE SHAPE X-POS
               LDY   #$00       ; HIGH-BYTE = 0
               LDA   #188       ; Y-OFFSET FOR TEXT OUTPUT
               JSR   HPOSN      ; POSITION THE CURSOR

               LDX   SHPDUMP    ; RETRIEVE SHAPE-NUMBER
               JSR   SHNUM      ; GET SHAPE ADRESS
               LDA   #32        ; DRAW ON SCREEN 1
               STA   $E6
               LDA   #$00       ; SET ROT = 0
               JSR   SHDRAW     ; DRAW SHAPE

               LDX   SHXPOS     ; GET SHAPE X-POS
               LDY   #$00       ; HIGH-BYTE = 0
               LDA   #188       ; Y-OFFSET FOR TEXT OUTPUT
               JSR   HPOSN      ; POSITION THE CURSOR
               LDX   SHPDUMP    ; RETRIEVE SHAPE-NUMBER
               JSR   SHNUM      ; GET SHAPE ADRESS
               LDA   #64        ; DRAW ON SCREEN 2
               STA   $E6
               LDA   #$00       ; SET ROT = 0
               JSR   SHDRAW     ; DRAW SHAPE

               LDY   YREGDUMP
               INY
               BNE   TXTLOOP3
TXTDONE        RTS
*
TXTDAT         HEX   292231313A01151135
               HEX   2901232A33352925223A
               HEX   012231312D26013E3C
               HEX   00
*
TXTDAT2        HEX   450114250E25262E3001
               HEX   0E012E0F28302D30
               HEX   2E2326242C01131112
               HEX   18014500
*
TXTDAT3        HEX   2D3022252A2F28013529
               HEX   2601352635332226252633
               HEX   0F0F0F010101010101
               HEX   010100
*
TXTDAT4        HEX   2D3022252A2F28013529
               HEX   2601362E2333262D2D22
               HEX   0F0F0F010101010101
               HEX   010100
*
TXTDAT5        HEX   2D3022252A2F28013529
               HEX   2601342A2E312D260124362326
               HEX   0F0F0F010101010101
               HEX   010100
*
TXTDAT6        HEX   2D3022252A2F28013529
               HEX   2601352635332224362326
               HEX   0F0F0F010101010101
               HEX   010100
*
TXTDAT7        HEX   2D3022252A2F28013529
               HEX   2601243623260135382A2F34
               HEX   0F0F0F010101010101
               HEX   010100
*
LCNT           DS    1
XREGDUMP       DS    1
YREGDUMP       DS    1
SHPDUMP        DS    1
SHXPOS         DS    1
*
* DELETE BOTTOM TEXT
*
DLTTXT         LDX   #$00
               JSR   HCOLOR     ; HCOLOR = 0
               LDA   ASCR
DLTSTRT        LDA   #180
               STA   YDELROW    ; Y OF LINE TO DELETE
DLTLOOP        LDA   #32
               STA   $E6        ; DELETE ON SCREEN 1
               LDX   #$02
               LDY   #$00
               LDA   YDELROW
               JSR   HPOSN
               LDA   #$15
               LDX   #$01
               LDY   YDELROW
               JSR   HLIN
               LDA   #64
               STA   $E6        ; DELETE ON SCREEN 2
               LDX   #$02
               LDY   #$00
               LDA   YDELROW
               JSR   HPOSN
               LDA   #$15
               LDX   #$01
               LDY   YDELROW
               JSR   HLIN
               INC   YDELROW
               LDA   YDELROW
               CMP   #189       ; LINE 189 REACHED?
               BCC   DLTLOOP    ; NO -> DELETE NEXT LINE
DLTEND         RTS              ; END OF LOOP
*
YDELROW        DS    1
*
********************************
* LOAD 3D-OBJECTS IN MEMORY    *
********************************
*
LOAD1          JSR   TXTOB1     ; PRINT LOADING MESSAGE
LOAD01         LDA   #$8D       ; LOAD 3D-OBJECT 1 INTO MEMORY
               JSR   COUT
               JSR   PRINT
               HEX   84
               ASC   "BLOAD OBJECT1.3D,A$7200"
               HEX   8D00
               RTS
*
LOAD2          JSR   TXTOB2
LOAD02         LDA   #$8D       ; LOAD 3D-OBJECT 1 INTO MEMORY
               JSR   COUT
               JSR   PRINT
               HEX   84
               ASC   "BLOAD OBJECT2.3D,A$7200"
               HEX   8D00
               RTS
*
LOAD3          JSR   TXTOB3
LOAD03         LDA   #$8D       ; LOAD 3D-OBJECT 1 INTO MEMORY
               JSR   COUT
               JSR   PRINT
               HEX   84
               ASC   "BLOAD OBJECT3.3D,A$7200"
               HEX   8D00
               RTS
*
LOAD4          JSR   TXTOB4
LOAD04         LDA   #$8D       ; LOAD 3D-OBJECT 1 INTO MEMORY
               JSR   COUT
               JSR   PRINT
               HEX   84
               ASC   "BLOAD OBJECT4.3D,A$7200"
               HEX   8D00
               RTS
*
LOAD5          JSR   TXTOB5
LOAD05         LDA   #$8D       ; LOAD 3D-OBJECT 1 INTO MEMORY
               JSR   COUT
               JSR   PRINT
               HEX   84
               ASC   "BLOAD OBJECT5.3D,A$7200"
               HEX   8D00
               RTS
*
PRINT          PLA
               STA   PTR
               PLA
               STA   PTR+1
               LDY   #$01
P0             LDA   (PTR),Y
               BEQ   PFIN
               JSR   COUT
               INY
               BNE   P0
               CHK
*
PFIN           CLC
               TYA
               ADC   PTR
               STA   PTR
               LDA   PTR+1
               ADC   #$00
               PHA
               LDA   PTR
               PHA
PEXIT          RTS
*
               LST   OFF
*
               CHK
*
