subtitle "Microchip MPLAB XC8 C Compiler v2.46 (Free license) build 20240104201356 Og1 "

pagewidth 120

	opt flic

	processor	16F877A
include "/opt/microchip/xc8/v2.46/pic/include/proc/16f877a.cgen.inc"
getbyte	macro	val,pos
	(((val) >> (8 * pos)) and 0xff)
endm
byte0	macro	val
	(getbyte(val,0))
endm
byte1	macro	val
	(getbyte(val,1))
endm
byte2	macro	val
	(getbyte(val,2))
endm
byte3	macro	val
	(getbyte(val,3))
endm
byte4	macro	val
	(getbyte(val,4))
endm
byte5	macro	val
	(getbyte(val,5))
endm
byte6	macro	val
	(getbyte(val,6))
endm
byte7	macro	val
	(getbyte(val,7))
endm
getword	macro	val,pos
	(((val) >> (8 * pos)) and 0xffff)
endm
word0	macro	val
	(getword(val,0))
endm
word1	macro	val
	(getword(val,2))
endm
word2	macro	val
	(getword(val,4))
endm
word3	macro	val
	(getword(val,6))
endm
gettword	macro	val,pos
	(((val) >> (8 * pos)) and 0xffffff)
endm
tword0	macro	val
	(gettword(val,0))
endm
tword1	macro	val
	(gettword(val,3))
endm
tword2	macro	val
	(gettword(val,6))
endm
getdword	macro	val,pos
	(((val) >> (8 * pos)) and 0xffffffff)
endm
dword0	macro	val
	(getdword(val,0))
endm
dword1	macro	val
	(getdword(val,4))
endm
clrc	macro
	bcf	3,0
	endm
clrz	macro
	bcf	3,2
	endm
setc	macro
	bsf	3,0
	endm
setz	macro
	bsf	3,2
	endm
skipc	macro
	btfss	3,0
	endm
skipz	macro
	btfss	3,2
	endm
skipnc	macro
	btfsc	3,0
	endm
skipnz	macro
	btfsc	3,2
	endm
# 54 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
INDF equ 00h ;# 
# 61 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR0 equ 01h ;# 
# 68 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PCL equ 02h ;# 
# 75 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
STATUS equ 03h ;# 
# 161 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
FSR equ 04h ;# 
# 168 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTA equ 05h ;# 
# 218 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTB equ 06h ;# 
# 280 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTC equ 07h ;# 
# 342 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTD equ 08h ;# 
# 404 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTE equ 09h ;# 
# 436 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PCLATH equ 0Ah ;# 
# 456 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
INTCON equ 0Bh ;# 
# 534 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIR1 equ 0Ch ;# 
# 596 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIR2 equ 0Dh ;# 
# 636 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR1 equ 0Eh ;# 
# 643 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR1L equ 0Eh ;# 
# 650 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR1H equ 0Fh ;# 
# 657 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
T1CON equ 010h ;# 
# 732 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR2 equ 011h ;# 
# 739 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
T2CON equ 012h ;# 
# 810 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPBUF equ 013h ;# 
# 817 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPCON equ 014h ;# 
# 887 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR1 equ 015h ;# 
# 894 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR1L equ 015h ;# 
# 901 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR1H equ 016h ;# 
# 908 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCP1CON equ 017h ;# 
# 966 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
RCSTA equ 018h ;# 
# 1061 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TXREG equ 019h ;# 
# 1068 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
RCREG equ 01Ah ;# 
# 1075 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR2 equ 01Bh ;# 
# 1082 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR2L equ 01Bh ;# 
# 1089 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR2H equ 01Ch ;# 
# 1096 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCP2CON equ 01Dh ;# 
# 1154 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADRESH equ 01Eh ;# 
# 1161 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADCON0 equ 01Fh ;# 
# 1257 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
OPTION_REG equ 081h ;# 
# 1327 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISA equ 085h ;# 
# 1377 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISB equ 086h ;# 
# 1439 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISC equ 087h ;# 
# 1501 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISD equ 088h ;# 
# 1563 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISE equ 089h ;# 
# 1620 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIE1 equ 08Ch ;# 
# 1682 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIE2 equ 08Dh ;# 
# 1722 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PCON equ 08Eh ;# 
# 1756 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPCON2 equ 091h ;# 
# 1818 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PR2 equ 092h ;# 
# 1825 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPADD equ 093h ;# 
# 1832 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPSTAT equ 094h ;# 
# 2001 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TXSTA equ 098h ;# 
# 2082 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SPBRG equ 099h ;# 
# 2089 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CMCON equ 09Ch ;# 
# 2159 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CVRCON equ 09Dh ;# 
# 2224 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADRESL equ 09Eh ;# 
# 2231 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADCON1 equ 09Fh ;# 
# 2290 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEDATA equ 010Ch ;# 
# 2297 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEADR equ 010Dh ;# 
# 2304 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEDATH equ 010Eh ;# 
# 2311 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEADRH equ 010Fh ;# 
# 2318 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EECON1 equ 018Ch ;# 
# 2363 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EECON2 equ 018Dh ;# 
# 54 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
INDF equ 00h ;# 
# 61 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR0 equ 01h ;# 
# 68 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PCL equ 02h ;# 
# 75 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
STATUS equ 03h ;# 
# 161 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
FSR equ 04h ;# 
# 168 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTA equ 05h ;# 
# 218 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTB equ 06h ;# 
# 280 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTC equ 07h ;# 
# 342 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTD equ 08h ;# 
# 404 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTE equ 09h ;# 
# 436 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PCLATH equ 0Ah ;# 
# 456 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
INTCON equ 0Bh ;# 
# 534 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIR1 equ 0Ch ;# 
# 596 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIR2 equ 0Dh ;# 
# 636 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR1 equ 0Eh ;# 
# 643 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR1L equ 0Eh ;# 
# 650 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR1H equ 0Fh ;# 
# 657 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
T1CON equ 010h ;# 
# 732 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR2 equ 011h ;# 
# 739 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
T2CON equ 012h ;# 
# 810 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPBUF equ 013h ;# 
# 817 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPCON equ 014h ;# 
# 887 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR1 equ 015h ;# 
# 894 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR1L equ 015h ;# 
# 901 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR1H equ 016h ;# 
# 908 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCP1CON equ 017h ;# 
# 966 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
RCSTA equ 018h ;# 
# 1061 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TXREG equ 019h ;# 
# 1068 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
RCREG equ 01Ah ;# 
# 1075 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR2 equ 01Bh ;# 
# 1082 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR2L equ 01Bh ;# 
# 1089 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR2H equ 01Ch ;# 
# 1096 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCP2CON equ 01Dh ;# 
# 1154 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADRESH equ 01Eh ;# 
# 1161 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADCON0 equ 01Fh ;# 
# 1257 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
OPTION_REG equ 081h ;# 
# 1327 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISA equ 085h ;# 
# 1377 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISB equ 086h ;# 
# 1439 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISC equ 087h ;# 
# 1501 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISD equ 088h ;# 
# 1563 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISE equ 089h ;# 
# 1620 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIE1 equ 08Ch ;# 
# 1682 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIE2 equ 08Dh ;# 
# 1722 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PCON equ 08Eh ;# 
# 1756 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPCON2 equ 091h ;# 
# 1818 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PR2 equ 092h ;# 
# 1825 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPADD equ 093h ;# 
# 1832 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPSTAT equ 094h ;# 
# 2001 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TXSTA equ 098h ;# 
# 2082 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SPBRG equ 099h ;# 
# 2089 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CMCON equ 09Ch ;# 
# 2159 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CVRCON equ 09Dh ;# 
# 2224 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADRESL equ 09Eh ;# 
# 2231 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADCON1 equ 09Fh ;# 
# 2290 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEDATA equ 010Ch ;# 
# 2297 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEADR equ 010Dh ;# 
# 2304 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEDATH equ 010Eh ;# 
# 2311 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEADRH equ 010Fh ;# 
# 2318 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EECON1 equ 018Ch ;# 
# 2363 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EECON2 equ 018Dh ;# 
# 54 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
INDF equ 00h ;# 
# 61 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR0 equ 01h ;# 
# 68 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PCL equ 02h ;# 
# 75 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
STATUS equ 03h ;# 
# 161 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
FSR equ 04h ;# 
# 168 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTA equ 05h ;# 
# 218 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTB equ 06h ;# 
# 280 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTC equ 07h ;# 
# 342 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTD equ 08h ;# 
# 404 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTE equ 09h ;# 
# 436 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PCLATH equ 0Ah ;# 
# 456 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
INTCON equ 0Bh ;# 
# 534 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIR1 equ 0Ch ;# 
# 596 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIR2 equ 0Dh ;# 
# 636 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR1 equ 0Eh ;# 
# 643 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR1L equ 0Eh ;# 
# 650 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR1H equ 0Fh ;# 
# 657 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
T1CON equ 010h ;# 
# 732 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR2 equ 011h ;# 
# 739 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
T2CON equ 012h ;# 
# 810 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPBUF equ 013h ;# 
# 817 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPCON equ 014h ;# 
# 887 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR1 equ 015h ;# 
# 894 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR1L equ 015h ;# 
# 901 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR1H equ 016h ;# 
# 908 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCP1CON equ 017h ;# 
# 966 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
RCSTA equ 018h ;# 
# 1061 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TXREG equ 019h ;# 
# 1068 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
RCREG equ 01Ah ;# 
# 1075 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR2 equ 01Bh ;# 
# 1082 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR2L equ 01Bh ;# 
# 1089 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR2H equ 01Ch ;# 
# 1096 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCP2CON equ 01Dh ;# 
# 1154 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADRESH equ 01Eh ;# 
# 1161 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADCON0 equ 01Fh ;# 
# 1257 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
OPTION_REG equ 081h ;# 
# 1327 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISA equ 085h ;# 
# 1377 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISB equ 086h ;# 
# 1439 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISC equ 087h ;# 
# 1501 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISD equ 088h ;# 
# 1563 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISE equ 089h ;# 
# 1620 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIE1 equ 08Ch ;# 
# 1682 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIE2 equ 08Dh ;# 
# 1722 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PCON equ 08Eh ;# 
# 1756 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPCON2 equ 091h ;# 
# 1818 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PR2 equ 092h ;# 
# 1825 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPADD equ 093h ;# 
# 1832 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPSTAT equ 094h ;# 
# 2001 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TXSTA equ 098h ;# 
# 2082 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SPBRG equ 099h ;# 
# 2089 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CMCON equ 09Ch ;# 
# 2159 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CVRCON equ 09Dh ;# 
# 2224 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADRESL equ 09Eh ;# 
# 2231 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADCON1 equ 09Fh ;# 
# 2290 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEDATA equ 010Ch ;# 
# 2297 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEADR equ 010Dh ;# 
# 2304 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEDATH equ 010Eh ;# 
# 2311 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEADRH equ 010Fh ;# 
# 2318 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EECON1 equ 018Ch ;# 
# 2363 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EECON2 equ 018Dh ;# 
# 54 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
INDF equ 00h ;# 
# 61 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR0 equ 01h ;# 
# 68 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PCL equ 02h ;# 
# 75 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
STATUS equ 03h ;# 
# 161 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
FSR equ 04h ;# 
# 168 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTA equ 05h ;# 
# 218 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTB equ 06h ;# 
# 280 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTC equ 07h ;# 
# 342 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTD equ 08h ;# 
# 404 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTE equ 09h ;# 
# 436 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PCLATH equ 0Ah ;# 
# 456 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
INTCON equ 0Bh ;# 
# 534 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIR1 equ 0Ch ;# 
# 596 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIR2 equ 0Dh ;# 
# 636 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR1 equ 0Eh ;# 
# 643 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR1L equ 0Eh ;# 
# 650 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR1H equ 0Fh ;# 
# 657 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
T1CON equ 010h ;# 
# 732 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR2 equ 011h ;# 
# 739 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
T2CON equ 012h ;# 
# 810 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPBUF equ 013h ;# 
# 817 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPCON equ 014h ;# 
# 887 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR1 equ 015h ;# 
# 894 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR1L equ 015h ;# 
# 901 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR1H equ 016h ;# 
# 908 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCP1CON equ 017h ;# 
# 966 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
RCSTA equ 018h ;# 
# 1061 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TXREG equ 019h ;# 
# 1068 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
RCREG equ 01Ah ;# 
# 1075 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR2 equ 01Bh ;# 
# 1082 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR2L equ 01Bh ;# 
# 1089 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR2H equ 01Ch ;# 
# 1096 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCP2CON equ 01Dh ;# 
# 1154 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADRESH equ 01Eh ;# 
# 1161 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADCON0 equ 01Fh ;# 
# 1257 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
OPTION_REG equ 081h ;# 
# 1327 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISA equ 085h ;# 
# 1377 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISB equ 086h ;# 
# 1439 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISC equ 087h ;# 
# 1501 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISD equ 088h ;# 
# 1563 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISE equ 089h ;# 
# 1620 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIE1 equ 08Ch ;# 
# 1682 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIE2 equ 08Dh ;# 
# 1722 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PCON equ 08Eh ;# 
# 1756 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPCON2 equ 091h ;# 
# 1818 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PR2 equ 092h ;# 
# 1825 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPADD equ 093h ;# 
# 1832 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPSTAT equ 094h ;# 
# 2001 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TXSTA equ 098h ;# 
# 2082 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SPBRG equ 099h ;# 
# 2089 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CMCON equ 09Ch ;# 
# 2159 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CVRCON equ 09Dh ;# 
# 2224 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADRESL equ 09Eh ;# 
# 2231 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADCON1 equ 09Fh ;# 
# 2290 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEDATA equ 010Ch ;# 
# 2297 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEADR equ 010Dh ;# 
# 2304 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEDATH equ 010Eh ;# 
# 2311 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEADRH equ 010Fh ;# 
# 2318 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EECON1 equ 018Ch ;# 
# 2363 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EECON2 equ 018Dh ;# 
# 54 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
INDF equ 00h ;# 
# 61 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR0 equ 01h ;# 
# 68 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PCL equ 02h ;# 
# 75 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
STATUS equ 03h ;# 
# 161 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
FSR equ 04h ;# 
# 168 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTA equ 05h ;# 
# 218 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTB equ 06h ;# 
# 280 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTC equ 07h ;# 
# 342 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTD equ 08h ;# 
# 404 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTE equ 09h ;# 
# 436 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PCLATH equ 0Ah ;# 
# 456 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
INTCON equ 0Bh ;# 
# 534 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIR1 equ 0Ch ;# 
# 596 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIR2 equ 0Dh ;# 
# 636 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR1 equ 0Eh ;# 
# 643 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR1L equ 0Eh ;# 
# 650 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR1H equ 0Fh ;# 
# 657 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
T1CON equ 010h ;# 
# 732 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR2 equ 011h ;# 
# 739 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
T2CON equ 012h ;# 
# 810 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPBUF equ 013h ;# 
# 817 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPCON equ 014h ;# 
# 887 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR1 equ 015h ;# 
# 894 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR1L equ 015h ;# 
# 901 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR1H equ 016h ;# 
# 908 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCP1CON equ 017h ;# 
# 966 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
RCSTA equ 018h ;# 
# 1061 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TXREG equ 019h ;# 
# 1068 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
RCREG equ 01Ah ;# 
# 1075 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR2 equ 01Bh ;# 
# 1082 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR2L equ 01Bh ;# 
# 1089 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR2H equ 01Ch ;# 
# 1096 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCP2CON equ 01Dh ;# 
# 1154 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADRESH equ 01Eh ;# 
# 1161 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADCON0 equ 01Fh ;# 
# 1257 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
OPTION_REG equ 081h ;# 
# 1327 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISA equ 085h ;# 
# 1377 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISB equ 086h ;# 
# 1439 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISC equ 087h ;# 
# 1501 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISD equ 088h ;# 
# 1563 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISE equ 089h ;# 
# 1620 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIE1 equ 08Ch ;# 
# 1682 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIE2 equ 08Dh ;# 
# 1722 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PCON equ 08Eh ;# 
# 1756 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPCON2 equ 091h ;# 
# 1818 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PR2 equ 092h ;# 
# 1825 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPADD equ 093h ;# 
# 1832 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPSTAT equ 094h ;# 
# 2001 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TXSTA equ 098h ;# 
# 2082 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SPBRG equ 099h ;# 
# 2089 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CMCON equ 09Ch ;# 
# 2159 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CVRCON equ 09Dh ;# 
# 2224 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADRESL equ 09Eh ;# 
# 2231 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADCON1 equ 09Fh ;# 
# 2290 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEDATA equ 010Ch ;# 
# 2297 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEADR equ 010Dh ;# 
# 2304 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEDATH equ 010Eh ;# 
# 2311 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEADRH equ 010Fh ;# 
# 2318 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EECON1 equ 018Ch ;# 
# 2363 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EECON2 equ 018Dh ;# 
# 54 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
INDF equ 00h ;# 
# 61 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR0 equ 01h ;# 
# 68 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PCL equ 02h ;# 
# 75 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
STATUS equ 03h ;# 
# 161 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
FSR equ 04h ;# 
# 168 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTA equ 05h ;# 
# 218 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTB equ 06h ;# 
# 280 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTC equ 07h ;# 
# 342 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTD equ 08h ;# 
# 404 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PORTE equ 09h ;# 
# 436 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PCLATH equ 0Ah ;# 
# 456 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
INTCON equ 0Bh ;# 
# 534 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIR1 equ 0Ch ;# 
# 596 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIR2 equ 0Dh ;# 
# 636 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR1 equ 0Eh ;# 
# 643 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR1L equ 0Eh ;# 
# 650 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR1H equ 0Fh ;# 
# 657 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
T1CON equ 010h ;# 
# 732 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TMR2 equ 011h ;# 
# 739 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
T2CON equ 012h ;# 
# 810 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPBUF equ 013h ;# 
# 817 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPCON equ 014h ;# 
# 887 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR1 equ 015h ;# 
# 894 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR1L equ 015h ;# 
# 901 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR1H equ 016h ;# 
# 908 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCP1CON equ 017h ;# 
# 966 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
RCSTA equ 018h ;# 
# 1061 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TXREG equ 019h ;# 
# 1068 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
RCREG equ 01Ah ;# 
# 1075 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR2 equ 01Bh ;# 
# 1082 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR2L equ 01Bh ;# 
# 1089 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCPR2H equ 01Ch ;# 
# 1096 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CCP2CON equ 01Dh ;# 
# 1154 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADRESH equ 01Eh ;# 
# 1161 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADCON0 equ 01Fh ;# 
# 1257 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
OPTION_REG equ 081h ;# 
# 1327 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISA equ 085h ;# 
# 1377 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISB equ 086h ;# 
# 1439 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISC equ 087h ;# 
# 1501 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISD equ 088h ;# 
# 1563 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TRISE equ 089h ;# 
# 1620 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIE1 equ 08Ch ;# 
# 1682 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PIE2 equ 08Dh ;# 
# 1722 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PCON equ 08Eh ;# 
# 1756 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPCON2 equ 091h ;# 
# 1818 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
PR2 equ 092h ;# 
# 1825 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPADD equ 093h ;# 
# 1832 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SSPSTAT equ 094h ;# 
# 2001 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
TXSTA equ 098h ;# 
# 2082 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
SPBRG equ 099h ;# 
# 2089 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CMCON equ 09Ch ;# 
# 2159 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
CVRCON equ 09Dh ;# 
# 2224 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADRESL equ 09Eh ;# 
# 2231 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
ADCON1 equ 09Fh ;# 
# 2290 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEDATA equ 010Ch ;# 
# 2297 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEADR equ 010Dh ;# 
# 2304 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEDATH equ 010Eh ;# 
# 2311 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EEADRH equ 010Fh ;# 
# 2318 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EECON1 equ 018Ch ;# 
# 2363 "/opt/microchip/xc8/v2.46/pic/include/proc/pic16f877a.h"
EECON2 equ 018Dh ;# 
	debug_source C
	FNCALL	_main,___awmod
	FNCALL	_main,_keypad_init
	FNCALL	_main,_keypad_scan
	FNCALL	_main,_lcd_clear
	FNCALL	_main,_lcd_init
	FNCALL	_main,_lcd_send_string
	FNCALL	_main,_lcd_set_cursor
	FNCALL	_main,_lcd_show_zone
	FNCALL	_main,_process_keypress
	FNCALL	_main,_send_uart_all_zones
	FNCALL	_main,_uart_init
	FNCALL	_main,_update_all_leds
	FNCALL	_main,_zones_init
	FNCALL	_zones_init,___bmul
	FNCALL	_send_uart_all_zones,___bmul
	FNCALL	_send_uart_all_zones,___xxtofl
	FNCALL	_send_uart_all_zones,_uart_send_packet
	FNCALL	_uart_send_packet,_uart_send_byte
	FNCALL	_process_keypress,___awmod
	FNCALL	_process_keypress,___bmul
	FNCALL	_process_keypress,_update_all_leds
	FNCALL	_process_keypress,_update_zone_mode
	FNCALL	_update_zone_mode,___bmul
	FNCALL	_lcd_show_zone,___bmul
	FNCALL	_lcd_show_zone,_lcd_send_string
	FNCALL	_lcd_show_zone,_lcd_set_cursor
	FNCALL	_lcd_show_zone,_sprintf
	FNCALL	_sprintf,_vfprintf
	FNCALL	_vfprintf,_vfpfcnvrt
	FNCALL	_vfpfcnvrt,_ctoa
	FNCALL	_vfpfcnvrt,_dtoa
	FNCALL	_vfpfcnvrt,_fputc
	FNCALL	_vfpfcnvrt,_read_prec_or_width
	FNCALL	_vfpfcnvrt,_utoa
	FNCALL	_utoa,___lwdiv
	FNCALL	_utoa,___lwmod
	FNCALL	_utoa,_pad
	FNCALL	_read_prec_or_width,___wmul
	FNCALL	_dtoa,___awdiv
	FNCALL	_dtoa,___awmod
	FNCALL	_dtoa,_abs
	FNCALL	_dtoa,_pad
	FNCALL	_pad,_fputc
	FNCALL	_pad,_fputs
	FNCALL	_fputs,_fputc
	FNCALL	_ctoa,_fputc
	FNCALL	_fputc,_putch
	FNCALL	_lcd_set_cursor,_lcd_send_cmd
	FNCALL	_lcd_send_string,_lcd_send_char
	FNCALL	_lcd_init,_lcd_send_cmd
	FNCALL	_lcd_clear,_lcd_send_cmd
	FNCALL	_keypad_scan,___bmul
	FNROOT	_main
	global	_temp_ids
	global	keypad_scan@F1012
	global	_occ_ids
psect	idataBANK0,class=CODE,space=0,delta=2,noexec
global __pidataBANK0
__pidataBANK0:
	file	"main.c"
	line	44

;initializer for _temp_ids
	retlw	low((((STR_1)-__stringbase)|8000h))
	retlw	low((((STR_2)-__stringbase)|8000h))
	retlw	low((((STR_3)-__stringbase)|8000h))
psect	idataBANK1,class=CODE,space=0,delta=2,noexec
global __pidataBANK1
__pidataBANK1:
	file	"keypad.c"
	line	26

;initializer for keypad_scan@F1012
	retlw	03h
	retlw	02h
	retlw	01h
	retlw	low(0)
	file	"main.c"
	line	45

;initializer for _occ_ids
	retlw	low((((STR_4)-__stringbase)|8000h))
	retlw	low((((STR_5)-__stringbase)|8000h))
	retlw	low((((STR_6)-__stringbase)|8000h))
	global	_width
	global	_prec
	global	_uart_counter
	global	_disp_counter
	global	_flags
	global	_current_zone
	global	_zones
	global	_dbuf
	global	_TXREG
_TXREG	set	0x19
	global	_RCSTA
_RCSTA	set	0x18
	global	_PORTE
_PORTE	set	0x9
	global	_PORTC
_PORTC	set	0x7
	global	_PORTB
_PORTB	set	0x6
	global	_PORTA
_PORTA	set	0x5
	global	_PORTD
_PORTD	set	0x8
	global	_RA2
_RA2	set	0x2A
	global	_RA1
_RA1	set	0x29
	global	_RA0
_RA0	set	0x28
	global	_RD2
_RD2	set	0x42
	global	_RD1
_RD1	set	0x41
	global	_RD0
_RD0	set	0x40
	global	_TXIF
_TXIF	set	0x64
	global	_RE1
_RE1	set	0x49
	global	_RE2
_RE2	set	0x4A
	global	_TXSTA
_TXSTA	set	0x98
	global	_SPBRG
_SPBRG	set	0x99
	global	_OPTION_REGbits
_OPTION_REGbits	set	0x81
	global	_ADCON1
_ADCON1	set	0x9F
	global	_TRISE
_TRISE	set	0x89
	global	_TRISD
_TRISD	set	0x88
	global	_TRISC
_TRISC	set	0x87
	global	_TRISB
_TRISB	set	0x86
	global	_TRISA
_TRISA	set	0x85
	global	_TRISC7
_TRISC7	set	0x43F
	global	_TRISC6
_TRISC6	set	0x43E
	global	_TRISE2
_TRISE2	set	0x44A
	global	_TRISE1
_TRISE1	set	0x449
psect	strings,class=STRING,delta=2,noexec
global __pstrings
__pstrings:
stringtab:
	global    __stringtab
__stringtab:
;	String table - string pointers are 1 byte each
	btfsc	(btemp+1),7
	ljmp	stringcode
	bcf	status,7
	btfsc	(btemp+1),0
	bsf	status,7
	movf	indf,w
	incf fsr
skipnz
incf btemp+1
	return
stringcode:stringdir:
movlw high(stringdir)
movwf pclath
movf fsr,w
incf fsr
	addwf pc
	global __stringbase
__stringbase:
	retlw	0
psect	strings
	global    __end_of__stringtab
__end_of__stringtab:
	
STR_7:	
	retlw	90	;'Z'
	retlw	111	;'o'
	retlw	110	;'n'
	retlw	101	;'e'
	retlw	37	;'%'
	retlw	117	;'u'
	retlw	32	;' '
	retlw	84	;'T'
	retlw	58	;':'
	retlw	37	;'%'
	retlw	50	;'2'
	retlw	100	;'d'
	retlw	67	;'C'
	retlw	32	;' '
	retlw	32	;' '
	retlw	37	;'%'
	retlw	99	;'c'
	retlw	32	;' '
	retlw	32	;' '
	retlw	0
psect	strings
	
STR_8:	
	retlw	79	;'O'
	retlw	99	;'c'
	retlw	99	;'c'
	retlw	58	;':'
	retlw	37	;'%'
	retlw	45	;'-'
	retlw	50	;'2'
	retlw	100	;'d'
	retlw	32	;' '
	retlw	112	;'p'
	retlw	101	;'e'
	retlw	111	;'o'
	retlw	112	;'p'
	retlw	108	;'l'
	retlw	101	;'e'
	retlw	32	;' '
	retlw	32	;' '
	retlw	32	;' '
	retlw	0
psect	strings
	
STR_10:	
	retlw	32	;' '
	retlw	51	;'3'
	retlw	45	;'-'
	retlw	90	;'Z'
	retlw	111	;'o'
	retlw	110	;'n'
	retlw	101	;'e'
	retlw	32	;' '
	retlw	83	;'S'
	retlw	121	;'y'
	retlw	115	;'s'
	retlw	116	;'t'
	retlw	101	;'e'
	retlw	109	;'m'
	retlw	32	;' '
	retlw	32	;' '
	retlw	0
psect	strings
	
STR_9:	
	retlw	69	;'E'
	retlw	110	;'n'
	retlw	101	;'e'
	retlw	114	;'r'
	retlw	103	;'g'
	retlw	121	;'y'
	retlw	32	;' '
	retlw	77	;'M'
	retlw	111	;'o'
	retlw	110	;'n'
	retlw	105	;'i'
	retlw	116	;'t'
	retlw	111	;'o'
	retlw	114	;'r'
	retlw	32	;' '
	retlw	32	;' '
	retlw	0
psect	strings
	
STR_1:	
	retlw	84	;'T'
	retlw	69	;'E'
	retlw	77	;'M'
	retlw	80	;'P'
	retlw	95	;'_'
	retlw	65	;'A'
	retlw	0
psect	strings
	
STR_2:	
	retlw	84	;'T'
	retlw	69	;'E'
	retlw	77	;'M'
	retlw	80	;'P'
	retlw	95	;'_'
	retlw	66	;'B'
	retlw	0
psect	strings
	
STR_3:	
	retlw	84	;'T'
	retlw	69	;'E'
	retlw	77	;'M'
	retlw	80	;'P'
	retlw	95	;'_'
	retlw	67	;'C'
	retlw	0
psect	strings
	
STR_4:	
	retlw	79	;'O'
	retlw	67	;'C'
	retlw	67	;'C'
	retlw	95	;'_'
	retlw	65	;'A'
	retlw	0
psect	strings
	
STR_5:	
	retlw	79	;'O'
	retlw	67	;'C'
	retlw	67	;'C'
	retlw	95	;'_'
	retlw	66	;'B'
	retlw	0
psect	strings
	
STR_6:	
	retlw	79	;'O'
	retlw	67	;'C'
	retlw	67	;'C'
	retlw	95	;'_'
	retlw	67	;'C'
	retlw	0
psect	strings
; #config settings
	config pad_punits      = on
	config apply_mask      = off
	config ignore_cmsgs    = off
	config default_configs = off
	config default_idlocs  = off
	config FOSC = "HS"
	config WDTE = "OFF"
	config PWRTE = "OFF"
	config BOREN = "ON"
	config LVP = "OFF"
	config CPD = "OFF"
	config WRT = "OFF"
	config CP = "OFF"
	file	"energy_monitor.s"
	line	#
psect cinit,class=CODE,delta=2
global start_initialization
start_initialization:

global __initialization
__initialization:
psect	bssBANK0,class=BANK0,space=1,noexec
global __pbssBANK0
__pbssBANK0:
_width:
       ds      2

_prec:
       ds      2

_uart_counter:
       ds      2

_disp_counter:
       ds      2

_flags:
       ds      1

_current_zone:
       ds      1

psect	dataBANK0,class=BANK0,space=1,noexec
global __pdataBANK0
__pdataBANK0:
	file	"main.c"
	line	44
_temp_ids:
       ds      3

psect	bssBANK1,class=BANK1,space=1,noexec
global __pbssBANK1
__pbssBANK1:
_zones:
       ds      15

psect	dataBANK1,class=BANK1,space=1,noexec
global __pdataBANK1
__pdataBANK1:
	file	"keypad.c"
	line	26
keypad_scan@F1012:
       ds      4

psect	dataBANK1
	file	"main.c"
	line	45
_occ_ids:
       ds      3

psect	bssBANK3,class=BANK3,space=1,noexec
global __pbssBANK3
__pbssBANK3:
_dbuf:
       ds      32

	file	"energy_monitor.s"
	line	#
global btemp
psect inittext,class=CODE,delta=2
global init_fetch0,btemp
;	Called with low address in FSR and high address in W
init_fetch0:
	movf btemp,w
	movwf pclath
	movf btemp+1,w
	movwf pc
global init_ram0
;Called with:
;	high address of idata address in btemp 
;	low address of idata address in btemp+1 
;	low address of data in FSR
;	high address + 1 of data in btemp-1
init_ram0:
	fcall init_fetch0
	movwf indf
	incf fsr,f
	movf fsr,w
	xorwf btemp-1,w
	btfsc status,2
	retlw 0
	incf btemp+1,f
	btfsc status,2
	incf btemp,f
	goto init_ram0
; Initialize objects allocated to BANK1
psect cinit,class=CODE,delta=2,merge=1
global init_ram0, __pidataBANK1
	bcf	status, 7	;select IRP bank0
	movlw low(__pdataBANK1+7)
	movwf btemp-1
	movlw high(__pidataBANK1)
	movwf btemp
	movlw low(__pidataBANK1)
	movwf btemp+1
	movlw low(__pdataBANK1)
	movwf fsr
	fcall init_ram0
; Initialize objects allocated to BANK0
psect cinit,class=CODE,delta=2,merge=1
global init_ram0, __pidataBANK0
	movlw low(__pdataBANK0+3)
	movwf btemp-1
	movlw high(__pidataBANK0)
	movwf btemp
	movlw low(__pidataBANK0)
	movwf btemp+1
	movlw low(__pdataBANK0)
	movwf fsr
	fcall init_ram0
	line	#
psect clrtext,class=CODE,delta=2
global clear_ram0
;	Called with FSR containing the base address, and
;	W with the last address+1
clear_ram0:
	clrwdt			;clear the watchdog before getting into this loop
clrloop0:
	clrf	indf		;clear RAM location pointed to by FSR
	incf	fsr,f		;increment pointer
	xorwf	fsr,w		;XOR with final address
	btfsc	status,2	;have we reached the end yet?
	retlw	0		;all done for this memory range, return
	xorwf	fsr,w		;XOR again to restore value
	goto	clrloop0		;do the next byte

; Clear objects allocated to BANK3
psect cinit,class=CODE,delta=2,merge=1
	bsf	status, 7	;select IRP bank2
	movlw	low(__pbssBANK3)
	movwf	fsr
	movlw	low((__pbssBANK3)+020h)
	fcall	clear_ram0
; Clear objects allocated to BANK1
psect cinit,class=CODE,delta=2,merge=1
	bcf	status, 7	;select IRP bank0
	movlw	low(__pbssBANK1)
	movwf	fsr
	movlw	low((__pbssBANK1)+0Fh)
	fcall	clear_ram0
; Clear objects allocated to BANK0
psect cinit,class=CODE,delta=2,merge=1
	movlw	low(__pbssBANK0)
	movwf	fsr
	movlw	low((__pbssBANK0)+0Ah)
	fcall	clear_ram0
psect cinit,class=CODE,delta=2,merge=1
global end_of_initialization,__end_of__initialization

;End of C runtime variable initialization code

end_of_initialization:
__end_of__initialization:
clrf status
ljmp _main	;jump to C main() function
psect	cstackBANK1,class=BANK1,space=1,noexec
global __pcstackBANK1
__pcstackBANK1:
	global	lcd_show_zone@line1
lcd_show_zone@line1:	; 17 bytes @ 0x0
	ds	17
	global	lcd_show_zone@line2
lcd_show_zone@line2:	; 17 bytes @ 0x11
	ds	17
	global	lcd_show_zone@z
lcd_show_zone@z:	; 1 bytes @ 0x22
	ds	1
psect	cstackCOMMON,class=COMMON,space=1,noexec
global __pcstackCOMMON
__pcstackCOMMON:
?_zones_init:	; 1 bytes @ 0x0
?_lcd_init:	; 1 bytes @ 0x0
?_uart_init:	; 1 bytes @ 0x0
??_uart_init:	; 1 bytes @ 0x0
?_keypad_init:	; 1 bytes @ 0x0
??_keypad_init:	; 1 bytes @ 0x0
?_lcd_clear:	; 1 bytes @ 0x0
?_update_all_leds:	; 1 bytes @ 0x0
??_update_all_leds:	; 1 bytes @ 0x0
?_keypad_scan:	; 1 bytes @ 0x0
?_process_keypress:	; 1 bytes @ 0x0
?_putch:	; 1 bytes @ 0x0
??_putch:	; 1 bytes @ 0x0
?_lcd_show_zone:	; 1 bytes @ 0x0
?_send_uart_all_zones:	; 1 bytes @ 0x0
?_main:	; 1 bytes @ 0x0
?_lcd_send_cmd:	; 1 bytes @ 0x0
??_lcd_send_cmd:	; 1 bytes @ 0x0
?_lcd_send_char:	; 1 bytes @ 0x0
??_lcd_send_char:	; 1 bytes @ 0x0
?_uart_send_byte:	; 1 bytes @ 0x0
??_uart_send_byte:	; 1 bytes @ 0x0
?_update_zone_mode:	; 1 bytes @ 0x0
?___bmul:	; 1 bytes @ 0x0
?_fputc:	; 2 bytes @ 0x0
	global	?___wmul
?___wmul:	; 2 bytes @ 0x0
	global	?___awdiv
?___awdiv:	; 2 bytes @ 0x0
	global	?___awmod
?___awmod:	; 2 bytes @ 0x0
	global	?___lwdiv
?___lwdiv:	; 2 bytes @ 0x0
	global	?___lwmod
?___lwmod:	; 2 bytes @ 0x0
	global	uart_send_byte@byte
uart_send_byte@byte:	; 1 bytes @ 0x0
	global	___bmul@multiplicand
___bmul@multiplicand:	; 1 bytes @ 0x0
putch@c:	; 1 bytes @ 0x0
	global	___wmul@multiplier
___wmul@multiplier:	; 2 bytes @ 0x0
	global	___awdiv@divisor
___awdiv@divisor:	; 2 bytes @ 0x0
	global	___awmod@divisor
___awmod@divisor:	; 2 bytes @ 0x0
	global	___lwdiv@divisor
___lwdiv@divisor:	; 2 bytes @ 0x0
	global	___lwmod@divisor
___lwmod@divisor:	; 2 bytes @ 0x0
	global	fputc@c
fputc@c:	; 2 bytes @ 0x0
	ds	1
??___bmul:	; 1 bytes @ 0x1
	ds	1
	global	lcd_send_cmd@cmd
lcd_send_cmd@cmd:	; 1 bytes @ 0x2
	global	lcd_send_char@ch
lcd_send_char@ch:	; 1 bytes @ 0x2
	global	___bmul@product
___bmul@product:	; 1 bytes @ 0x2
	global	fputc@fp
fputc@fp:	; 1 bytes @ 0x2
	global	___wmul@multiplicand
___wmul@multiplicand:	; 2 bytes @ 0x2
	global	___awdiv@dividend
___awdiv@dividend:	; 2 bytes @ 0x2
	global	___awmod@dividend
___awmod@dividend:	; 2 bytes @ 0x2
	global	___lwdiv@dividend
___lwdiv@dividend:	; 2 bytes @ 0x2
	global	___lwmod@dividend
___lwmod@dividend:	; 2 bytes @ 0x2
	ds	1
?_lcd_set_cursor:	; 1 bytes @ 0x3
?_lcd_send_string:	; 1 bytes @ 0x3
??_lcd_init:	; 1 bytes @ 0x3
??_lcd_clear:	; 1 bytes @ 0x3
??_fputc:	; 1 bytes @ 0x3
	global	lcd_set_cursor@col
lcd_set_cursor@col:	; 1 bytes @ 0x3
	global	___bmul@multiplier
___bmul@multiplier:	; 1 bytes @ 0x3
	global	lcd_send_string@str
lcd_send_string@str:	; 2 bytes @ 0x3
	ds	1
??_lcd_set_cursor:	; 1 bytes @ 0x4
??_zones_init:	; 1 bytes @ 0x4
??_keypad_scan:	; 1 bytes @ 0x4
??_update_zone_mode:	; 1 bytes @ 0x4
??___wmul:	; 1 bytes @ 0x4
??___awdiv:	; 1 bytes @ 0x4
??___awmod:	; 1 bytes @ 0x4
??___lwdiv:	; 1 bytes @ 0x4
??___lwmod:	; 1 bytes @ 0x4
	global	?___xxtofl
?___xxtofl:	; 4 bytes @ 0x4
	global	lcd_set_cursor@row
lcd_set_cursor@row:	; 1 bytes @ 0x4
	global	___wmul@product
___wmul@product:	; 2 bytes @ 0x4
	global	___xxtofl@val
___xxtofl@val:	; 4 bytes @ 0x4
	ds	1
??_lcd_send_string:	; 1 bytes @ 0x5
	global	zones_init@z
zones_init@z:	; 1 bytes @ 0x5
	global	___awdiv@counter
___awdiv@counter:	; 1 bytes @ 0x5
	global	___awmod@counter
___awmod@counter:	; 1 bytes @ 0x5
	global	___lwmod@counter
___lwmod@counter:	; 1 bytes @ 0x5
	global	_lcd_set_cursor$186
_lcd_set_cursor$186:	; 2 bytes @ 0x5
	global	___lwdiv@quotient
___lwdiv@quotient:	; 2 bytes @ 0x5
	ds	1
	global	?_read_prec_or_width
?_read_prec_or_width:	; 2 bytes @ 0x6
	global	update_zone_mode@z
update_zone_mode@z:	; 1 bytes @ 0x6
	global	___awdiv@sign
___awdiv@sign:	; 1 bytes @ 0x6
	global	___awmod@sign
___awmod@sign:	; 1 bytes @ 0x6
	global	read_prec_or_width@ap
read_prec_or_width@ap:	; 1 bytes @ 0x6
	global	keypad_scan@row_pins
keypad_scan@row_pins:	; 4 bytes @ 0x6
	ds	1
??_process_keypress:	; 1 bytes @ 0x7
	global	?_abs
?_abs:	; 2 bytes @ 0x7
	global	___lwdiv@counter
___lwdiv@counter:	; 1 bytes @ 0x7
	global	___awdiv@quotient
___awdiv@quotient:	; 2 bytes @ 0x7
	global	abs@a
abs@a:	; 2 bytes @ 0x7
	ds	1
??___xxtofl:	; 1 bytes @ 0x8
?_ctoa:	; 1 bytes @ 0x8
??_read_prec_or_width:	; 1 bytes @ 0x8
?_fputs:	; 2 bytes @ 0x8
	global	ctoa@c
ctoa@c:	; 1 bytes @ 0x8
	global	fputs@fp
fputs@fp:	; 1 bytes @ 0x8
	ds	1
??_fputs:	; 1 bytes @ 0x9
??_abs:	; 1 bytes @ 0x9
??_ctoa:	; 1 bytes @ 0x9
	global	process_keypress@key
process_keypress@key:	; 1 bytes @ 0x9
	global	read_prec_or_width@c
read_prec_or_width@c:	; 1 bytes @ 0x9
	ds	1
	global	keypad_scan@row
keypad_scan@row:	; 1 bytes @ 0xA
	global	process_keypress@zone
process_keypress@zone:	; 1 bytes @ 0xA
	global	read_prec_or_width@n
read_prec_or_width@n:	; 2 bytes @ 0xA
	ds	1
?_pad:	; 1 bytes @ 0xB
	global	keypad_scan@col
keypad_scan@col:	; 1 bytes @ 0xB
	global	pad@buf
pad@buf:	; 1 bytes @ 0xB
	ds	1
??_uart_send_packet:	; 1 bytes @ 0xC
	global	read_prec_or_width@fmt
read_prec_or_width@fmt:	; 1 bytes @ 0xC
	global	pad@p
pad@p:	; 2 bytes @ 0xC
	ds	2
??_vfprintf:	; 1 bytes @ 0xE
??_dtoa:	; 1 bytes @ 0xE
??_utoa:	; 1 bytes @ 0xE
psect	cstackBANK0,class=BANK0,space=1,noexec
global __pcstackBANK0
__pcstackBANK0:
	global	___xxtofl@sign
___xxtofl@sign:	; 1 bytes @ 0x0
	global	fputs@c
fputs@c:	; 1 bytes @ 0x0
	global	ctoa@l
ctoa@l:	; 2 bytes @ 0x0
	ds	1
	global	___xxtofl@exp
___xxtofl@exp:	; 1 bytes @ 0x1
	global	fputs@i
fputs@i:	; 2 bytes @ 0x1
	ds	1
	global	ctoa@w
ctoa@w:	; 2 bytes @ 0x2
	global	___xxtofl@arg
___xxtofl@arg:	; 4 bytes @ 0x2
	ds	1
	global	fputs@s
fputs@s:	; 1 bytes @ 0x3
	ds	1
??_pad:	; 1 bytes @ 0x4
	global	ctoa@fp
ctoa@fp:	; 1 bytes @ 0x4
	ds	1
	global	pad@i
pad@i:	; 2 bytes @ 0x5
	ds	1
?_uart_send_packet:	; 1 bytes @ 0x6
	global	uart_send_packet@value
uart_send_packet@value:	; 4 bytes @ 0x6
	ds	1
	global	pad@fp
pad@fp:	; 1 bytes @ 0x7
	ds	1
?_dtoa:	; 1 bytes @ 0x8
?_utoa:	; 1 bytes @ 0x8
	global	dtoa@d
dtoa@d:	; 2 bytes @ 0x8
	global	utoa@d
utoa@d:	; 2 bytes @ 0x8
	ds	2
	global	uart_send_packet@type
uart_send_packet@type:	; 1 bytes @ 0xA
	global	dtoa@fp
dtoa@fp:	; 1 bytes @ 0xA
	global	utoa@w
utoa@w:	; 2 bytes @ 0xA
	ds	1
	global	_dtoa$765
_dtoa$765:	; 2 bytes @ 0xB
	global	uart_send_packet@pkt
uart_send_packet@pkt:	; 20 bytes @ 0xB
	ds	1
	global	utoa@fp
utoa@fp:	; 1 bytes @ 0xC
	ds	1
	global	dtoa@p
dtoa@p:	; 1 bytes @ 0xD
	global	utoa@p
utoa@p:	; 1 bytes @ 0xD
	ds	1
	global	dtoa@w
dtoa@w:	; 2 bytes @ 0xE
	global	utoa@i
utoa@i:	; 2 bytes @ 0xE
	ds	2
	global	dtoa@s
dtoa@s:	; 1 bytes @ 0x10
	ds	1
	global	dtoa@i
dtoa@i:	; 2 bytes @ 0x11
	ds	2
?_vfpfcnvrt:	; 1 bytes @ 0x13
	global	vfpfcnvrt@fmt
vfpfcnvrt@fmt:	; 1 bytes @ 0x13
	ds	1
	global	vfpfcnvrt@ap
vfpfcnvrt@ap:	; 1 bytes @ 0x14
	ds	1
??_vfpfcnvrt:	; 1 bytes @ 0x15
	ds	2
	global	vfpfcnvrt@c
vfpfcnvrt@c:	; 1 bytes @ 0x17
	ds	1
	global	vfpfcnvrt@done
vfpfcnvrt@done:	; 1 bytes @ 0x18
	ds	1
	global	vfpfcnvrt@convarg
vfpfcnvrt@convarg:	; 4 bytes @ 0x19
	ds	4
	global	vfpfcnvrt@fp
vfpfcnvrt@fp:	; 1 bytes @ 0x1D
	ds	1
	global	vfpfcnvrt@cp
vfpfcnvrt@cp:	; 1 bytes @ 0x1E
	ds	1
	global	?_vfprintf
?_vfprintf:	; 2 bytes @ 0x1F
	global	vfprintf@fmt
vfprintf@fmt:	; 1 bytes @ 0x1F
	global	uart_send_packet@checksum
uart_send_packet@checksum:	; 2 bytes @ 0x1F
	ds	1
	global	vfprintf@ap
vfprintf@ap:	; 1 bytes @ 0x20
	ds	1
	global	uart_send_packet@device_id
uart_send_packet@device_id:	; 1 bytes @ 0x21
	global	vfprintf@fp
vfprintf@fp:	; 1 bytes @ 0x21
	ds	1
	global	uart_send_packet@fp
uart_send_packet@fp:	; 1 bytes @ 0x22
	global	vfprintf@cfmt
vfprintf@cfmt:	; 1 bytes @ 0x22
	ds	1
	global	?_sprintf
?_sprintf:	; 2 bytes @ 0x23
	global	uart_send_packet@i
uart_send_packet@i:	; 1 bytes @ 0x23
	global	sprintf@fmt
sprintf@fmt:	; 1 bytes @ 0x23
	ds	1
??_send_uart_all_zones:	; 1 bytes @ 0x24
	ds	2
	global	send_uart_all_zones@z
send_uart_all_zones@z:	; 1 bytes @ 0x26
	ds	4
??_sprintf:	; 1 bytes @ 0x2A
	ds	1
	global	sprintf@s
sprintf@s:	; 1 bytes @ 0x2B
	ds	1
	global	sprintf@ap
sprintf@ap:	; 1 bytes @ 0x2C
	ds	1
	global	sprintf@f
sprintf@f:	; 11 bytes @ 0x2D
	ds	11
??_lcd_show_zone:	; 1 bytes @ 0x38
	ds	2
??_main:	; 1 bytes @ 0x3A
	ds	3
	global	main@key
main@key:	; 1 bytes @ 0x3D
	ds	1
;!
;!Data Sizes:
;!    Strings     112
;!    Constant    0
;!    Data        10
;!    BSS         57
;!    Persistent  0
;!    Stack       0
;!
;!Auto Spaces:
;!    Space          Size  Autos    Used
;!    COMMON           14     14      14
;!    BANK0            80     62      75
;!    BANK1            80     35      57
;!    BANK3            96      0      32
;!    BANK2            96      0       0

;!
;!Pointer List with Targets:
;!
;!    ctoa@fp	PTR struct _IO_FILE size(1) Largest target is 11
;!		 -> sprintf@f(BANK0[11]), 
;!
;!    dtoa@fp	PTR struct _IO_FILE size(1) Largest target is 11
;!		 -> sprintf@f(BANK0[11]), 
;!
;!    f$.$buffer	PTR unsigned char  size(1) Largest target is 0
;!
;!    f$.$source	PTR const unsigned char  size(1) Largest target is 0
;!
;!    fputc@fp	PTR struct _IO_FILE size(1) Largest target is 11
;!		 -> sprintf@f(BANK0[11]), 
;!
;!    fputc@fp$.$buffer	PTR unsigned char  size(1) Largest target is 0
;!
;!    fputc@fp$.$source	PTR const unsigned char  size(1) Largest target is 0
;!
;!    fputs@fp	PTR struct _IO_FILE size(1) Largest target is 11
;!		 -> sprintf@f(BANK0[11]), 
;!
;!    fputs@s	PTR const unsigned char  size(1) Largest target is 32
;!		 -> dbuf(BANK3[32]), 
;!
;!    lcd_send_string@str	PTR const unsigned char  size(2) Largest target is 17
;!		 -> lcd_show_zone@line1(BANK1[17]), lcd_show_zone@line2(BANK1[17]), STR_10(CODE[17]), STR_9(CODE[17]), 
;!
;!    occ_ids	PTR const unsigned char [3] size(1) Largest target is 6
;!		 -> STR_4(CODE[6]), STR_5(CODE[6]), STR_6(CODE[6]), 
;!
;!    pad@buf	PTR unsigned char  size(1) Largest target is 32
;!		 -> dbuf(BANK3[32]), 
;!
;!    pad@fp	PTR struct _IO_FILE size(1) Largest target is 11
;!		 -> sprintf@f(BANK0[11]), 
;!
;!    read_prec_or_width@ap	PTR PTR void [1] size(1) Largest target is 1
;!		 -> sprintf@ap(BANK0[1]), 
;!
;!    read_prec_or_width@fmt	PTR PTR const unsigned char  size(1) Largest target is 1
;!		 -> vfprintf@cfmt(BANK0[1]), 
;!
;!    S681$buffer	PTR unsigned char  size(1) Largest target is 0
;!
;!    S681$source	PTR const unsigned char  size(1) Largest target is 0
;!
;!    sprintf@ap	PTR void [1] size(1) Largest target is 2
;!		 -> ?_sprintf(BANK0[2]), 
;!
;!    sprintf@fmt	PTR const unsigned char  size(1) Largest target is 20
;!		 -> STR_7(CODE[20]), STR_8(CODE[19]), 
;!
;!    sprintf@s	PTR unsigned char  size(1) Largest target is 17
;!		 -> lcd_show_zone@line1(BANK1[17]), lcd_show_zone@line2(BANK1[17]), 
;!
;!    temp_ids	PTR const unsigned char [3] size(1) Largest target is 7
;!		 -> STR_1(CODE[7]), STR_2(CODE[7]), STR_3(CODE[7]), 
;!
;!    uart_send_packet@device_id	PTR const unsigned char  size(1) Largest target is 7
;!		 -> STR_1(CODE[7]), STR_2(CODE[7]), STR_3(CODE[7]), STR_4(CODE[6]), 
;!		 -> STR_5(CODE[6]), STR_6(CODE[6]), 
;!
;!    uart_send_packet@fp	PTR unsigned char  size(1) Largest target is 4
;!		 -> uart_send_packet@value(BANK0[4]), 
;!
;!    utoa@fp	PTR struct _IO_FILE size(1) Largest target is 11
;!		 -> sprintf@f(BANK0[11]), 
;!
;!    vfpfcnvrt@ap	PTR PTR void  size(1) Largest target is 1
;!		 -> sprintf@ap(BANK0[1]), 
;!
;!    vfpfcnvrt@cp	PTR unsigned char  size(1) Largest target is 20
;!		 -> STR_7(CODE[20]), STR_8(CODE[19]), 
;!
;!    vfpfcnvrt@fmt	PTR PTR unsigned char  size(1) Largest target is 1
;!		 -> vfprintf@cfmt(BANK0[1]), 
;!
;!    vfpfcnvrt@fp	PTR struct _IO_FILE size(1) Largest target is 11
;!		 -> sprintf@f(BANK0[11]), 
;!
;!    vfprintf@ap	PTR PTR void  size(1) Largest target is 1
;!		 -> sprintf@ap(BANK0[1]), 
;!
;!    vfprintf@cfmt	PTR unsigned char  size(1) Largest target is 20
;!		 -> STR_7(CODE[20]), STR_8(CODE[19]), 
;!
;!    vfprintf@fmt	PTR const unsigned char  size(1) Largest target is 20
;!		 -> STR_7(CODE[20]), STR_8(CODE[19]), 
;!
;!    vfprintf@fp	PTR struct _IO_FILE size(1) Largest target is 11
;!		 -> sprintf@f(BANK0[11]), 
;!


;!
;!Critical Paths under _main in COMMON
;!
;!    _zones_init->___bmul
;!    _send_uart_all_zones->_uart_send_packet
;!    _uart_send_packet->___xxtofl
;!    ___xxtofl->___bmul
;!    _process_keypress->___awmod
;!    _process_keypress->_update_zone_mode
;!    _update_zone_mode->___bmul
;!    _utoa->_pad
;!    _read_prec_or_width->___wmul
;!    _dtoa->_pad
;!    _pad->_fputs
;!    _fputs->_fputc
;!    _abs->___awmod
;!    _ctoa->_fputc
;!    _lcd_set_cursor->_lcd_send_cmd
;!    _lcd_send_string->_lcd_send_char
;!    _lcd_init->_lcd_send_cmd
;!    _lcd_clear->_lcd_send_cmd
;!    _keypad_scan->___bmul
;!
;!Critical Paths under _main in BANK0
;!
;!    _main->_lcd_show_zone
;!    _send_uart_all_zones->_uart_send_packet
;!    _uart_send_packet->___xxtofl
;!    _lcd_show_zone->_sprintf
;!    _sprintf->_vfprintf
;!    _vfprintf->_vfpfcnvrt
;!    _vfpfcnvrt->_dtoa
;!    _utoa->_pad
;!    _dtoa->_pad
;!    _pad->_fputs
;!
;!Critical Paths under _main in BANK1
;!
;!    _main->_lcd_show_zone
;!
;!Critical Paths under _main in BANK3
;!
;!    None.
;!
;!Critical Paths under _main in BANK2
;!
;!    None.

;;
;;Main: autosize = 0, tempsize = 3, incstack = 0, save=0
;;

;!
;!Call Graph Tables:
;!
;! ---------------------------------------------------------------------------------
;! (Depth) Function   	        Calls       Base Space   Used Autos Params    Refs
;! ---------------------------------------------------------------------------------
;! (0) _main                                                 4     4      0   29695
;!                                             58 BANK0      4     4      0
;!                            ___awmod
;!                        _keypad_init
;!                        _keypad_scan
;!                          _lcd_clear
;!                           _lcd_init
;!                    _lcd_send_string
;!                     _lcd_set_cursor
;!                      _lcd_show_zone
;!                   _process_keypress
;!                _send_uart_all_zones
;!                          _uart_init
;!                    _update_all_leds
;!                         _zones_init
;! ---------------------------------------------------------------------------------
;! (1) _zones_init                                           2     2      0    1122
;!                                              4 COMMON     2     2      0
;!                             ___bmul
;! ---------------------------------------------------------------------------------
;! (1) _uart_init                                            0     0      0       0
;! ---------------------------------------------------------------------------------
;! (1) _send_uart_all_zones                                  3     3      0    2852
;!                                             36 BANK0      3     3      0
;!                             ___bmul
;!                           ___xxtofl
;!                   _uart_send_packet
;! ---------------------------------------------------------------------------------
;! (2) _uart_send_packet                                    32    27      5    1225
;!                                             12 COMMON     2     2      0
;!                                              6 BANK0     30    25      5
;!                             ___bmul (ARG)
;!                           ___xxtofl (ARG)
;!                     _uart_send_byte
;! ---------------------------------------------------------------------------------
;! (3) _uart_send_byte                                       1     1      0      22
;!                                              0 COMMON     1     1      0
;! ---------------------------------------------------------------------------------
;! (2) ___xxtofl                                            14    10      4     474
;!                                              4 COMMON     8     4      4
;!                                              0 BANK0      6     6      0
;!                             ___bmul (ARG)
;! ---------------------------------------------------------------------------------
;! (1) _process_keypress                                     4     4      0    3456
;!                                              7 COMMON     4     4      0
;!                            ___awmod
;!                             ___bmul
;!                    _update_all_leds
;!                   _update_zone_mode
;! ---------------------------------------------------------------------------------
;! (2) _update_zone_mode                                     3     3      0    1116
;!                                              4 COMMON     3     3      0
;!                             ___bmul
;! ---------------------------------------------------------------------------------
;! (1) _update_all_leds                                      0     0      0       0
;! ---------------------------------------------------------------------------------
;! (1) _lcd_show_zone                                       37    37      0   19129
;!                                             56 BANK0      2     2      0
;!                                              0 BANK1     35    35      0
;!                             ___bmul
;!                    _lcd_send_string
;!                     _lcd_set_cursor
;!                            _sprintf
;! ---------------------------------------------------------------------------------
;! (2) _sprintf                                             23    16      7   17119
;!                                             35 BANK0     21    14      7
;!                             ___bmul (ARG)
;!                           _vfprintf
;! ---------------------------------------------------------------------------------
;! (3) _vfprintf                                             4     2      2   16543
;!                                             31 BANK0      4     2      2
;!                          _vfpfcnvrt
;! ---------------------------------------------------------------------------------
;! (4) _vfpfcnvrt                                           12    10      2   16094
;!                                             19 BANK0     12    10      2
;!                               _ctoa
;!                               _dtoa
;!                              _fputc
;!                 _read_prec_or_width
;!                               _utoa
;! ---------------------------------------------------------------------------------
;! (5) _utoa                                                 8     6      2    4101
;!                                              8 BANK0      8     6      2
;!                            ___lwdiv
;!                            ___lwmod
;!                                _pad
;! ---------------------------------------------------------------------------------
;! (6) ___lwmod                                              6     2      4     311
;!                                              0 COMMON     6     2      4
;! ---------------------------------------------------------------------------------
;! (6) ___lwdiv                                              8     4      4     314
;!                                              0 COMMON     8     4      4
;! ---------------------------------------------------------------------------------
;! (5) _read_prec_or_width                                   7     5      2    2833
;!                                              6 COMMON     7     5      2
;!                             ___wmul
;! ---------------------------------------------------------------------------------
;! (6) ___wmul                                               6     2      4    2544
;!                                              0 COMMON     6     2      4
;! ---------------------------------------------------------------------------------
;! (5) _dtoa                                                11     9      2    5399
;!                                              8 BANK0     11     9      2
;!                            ___awdiv
;!                            ___awmod
;!                                _abs
;!                                _pad
;! ---------------------------------------------------------------------------------
;! (6) _pad                                                  7     4      3    3140
;!                                             11 COMMON     3     0      3
;!                                              4 BANK0      4     4      0
;!                              _fputc
;!                              _fputs
;! ---------------------------------------------------------------------------------
;! (7) _fputs                                                7     6      1    1453
;!                                              8 COMMON     3     2      1
;!                                              0 BANK0      4     4      0
;!                              _fputc
;! ---------------------------------------------------------------------------------
;! (6) _abs                                                  4     2      2     142
;!                                              7 COMMON     4     2      2
;!                            ___awmod (ARG)
;! ---------------------------------------------------------------------------------
;! (2) ___awmod                                              7     3      4     973
;!                                              0 COMMON     7     3      4
;! ---------------------------------------------------------------------------------
;! (6) ___awdiv                                              9     5      4     452
;!                                              0 COMMON     9     5      4
;! ---------------------------------------------------------------------------------
;! (5) _ctoa                                                 8     7      1    1428
;!                                              8 COMMON     3     2      1
;!                                              0 BANK0      5     5      0
;!                              _fputc
;! ---------------------------------------------------------------------------------
;! (8) _fputc                                                8     5      3    1138
;!                                              0 COMMON     8     5      3
;!                              _putch
;! ---------------------------------------------------------------------------------
;! (9) _putch                                                1     1      0       0
;! ---------------------------------------------------------------------------------
;! (2) _lcd_set_cursor                                       4     3      1     394
;!                                              3 COMMON     4     3      1
;!                       _lcd_send_cmd
;! ---------------------------------------------------------------------------------
;! (2) _lcd_send_string                                      2     0      2     371
;!                                              3 COMMON     2     0      2
;!                      _lcd_send_char
;! ---------------------------------------------------------------------------------
;! (3) _lcd_send_char                                        3     3      0      22
;!                                              0 COMMON     3     3      0
;! ---------------------------------------------------------------------------------
;! (1) _lcd_init                                             2     2      0      22
;!                                              3 COMMON     2     2      0
;!                       _lcd_send_cmd
;! ---------------------------------------------------------------------------------
;! (1) _lcd_clear                                            2     2      0      22
;!                                              3 COMMON     2     2      0
;!                       _lcd_send_cmd
;! ---------------------------------------------------------------------------------
;! (3) _lcd_send_cmd                                         3     3      0      22
;!                                              0 COMMON     3     3      0
;! ---------------------------------------------------------------------------------
;! (1) _keypad_scan                                          8     8      0    1289
;!                                              4 COMMON     8     8      0
;!                             ___bmul
;! ---------------------------------------------------------------------------------
;! (2) ___bmul                                               4     3      1     961
;!                                              0 COMMON     4     3      1
;! ---------------------------------------------------------------------------------
;! (1) _keypad_init                                          1     1      0       0
;!                                              0 COMMON     1     1      0
;! ---------------------------------------------------------------------------------
;! Estimated maximum stack depth 9
;! ---------------------------------------------------------------------------------
;!
;! Call Graph Graphs:
;!
;! _main (ROOT)
;!   ___awmod
;!   _keypad_init
;!   _keypad_scan
;!     ___bmul
;!   _lcd_clear
;!     _lcd_send_cmd
;!   _lcd_init
;!     _lcd_send_cmd
;!   _lcd_send_string
;!     _lcd_send_char
;!   _lcd_set_cursor
;!     _lcd_send_cmd
;!   _lcd_show_zone
;!     ___bmul
;!     _lcd_send_string
;!     _lcd_set_cursor
;!     _sprintf
;!       ___bmul (ARG)
;!       _vfprintf (ARG)
;!         _vfpfcnvrt
;!           _ctoa
;!             _fputc
;!               _putch
;!           _dtoa
;!             ___awdiv
;!             ___awmod
;!             _abs
;!               ___awmod (ARG)
;!             _pad
;!               _fputc
;!               _fputs
;!                 _fputc
;!           _fputc
;!           _read_prec_or_width
;!             ___wmul
;!           _utoa
;!             ___lwdiv
;!             ___lwmod
;!             _pad
;!   _process_keypress
;!     ___awmod
;!     ___bmul
;!     _update_all_leds
;!     _update_zone_mode
;!       ___bmul
;!   _send_uart_all_zones
;!     ___bmul
;!     ___xxtofl
;!       ___bmul (ARG)
;!     _uart_send_packet
;!       ___bmul (ARG)
;!       ___xxtofl (ARG)
;!       _uart_send_byte (ARG)
;!   _uart_init
;!   _update_all_leds
;!   _zones_init
;!     ___bmul
;!

;! Address spaces:

;!Name               Size   Autos  Total    Cost      Usage
;!BANK3               60      0      20       9       33.3%
;!BITBANK3            60      0       0       8        0.0%
;!SFR3                 0      0       0       4        0.0%
;!BITSFR3              0      0       0       4        0.0%
;!BANK2               60      0       0      11        0.0%
;!BITBANK2            60      0       0      10        0.0%
;!SFR2                 0      0       0       5        0.0%
;!BITSFR2              0      0       0       5        0.0%
;!BANK1               50     23      39       7       71.2%
;!BITBANK1            50      0       0       6        0.0%
;!SFR1                 0      0       0       2        0.0%
;!BITSFR1              0      0       0       2        0.0%
;!BANK0               50     3E      4B       5       93.8%
;!BITBANK0            50      0       0       4        0.0%
;!SFR0                 0      0       0       1        0.0%
;!BITSFR0              0      0       0       1        0.0%
;!COMMON               E      E       E       1      100.0%
;!BITCOMMON            E      0       0       0        0.0%
;!CODE                 0      0       0       0        0.0%
;!DATA                 0      0      B2      12        0.0%
;!ABS                  0      0      B2       3        0.0%
;!NULL                 0      0       0       0        0.0%
;!STACK                0      0       0       2        0.0%
;!EEDATA             100      0       0       0        0.0%

	global	_main

;; *************** function _main *****************
;; Defined at:
;;		line 93 in file "main.c"
;; Parameters:    Size  Location     Type
;;		None
;; Auto vars:     Size  Location     Type
;;  key             1   61[BANK0 ] unsigned char 
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, btemp+1, pclath, cstack
;; Tracked objects:
;;		On entry : B00/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       0       0       0       0
;;      Locals:         0       1       0       0       0
;;      Temps:          0       3       0       0       0
;;      Totals:         0       4       0       0       0
;;Total ram usage:        4 bytes
;; Hardware stack levels required when called: 9
;; This function calls:
;;		___awmod
;;		_keypad_init
;;		_keypad_scan
;;		_lcd_clear
;;		_lcd_init
;;		_lcd_send_string
;;		_lcd_set_cursor
;;		_lcd_show_zone
;;		_process_keypress
;;		_send_uart_all_zones
;;		_uart_init
;;		_update_all_leds
;;		_zones_init
;; This function is called by:
;;		Startup code after reset
;; This function uses a non-reentrant model
;;
psect	maintext,global,class=CODE,delta=2,split=1,group=0
	file	"main.c"
	line	93
global __pmaintext
__pmaintext:	;psect for function _main
psect	maintext
	file	"main.c"
	line	93
	
_main:	
;incstack = 0
;; hardware stack exceeded
	callstack 0
; Regs used in _main: [wreg-fsr0h+status,2+status,0+btemp+1+pclath+cstack]
	line	95
	
l2747:	
	bsf	status, 5	;RP0=1, select bank1
	bcf	status, 6	;RP1=0, select bank1
	clrf	(133)^080h	;volatile
	line	96
	
l2749:	
	movlw	low(07h)
	movwf	(134)^080h	;volatile
	line	97
	
l2751:	
	movlw	low(0C0h)
	movwf	(135)^080h	;volatile
	line	98
	clrf	(136)^080h	;volatile
	line	99
	clrf	(137)^080h	;volatile
	line	102
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	clrf	(5)	;volatile
	line	103
	
l2753:	
	movlw	low(07h)
	movwf	(6)	;volatile
	line	104
	
l2755:	
	clrf	(7)	;volatile
	line	105
	movlw	low(0Fh)
	movwf	(8)	;volatile
	line	106
	
l2757:	
	clrf	(9)	;volatile
	line	110
	
l2759:	
	movlw	low(06h)
	bsf	status, 5	;RP0=1, select bank1
	bcf	status, 6	;RP1=0, select bank1
	movwf	(159)^080h	;volatile
	line	114
	
l2761:	
	bcf	(129)^080h,7	;volatile
	line	117
	
l2763:	
	fcall	_zones_init
	line	118
	
l2765:	
	fcall	_lcd_init
	line	119
	
l2767:	
	fcall	_uart_init
	line	120
	
l2769:	
	fcall	_keypad_init
	line	123
	
l2771:	
	clrf	(lcd_set_cursor@col)
	movlw	low(0)
	fcall	_lcd_set_cursor
	line	124
	
l2773:	
	movlw	(low((((STR_9)-__stringbase)|8000h)))&0ffh
	movwf	(lcd_send_string@str)
	movlw	80h
	movwf	(lcd_send_string@str+1)
	fcall	_lcd_send_string
	line	125
	
l2775:	
	clrf	(lcd_set_cursor@col)
	movlw	low(01h)
	fcall	_lcd_set_cursor
	line	126
	
l2777:	
	movlw	(low((((STR_10)-__stringbase)|8000h)))&0ffh
	movwf	(lcd_send_string@str)
	movlw	80h
	movwf	(lcd_send_string@str+1)
	fcall	_lcd_send_string
	line	127
	
l2779:	
	asmopt push
asmopt off
movlw  21
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
movwf	((??_main+0)+0+2)
movlw	75
movwf	((??_main+0)+0+1)
	movlw	189
movwf	((??_main+0)+0)
	u3197:
decfsz	((??_main+0)+0),f
	goto	u3197
	decfsz	((??_main+0)+0+1),f
	goto	u3197
	decfsz	((??_main+0)+0+2),f
	goto	u3197
	nop2
asmopt pop

	line	128
	
l2781:	
	fcall	_lcd_clear
	line	131
	
l2783:	
	fcall	_update_all_leds
	line	132
	
l2785:	
	movlw	low(0)
	fcall	_lcd_show_zone
	line	138
	
l2787:	
	fcall	_keypad_scan
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(main@key)
	line	139
	
l2789:	
		incf	((main@key)),w
	btfsc	status,2
	goto	u3161
	goto	u3160
u3161:
	goto	l2793
u3160:
	line	140
	
l2791:	
	movf	(main@key),w
	fcall	_process_keypress
	line	141
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movf	(_current_zone),w
	fcall	_lcd_show_zone
	line	145
	
l2793:	
	movlw	01h
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	addwf	(_disp_counter),f
	skipnc
	incf	(_disp_counter+1),f
	movlw	0
	addwf	(_disp_counter+1),f
	line	146
	
l2795:	
	movlw	07h
	subwf	(_disp_counter+1),w
	movlw	0D0h
	skipnz
	subwf	(_disp_counter),w
	skipc
	goto	u3171
	goto	u3170
u3171:
	goto	l2803
u3170:
	line	147
	
l2797:	
	clrf	(_disp_counter)
	clrf	(_disp_counter+1)
	line	148
	
l2799:	
	movlw	03h
	movwf	(___awmod@divisor)
	movlw	0
	movwf	((___awmod@divisor))+1
	movf	(_current_zone),w
	addlw	low(01h)
	movwf	(___awmod@dividend)
	movlw	high(01h)
	skipnc
	movlw	(high(01h)+1)&0ffh
	movwf	((___awmod@dividend))+1
	fcall	___awmod
	movf	(0+(?___awmod)),w
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(_current_zone)
	line	149
	
l2801:	
	movf	(_current_zone),w
	fcall	_lcd_show_zone
	line	153
	
l2803:	
	movlw	01h
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	addwf	(_uart_counter),f
	skipnc
	incf	(_uart_counter+1),f
	movlw	0
	addwf	(_uart_counter+1),f
	line	154
	
l2805:	
	movlw	013h
	subwf	(_uart_counter+1),w
	movlw	088h
	skipnz
	subwf	(_uart_counter),w
	skipc
	goto	u3181
	goto	u3180
u3181:
	goto	l2811
u3180:
	line	155
	
l2807:	
	clrf	(_uart_counter)
	clrf	(_uart_counter+1)
	line	156
	
l2809:	
	fcall	_send_uart_all_zones
	line	159
	
l2811:	
	asmopt push
asmopt off
movlw	3
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
movwf	((??_main+0)+0+1)
	movlw	151
movwf	((??_main+0)+0)
	u3207:
decfsz	((??_main+0)+0),f
	goto	u3207
	decfsz	((??_main+0)+0+1),f
	goto	u3207
asmopt pop

	goto	l2787
	global	start
	ljmp	start
	callstack 0
	line	161
GLOBAL	__end_of_main
	__end_of_main:
	signat	_main,89
	global	_zones_init

;; *************** function _zones_init *****************
;; Defined at:
;;		line 18 in file "zones.c"
;; Parameters:    Size  Location     Type
;;		None
;; Auto vars:     Size  Location     Type
;;  z               1    5[COMMON] unsigned char 
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       0       0       0       0
;;      Locals:         1       0       0       0       0
;;      Temps:          1       0       0       0       0
;;      Totals:         2       0       0       0       0
;;Total ram usage:        2 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 1
;; This function calls:
;;		___bmul
;; This function is called by:
;;		_main
;; This function uses a non-reentrant model
;;
psect	text1,local,class=CODE,delta=2,merge=1,group=0
	file	"zones.c"
	line	18
global __ptext1
__ptext1:	;psect for function _zones_init
psect	text1
	file	"zones.c"
	line	18
	
_zones_init:	
;incstack = 0
	callstack 6
; Regs used in _zones_init: [wreg-fsr0h+status,2+status,0+pclath+cstack]
	line	20
	
l2661:	
	clrf	(zones_init@z)
	line	21
	
l2667:	
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	movf	(zones_init@z),w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8))&0ffh
	movwf	fsr0
	movlw	016h
	bcf	status, 7	;select IRP bank1
	movwf	indf
	incf	fsr0,f
	movlw	0
	movwf	indf
	line	22
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	movf	(zones_init@z),w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8)+02h)&0ffh
	movwf	fsr0
	bcf	status, 7	;select IRP bank1
	clrf	indf
	incf	fsr0,f
	clrf	indf
	line	23
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	movf	(zones_init@z),w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8)+04h)&0ffh
	movwf	fsr0
	movlw	low(053h)
	bcf	status, 7	;select IRP bank1
	movwf	indf
	line	24
	
l2669:	
	movlw	low(01h)
	movwf	(??_zones_init+0)+0
	movf	(??_zones_init+0)+0,w
	addwf	(zones_init@z),f
	
l2671:	
	movlw	low(03h)
	subwf	(zones_init@z),w
	skipc
	goto	u3011
	goto	u3010
u3011:
	goto	l2667
u3010:
	line	25
	
l206:	
	return
	callstack 0
GLOBAL	__end_of_zones_init
	__end_of_zones_init:
	signat	_zones_init,89
	global	_uart_init

;; *************** function _uart_init *****************
;; Defined at:
;;		line 19 in file "uart.c"
;; Parameters:    Size  Location     Type
;;		None
;; Auto vars:     Size  Location     Type
;;		None
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       0       0       0       0
;;      Locals:         0       0       0       0       0
;;      Temps:          0       0       0       0       0
;;      Totals:         0       0       0       0       0
;;Total ram usage:        0 bytes
;; Hardware stack levels used: 1
;; This function calls:
;;		Nothing
;; This function is called by:
;;		_main
;; This function uses a non-reentrant model
;;
psect	text2,local,class=CODE,delta=2,merge=1,group=0
	file	"uart.c"
	line	19
global __ptext2
__ptext2:	;psect for function _uart_init
psect	text2
	file	"uart.c"
	line	19
	
_uart_init:	
;incstack = 0
	callstack 7
; Regs used in _uart_init: [wreg]
	line	20
	
l2287:	
	bsf	status, 5	;RP0=1, select bank1
	bcf	status, 6	;RP1=0, select bank1
	bcf	(1086/8)^080h,(1086)&7	;volatile
	line	21
	bsf	(1087/8)^080h,(1087)&7	;volatile
	line	22
	
l2289:	
	movlw	low(033h)
	movwf	(153)^080h	;volatile
	line	23
	movlw	low(024h)
	movwf	(152)^080h	;volatile
	line	24
	movlw	low(090h)
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(24)	;volatile
	line	25
	
l167:	
	return
	callstack 0
GLOBAL	__end_of_uart_init
	__end_of_uart_init:
	signat	_uart_init,89
	global	_send_uart_all_zones

;; *************** function _send_uart_all_zones *****************
;; Defined at:
;;		line 79 in file "main.c"
;; Parameters:    Size  Location     Type
;;		None
;; Auto vars:     Size  Location     Type
;;  z               1   38[BANK0 ] unsigned char 
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       0       0       0       0
;;      Locals:         0       1       0       0       0
;;      Temps:          0       2       0       0       0
;;      Totals:         0       3       0       0       0
;;Total ram usage:        3 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 2
;; This function calls:
;;		___bmul
;;		___xxtofl
;;		_uart_send_packet
;; This function is called by:
;;		_main
;; This function uses a non-reentrant model
;;
psect	text3,local,class=CODE,delta=2,merge=1,group=0
	file	"main.c"
	line	79
global __ptext3
__ptext3:	;psect for function _send_uart_all_zones
psect	text3
	file	"main.c"
	line	79
	
_send_uart_all_zones:	
;incstack = 0
	callstack 5
; Regs used in _send_uart_all_zones: [wreg-fsr0h+status,2+status,0+pclath+cstack]
	line	81
	
l2643:	
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	clrf	(send_uart_all_zones@z)
	line	82
	
l2649:	
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	movf	(send_uart_all_zones@z),w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8))&0ffh
	movwf	fsr0
	bcf	status, 7	;select IRP bank1
	movf	indf,w
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(??_send_uart_all_zones+0)+0+0
	incf	fsr0,f
	movf	indf,w
	movwf	(??_send_uart_all_zones+0)+0+1
	movf	0+(??_send_uart_all_zones+0)+0,w
	movwf	(___xxtofl@val)
	movf	1+(??_send_uart_all_zones+0)+0,w
	movwf	(___xxtofl@val+1)
	movlw	0
	btfsc	(___xxtofl@val+1),7
	movlw	255
	movwf	(___xxtofl@val+2)
	movwf	(___xxtofl@val+3)
	movlw	low(01h)
	fcall	___xxtofl
	movf	(3+(?___xxtofl)),w
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(uart_send_packet@value+3)
	movf	(2+(?___xxtofl)),w
	movwf	(uart_send_packet@value+2)
	movf	(1+(?___xxtofl)),w
	movwf	(uart_send_packet@value+1)
	movf	(0+(?___xxtofl)),w
	movwf	(uart_send_packet@value)

	clrf	(uart_send_packet@type)
	movf	(send_uart_all_zones@z),w
	addlw	low(_temp_ids|((0x0)<<8))&0ffh
	movwf	fsr0
	bcf	status, 7	;select IRP bank0
	movf	indf,w
	fcall	_uart_send_packet
	line	84
	
l2651:	
	asmopt push
asmopt off
movlw	26
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
movwf	((??_send_uart_all_zones+0)+0+1)
	movlw	247
movwf	((??_send_uart_all_zones+0)+0)
	u3217:
decfsz	((??_send_uart_all_zones+0)+0),f
	goto	u3217
	decfsz	((??_send_uart_all_zones+0)+0+1),f
	goto	u3217
	nop2
asmopt pop

	line	85
	
l2653:	
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movf	(send_uart_all_zones@z),w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8)+02h)&0ffh
	movwf	fsr0
	bcf	status, 7	;select IRP bank1
	movf	indf,w
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(??_send_uart_all_zones+0)+0+0
	incf	fsr0,f
	movf	indf,w
	movwf	(??_send_uart_all_zones+0)+0+1
	movf	0+(??_send_uart_all_zones+0)+0,w
	movwf	(___xxtofl@val)
	movf	1+(??_send_uart_all_zones+0)+0,w
	movwf	(___xxtofl@val+1)
	movlw	0
	btfsc	(___xxtofl@val+1),7
	movlw	255
	movwf	(___xxtofl@val+2)
	movwf	(___xxtofl@val+3)
	movlw	low(01h)
	fcall	___xxtofl
	movf	(3+(?___xxtofl)),w
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(uart_send_packet@value+3)
	movf	(2+(?___xxtofl)),w
	movwf	(uart_send_packet@value+2)
	movf	(1+(?___xxtofl)),w
	movwf	(uart_send_packet@value+1)
	movf	(0+(?___xxtofl)),w
	movwf	(uart_send_packet@value)

	movlw	low(03h)
	movwf	(uart_send_packet@type)
	movf	(send_uart_all_zones@z),w
	addlw	low(_occ_ids|((0x0)<<8))&0ffh
	movwf	fsr0
	bcf	status, 7	;select IRP bank1
	movf	indf,w
	fcall	_uart_send_packet
	line	87
	asmopt push
asmopt off
movlw	26
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
movwf	((??_send_uart_all_zones+0)+0+1)
	movlw	247
movwf	((??_send_uart_all_zones+0)+0)
	u3227:
decfsz	((??_send_uart_all_zones+0)+0),f
	goto	u3227
	decfsz	((??_send_uart_all_zones+0)+0+1),f
	goto	u3227
	nop2
asmopt pop

	line	88
	
l2655:	
	movlw	low(01h)
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(??_send_uart_all_zones+0)+0
	movf	(??_send_uart_all_zones+0)+0,w
	addwf	(send_uart_all_zones@z),f
	
l2657:	
	movlw	low(03h)
	subwf	(send_uart_all_zones@z),w
	skipc
	goto	u3001
	goto	u3000
u3001:
	goto	l2649
u3000:
	line	90
	
l2659:	
	movlw	low(0Fh)
	movwf	(??_send_uart_all_zones+0)+0
	movf	(??_send_uart_all_zones+0)+0,w
	iorwf	(8),f	;volatile
	line	91
	
l70:	
	return
	callstack 0
GLOBAL	__end_of_send_uart_all_zones
	__end_of_send_uart_all_zones:
	signat	_send_uart_all_zones,89
	global	_uart_send_packet

;; *************** function _uart_send_packet *****************
;; Defined at:
;;		line 37 in file "uart.c"
;; Parameters:    Size  Location     Type
;;  device_id       1    wreg     PTR const unsigned char 
;;		 -> STR_6(6), STR_5(6), STR_4(6), STR_3(7), 
;;		 -> STR_2(7), STR_1(7), 
;;  value           4    6[BANK0 ] float 
;;  type            1   10[BANK0 ] unsigned char 
;; Auto vars:     Size  Location     Type
;;  device_id       1   33[BANK0 ] PTR const unsigned char 
;;		 -> STR_6(6), STR_5(6), STR_4(6), STR_3(7), 
;;		 -> STR_2(7), STR_1(7), 
;;  pkt            20   11[BANK0 ] unsigned char [20]
;;  checksum        2   31[BANK0 ] unsigned int 
;;  i               1   35[BANK0 ] unsigned char 
;;  fp              1   34[BANK0 ] PTR unsigned char 
;;		 -> uart_send_packet@value(4), 
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       5       0       0       0
;;      Locals:         0      25       0       0       0
;;      Temps:          2       0       0       0       0
;;      Totals:         2      30       0       0       0
;;Total ram usage:       32 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 1
;; This function calls:
;;		_uart_send_byte
;; This function is called by:
;;		_send_uart_all_zones
;; This function uses a non-reentrant model
;;
psect	text4,local,class=CODE,delta=2,merge=1,group=0
	file	"uart.c"
	line	37
global __ptext4
__ptext4:	;psect for function _uart_send_packet
psect	text4
	file	"uart.c"
	line	37
	
_uart_send_packet:	
;incstack = 0
	callstack 5
; Regs used in _uart_send_packet: [wreg-fsr0h+status,2+status,0+pclath+cstack]
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(uart_send_packet@device_id)
	line	42
	
l2111:	
	clrf	(uart_send_packet@checksum)
	clrf	(uart_send_packet@checksum+1)
	line	45
	clrf	(uart_send_packet@i)
	
l2117:	
	movf	(uart_send_packet@i),w
	addlw	low(uart_send_packet@pkt|((0x0)<<8))&0ffh
	movwf	fsr0
	bcf	status, 7	;select IRP bank0
	clrf	indf
	
l2119:	
	movlw	low(01h)
	movwf	(??_uart_send_packet+0)+0
	movf	(??_uart_send_packet+0)+0,w
	addwf	(uart_send_packet@i),f
	
l2121:	
	movlw	low(014h)
	subwf	(uart_send_packet@i),w
	skipc
	goto	u2071
	goto	u2070
u2071:
	goto	l2117
u2070:
	line	48
	
l2123:	
	clrf	(uart_send_packet@i)
	goto	l2129
	line	49
	
l2125:	
	movf	(uart_send_packet@i),w
	addwf	(uart_send_packet@device_id),w
	movwf	fsr0
	fcall	stringdir
	movwf	(??_uart_send_packet+0)+0
	movf	(uart_send_packet@i),w
	addlw	low(uart_send_packet@pkt|((0x0)<<8))&0ffh
	movwf	fsr0
	movf	(??_uart_send_packet+0)+0,w
	movwf	indf
	
l2127:	
	movlw	low(01h)
	movwf	(??_uart_send_packet+0)+0
	movf	(??_uart_send_packet+0)+0,w
	addwf	(uart_send_packet@i),f
	
l2129:	
	movlw	low(07h)
	subwf	(uart_send_packet@i),w
	skipnc
	goto	u2081
	goto	u2080
u2081:
	goto	l2133
u2080:
	
l2131:	
	movf	(uart_send_packet@i),w
	addwf	(uart_send_packet@device_id),w
	movwf	fsr0
	fcall	stringdir
	xorlw	0
	skipz
	goto	u2091
	goto	u2090
u2091:
	goto	l2125
u2090:
	line	52
	
l2133:	
	clrf	0+(uart_send_packet@pkt)+0Bh
	clrf	0+(uart_send_packet@pkt)+0Ah
	clrf	0+(uart_send_packet@pkt)+09h
	clrf	0+(uart_send_packet@pkt)+08h
	line	55
	
l2135:	
	movlw	(low(uart_send_packet@value|((0x0)<<8)))&0ffh
	movwf	(uart_send_packet@fp)
	line	56
	
l2137:	
	movf	(uart_send_packet@fp),w
	movwf	fsr0
	movf	indf,w
	movwf	0+(uart_send_packet@pkt)+0Ch
	line	57
	
l2139:	
	incf	(uart_send_packet@fp),w
	movwf	fsr0
	movf	indf,w
	movwf	0+(uart_send_packet@pkt)+0Dh
	line	58
	
l2141:	
	movf	(uart_send_packet@fp),w
	addlw	02h
	movwf	fsr0
	movf	indf,w
	movwf	0+(uart_send_packet@pkt)+0Eh
	line	59
	
l2143:	
	movf	(uart_send_packet@fp),w
	addlw	03h
	movwf	fsr0
	movf	indf,w
	movwf	0+(uart_send_packet@pkt)+0Fh
	line	62
	
l2145:	
	movf	(uart_send_packet@type),w
	movwf	0+(uart_send_packet@pkt)+010h
	line	65
	clrf	(uart_send_packet@i)
	
l2151:	
	movf	(uart_send_packet@i),w
	addlw	low(uart_send_packet@pkt|((0x0)<<8))&0ffh
	movwf	fsr0
	movf	indf,w
	movwf	(??_uart_send_packet+0)+0
	clrf	(??_uart_send_packet+0)+0+1
	movf	0+(??_uart_send_packet+0)+0,w
	addwf	(uart_send_packet@checksum),f
	skipnc
	incf	(uart_send_packet@checksum+1),f
	movf	1+(??_uart_send_packet+0)+0,w
	addwf	(uart_send_packet@checksum+1),f
	
l2153:	
	movlw	low(01h)
	movwf	(??_uart_send_packet+0)+0
	movf	(??_uart_send_packet+0)+0,w
	addwf	(uart_send_packet@i),f
	
l2155:	
	movlw	low(011h)
	subwf	(uart_send_packet@i),w
	skipc
	goto	u2101
	goto	u2100
u2101:
	goto	l2151
u2100:
	line	66
	
l2157:	
	movf	(uart_send_packet@checksum),w
	movwf	0+(uart_send_packet@pkt)+011h
	line	71
	
l2159:	
	clrf	(uart_send_packet@i)
	
l2165:	
	movf	(uart_send_packet@i),w
	addlw	low(uart_send_packet@pkt|((0x0)<<8))&0ffh
	movwf	fsr0
	bcf	status, 7	;select IRP bank0
	movf	indf,w
	fcall	_uart_send_byte
	
l2167:	
	movlw	low(01h)
	movwf	(??_uart_send_packet+0)+0
	movf	(??_uart_send_packet+0)+0,w
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	addwf	(uart_send_packet@i),f
	
l2169:	
	movlw	low(014h)
	subwf	(uart_send_packet@i),w
	skipc
	goto	u2111
	goto	u2110
u2111:
	goto	l2165
u2110:
	line	72
	
l187:	
	return
	callstack 0
GLOBAL	__end_of_uart_send_packet
	__end_of_uart_send_packet:
	signat	_uart_send_packet,12409
	global	_uart_send_byte

;; *************** function _uart_send_byte *****************
;; Defined at:
;;		line 28 in file "uart.c"
;; Parameters:    Size  Location     Type
;;  byte            1    wreg     unsigned char 
;; Auto vars:     Size  Location     Type
;;  byte            1    0[COMMON] unsigned char 
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       0       0       0       0
;;      Locals:         1       0       0       0       0
;;      Temps:          0       0       0       0       0
;;      Totals:         1       0       0       0       0
;;Total ram usage:        1 bytes
;; Hardware stack levels used: 1
;; This function calls:
;;		Nothing
;; This function is called by:
;;		_uart_send_packet
;; This function uses a non-reentrant model
;;
psect	text5,local,class=CODE,delta=2,merge=1,group=0
	line	28
global __ptext5
__ptext5:	;psect for function _uart_send_byte
psect	text5
	file	"uart.c"
	line	28
	
_uart_send_byte:	
;incstack = 0
	callstack 5
; Regs used in _uart_send_byte: [wreg]
	movwf	(uart_send_byte@byte)
	line	29
	
l2055:	
	
l170:	
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	btfss	(100/8),(100)&7	;volatile
	goto	u2011
	goto	u2010
u2011:
	goto	l170
u2010:
	line	30
	
l2057:	
	movf	(uart_send_byte@byte),w
	movwf	(25)	;volatile
	line	31
	
l173:	
	return
	callstack 0
GLOBAL	__end_of_uart_send_byte
	__end_of_uart_send_byte:
	signat	_uart_send_byte,4217
	global	___xxtofl

;; *************** function ___xxtofl *****************
;; Defined at:
;;		line 10 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/xxtofl.c"
;; Parameters:    Size  Location     Type
;;  sign            1    wreg     unsigned char 
;;  val             4    4[COMMON] long 
;; Auto vars:     Size  Location     Type
;;  sign            1    0[BANK0 ] unsigned char 
;;  arg             4    2[BANK0 ] unsigned long 
;;  exp             1    1[BANK0 ] unsigned char 
;; Return value:  Size  Location     Type
;;                  4    4[COMMON] unsigned char 
;; Registers used:
;;		wreg, status,2, status,0
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         4       0       0       0       0
;;      Locals:         0       6       0       0       0
;;      Temps:          4       0       0       0       0
;;      Totals:         8       6       0       0       0
;;Total ram usage:       14 bytes
;; Hardware stack levels used: 1
;; This function calls:
;;		Nothing
;; This function is called by:
;;		_send_uart_all_zones
;; This function uses a non-reentrant model
;;
psect	text6,local,class=CODE,delta=2,merge=1,group=2
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/xxtofl.c"
	line	10
global __ptext6
__ptext6:	;psect for function ___xxtofl
psect	text6
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/xxtofl.c"
	line	10
	
___xxtofl:	
;incstack = 0
	callstack 6
; Regs used in ___xxtofl: [wreg+status,2+status,0]
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(___xxtofl@sign)
	line	15
	
l2183:	
	movf	((___xxtofl@sign)),w
	btfsc	status,2
	goto	u2261
	goto	u2260
u2261:
	goto	l2189
u2260:
	
l2185:	
	btfss	(___xxtofl@val+3),7
	goto	u2271
	goto	u2270
u2271:
	goto	l2189
u2270:
	line	16
	
l2187:	
	comf	(___xxtofl@val)+0,w
	movwf	(___xxtofl@arg)
	comf	(___xxtofl@val)+1,w
	movwf	(___xxtofl@arg+1)
	comf	(___xxtofl@val)+2,w
	movwf	(___xxtofl@arg+2)
	comf	(___xxtofl@val)+3,w
	movwf	(___xxtofl@arg+3)
	incf	(___xxtofl@arg),f
	skipnz
	incf	(___xxtofl@arg+1),f
	skipnz
	incf	(___xxtofl@arg+2),f
	skipnz
	incf	(___xxtofl@arg+3),f
	line	17
	goto	l756
	line	19
	
l2189:	
	movf	(___xxtofl@val+3),w
	movwf	(___xxtofl@arg+3)
	movf	(___xxtofl@val+2),w
	movwf	(___xxtofl@arg+2)
	movf	(___xxtofl@val+1),w
	movwf	(___xxtofl@arg+1)
	movf	(___xxtofl@val),w
	movwf	(___xxtofl@arg)

	line	20
	
l756:	
	line	21
	movf	(___xxtofl@val+3),w
	iorwf	(___xxtofl@val+2),w
	iorwf	(___xxtofl@val+1),w
	iorwf	(___xxtofl@val),w
	skipz
	goto	u2281
	goto	u2280
u2281:
	goto	l2195
u2280:
	line	22
	
l2191:	
	movlw	0x0
	movwf	(?___xxtofl+3)
	movlw	0x0
	movwf	(?___xxtofl+2)
	movlw	0x0
	movwf	(?___xxtofl+1)
	movlw	0x0
	movwf	(?___xxtofl)

	goto	l758
	line	23
	
l2195:	
	movlw	low(096h)
	movwf	(___xxtofl@exp)
	line	24
	goto	l2199
	line	25
	
l2197:	
	movlw	low(01h)
	movwf	(??___xxtofl+0)+0
	movf	(??___xxtofl+0)+0,w
	addwf	(___xxtofl@exp),f
	line	26
	movlw	01h
u2295:
	clrc
	rrf	(___xxtofl@arg+3),f
	rrf	(___xxtofl@arg+2),f
	rrf	(___xxtofl@arg+1),f
	rrf	(___xxtofl@arg),f
	addlw	-1
	skipz
	goto	u2295

	line	24
	
l2199:	
	movlw	high highword(0FE000000h)
	andwf	(___xxtofl@arg+3),w
	btfss	status,2
	goto	u2301
	goto	u2300
u2301:
	goto	l2197
u2300:
	goto	l762
	line	29
	
l2201:	
	movlw	low(01h)
	movwf	(??___xxtofl+0)+0
	movf	(??___xxtofl+0)+0,w
	addwf	(___xxtofl@exp),f
	line	30
	
l2203:	
	movlw	01h
	addwf	(___xxtofl@arg),f
	movlw	0
	skipnc
movlw 1
	addwf	(___xxtofl@arg+1),f
	movlw	0
	skipnc
movlw 1
	addwf	(___xxtofl@arg+2),f
	movlw	0
	skipnc
movlw 1
	addwf	(___xxtofl@arg+3),f
	line	31
	
l2205:	
	movlw	01h
u2315:
	clrc
	rrf	(___xxtofl@arg+3),f
	rrf	(___xxtofl@arg+2),f
	rrf	(___xxtofl@arg+1),f
	rrf	(___xxtofl@arg),f
	addlw	-1
	skipz
	goto	u2315

	line	32
	
l762:	
	line	28
	movlw	high highword(0FF000000h)
	andwf	(___xxtofl@arg+3),w
	btfss	status,2
	goto	u2321
	goto	u2320
u2321:
	goto	l2201
u2320:
	goto	l2209
	line	34
	
l2207:	
	movlw	01h
	subwf	(___xxtofl@exp),f
	line	35
	movlw	01h
	movwf	(??___xxtofl+0)+0
u2335:
	clrc
	rlf	(___xxtofl@arg),f
	rlf	(___xxtofl@arg+1),f
	rlf	(___xxtofl@arg+2),f
	rlf	(___xxtofl@arg+3),f
	decfsz	(??___xxtofl+0)+0
	goto	u2335
	line	33
	
l2209:	
	btfsc	(___xxtofl@arg+2),(23)&7
	goto	u2341
	goto	u2340
u2341:
	goto	l769
u2340:
	
l2211:	
	movlw	low(02h)
	subwf	(___xxtofl@exp),w
	skipnc
	goto	u2351
	goto	u2350
u2351:
	goto	l2207
u2350:
	
l769:	
	line	37
	btfsc	(___xxtofl@exp),(0)&7
	goto	u2361
	goto	u2360
u2361:
	goto	l770
u2360:
	line	38
	
l2213:	
	movlw	0FFh
	andwf	(___xxtofl@arg),f
	movlw	0FFh
	andwf	(___xxtofl@arg+1),f
	movlw	07Fh
	andwf	(___xxtofl@arg+2),f
	movlw	0FFh
	andwf	(___xxtofl@arg+3),f
	
l770:	
	line	39
	clrc
	rrf	(___xxtofl@exp),f

	line	40
	
l2215:	
	movf	(___xxtofl@exp),w
	movwf	(??___xxtofl+0)+0
	clrf	(??___xxtofl+0)+0+1
	clrf	(??___xxtofl+0)+0+2
	clrf	(??___xxtofl+0)+0+3
	movlw	018h
u2375:
	clrc
	rlf	(??___xxtofl+0)+0,f
	rlf	(??___xxtofl+0)+1,f
	rlf	(??___xxtofl+0)+2,f
	rlf	(??___xxtofl+0)+3,f
u2370:
	addlw	-1
	skipz
	goto	u2375
	movf	0+(??___xxtofl+0)+0,w
	iorwf	(___xxtofl@arg),f
	movf	1+(??___xxtofl+0)+0,w
	iorwf	(___xxtofl@arg+1),f
	movf	2+(??___xxtofl+0)+0,w
	iorwf	(___xxtofl@arg+2),f
	movf	3+(??___xxtofl+0)+0,w
	iorwf	(___xxtofl@arg+3),f
	line	41
	
l2217:	
	movf	((___xxtofl@sign)),w
	btfsc	status,2
	goto	u2381
	goto	u2380
u2381:
	goto	l2223
u2380:
	
l2219:	
	btfss	(___xxtofl@val+3),7
	goto	u2391
	goto	u2390
u2391:
	goto	l2223
u2390:
	line	42
	
l2221:	
	bsf	(___xxtofl@arg)+(31/8),(31)&7
	line	43
	
l2223:	
	movf	(___xxtofl@arg+3),w
	movwf	(?___xxtofl+3)
	movf	(___xxtofl@arg+2),w
	movwf	(?___xxtofl+2)
	movf	(___xxtofl@arg+1),w
	movwf	(?___xxtofl+1)
	movf	(___xxtofl@arg),w
	movwf	(?___xxtofl)

	line	44
	
l758:	
	return
	callstack 0
GLOBAL	__end_of___xxtofl
	__end_of___xxtofl:
	signat	___xxtofl,8316
	global	_process_keypress

;; *************** function _process_keypress *****************
;; Defined at:
;;		line 62 in file "zones.c"
;; Parameters:    Size  Location     Type
;;  key             1    wreg     unsigned char 
;; Auto vars:     Size  Location     Type
;;  key             1    9[COMMON] unsigned char 
;;  zone            1   10[COMMON] unsigned char 
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, btemp+1, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       0       0       0       0
;;      Locals:         2       0       0       0       0
;;      Temps:          2       0       0       0       0
;;      Totals:         4       0       0       0       0
;;Total ram usage:        4 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 2
;; This function calls:
;;		___awmod
;;		___bmul
;;		_update_all_leds
;;		_update_zone_mode
;; This function is called by:
;;		_main
;; This function uses a non-reentrant model
;;
psect	text7,local,class=CODE,delta=2,merge=1,group=0
	file	"zones.c"
	line	62
global __ptext7
__ptext7:	;psect for function _process_keypress
psect	text7
	file	"zones.c"
	line	62
	
_process_keypress:	
;incstack = 0
	callstack 5
; Regs used in _process_keypress: [wreg-fsr0h+status,2+status,0+btemp+1+pclath+cstack]
	movwf	(process_keypress@key)
	line	63
	
l2721:	
	movlw	03h
	movwf	(___awmod@divisor)
	movlw	0
	movwf	((___awmod@divisor))+1
	movf	(process_keypress@key),w
	movwf	(??_process_keypress+0)+0
	clrf	(??_process_keypress+0)+0+1
	movf	0+(??_process_keypress+0)+0,w
	movwf	(___awmod@dividend)
	movf	1+(??_process_keypress+0)+0,w
	movwf	(___awmod@dividend+1)
	fcall	___awmod
	movf	(0+(?___awmod)),w
	movwf	(process_keypress@zone)
	line	65
	
l2723:	
	movlw	low(03h)
	subwf	(process_keypress@key),w
	skipnc
	goto	u3091
	goto	u3090
u3091:
	goto	l2729
u3090:
	line	66
	
l2725:	
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	movf	(process_keypress@zone),w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8))&0ffh
	movwf	fsr0
	bcf	status, 7	;select IRP bank1
	movf	indf,w
	movwf	(??_process_keypress+0)+0+0
	incf	fsr0,f
	movf	indf,w
	movwf	(??_process_keypress+0)+0+1
	movf	1+(??_process_keypress+0)+0,w
	xorlw	80h
	movwf	btemp+1
	movlw	(0)^80h
	subwf	btemp+1,w
	skipz
	goto	u3105
	movlw	023h
	subwf	0+(??_process_keypress+0)+0,w
u3105:

	skipnc
	goto	u3101
	goto	u3100
u3101:
	goto	l221
u3100:
	
l2727:	
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	movf	(process_keypress@zone),w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8))&0ffh
	movwf	fsr0
	movlw	01h
	bcf	status, 7	;select IRP bank1
	addwf	indf,f
	incf	fsr0,f
	skipnc
	incf	indf,f
	goto	l221
	line	67
	
l2729:	
	movlw	low(06h)
	subwf	(process_keypress@key),w
	skipnc
	goto	u3111
	goto	u3110
u3111:
	goto	l2735
u3110:
	line	68
	
l2731:	
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	movf	(process_keypress@zone),w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8))&0ffh
	movwf	fsr0
	bcf	status, 7	;select IRP bank1
	movf	indf,w
	movwf	(??_process_keypress+0)+0+0
	incf	fsr0,f
	movf	indf,w
	movwf	(??_process_keypress+0)+0+1
	movf	1+(??_process_keypress+0)+0,w
	xorlw	80h
	movwf	btemp+1
	movlw	(0)^80h
	subwf	btemp+1,w
	skipz
	goto	u3125
	movlw	010h
	subwf	0+(??_process_keypress+0)+0,w
u3125:

	skipc
	goto	u3121
	goto	u3120
u3121:
	goto	l221
u3120:
	
l2733:	
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	movf	(process_keypress@zone),w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8))&0ffh
	movwf	fsr0
	movlw	0FFh
	bcf	status, 7	;select IRP bank1
	addwf	indf,f
	incfsz	fsr0,f
	movf	indf,w
	skipnc
	incf	indf,w
	movwf	btemp+1
	movlw	0FFh
	addwf	btemp+1,w
	movwf	indf
	decf	fsr0,f
	goto	l221
	line	69
	
l2735:	
	movlw	low(09h)
	subwf	(process_keypress@key),w
	skipnc
	goto	u3131
	goto	u3130
u3131:
	goto	l2741
u3130:
	line	70
	
l2737:	
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	movf	(process_keypress@zone),w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8)+02h)&0ffh
	movwf	fsr0
	bcf	status, 7	;select IRP bank1
	movf	indf,w
	movwf	(??_process_keypress+0)+0+0
	incf	fsr0,f
	movf	indf,w
	movwf	(??_process_keypress+0)+0+1
	movf	1+(??_process_keypress+0)+0,w
	xorlw	80h
	movwf	btemp+1
	movlw	(0)^80h
	subwf	btemp+1,w
	skipz
	goto	u3145
	movlw	01Eh
	subwf	0+(??_process_keypress+0)+0,w
u3145:

	skipnc
	goto	u3141
	goto	u3140
u3141:
	goto	l221
u3140:
	
l2739:	
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	movf	(process_keypress@zone),w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8)+02h)&0ffh
	movwf	fsr0
	movlw	01h
	bcf	status, 7	;select IRP bank1
	addwf	indf,f
	incf	fsr0,f
	skipnc
	incf	indf,f
	goto	l221
	line	72
	
l2741:	
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	movf	(process_keypress@zone),w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8)+02h)&0ffh
	movwf	fsr0
	bcf	status, 7	;select IRP bank1
	movf	indf,w
	movwf	(??_process_keypress+0)+0+0
	incf	fsr0,f
	movf	indf,w
	movwf	(??_process_keypress+0)+0+1
	movf	1+(??_process_keypress+0)+0,w
	xorlw	80h
	movwf	btemp+1
	movlw	(0)^80h
	subwf	btemp+1,w
	skipz
	goto	u3155
	movlw	01h
	subwf	0+(??_process_keypress+0)+0,w
u3155:

	skipc
	goto	u3151
	goto	u3150
u3151:
	goto	l221
u3150:
	
l2743:	
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	movf	(process_keypress@zone),w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8)+02h)&0ffh
	movwf	fsr0
	movlw	0FFh
	bcf	status, 7	;select IRP bank1
	addwf	indf,f
	incfsz	fsr0,f
	movf	indf,w
	skipnc
	incf	indf,w
	movwf	btemp+1
	movlw	0FFh
	addwf	btemp+1,w
	movwf	indf
	decf	fsr0,f
	line	73
	
l221:	
	line	75
	movf	(process_keypress@zone),w
	fcall	_update_zone_mode
	line	76
	
l2745:	
	fcall	_update_all_leds
	line	77
	
l229:	
	return
	callstack 0
GLOBAL	__end_of_process_keypress
	__end_of_process_keypress:
	signat	_process_keypress,4217
	global	_update_zone_mode

;; *************** function _update_zone_mode *****************
;; Defined at:
;;		line 28 in file "zones.c"
;; Parameters:    Size  Location     Type
;;  z               1    wreg     unsigned char 
;; Auto vars:     Size  Location     Type
;;  z               1    6[COMMON] unsigned char 
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, btemp+1, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       0       0       0       0
;;      Locals:         1       0       0       0       0
;;      Temps:          2       0       0       0       0
;;      Totals:         3       0       0       0       0
;;Total ram usage:        3 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 1
;; This function calls:
;;		___bmul
;; This function is called by:
;;		_process_keypress
;; This function uses a non-reentrant model
;;
psect	text8,local,class=CODE,delta=2,merge=1,group=0
	line	28
global __ptext8
__ptext8:	;psect for function _update_zone_mode
psect	text8
	file	"zones.c"
	line	28
	
_update_zone_mode:	
;incstack = 0
	callstack 5
; Regs used in _update_zone_mode: [wreg-fsr0h+status,2+status,0+btemp+1+pclath+cstack]
	movwf	(update_zone_mode@z)
	line	29
	
l2623:	
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	movf	(update_zone_mode@z),w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8))&0ffh
	movwf	fsr0
	bcf	status, 7	;select IRP bank1
	movf	indf,w
	movwf	(??_update_zone_mode+0)+0+0
	incf	fsr0,f
	movf	indf,w
	movwf	(??_update_zone_mode+0)+0+1
	movf	1+(??_update_zone_mode+0)+0,w
	xorlw	80h
	movwf	btemp+1
	movlw	(0)^80h
	subwf	btemp+1,w
	skipz
	goto	u2985
	movlw	013h
	subwf	0+(??_update_zone_mode+0)+0,w
u2985:

	skipnc
	goto	u2981
	goto	u2980
u2981:
	goto	l2627
u2980:
	line	30
	
l2625:	
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	movf	(update_zone_mode@z),w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8)+04h)&0ffh
	movwf	fsr0
	movlw	low(048h)
	bcf	status, 7	;select IRP bank1
	movwf	indf
	goto	l213
	line	31
	
l2627:	
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	movf	(update_zone_mode@z),w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8))&0ffh
	movwf	fsr0
	bcf	status, 7	;select IRP bank1
	movf	indf,w
	movwf	(??_update_zone_mode+0)+0+0
	incf	fsr0,f
	movf	indf,w
	movwf	(??_update_zone_mode+0)+0+1
	movf	1+(??_update_zone_mode+0)+0,w
	xorlw	80h
	movwf	btemp+1
	movlw	(0)^80h
	subwf	btemp+1,w
	skipz
	goto	u2995
	movlw	01Ah
	subwf	0+(??_update_zone_mode+0)+0,w
u2995:

	skipc
	goto	u2991
	goto	u2990
u2991:
	goto	l2631
u2990:
	line	32
	
l2629:	
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	movf	(update_zone_mode@z),w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8)+04h)&0ffh
	movwf	fsr0
	movlw	low(043h)
	bcf	status, 7	;select IRP bank1
	movwf	indf
	goto	l213
	line	34
	
l2631:	
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	movf	(update_zone_mode@z),w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8)+04h)&0ffh
	movwf	fsr0
	movlw	low(053h)
	bcf	status, 7	;select IRP bank1
	movwf	indf
	line	35
	
l213:	
	return
	callstack 0
GLOBAL	__end_of_update_zone_mode
	__end_of_update_zone_mode:
	signat	_update_zone_mode,4217
	global	_update_all_leds

;; *************** function _update_all_leds *****************
;; Defined at:
;;		line 38 in file "zones.c"
;; Parameters:    Size  Location     Type
;;		None
;; Auto vars:     Size  Location     Type
;;		None
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg, status,2, status,0
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       0       0       0       0
;;      Locals:         0       0       0       0       0
;;      Temps:          0       0       0       0       0
;;      Totals:         0       0       0       0       0
;;Total ram usage:        0 bytes
;; Hardware stack levels used: 1
;; This function calls:
;;		Nothing
;; This function is called by:
;;		_main
;;		_process_keypress
;; This function uses a non-reentrant model
;;
psect	text9,local,class=CODE,delta=2,merge=1,group=0
	line	38
global __ptext9
__ptext9:	;psect for function _update_all_leds
psect	text9
	file	"zones.c"
	line	38
	
_update_all_leds:	
;incstack = 0
	callstack 7
; Regs used in _update_all_leds: [wreg+status,2+status,0]
	line	39
	
l2621:	
		movlw	72
	bsf	status, 5	;RP0=1, select bank1
	bcf	status, 6	;RP1=0, select bank1
	xorwf	(0+(_zones)^080h+04h),w
	btfsc	status,2
	goto	u2861
	goto	u2860
	
u2861:
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	bsf	(64/8),(64)&7	;volatile
	goto	u2874
u2860:
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	bcf	(64/8),(64)&7	;volatile
u2874:
	line	40
		movlw	72
	bsf	status, 5	;RP0=1, select bank1
	bcf	status, 6	;RP1=0, select bank1
	xorwf	(0+(_zones)^080h+09h),w
	btfsc	status,2
	goto	u2881
	goto	u2880
	
u2881:
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	bsf	(65/8),(65)&7	;volatile
	goto	u2894
u2880:
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	bcf	(65/8),(65)&7	;volatile
u2894:
	line	41
		movlw	72
	bsf	status, 5	;RP0=1, select bank1
	bcf	status, 6	;RP1=0, select bank1
	xorwf	(0+(_zones)^080h+0Eh),w
	btfsc	status,2
	goto	u2901
	goto	u2900
	
u2901:
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	bsf	(66/8),(66)&7	;volatile
	goto	u2914
u2900:
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	bcf	(66/8),(66)&7	;volatile
u2914:
	line	42
		movlw	67
	bsf	status, 5	;RP0=1, select bank1
	bcf	status, 6	;RP1=0, select bank1
	xorwf	(0+(_zones)^080h+04h),w
	btfsc	status,2
	goto	u2921
	goto	u2920
	
u2921:
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	bsf	(40/8),(40)&7	;volatile
	goto	u2934
u2920:
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	bcf	(40/8),(40)&7	;volatile
u2934:
	line	43
		movlw	67
	bsf	status, 5	;RP0=1, select bank1
	bcf	status, 6	;RP1=0, select bank1
	xorwf	(0+(_zones)^080h+09h),w
	btfsc	status,2
	goto	u2941
	goto	u2940
	
u2941:
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	bsf	(41/8),(41)&7	;volatile
	goto	u2954
u2940:
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	bcf	(41/8),(41)&7	;volatile
u2954:
	line	44
		movlw	67
	bsf	status, 5	;RP0=1, select bank1
	bcf	status, 6	;RP1=0, select bank1
	xorwf	(0+(_zones)^080h+0Eh),w
	btfsc	status,2
	goto	u2961
	goto	u2960
	
u2961:
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	bsf	(42/8),(42)&7	;volatile
	goto	u2974
u2960:
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	bcf	(42/8),(42)&7	;volatile
u2974:
	line	45
	
l216:	
	return
	callstack 0
GLOBAL	__end_of_update_all_leds
	__end_of_update_all_leds:
	signat	_update_all_leds,89
	global	_lcd_show_zone

;; *************** function _lcd_show_zone *****************
;; Defined at:
;;		line 57 in file "main.c"
;; Parameters:    Size  Location     Type
;;  z               1    wreg     unsigned char 
;; Auto vars:     Size  Location     Type
;;  z               1   34[BANK1 ] unsigned char 
;;  line2          17   17[BANK1 ] unsigned char [17]
;;  line1          17    0[BANK1 ] unsigned char [17]
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, btemp+1, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       0       0       0       0
;;      Locals:         0       0      35       0       0
;;      Temps:          0       2       0       0       0
;;      Totals:         0       2      35       0       0
;;Total ram usage:       37 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 8
;; This function calls:
;;		___bmul
;;		_lcd_send_string
;;		_lcd_set_cursor
;;		_sprintf
;; This function is called by:
;;		_main
;; This function uses a non-reentrant model
;;
psect	text10,local,class=CODE,delta=2,merge=1,group=0
	file	"main.c"
	line	57
global __ptext10
__ptext10:	;psect for function _lcd_show_zone
psect	text10
	file	"main.c"
	line	57
	
_lcd_show_zone:	
;incstack = 0
;; hardware stack exceeded
	callstack 0
; Regs used in _lcd_show_zone: [wreg-fsr0h+status,2+status,0+btemp+1+pclath+cstack]
	bsf	status, 5	;RP0=1, select bank1
	bcf	status, 6	;RP1=0, select bank1
	movwf	(lcd_show_zone@z)^080h
	line	61
	
l2633:	
	movlw	(low((((STR_7)-__stringbase)|8000h)))&0ffh
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(sprintf@fmt)
	bsf	status, 5	;RP0=1, select bank1
	bcf	status, 6	;RP1=0, select bank1
	movf	(lcd_show_zone@z)^080h,w
	addlw	low(01h)
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	0+(?_sprintf)+01h
	movlw	high(01h)
	skipnc
	movlw	(high(01h)+1)&0ffh
	movwf	(0+(?_sprintf)+01h)+1
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	bsf	status, 5	;RP0=1, select bank1
	bcf	status, 6	;RP1=0, select bank1
	movf	(lcd_show_zone@z)^080h,w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8))&0ffh
	movwf	fsr0
	bcf	status, 7	;select IRP bank1
	movf	indf,w
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	0+(?_sprintf)+03h
	incf	fsr0,f
	movf	indf,w
	movwf	1+(?_sprintf)+03h
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	bsf	status, 5	;RP0=1, select bank1
	bcf	status, 6	;RP1=0, select bank1
	movf	(lcd_show_zone@z)^080h,w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8)+04h)&0ffh
	movwf	fsr0
	bcf	status, 7	;select IRP bank1
	movf	indf,w
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(??_lcd_show_zone+0)+0
	clrf	(??_lcd_show_zone+0)+0+1
	movf	0+(??_lcd_show_zone+0)+0,w
	movwf	0+(?_sprintf)+05h
	movf	1+(??_lcd_show_zone+0)+0,w
	movwf	1+(?_sprintf)+05h
	movlw	(low(lcd_show_zone@line1|((0x0)<<8)))&0ffh
	fcall	_sprintf
	line	66
	movlw	(low((((STR_8)-__stringbase)|8000h)))&0ffh
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(sprintf@fmt)
	movlw	low(05h)
	movwf	(___bmul@multiplicand)
	bsf	status, 5	;RP0=1, select bank1
	bcf	status, 6	;RP1=0, select bank1
	movf	(lcd_show_zone@z)^080h,w
	fcall	___bmul
	addlw	low(_zones|((0x0)<<8)+02h)&0ffh
	movwf	fsr0
	bcf	status, 7	;select IRP bank1
	movf	indf,w
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	0+(?_sprintf)+01h
	incf	fsr0,f
	movf	indf,w
	movwf	1+(?_sprintf)+01h
	movlw	(low(lcd_show_zone@line2|((0x0)<<8)))&0ffh
	fcall	_sprintf
	line	69
	
l2635:	
	clrf	(lcd_set_cursor@col)
	movlw	low(0)
	fcall	_lcd_set_cursor
	line	70
	
l2637:	
	movlw	(low(lcd_show_zone@line1|((0x0)<<8))&0ffh)
	movwf	(lcd_send_string@str)
	movlw	(0x0)
	movwf	(lcd_send_string@str+1)
	fcall	_lcd_send_string
	line	71
	clrf	(lcd_set_cursor@col)
	movlw	low(01h)
	fcall	_lcd_set_cursor
	line	72
	
l2639:	
	movlw	(low(lcd_show_zone@line2|((0x0)<<8))&0ffh)
	movwf	(lcd_send_string@str)
	movlw	(0x0)
	movwf	(lcd_send_string@str+1)
	fcall	_lcd_send_string
	line	75
	
l2641:	
	movlw	low(0Fh)
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(??_lcd_show_zone+0)+0
	movf	(??_lcd_show_zone+0)+0,w
	iorwf	(8),f	;volatile
	line	76
	
l65:	
	return
	callstack 0
GLOBAL	__end_of_lcd_show_zone
	__end_of_lcd_show_zone:
	signat	_lcd_show_zone,4217
	global	_sprintf

;; *************** function _sprintf *****************
;; Defined at:
;;		line 9 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/nf_sprintf.c"
;; Parameters:    Size  Location     Type
;;  s               1    wreg     PTR unsigned char 
;;		 -> lcd_show_zone@line2(17), lcd_show_zone@line1(17), 
;;  fmt             1   35[BANK0 ] PTR const unsigned char 
;;		 -> STR_8(19), STR_7(20), 
;; Auto vars:     Size  Location     Type
;;  s               1   43[BANK0 ] PTR unsigned char 
;;		 -> lcd_show_zone@line2(17), lcd_show_zone@line1(17), 
;;  f              11   45[BANK0 ] struct _IO_FILE
;;  ret             2    0        int 
;;  ap              1   44[BANK0 ] PTR void [1]
;;		 -> ?_sprintf(2), 
;; Return value:  Size  Location     Type
;;                  2   35[BANK0 ] int 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, btemp+1, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       7       0       0       0
;;      Locals:         0      13       0       0       0
;;      Temps:          0       1       0       0       0
;;      Totals:         0      21       0       0       0
;;Total ram usage:       21 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 7
;; This function calls:
;;		_vfprintf
;; This function is called by:
;;		_lcd_show_zone
;; This function uses a non-reentrant model
;;
psect	text11,local,class=CODE,delta=2,merge=1,group=3
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/nf_sprintf.c"
	line	9
global __ptext11
__ptext11:	;psect for function _sprintf
psect	text11
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/nf_sprintf.c"
	line	9
	
_sprintf:	
;incstack = 0
;; hardware stack exceeded
	callstack 0
; Regs used in _sprintf: [wreg-fsr0h+status,2+status,0+btemp+1+pclath+cstack]
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(sprintf@s)
	line	15
	
l2609:	
	movlw	(low(?_sprintf|((0x0)<<8)+01h))&0ffh
	movwf	(sprintf@ap)
	line	16
	movf	(sprintf@s),w
	movwf	(sprintf@f)
	line	17
	
l2611:	
	clrf	0+(sprintf@f)+02h
	clrf	1+(sprintf@f)+02h
	line	18
	
l2613:	
	clrf	0+(sprintf@f)+09h
	clrf	1+(sprintf@f)+09h
	line	19
	
l2615:	
	movf	(sprintf@fmt),w
	movwf	(vfprintf@fmt)
	movlw	(low(sprintf@ap|((0x0)<<8)))&0ffh
	movwf	(vfprintf@ap)
	movlw	(low(sprintf@f|((0x0)<<8)))&0ffh
	fcall	_vfprintf
	line	20
	
l2617:	
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movf	0+(sprintf@f)+02h,w
	addwf	(sprintf@s),w
	movwf	(??_sprintf+0)+0
	movf	0+(??_sprintf+0)+0,w
	movwf	fsr0
	bcf	status, 7	;select IRP bank0
	clrf	indf
	line	23
	
l778:	
	return
	callstack 0
GLOBAL	__end_of_sprintf
	__end_of_sprintf:
	signat	_sprintf,4698
	global	_vfprintf

;; *************** function _vfprintf *****************
;; Defined at:
;;		line 1817 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/doprnt.c"
;; Parameters:    Size  Location     Type
;;  fp              1    wreg     PTR struct _IO_FILE
;;		 -> sprintf@f(11), 
;;  fmt             1   31[BANK0 ] PTR const unsigned char 
;;		 -> STR_8(19), STR_7(20), 
;;  ap              1   32[BANK0 ] PTR PTR void 
;;		 -> sprintf@ap(1), 
;; Auto vars:     Size  Location     Type
;;  fp              1   33[BANK0 ] PTR struct _IO_FILE
;;		 -> sprintf@f(11), 
;;  cfmt            1   34[BANK0 ] PTR unsigned char 
;;		 -> STR_8(19), STR_7(20), 
;; Return value:  Size  Location     Type
;;                  2   31[BANK0 ] int 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, btemp+1, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       2       0       0       0
;;      Locals:         0       2       0       0       0
;;      Temps:          0       0       0       0       0
;;      Totals:         0       4       0       0       0
;;Total ram usage:        4 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 6
;; This function calls:
;;		_vfpfcnvrt
;; This function is called by:
;;		_sprintf
;; This function uses a non-reentrant model
;;
psect	text12,local,class=CODE,delta=2,merge=1,group=1
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/doprnt.c"
	line	1817
global __ptext12
__ptext12:	;psect for function _vfprintf
psect	text12
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/doprnt.c"
	line	1817
	
_vfprintf:	
;incstack = 0
;; hardware stack exceeded
	callstack 0
; Regs used in _vfprintf: [wreg-fsr0h+status,2+status,0+btemp+1+pclath+cstack]
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(vfprintf@fp)
	line	1822
	
l2599:	
	movf	(vfprintf@fmt),w
	movwf	(vfprintf@cfmt)
	line	1826
	goto	l2603
	line	1830
	
l2601:	
	movlw	(low(vfprintf@cfmt|((0x0)<<8)))&0ffh
	movwf	(vfpfcnvrt@fmt)
	movf	(vfprintf@ap),w
	movwf	(vfpfcnvrt@ap)
	movf	(vfprintf@fp),w
	fcall	_vfpfcnvrt
	line	1826
	
l2603:	
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movf	(vfprintf@cfmt),w
	movwf	fsr0
	fcall	stringdir
	xorlw	0
	skipz
	goto	u2851
	goto	u2850
u2851:
	goto	l2601
u2850:
	line	1835
	
l2605:	
	clrf	(?_vfprintf)
	clrf	(?_vfprintf+1)
	line	1840
	
l877:	
	return
	callstack 0
GLOBAL	__end_of_vfprintf
	__end_of_vfprintf:
	signat	_vfprintf,12410
	global	_vfpfcnvrt

;; *************** function _vfpfcnvrt *****************
;; Defined at:
;;		line 1177 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/doprnt.c"
;; Parameters:    Size  Location     Type
;;  fp              1    wreg     PTR struct _IO_FILE
;;		 -> sprintf@f(11), 
;;  fmt             1   19[BANK0 ] PTR PTR unsigned char 
;;		 -> vfprintf@cfmt(1), 
;;  ap              1   20[BANK0 ] PTR PTR void 
;;		 -> sprintf@ap(1), 
;; Auto vars:     Size  Location     Type
;;  fp              1   29[BANK0 ] PTR struct _IO_FILE
;;		 -> sprintf@f(11), 
;;  convarg         4   25[BANK0 ] struct .
;;  cp              1   30[BANK0 ] PTR unsigned char 
;;		 -> STR_8(19), STR_7(20), 
;;  done            1   24[BANK0 ] _Bool 
;;  c               1   23[BANK0 ] unsigned char 
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, btemp+1, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       2       0       0       0
;;      Locals:         0       8       0       0       0
;;      Temps:          0       2       0       0       0
;;      Totals:         0      12       0       0       0
;;Total ram usage:       12 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 5
;; This function calls:
;;		_ctoa
;;		_dtoa
;;		_fputc
;;		_read_prec_or_width
;;		_utoa
;; This function is called by:
;;		_vfprintf
;; This function uses a non-reentrant model
;;
psect	text13,local,class=CODE,delta=2,merge=1,group=1
	line	1177
global __ptext13
__ptext13:	;psect for function _vfpfcnvrt
psect	text13
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/doprnt.c"
	line	1177
	
_vfpfcnvrt:	
;incstack = 0
;; hardware stack exceeded
	callstack 0
; Regs used in _vfpfcnvrt: [wreg-fsr0h+status,2+status,0+btemp+1+pclath+cstack]
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(vfpfcnvrt@fp)
	line	1201
	
l2517:	
	movf	(vfpfcnvrt@fmt),w
	movwf	fsr0
	bcf	status, 7	;select IRP bank0
	movf	indf,w
	movwf	fsr0
	fcall	stringdir
	xorlw	025h
	skipz
	goto	u2761
	goto	u2760
u2761:
	goto	l2579
u2760:
	line	1202
	
l2519:	
	movlw	low(01h)
	movwf	(??_vfpfcnvrt+0)+0
	movf	(vfpfcnvrt@fmt),w
	movwf	fsr0
	movf	(??_vfpfcnvrt+0)+0,w
	addwf	indf,f
	line	1204
	
l2521:	
	clrf	(_width)
	clrf	(_width+1)
	clrc
	movlw	0
	btfsc	status,0
	movlw	1
	movwf	(_flags)
	line	1205
	
l2523:	
	movlw	0FFh
	movwf	(_prec)
	movlw	0FFh
	movwf	((_prec))+1
	line	1209
	
l2525:	
	clrf	(vfpfcnvrt@done)
	line	1210
	goto	l2533
	line	1213
	
l856:	
	line	1214
	bsf	(_flags)+(0/8),(0)&7
	line	1215
	
l2527:	
	movlw	low(01h)
	movwf	(??_vfpfcnvrt+0)+0
	movf	(vfpfcnvrt@fmt),w
	movwf	fsr0
	movf	(??_vfpfcnvrt+0)+0,w
	addwf	indf,f
	line	1216
	goto	l2533
	line	1242
	
l858:	
	line	1243
	clrf	(vfpfcnvrt@done)
	incf	(vfpfcnvrt@done),f
	line	1244
	goto	l2533
	line	1245
	
l2531:	
	movf	(vfpfcnvrt@fmt),w
	movwf	fsr0
	movf	indf,w
	movwf	fsr0
	fcall	stringdir
	; Switch size 1, requested type "simple"
; Number of cases is 1, Range of values is 45 to 45
; switch strategies available:
; Name         Instructions Cycles
; simple_byte            4     3 (average)
; direct_byte           14    11 (fixed)
; jumptable            263     9 (fixed)
;	Chosen strategy is simple_byte

	asmopt push
	asmopt off
	xorlw	45^0	; case 45
	skipnz
	goto	l856
	goto	l858
	asmopt pop

	line	1210
	
l2533:	
	movf	((vfpfcnvrt@done)),w
	btfsc	status,2
	goto	u2771
	goto	u2770
u2771:
	goto	l2531
u2770:
	line	1256
	
l2535:	
	movf	(vfpfcnvrt@ap),w
	movwf	(read_prec_or_width@ap)
	movf	(vfpfcnvrt@fmt),w
	fcall	_read_prec_or_width
	movf	(1+(?_read_prec_or_width)),w
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(_width+1)
	movf	(0+(?_read_prec_or_width)),w
	movwf	(_width)
	line	1257
	
l2537:	
	btfss	(_width+1),7
	goto	u2781
	goto	u2780
u2781:
	goto	l2543
u2780:
	line	1258
	
l2539:	
	bsf	(_flags)+(0/8),(0)&7
	line	1259
	
l2541:	
	comf	(_width),f
	comf	(_width+1),f
	incf	(_width),f
	skipnz
	incf	(_width+1),f
	line	1273
	
l2543:	
	movf	(vfpfcnvrt@fmt),w
	movwf	fsr0
	bcf	status, 7	;select IRP bank0
	movf	indf,w
	movwf	fsr0
	fcall	stringdir
	xorlw	063h
	skipz
	goto	u2791
	goto	u2790
u2791:
	goto	l2551
u2790:
	line	1274
	
l2545:	
	movlw	low(01h)
	movwf	(??_vfpfcnvrt+0)+0
	movf	(vfpfcnvrt@fmt),w
	movwf	fsr0
	movf	(??_vfpfcnvrt+0)+0,w
	addwf	indf,f
	line	1275
	movf	(vfpfcnvrt@ap),w
	movwf	fsr0
	movf	indf,w
	movwf	((??_vfpfcnvrt+0)+0)
	movlw	02h
	addwf	indf,f
	movf	((??_vfpfcnvrt+0)+0),w
	movwf	fsr0
	movf	indf,w
	movwf	(vfpfcnvrt@c)
	line	1284
	
l2547:	
;	Return value of _vfpfcnvrt is never used
	movf	(vfpfcnvrt@c),w
	movwf	(ctoa@c)
	movf	(vfpfcnvrt@fp),w
	fcall	_ctoa
	goto	l862
	line	1291
	
l2551:	
	movf	(vfpfcnvrt@fmt),w
	movwf	fsr0
	movf	indf,w
	movwf	(vfpfcnvrt@cp)
	line	1361
	
l2553:	
	movf	(vfpfcnvrt@cp),w
	movwf	fsr0
	fcall	stringdir
	xorlw	064h
	skipnz
	goto	u2801
	goto	u2800
u2801:
	goto	l2557
u2800:
	
l2555:	
	movf	(vfpfcnvrt@cp),w
	movwf	fsr0
	fcall	stringdir
	xorlw	069h
	skipz
	goto	u2811
	goto	u2810
u2811:
	goto	l2563
u2810:
	line	1404
	
l2557:	
	movf	(vfpfcnvrt@ap),w
	movwf	fsr0
	movf	indf,w
	movwf	((??_vfpfcnvrt+0)+0)
	movlw	02h
	addwf	indf,f
	movf	((??_vfpfcnvrt+0)+0),w
	movwf	fsr0
	movf	indf,w
	movwf	(vfpfcnvrt@convarg)
	incf	fsr0,f
	movf	indf,w
	movwf	(vfpfcnvrt@convarg+1)
	line	1406
	movf	(vfpfcnvrt@fmt),w
	movwf	fsr0
	movf	(vfpfcnvrt@cp),w
	addlw	01h
	movwf	indf
	line	1432
	
l2559:	
;	Return value of _vfpfcnvrt is never used
	movf	(vfpfcnvrt@convarg+1),w
	movwf	(dtoa@d+1)
	movf	(vfpfcnvrt@convarg),w
	movwf	(dtoa@d)
	movf	(vfpfcnvrt@fp),w
	fcall	_dtoa
	goto	l862
	line	1439
	
l2563:	
	movf	(vfpfcnvrt@cp),w
	movwf	fsr0
	fcall	stringdir
	xorlw	075h
	skipz
	goto	u2821
	goto	u2820
u2821:
	goto	l2575
u2820:
	line	1495
	
l2565:	
	movf	(vfpfcnvrt@ap),w
	movwf	fsr0
	movf	indf,w
	movwf	((??_vfpfcnvrt+0)+0)
	movlw	02h
	addwf	indf,f
	movf	((??_vfpfcnvrt+0)+0),w
	movwf	fsr0
	movf	indf,w
	movwf	(vfpfcnvrt@convarg)
	incf	fsr0,f
	movf	indf,w
	movwf	(vfpfcnvrt@convarg+1)
	line	1497
	movf	(vfpfcnvrt@fmt),w
	movwf	fsr0
	movf	(vfpfcnvrt@cp),w
	addlw	01h
	movwf	indf
	line	1498
	goto	l2573
	line	1542
	
l2567:	
;	Return value of _vfpfcnvrt is never used
	movf	(vfpfcnvrt@convarg+1),w
	movwf	(utoa@d+1)
	movf	(vfpfcnvrt@convarg),w
	movwf	(utoa@d)
	movf	(vfpfcnvrt@fp),w
	fcall	_utoa
	goto	l862
	line	1589
	
l2573:	
	movf	(vfpfcnvrt@cp),w
	movwf	fsr0
	fcall	stringdir
	; Switch size 1, requested type "simple"
; Number of cases is 1, Range of values is 117 to 117
; switch strategies available:
; Name         Instructions Cycles
; simple_byte            4     3 (average)
; direct_byte           14    11 (fixed)
; jumptable            263     9 (fixed)
;	Chosen strategy is simple_byte

	asmopt push
	asmopt off
	xorlw	117^0	; case 117
	skipnz
	goto	l2567
	goto	l2575
	asmopt pop

	line	1806
	
l2575:	
	movlw	low(01h)
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(??_vfpfcnvrt+0)+0
	movf	(vfpfcnvrt@fmt),w
	movwf	fsr0
	movf	(??_vfpfcnvrt+0)+0,w
	bcf	status, 7	;select IRP bank0
	addwf	indf,f
	goto	l862
	line	1811
	
l2579:	
	movf	(vfpfcnvrt@fmt),w
	movwf	fsr0
	movf	indf,w
	movwf	fsr0
	fcall	stringdir
	movwf	(??_vfpfcnvrt+0)+0
	clrf	(??_vfpfcnvrt+0)+0+1
	movf	0+(??_vfpfcnvrt+0)+0,w
	movwf	(fputc@c)
	movf	1+(??_vfpfcnvrt+0)+0,w
	movwf	(fputc@c+1)
	movf	(vfpfcnvrt@fp),w
	movwf	(fputc@fp)
	fcall	_fputc
	goto	l2575
	line	1814
	
l862:	
	return
	callstack 0
GLOBAL	__end_of_vfpfcnvrt
	__end_of_vfpfcnvrt:
	signat	_vfpfcnvrt,12409
	global	_utoa

;; *************** function _utoa *****************
;; Defined at:
;;		line 1001 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/doprnt.c"
;; Parameters:    Size  Location     Type
;;  fp              1    wreg     PTR struct _IO_FILE
;;		 -> sprintf@f(11), 
;;  d               2    8[BANK0 ] unsigned int 
;; Auto vars:     Size  Location     Type
;;  fp              1   12[BANK0 ] PTR struct _IO_FILE
;;		 -> sprintf@f(11), 
;;  i               2   14[BANK0 ] int 
;;  w               2   10[BANK0 ] int 
;;  p               1   13[BANK0 ] _Bool 
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       2       0       0       0
;;      Locals:         0       6       0       0       0
;;      Temps:          0       0       0       0       0
;;      Totals:         0       8       0       0       0
;;Total ram usage:        8 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 4
;; This function calls:
;;		___lwdiv
;;		___lwmod
;;		_pad
;; This function is called by:
;;		_vfpfcnvrt
;; This function uses a non-reentrant model
;;
psect	text14,local,class=CODE,delta=2,merge=1,group=1
	line	1001
global __ptext14
__ptext14:	;psect for function _utoa
psect	text14
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/doprnt.c"
	line	1001
	
_utoa:	
;incstack = 0
;; hardware stack exceeded
	callstack 0
; Regs used in _utoa: [wreg-fsr0h+status,2+status,0+pclath+cstack]
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(utoa@fp)
	line	1007
	
l1929:	
	clrf	(utoa@p)
	incf	(utoa@p),f
	line	1019
	
l1931:	
	movf	(_width+1),w
	movwf	(utoa@w+1)
	movf	(_width),w
	movwf	(utoa@w)
	line	1022
	movlw	01Fh
	movwf	(utoa@i)
	movlw	0
	movwf	((utoa@i))+1
	line	1023
	
l1933:	
	bsf	status, 5	;RP0=1, select bank3
	bsf	status, 6	;RP1=1, select bank3
	clrf	0+(_dbuf)^0180h+01Fh
	line	1024
	goto	l1945
	line	1034
	
l1935:	
	movlw	0FFh
	addwf	(utoa@i),f
	skipnc
	incf	(utoa@i+1),f
	movlw	0FFh
	addwf	(utoa@i+1),f
	line	1035
	
l1937:	
	movf	(utoa@i),w
	addlw	low(_dbuf|((0x1)<<8))&0ffh
	movwf	fsr0
	movlw	0Ah
	movwf	(___lwmod@divisor)
	movlw	0
	movwf	((___lwmod@divisor))+1
	movf	(utoa@d+1),w
	movwf	(___lwmod@dividend+1)
	movf	(utoa@d),w
	movwf	(___lwmod@dividend)
	fcall	___lwmod
	movf	(0+(?___lwmod)),w
	addlw	030h
	bsf	status, 7	;select IRP bank3
	movwf	indf
	line	1039
	
l1939:	
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	clrf	(utoa@p)
	line	1041
	
l1941:	
	movlw	0FFh
	addwf	(utoa@w),f
	skipnc
	incf	(utoa@w+1),f
	movlw	0FFh
	addwf	(utoa@w+1),f
	line	1042
	
l1943:	
	movlw	0Ah
	movwf	(___lwdiv@divisor)
	movlw	0
	movwf	((___lwdiv@divisor))+1
	movf	(utoa@d+1),w
	movwf	(___lwdiv@dividend+1)
	movf	(utoa@d),w
	movwf	(___lwdiv@dividend)
	fcall	___lwdiv
	movf	(1+(?___lwdiv)),w
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(utoa@d+1)
	movf	(0+(?___lwdiv)),w
	movwf	(utoa@d)
	line	1024
	
l1945:	
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movf	((utoa@i)),w
iorwf	((utoa@i+1)),w
	btfsc	status,2
	goto	u1891
	goto	u1890
u1891:
	goto	l1951
u1890:
	
l1947:	
	movf	((utoa@d)),w
iorwf	((utoa@d+1)),w
	btfss	status,2
	goto	u1901
	goto	u1900
u1901:
	goto	l1935
u1900:
	
l1949:	
	movf	((utoa@p)),w
	btfss	status,2
	goto	u1911
	goto	u1910
u1911:
	goto	l1935
u1910:
	line	1046
	
l1951:	
	movf	(utoa@i),w
	addlw	low(_dbuf|((0x1)<<8))&0ffh
	movwf	(pad@buf)
	movf	(utoa@w+1),w
	movwf	(pad@p+1)
	movf	(utoa@w),w
	movwf	(pad@p)
	movf	(utoa@fp),w
	fcall	_pad
	line	1047
	
l841:	
	return
	callstack 0
GLOBAL	__end_of_utoa
	__end_of_utoa:
	signat	_utoa,8313
	global	___lwmod

;; *************** function ___lwmod *****************
;; Defined at:
;;		line 5 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/lwmod.c"
;; Parameters:    Size  Location     Type
;;  divisor         2    0[COMMON] unsigned int 
;;  dividend        2    2[COMMON] unsigned int 
;; Auto vars:     Size  Location     Type
;;  counter         1    5[COMMON] unsigned char 
;; Return value:  Size  Location     Type
;;                  2    0[COMMON] unsigned int 
;; Registers used:
;;		wreg, status,2, status,0
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         4       0       0       0       0
;;      Locals:         1       0       0       0       0
;;      Temps:          1       0       0       0       0
;;      Totals:         6       0       0       0       0
;;Total ram usage:        6 bytes
;; Hardware stack levels used: 1
;; This function calls:
;;		Nothing
;; This function is called by:
;;		_utoa
;; This function uses a non-reentrant model
;;
psect	text15,local,class=CODE,delta=2,merge=1,group=2
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/lwmod.c"
	line	5
global __ptext15
__ptext15:	;psect for function ___lwmod
psect	text15
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/lwmod.c"
	line	5
	
___lwmod:	
;incstack = 0
	callstack 2
; Regs used in ___lwmod: [wreg+status,2+status,0]
	line	12
	
l1817:	
	movf	((___lwmod@divisor)),w
iorwf	((___lwmod@divisor+1)),w
	btfsc	status,2
	goto	u1651
	goto	u1650
u1651:
	goto	l1835
u1650:
	line	13
	
l1819:	
	clrf	(___lwmod@counter)
	incf	(___lwmod@counter),f
	line	14
	goto	l1825
	line	15
	
l1821:	
	movlw	01h
	
u1665:
	clrc
	rlf	(___lwmod@divisor),f
	rlf	(___lwmod@divisor+1),f
	addlw	-1
	skipz
	goto	u1665
	line	16
	
l1823:	
	movlw	low(01h)
	movwf	(??___lwmod+0)+0
	movf	(??___lwmod+0)+0,w
	addwf	(___lwmod@counter),f
	line	14
	
l1825:	
	btfss	(___lwmod@divisor+1),(15)&7
	goto	u1671
	goto	u1670
u1671:
	goto	l1821
u1670:
	line	19
	
l1827:	
	movf	(___lwmod@divisor+1),w
	subwf	(___lwmod@dividend+1),w
	skipz
	goto	u1685
	movf	(___lwmod@divisor),w
	subwf	(___lwmod@dividend),w
u1685:
	skipc
	goto	u1681
	goto	u1680
u1681:
	goto	l1831
u1680:
	line	20
	
l1829:	
	movf	(___lwmod@divisor),w
	subwf	(___lwmod@dividend),f
	movf	(___lwmod@divisor+1),w
	skipc
	decf	(___lwmod@dividend+1),f
	subwf	(___lwmod@dividend+1),f
	line	21
	
l1831:	
	movlw	01h
	
u1695:
	clrc
	rrf	(___lwmod@divisor+1),f
	rrf	(___lwmod@divisor),f
	addlw	-1
	skipz
	goto	u1695
	line	22
	
l1833:	
	movlw	01h
	subwf	(___lwmod@counter),f
	btfss	status,2
	goto	u1701
	goto	u1700
u1701:
	goto	l1827
u1700:
	line	24
	
l1835:	
	movf	(___lwmod@dividend+1),w
	movwf	(?___lwmod+1)
	movf	(___lwmod@dividend),w
	movwf	(?___lwmod)
	line	25
	
l605:	
	return
	callstack 0
GLOBAL	__end_of___lwmod
	__end_of___lwmod:
	signat	___lwmod,8314
	global	___lwdiv

;; *************** function ___lwdiv *****************
;; Defined at:
;;		line 5 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/lwdiv.c"
;; Parameters:    Size  Location     Type
;;  divisor         2    0[COMMON] unsigned int 
;;  dividend        2    2[COMMON] unsigned int 
;; Auto vars:     Size  Location     Type
;;  quotient        2    5[COMMON] unsigned int 
;;  counter         1    7[COMMON] unsigned char 
;; Return value:  Size  Location     Type
;;                  2    0[COMMON] unsigned int 
;; Registers used:
;;		wreg, status,2, status,0
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         4       0       0       0       0
;;      Locals:         3       0       0       0       0
;;      Temps:          1       0       0       0       0
;;      Totals:         8       0       0       0       0
;;Total ram usage:        8 bytes
;; Hardware stack levels used: 1
;; This function calls:
;;		Nothing
;; This function is called by:
;;		_utoa
;; This function uses a non-reentrant model
;;
psect	text16,local,class=CODE,delta=2,merge=1,group=2
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/lwdiv.c"
	line	5
global __ptext16
__ptext16:	;psect for function ___lwdiv
psect	text16
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/lwdiv.c"
	line	5
	
___lwdiv:	
;incstack = 0
	callstack 2
; Regs used in ___lwdiv: [wreg+status,2+status,0]
	line	13
	
l1791:	
	clrf	(___lwdiv@quotient)
	clrf	(___lwdiv@quotient+1)
	line	14
	
l1793:	
	movf	((___lwdiv@divisor)),w
iorwf	((___lwdiv@divisor+1)),w
	btfsc	status,2
	goto	u1581
	goto	u1580
u1581:
	goto	l1813
u1580:
	line	15
	
l1795:	
	clrf	(___lwdiv@counter)
	incf	(___lwdiv@counter),f
	line	16
	goto	l1801
	line	17
	
l1797:	
	movlw	01h
	
u1595:
	clrc
	rlf	(___lwdiv@divisor),f
	rlf	(___lwdiv@divisor+1),f
	addlw	-1
	skipz
	goto	u1595
	line	18
	
l1799:	
	movlw	low(01h)
	movwf	(??___lwdiv+0)+0
	movf	(??___lwdiv+0)+0,w
	addwf	(___lwdiv@counter),f
	line	16
	
l1801:	
	btfss	(___lwdiv@divisor+1),(15)&7
	goto	u1601
	goto	u1600
u1601:
	goto	l1797
u1600:
	line	21
	
l1803:	
	movlw	01h
	
u1615:
	clrc
	rlf	(___lwdiv@quotient),f
	rlf	(___lwdiv@quotient+1),f
	addlw	-1
	skipz
	goto	u1615
	line	22
	movf	(___lwdiv@divisor+1),w
	subwf	(___lwdiv@dividend+1),w
	skipz
	goto	u1625
	movf	(___lwdiv@divisor),w
	subwf	(___lwdiv@dividend),w
u1625:
	skipc
	goto	u1621
	goto	u1620
u1621:
	goto	l1809
u1620:
	line	23
	
l1805:	
	movf	(___lwdiv@divisor),w
	subwf	(___lwdiv@dividend),f
	movf	(___lwdiv@divisor+1),w
	skipc
	decf	(___lwdiv@dividend+1),f
	subwf	(___lwdiv@dividend+1),f
	line	24
	
l1807:	
	bsf	(___lwdiv@quotient)+(0/8),(0)&7
	line	26
	
l1809:	
	movlw	01h
	
u1635:
	clrc
	rrf	(___lwdiv@divisor+1),f
	rrf	(___lwdiv@divisor),f
	addlw	-1
	skipz
	goto	u1635
	line	27
	
l1811:	
	movlw	01h
	subwf	(___lwdiv@counter),f
	btfss	status,2
	goto	u1641
	goto	u1640
u1641:
	goto	l1803
u1640:
	line	29
	
l1813:	
	movf	(___lwdiv@quotient+1),w
	movwf	(?___lwdiv+1)
	movf	(___lwdiv@quotient),w
	movwf	(?___lwdiv)
	line	30
	
l595:	
	return
	callstack 0
GLOBAL	__end_of___lwdiv
	__end_of___lwdiv:
	signat	___lwdiv,8314
	global	_read_prec_or_width

;; *************** function _read_prec_or_width *****************
;; Defined at:
;;		line 1158 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/doprnt.c"
;; Parameters:    Size  Location     Type
;;  fmt             1    wreg     PTR PTR const unsigned c
;;		 -> vfprintf@cfmt(1), 
;;  ap              1    6[COMMON] PTR PTR void [1]
;;		 -> sprintf@ap(1), 
;; Auto vars:     Size  Location     Type
;;  fmt             1   12[COMMON] PTR PTR const unsigned c
;;		 -> vfprintf@cfmt(1), 
;;  c               1    9[COMMON] unsigned char 
;;  n               2   10[COMMON] int 
;; Return value:  Size  Location     Type
;;                  2    6[COMMON] int 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         2       0       0       0       0
;;      Locals:         4       0       0       0       0
;;      Temps:          1       0       0       0       0
;;      Totals:         7       0       0       0       0
;;Total ram usage:        7 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 1
;; This function calls:
;;		___wmul
;; This function is called by:
;;		_vfpfcnvrt
;; This function uses a non-reentrant model
;;
psect	text17,local,class=CODE,delta=2,merge=1,group=1
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/doprnt.c"
	line	1158
global __ptext17
__ptext17:	;psect for function _read_prec_or_width
psect	text17
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/doprnt.c"
	line	1158
	
_read_prec_or_width:	
;incstack = 0
	callstack 2
; Regs used in _read_prec_or_width: [wreg-fsr0h+status,2+status,0+pclath+cstack]
	movwf	(read_prec_or_width@fmt)
	line	1159
	
l1955:	
	clrf	(read_prec_or_width@n)
	clrf	(read_prec_or_width@n+1)
	line	1160
	
l1957:	
	movf	(read_prec_or_width@fmt),w
	movwf	fsr0
	bcf	status, 7	;select IRP bank0
	movf	indf,w
	movwf	fsr0
	fcall	stringdir
	xorlw	02Ah
	skipz
	goto	u1921
	goto	u1920
u1921:
	goto	l1965
u1920:
	line	1161
	
l1959:	
	movlw	low(01h)
	movwf	(??_read_prec_or_width+0)+0
	movf	(read_prec_or_width@fmt),w
	movwf	fsr0
	movf	(??_read_prec_or_width+0)+0,w
	addwf	indf,f
	line	1162
	movf	(read_prec_or_width@ap),w
	movwf	fsr0
	movf	indf,w
	movwf	((??_read_prec_or_width+0)+0)
	movlw	02h
	addwf	indf,f
	movf	((??_read_prec_or_width+0)+0),w
	movwf	fsr0
	movf	indf,w
	movwf	(read_prec_or_width@n)
	incf	fsr0,f
	movf	indf,w
	movwf	(read_prec_or_width@n+1)
	line	1163
	goto	l1967
	line	1166
	
l1961:	
	movf	(read_prec_or_width@n+1),w
	movwf	(___wmul@multiplier+1)
	movf	(read_prec_or_width@n),w
	movwf	(___wmul@multiplier)
	movlw	0Ah
	movwf	(___wmul@multiplicand)
	movlw	0
	movwf	((___wmul@multiplicand))+1
	fcall	___wmul
	movf	(read_prec_or_width@c),w
	addwf	(0+(?___wmul)),w
	movwf	(read_prec_or_width@n)
	movlw	0
	skipnc
	movlw	1
	addwf	(1+(?___wmul)),w
	movwf	1+(read_prec_or_width@n)
	line	1167
	
l1963:	
	movlw	low(01h)
	movwf	(??_read_prec_or_width+0)+0
	movf	(read_prec_or_width@fmt),w
	movwf	fsr0
	movf	(??_read_prec_or_width+0)+0,w
	bcf	status, 7	;select IRP bank0
	addwf	indf,f
	line	1165
	
l1965:	
	movf	(read_prec_or_width@fmt),w
	movwf	fsr0
	movf	indf,w
	movwf	fsr0
	fcall	stringdir
	addlw	0D0h
	movwf	(read_prec_or_width@c)
	movlw	low(0Ah)
	subwf	((read_prec_or_width@c)),w
	skipc
	goto	u1931
	goto	u1930
u1931:
	goto	l1961
u1930:
	line	1170
	
l1967:	
	movf	(read_prec_or_width@n+1),w
	movwf	(?_read_prec_or_width+1)
	movf	(read_prec_or_width@n),w
	movwf	(?_read_prec_or_width)
	line	1171
	
l849:	
	return
	callstack 0
GLOBAL	__end_of_read_prec_or_width
	__end_of_read_prec_or_width:
	signat	_read_prec_or_width,8314
	global	___wmul

;; *************** function ___wmul *****************
;; Defined at:
;;		line 15 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/Umul16.c"
;; Parameters:    Size  Location     Type
;;  multiplier      2    0[COMMON] unsigned int 
;;  multiplicand    2    2[COMMON] unsigned int 
;; Auto vars:     Size  Location     Type
;;  product         2    4[COMMON] unsigned int 
;; Return value:  Size  Location     Type
;;                  2    0[COMMON] unsigned int 
;; Registers used:
;;		wreg, status,2, status,0
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         4       0       0       0       0
;;      Locals:         2       0       0       0       0
;;      Temps:          0       0       0       0       0
;;      Totals:         6       0       0       0       0
;;Total ram usage:        6 bytes
;; Hardware stack levels used: 1
;; This function calls:
;;		Nothing
;; This function is called by:
;;		_read_prec_or_width
;; This function uses a non-reentrant model
;;
psect	text18,local,class=CODE,delta=2,merge=1,group=2
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/Umul16.c"
	line	15
global __ptext18
__ptext18:	;psect for function ___wmul
psect	text18
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/Umul16.c"
	line	15
	
___wmul:	
;incstack = 0
	callstack 2
; Regs used in ___wmul: [wreg+status,2+status,0]
	line	43
	
l1695:	
	clrf	(___wmul@product)
	clrf	(___wmul@product+1)
	line	45
	
l1697:	
	btfss	(___wmul@multiplier),(0)&7
	goto	u1351
	goto	u1350
u1351:
	goto	l315
u1350:
	line	46
	
l1699:	
	movf	(___wmul@multiplicand),w
	addwf	(___wmul@product),f
	skipnc
	incf	(___wmul@product+1),f
	movf	(___wmul@multiplicand+1),w
	addwf	(___wmul@product+1),f
	
l315:	
	line	47
	movlw	01h
	
u1365:
	clrc
	rlf	(___wmul@multiplicand),f
	rlf	(___wmul@multiplicand+1),f
	addlw	-1
	skipz
	goto	u1365
	line	48
	
l1701:	
	movlw	01h
	
u1375:
	clrc
	rrf	(___wmul@multiplier+1),f
	rrf	(___wmul@multiplier),f
	addlw	-1
	skipz
	goto	u1375
	line	49
	
l1703:	
	movf	((___wmul@multiplier)),w
iorwf	((___wmul@multiplier+1)),w
	btfss	status,2
	goto	u1381
	goto	u1380
u1381:
	goto	l1697
u1380:
	line	52
	
l1705:	
	movf	(___wmul@product+1),w
	movwf	(?___wmul+1)
	movf	(___wmul@product),w
	movwf	(?___wmul)
	line	53
	
l317:	
	return
	callstack 0
GLOBAL	__end_of___wmul
	__end_of___wmul:
	signat	___wmul,8314
	global	_dtoa

;; *************** function _dtoa *****************
;; Defined at:
;;		line 513 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/doprnt.c"
;; Parameters:    Size  Location     Type
;;  fp              1    wreg     PTR struct _IO_FILE
;;		 -> sprintf@f(11), 
;;  d               2    8[BANK0 ] int 
;; Auto vars:     Size  Location     Type
;;  fp              1   10[BANK0 ] PTR struct _IO_FILE
;;		 -> sprintf@f(11), 
;;  i               2   17[BANK0 ] int 
;;  w               2   14[BANK0 ] int 
;;  s               1   16[BANK0 ] unsigned char 
;;  p               1   13[BANK0 ] _Bool 
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, btemp+1, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       2       0       0       0
;;      Locals:         0       9       0       0       0
;;      Temps:          0       0       0       0       0
;;      Totals:         0      11       0       0       0
;;Total ram usage:       11 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 4
;; This function calls:
;;		___awdiv
;;		___awmod
;;		_abs
;;		_pad
;; This function is called by:
;;		_vfpfcnvrt
;; This function uses a non-reentrant model
;;
psect	text19,local,class=CODE,delta=2,merge=1,group=1
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/doprnt.c"
	line	513
global __ptext19
__ptext19:	;psect for function _dtoa
psect	text19
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/doprnt.c"
	line	513
	
_dtoa:	
;incstack = 0
;; hardware stack exceeded
	callstack 0
; Regs used in _dtoa: [wreg-fsr0h+status,2+status,0+btemp+1+pclath+cstack]
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(dtoa@fp)
	line	520
	
l2475:	
	clrf	(dtoa@p)
	incf	(dtoa@p),f
	line	524
	
l2477:	
	btfsc	(dtoa@d+1),7
	goto	u2681
	goto	u2680
u2681:
	movlw	1
	goto	u2690
u2680:
	movlw	0
u2690:
	movwf	(dtoa@s)
	line	535
	movf	(_width+1),w
	movwf	(dtoa@w+1)
	movf	(_width),w
	movwf	(dtoa@w)
	line	536
	
l2479:	
	movf	((dtoa@s)),w
	btfsc	status,2
	goto	u2701
	goto	u2700
u2701:
	goto	l822
u2700:
	line	541
	
l2481:	
	movlw	0FFh
	addwf	(dtoa@w),f
	skipnc
	incf	(dtoa@w+1),f
	movlw	0FFh
	addwf	(dtoa@w+1),f
	line	542
	
l2483:	
	movf	((dtoa@s)),w
	btfss	status,2
	goto	u2711
	goto	u2710
u2711:
	goto	l2487
u2710:
	
l2485:	
	movlw	02Bh
	movwf	(_dtoa$765)
	movlw	0
	movwf	((_dtoa$765))+1
	goto	l826
	
l2487:	
	movlw	02Dh
	movwf	(_dtoa$765)
	movlw	0
	movwf	((_dtoa$765))+1
	
l826:	
	movf	(_dtoa$765),w
	movwf	(dtoa@s)
	line	543
	
l822:	
	line	552
	movlw	01Fh
	movwf	(dtoa@i)
	movlw	0
	movwf	((dtoa@i))+1
	line	553
	
l2489:	
	bsf	status, 5	;RP0=1, select bank3
	bsf	status, 6	;RP1=1, select bank3
	clrf	0+(_dbuf)^0180h+01Fh
	line	554
	goto	l2501
	line	564
	
l2491:	
	movlw	0FFh
	addwf	(dtoa@i),f
	skipnc
	incf	(dtoa@i+1),f
	movlw	0FFh
	addwf	(dtoa@i+1),f
	line	565
	
l2493:	
	movf	(dtoa@i),w
	addlw	low(_dbuf|((0x1)<<8))&0ffh
	movwf	fsr0
	movlw	0Ah
	movwf	(___awmod@divisor)
	movlw	0
	movwf	((___awmod@divisor))+1
	movf	(dtoa@d+1),w
	movwf	(___awmod@dividend+1)
	movf	(dtoa@d),w
	movwf	(___awmod@dividend)
	fcall	___awmod
	movf	(1+(?___awmod)),w
	movwf	(abs@a+1)
	movf	(0+(?___awmod)),w
	movwf	(abs@a)
	fcall	_abs
	movf	(0+(?_abs)),w
	addlw	030h
	bsf	status, 7	;select IRP bank3
	movwf	indf
	line	569
	
l2495:	
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	clrf	(dtoa@p)
	line	571
	
l2497:	
	movlw	0FFh
	addwf	(dtoa@w),f
	skipnc
	incf	(dtoa@w+1),f
	movlw	0FFh
	addwf	(dtoa@w+1),f
	line	572
	
l2499:	
	movlw	0Ah
	movwf	(___awdiv@divisor)
	movlw	0
	movwf	((___awdiv@divisor))+1
	movf	(dtoa@d+1),w
	movwf	(___awdiv@dividend+1)
	movf	(dtoa@d),w
	movwf	(___awdiv@dividend)
	fcall	___awdiv
	movf	(1+(?___awdiv)),w
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(dtoa@d+1)
	movf	(0+(?___awdiv)),w
	movwf	(dtoa@d)
	line	554
	
l2501:	
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movf	(dtoa@i+1),w
	xorlw	80h
	movwf	btemp+1
	movlw	(0)^80h
	subwf	btemp+1,w
	skipz
	goto	u2725
	movlw	01h
	subwf	(dtoa@i),w
u2725:

	skipc
	goto	u2721
	goto	u2720
u2721:
	goto	l2507
u2720:
	
l2503:	
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movf	((dtoa@d)),w
iorwf	((dtoa@d+1)),w
	btfss	status,2
	goto	u2731
	goto	u2730
u2731:
	goto	l2491
u2730:
	
l2505:	
	movf	((dtoa@p)),w
	btfss	status,2
	goto	u2741
	goto	u2740
u2741:
	goto	l2491
u2740:
	line	576
	
l2507:	
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movf	((dtoa@s)),w
	btfsc	status,2
	goto	u2751
	goto	u2750
u2751:
	goto	l2513
u2750:
	line	577
	
l2509:	
	movlw	0FFh
	addwf	(dtoa@i),f
	skipnc
	incf	(dtoa@i+1),f
	movlw	0FFh
	addwf	(dtoa@i+1),f
	line	578
	
l2511:	
	movf	(dtoa@i),w
	addlw	low(_dbuf|((0x1)<<8))&0ffh
	movwf	fsr0
	movf	(dtoa@s),w
	bsf	status, 7	;select IRP bank3
	movwf	indf
	line	582
	
l2513:	
	movf	(dtoa@i),w
	addlw	low(_dbuf|((0x1)<<8))&0ffh
	movwf	(pad@buf)
	movf	(dtoa@w+1),w
	movwf	(pad@p+1)
	movf	(dtoa@w),w
	movwf	(pad@p)
	movf	(dtoa@fp),w
	fcall	_pad
	line	583
	
l833:	
	return
	callstack 0
GLOBAL	__end_of_dtoa
	__end_of_dtoa:
	signat	_dtoa,8313
	global	_pad

;; *************** function _pad *****************
;; Defined at:
;;		line 193 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/doprnt.c"
;; Parameters:    Size  Location     Type
;;  fp              1    wreg     PTR struct _IO_FILE
;;		 -> sprintf@f(11), 
;;  buf             1   11[COMMON] PTR unsigned char 
;;		 -> dbuf(32), 
;;  p               2   12[COMMON] int 
;; Auto vars:     Size  Location     Type
;;  fp              1    7[BANK0 ] PTR struct _IO_FILE
;;		 -> sprintf@f(11), 
;;  i               2    5[BANK0 ] int 
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         3       0       0       0       0
;;      Locals:         0       3       0       0       0
;;      Temps:          0       1       0       0       0
;;      Totals:         3       4       0       0       0
;;Total ram usage:        7 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 3
;; This function calls:
;;		_fputc
;;		_fputs
;; This function is called by:
;;		_dtoa
;;		_utoa
;; This function uses a non-reentrant model
;;
psect	text20,local,class=CODE,delta=2,merge=1,group=1
	line	193
global __ptext20
__ptext20:	;psect for function _pad
psect	text20
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/doprnt.c"
	line	193
	
_pad:	
;incstack = 0
;; hardware stack exceeded
	callstack 0
; Regs used in _pad: [wreg-fsr0h+status,2+status,0+pclath+cstack]
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(pad@fp)
	line	199
	
l1839:	
	btfss	(_flags),(0)&7
	goto	u1711
	goto	u1710
u1711:
	goto	l1843
u1710:
	line	200
	
l1841:	
	movf	(pad@fp),w
	movwf	(fputs@fp)
	movf	(pad@buf),w
	fcall	_fputs
	line	205
	
l1843:	
	btfss	(pad@p+1),7
	goto	u1721
	goto	u1720
u1721:
	goto	l798
u1720:
	line	206
	
l1845:	
	clrf	(pad@p)
	clrf	(pad@p+1)
	line	207
	
l798:	
	line	208
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	clrf	(pad@i)
	clrf	(pad@i+1)
	line	209
	goto	l1851
	line	210
	
l1847:	
	movlw	020h
	movwf	(fputc@c)
	movlw	0
	movwf	((fputc@c))+1
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movf	(pad@fp),w
	movwf	(fputc@fp)
	fcall	_fputc
	line	211
	
l1849:	
	movlw	01h
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	addwf	(pad@i),f
	skipnc
	incf	(pad@i+1),f
	movlw	0
	addwf	(pad@i+1),f
	line	209
	
l1851:	
	movf	(pad@i+1),w
	xorlw	80h
	movwf	(??_pad+0)+0
	movf	(pad@p+1),w
	xorlw	80h
	subwf	(??_pad+0)+0,w
	skipz
	goto	u1735
	movf	(pad@p),w
	subwf	(pad@i),w
u1735:

	skipc
	goto	u1731
	goto	u1730
u1731:
	goto	l1847
u1730:
	
l801:	
	line	216
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	btfsc	(_flags),(0)&7
	goto	u1741
	goto	u1740
u1741:
	goto	l803
u1740:
	line	218
	
l1853:	
	movf	(pad@fp),w
	movwf	(fputs@fp)
	movf	(pad@buf),w
	fcall	_fputs
	line	226
	
l803:	
	return
	callstack 0
GLOBAL	__end_of_pad
	__end_of_pad:
	signat	_pad,12409
	global	_fputs

;; *************** function _fputs *****************
;; Defined at:
;;		line 8 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/nf_fputs.c"
;; Parameters:    Size  Location     Type
;;  s               1    wreg     PTR const unsigned char 
;;		 -> dbuf(32), 
;;  fp              1    8[COMMON] PTR struct _IO_FILE
;;		 -> sprintf@f(11), 
;; Auto vars:     Size  Location     Type
;;  s               1    3[BANK0 ] PTR const unsigned char 
;;		 -> dbuf(32), 
;;  i               2    1[BANK0 ] int 
;;  c               1    0[BANK0 ] unsigned char 
;; Return value:  Size  Location     Type
;;                  2    8[COMMON] int 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         1       0       0       0       0
;;      Locals:         0       4       0       0       0
;;      Temps:          2       0       0       0       0
;;      Totals:         3       4       0       0       0
;;Total ram usage:        7 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 2
;; This function calls:
;;		_fputc
;; This function is called by:
;;		_pad
;; This function uses a non-reentrant model
;;
psect	text21,local,class=CODE,delta=2,merge=1,group=3
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/nf_fputs.c"
	line	8
global __ptext21
__ptext21:	;psect for function _fputs
psect	text21
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/nf_fputs.c"
	line	8
	
_fputs:	
;incstack = 0
;; hardware stack exceeded
	callstack 0
; Regs used in _fputs: [wreg-fsr0h+status,2+status,0+pclath+cstack]
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(fputs@s)
	line	13
	
l1687:	
	clrf	(fputs@i)
	clrf	(fputs@i+1)
	line	14
	goto	l1693
	line	15
	
l1689:	
	movf	(fputs@c),w
	movwf	(??_fputs+0)+0
	clrf	(??_fputs+0)+0+1
	movf	0+(??_fputs+0)+0,w
	movwf	(fputc@c)
	movf	1+(??_fputs+0)+0,w
	movwf	(fputc@c+1)
	movf	(fputs@fp),w
	movwf	(fputc@fp)
	fcall	_fputc
	line	16
	
l1691:	
	movlw	01h
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	addwf	(fputs@i),f
	skipnc
	incf	(fputs@i+1),f
	movlw	0
	addwf	(fputs@i+1),f
	line	14
	
l1693:	
	movf	(fputs@i),w
	addwf	(fputs@s),w
	movwf	(??_fputs+0)+0
	movf	0+(??_fputs+0)+0,w
	movwf	fsr0
	bsf	status, 7	;select IRP bank2
	movf	indf,w
	movwf	(fputs@c)
	movf	(((fputs@c))),w
	btfss	status,2
	goto	u1341
	goto	u1340
u1341:
	goto	l1689
u1340:
	line	19
	
l904:	
	return
	callstack 0
GLOBAL	__end_of_fputs
	__end_of_fputs:
	signat	_fputs,8314
	global	_abs

;; *************** function _abs *****************
;; Defined at:
;;		line 1 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/abs.c"
;; Parameters:    Size  Location     Type
;;  a               2    7[COMMON] int 
;; Auto vars:     Size  Location     Type
;;		None
;; Return value:  Size  Location     Type
;;                  2    7[COMMON] int 
;; Registers used:
;;		wreg, status,2, status,0
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         2       0       0       0       0
;;      Locals:         0       0       0       0       0
;;      Temps:          2       0       0       0       0
;;      Totals:         4       0       0       0       0
;;Total ram usage:        4 bytes
;; Hardware stack levels used: 1
;; This function calls:
;;		Nothing
;; This function is called by:
;;		_dtoa
;; This function uses a non-reentrant model
;;
psect	text22,local,class=CODE,delta=2,merge=1,group=3
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/abs.c"
	line	1
global __ptext22
__ptext22:	;psect for function _abs
psect	text22
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/abs.c"
	line	1
	
_abs:	
;incstack = 0
	callstack 2
; Regs used in _abs: [wreg+status,2+status,0]
	line	3
	
l1855:	
	btfsc	(abs@a+1),7
	goto	u1751
	goto	u1750
u1751:
	goto	l1859
u1750:
	
l1857:	
	goto	l884
	
l1859:	
	comf	(abs@a),w
	movwf	(??_abs+0)+0
	comf	(abs@a+1),w
	movwf	((??_abs+0)+0+1)
	incf	(??_abs+0)+0,f
	skipnz
	incf	((??_abs+0)+0+1),f
	movf	0+(??_abs+0)+0,w
	movwf	(?_abs)
	movf	1+(??_abs+0)+0,w
	movwf	(?_abs+1)
	line	4
	
l884:	
	return
	callstack 0
GLOBAL	__end_of_abs
	__end_of_abs:
	signat	_abs,4218
	global	___awmod

;; *************** function ___awmod *****************
;; Defined at:
;;		line 5 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/awmod.c"
;; Parameters:    Size  Location     Type
;;  divisor         2    0[COMMON] int 
;;  dividend        2    2[COMMON] int 
;; Auto vars:     Size  Location     Type
;;  sign            1    6[COMMON] unsigned char 
;;  counter         1    5[COMMON] unsigned char 
;; Return value:  Size  Location     Type
;;                  2    0[COMMON] int 
;; Registers used:
;;		wreg, status,2, status,0
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         4       0       0       0       0
;;      Locals:         2       0       0       0       0
;;      Temps:          1       0       0       0       0
;;      Totals:         7       0       0       0       0
;;Total ram usage:        7 bytes
;; Hardware stack levels used: 1
;; This function calls:
;;		Nothing
;; This function is called by:
;;		_main
;;		_process_keypress
;;		_dtoa
;; This function uses a non-reentrant model
;;
psect	text23,local,class=CODE,delta=2,merge=1,group=2
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/awmod.c"
	line	5
global __ptext23
__ptext23:	;psect for function ___awmod
psect	text23
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/awmod.c"
	line	5
	
___awmod:	
;incstack = 0
	callstack 6
; Regs used in ___awmod: [wreg+status,2+status,0]
	line	12
	
l2437:	
	clrf	(___awmod@sign)
	line	13
	
l2439:	
	btfss	(___awmod@dividend+1),7
	goto	u2591
	goto	u2590
u2591:
	goto	l2445
u2590:
	line	14
	
l2441:	
	comf	(___awmod@dividend),f
	comf	(___awmod@dividend+1),f
	incf	(___awmod@dividend),f
	skipnz
	incf	(___awmod@dividend+1),f
	line	15
	
l2443:	
	clrf	(___awmod@sign)
	incf	(___awmod@sign),f
	line	17
	
l2445:	
	btfss	(___awmod@divisor+1),7
	goto	u2601
	goto	u2600
u2601:
	goto	l2449
u2600:
	line	18
	
l2447:	
	comf	(___awmod@divisor),f
	comf	(___awmod@divisor+1),f
	incf	(___awmod@divisor),f
	skipnz
	incf	(___awmod@divisor+1),f
	line	19
	
l2449:	
	movf	((___awmod@divisor)),w
iorwf	((___awmod@divisor+1)),w
	btfsc	status,2
	goto	u2611
	goto	u2610
u2611:
	goto	l2467
u2610:
	line	20
	
l2451:	
	clrf	(___awmod@counter)
	incf	(___awmod@counter),f
	line	21
	goto	l2457
	line	22
	
l2453:	
	movlw	01h
	
u2625:
	clrc
	rlf	(___awmod@divisor),f
	rlf	(___awmod@divisor+1),f
	addlw	-1
	skipz
	goto	u2625
	line	23
	
l2455:	
	movlw	low(01h)
	movwf	(??___awmod+0)+0
	movf	(??___awmod+0)+0,w
	addwf	(___awmod@counter),f
	line	21
	
l2457:	
	btfss	(___awmod@divisor+1),(15)&7
	goto	u2631
	goto	u2630
u2631:
	goto	l2453
u2630:
	line	26
	
l2459:	
	movf	(___awmod@divisor+1),w
	subwf	(___awmod@dividend+1),w
	skipz
	goto	u2645
	movf	(___awmod@divisor),w
	subwf	(___awmod@dividend),w
u2645:
	skipc
	goto	u2641
	goto	u2640
u2641:
	goto	l2463
u2640:
	line	27
	
l2461:	
	movf	(___awmod@divisor),w
	subwf	(___awmod@dividend),f
	movf	(___awmod@divisor+1),w
	skipc
	decf	(___awmod@dividend+1),f
	subwf	(___awmod@dividend+1),f
	line	28
	
l2463:	
	movlw	01h
	
u2655:
	clrc
	rrf	(___awmod@divisor+1),f
	rrf	(___awmod@divisor),f
	addlw	-1
	skipz
	goto	u2655
	line	29
	
l2465:	
	movlw	01h
	subwf	(___awmod@counter),f
	btfss	status,2
	goto	u2661
	goto	u2660
u2661:
	goto	l2459
u2660:
	line	31
	
l2467:	
	movf	((___awmod@sign)),w
	btfsc	status,2
	goto	u2671
	goto	u2670
u2671:
	goto	l2471
u2670:
	line	32
	
l2469:	
	comf	(___awmod@dividend),f
	comf	(___awmod@dividend+1),f
	incf	(___awmod@dividend),f
	skipnz
	incf	(___awmod@dividend+1),f
	line	33
	
l2471:	
	movf	(___awmod@dividend+1),w
	movwf	(?___awmod+1)
	movf	(___awmod@dividend),w
	movwf	(?___awmod)
	line	34
	
l481:	
	return
	callstack 0
GLOBAL	__end_of___awmod
	__end_of___awmod:
	signat	___awmod,8314
	global	___awdiv

;; *************** function ___awdiv *****************
;; Defined at:
;;		line 5 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/awdiv.c"
;; Parameters:    Size  Location     Type
;;  divisor         2    0[COMMON] int 
;;  dividend        2    2[COMMON] int 
;; Auto vars:     Size  Location     Type
;;  quotient        2    7[COMMON] int 
;;  sign            1    6[COMMON] unsigned char 
;;  counter         1    5[COMMON] unsigned char 
;; Return value:  Size  Location     Type
;;                  2    0[COMMON] int 
;; Registers used:
;;		wreg, status,2, status,0
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         4       0       0       0       0
;;      Locals:         4       0       0       0       0
;;      Temps:          1       0       0       0       0
;;      Totals:         9       0       0       0       0
;;Total ram usage:        9 bytes
;; Hardware stack levels used: 1
;; This function calls:
;;		Nothing
;; This function is called by:
;;		_dtoa
;; This function uses a non-reentrant model
;;
psect	text24,local,class=CODE,delta=2,merge=1,group=2
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/awdiv.c"
	line	5
global __ptext24
__ptext24:	;psect for function ___awdiv
psect	text24
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/awdiv.c"
	line	5
	
___awdiv:	
;incstack = 0
	callstack 2
; Regs used in ___awdiv: [wreg+status,2+status,0]
	line	13
	
l1709:	
	clrf	(___awdiv@sign)
	line	14
	
l1711:	
	btfss	(___awdiv@divisor+1),7
	goto	u1391
	goto	u1390
u1391:
	goto	l1717
u1390:
	line	15
	
l1713:	
	comf	(___awdiv@divisor),f
	comf	(___awdiv@divisor+1),f
	incf	(___awdiv@divisor),f
	skipnz
	incf	(___awdiv@divisor+1),f
	line	16
	
l1715:	
	clrf	(___awdiv@sign)
	incf	(___awdiv@sign),f
	line	18
	
l1717:	
	btfss	(___awdiv@dividend+1),7
	goto	u1401
	goto	u1400
u1401:
	goto	l1723
u1400:
	line	19
	
l1719:	
	comf	(___awdiv@dividend),f
	comf	(___awdiv@dividend+1),f
	incf	(___awdiv@dividend),f
	skipnz
	incf	(___awdiv@dividend+1),f
	line	20
	
l1721:	
	movlw	low(01h)
	movwf	(??___awdiv+0)+0
	movf	(??___awdiv+0)+0,w
	xorwf	(___awdiv@sign),f
	line	22
	
l1723:	
	clrf	(___awdiv@quotient)
	clrf	(___awdiv@quotient+1)
	line	23
	
l1725:	
	movf	((___awdiv@divisor)),w
iorwf	((___awdiv@divisor+1)),w
	btfsc	status,2
	goto	u1411
	goto	u1410
u1411:
	goto	l1745
u1410:
	line	24
	
l1727:	
	clrf	(___awdiv@counter)
	incf	(___awdiv@counter),f
	line	25
	goto	l1733
	line	26
	
l1729:	
	movlw	01h
	
u1425:
	clrc
	rlf	(___awdiv@divisor),f
	rlf	(___awdiv@divisor+1),f
	addlw	-1
	skipz
	goto	u1425
	line	27
	
l1731:	
	movlw	low(01h)
	movwf	(??___awdiv+0)+0
	movf	(??___awdiv+0)+0,w
	addwf	(___awdiv@counter),f
	line	25
	
l1733:	
	btfss	(___awdiv@divisor+1),(15)&7
	goto	u1431
	goto	u1430
u1431:
	goto	l1729
u1430:
	line	30
	
l1735:	
	movlw	01h
	
u1445:
	clrc
	rlf	(___awdiv@quotient),f
	rlf	(___awdiv@quotient+1),f
	addlw	-1
	skipz
	goto	u1445
	line	31
	movf	(___awdiv@divisor+1),w
	subwf	(___awdiv@dividend+1),w
	skipz
	goto	u1455
	movf	(___awdiv@divisor),w
	subwf	(___awdiv@dividend),w
u1455:
	skipc
	goto	u1451
	goto	u1450
u1451:
	goto	l1741
u1450:
	line	32
	
l1737:	
	movf	(___awdiv@divisor),w
	subwf	(___awdiv@dividend),f
	movf	(___awdiv@divisor+1),w
	skipc
	decf	(___awdiv@dividend+1),f
	subwf	(___awdiv@dividend+1),f
	line	33
	
l1739:	
	bsf	(___awdiv@quotient)+(0/8),(0)&7
	line	35
	
l1741:	
	movlw	01h
	
u1465:
	clrc
	rrf	(___awdiv@divisor+1),f
	rrf	(___awdiv@divisor),f
	addlw	-1
	skipz
	goto	u1465
	line	36
	
l1743:	
	movlw	01h
	subwf	(___awdiv@counter),f
	btfss	status,2
	goto	u1471
	goto	u1470
u1471:
	goto	l1735
u1470:
	line	38
	
l1745:	
	movf	((___awdiv@sign)),w
	btfsc	status,2
	goto	u1481
	goto	u1480
u1481:
	goto	l1749
u1480:
	line	39
	
l1747:	
	comf	(___awdiv@quotient),f
	comf	(___awdiv@quotient+1),f
	incf	(___awdiv@quotient),f
	skipnz
	incf	(___awdiv@quotient+1),f
	line	40
	
l1749:	
	movf	(___awdiv@quotient+1),w
	movwf	(?___awdiv+1)
	movf	(___awdiv@quotient),w
	movwf	(?___awdiv)
	line	41
	
l468:	
	return
	callstack 0
GLOBAL	__end_of___awdiv
	__end_of___awdiv:
	signat	___awdiv,8314
	global	_ctoa

;; *************** function _ctoa *****************
;; Defined at:
;;		line 476 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/doprnt.c"
;; Parameters:    Size  Location     Type
;;  fp              1    wreg     PTR struct _IO_FILE
;;		 -> sprintf@f(11), 
;;  c               1    8[COMMON] unsigned char 
;; Auto vars:     Size  Location     Type
;;  fp              1    4[BANK0 ] PTR struct _IO_FILE
;;		 -> sprintf@f(11), 
;;  w               2    2[BANK0 ] int 
;;  l               2    0[BANK0 ] int 
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         1       0       0       0       0
;;      Locals:         0       5       0       0       0
;;      Temps:          2       0       0       0       0
;;      Totals:         3       5       0       0       0
;;Total ram usage:        8 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 2
;; This function calls:
;;		_fputc
;; This function is called by:
;;		_vfpfcnvrt
;; This function uses a non-reentrant model
;;
psect	text25,local,class=CODE,delta=2,merge=1,group=1
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/doprnt.c"
	line	476
global __ptext25
__ptext25:	;psect for function _ctoa
psect	text25
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/doprnt.c"
	line	476
	
_ctoa:	
;incstack = 0
	callstack 1
; Regs used in _ctoa: [wreg-fsr0h+status,2+status,0+pclath+cstack]
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	(ctoa@fp)
	line	481
	
l1863:	
	movf	((_width)),w
iorwf	((_width+1)),w
	btfss	status,2
	goto	u1761
	goto	u1760
u1761:
	goto	l1867
u1760:
	
l1865:	
	movf	(_width+1),w
	movwf	(ctoa@w+1)
	movf	(_width),w
	movwf	(ctoa@w)
	goto	l1869
	
l1867:	
	movf	(_width),w
	addlw	low(-1)
	movwf	(ctoa@w)
	movf	(_width+1),w
	skipnc
	addlw	1
	addlw	high(-1)
	movwf	1+(ctoa@w)
	line	485
	
l1869:	
	btfss	(_flags),(0)&7
	goto	u1771
	goto	u1770
u1771:
	goto	l1873
u1770:
	line	486
	
l1871:	
	movf	(ctoa@c),w
	movwf	(??_ctoa+0)+0
	clrf	(??_ctoa+0)+0+1
	movf	0+(??_ctoa+0)+0,w
	movwf	(fputc@c)
	movf	1+(??_ctoa+0)+0,w
	movwf	(fputc@c+1)
	movf	(ctoa@fp),w
	movwf	(fputc@fp)
	fcall	_fputc
	line	491
	
l1873:	
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	btfsc	(ctoa@w+1),7
	goto	u1781
	goto	u1780
u1781:
	goto	l1877
u1780:
	goto	l814
	
l1877:	
	clrf	(ctoa@w)
	clrf	(ctoa@w+1)
	
l814:	
	line	492
	clrf	(ctoa@l)
	clrf	(ctoa@l+1)
	line	493
	goto	l1883
	line	494
	
l1879:	
	movlw	020h
	movwf	(fputc@c)
	movlw	0
	movwf	((fputc@c))+1
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movf	(ctoa@fp),w
	movwf	(fputc@fp)
	fcall	_fputc
	line	495
	
l1881:	
	movlw	01h
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	addwf	(ctoa@l),f
	skipnc
	incf	(ctoa@l+1),f
	movlw	0
	addwf	(ctoa@l+1),f
	line	493
	
l1883:	
	movf	(ctoa@l+1),w
	xorlw	80h
	movwf	(??_ctoa+0)+0
	movf	(ctoa@w+1),w
	xorlw	80h
	subwf	(??_ctoa+0)+0,w
	skipz
	goto	u1795
	movf	(ctoa@w),w
	subwf	(ctoa@l),w
u1795:

	skipc
	goto	u1791
	goto	u1790
u1791:
	goto	l1879
u1790:
	
l817:	
	line	499
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	btfsc	(_flags),(0)&7
	goto	u1801
	goto	u1800
u1801:
	goto	l819
u1800:
	line	501
	
l1885:	
	movf	(ctoa@c),w
	movwf	(??_ctoa+0)+0
	clrf	(??_ctoa+0)+0+1
	movf	0+(??_ctoa+0)+0,w
	movwf	(fputc@c)
	movf	1+(??_ctoa+0)+0,w
	movwf	(fputc@c+1)
	movf	(ctoa@fp),w
	movwf	(fputc@fp)
	fcall	_fputc
	line	509
	
l819:	
	return
	callstack 0
GLOBAL	__end_of_ctoa
	__end_of_ctoa:
	signat	_ctoa,8313
	global	_fputc

;; *************** function _fputc *****************
;; Defined at:
;;		line 8 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/nf_fputc.c"
;; Parameters:    Size  Location     Type
;;  c               2    0[COMMON] int 
;;  fp              1    2[COMMON] PTR struct _IO_FILE
;;		 -> sprintf@f(11), 
;; Auto vars:     Size  Location     Type
;;		None
;; Return value:  Size  Location     Type
;;                  2    0[COMMON] int 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         3       0       0       0       0
;;      Locals:         0       0       0       0       0
;;      Temps:          5       0       0       0       0
;;      Totals:         8       0       0       0       0
;;Total ram usage:        8 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 1
;; This function calls:
;;		_putch
;; This function is called by:
;;		_pad
;;		_ctoa
;;		_vfpfcnvrt
;;		_fputs
;; This function uses a non-reentrant model
;;
psect	text26,local,class=CODE,delta=2,merge=1,group=3
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/nf_fputc.c"
	line	8
global __ptext26
__ptext26:	;psect for function _fputc
psect	text26
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/nf_fputc.c"
	line	8
	
_fputc:	
;incstack = 0
;; hardware stack exceeded
	callstack 0
; Regs used in _fputc: [wreg-fsr0h+status,2+status,0+pclath+cstack]
	line	12
	
l1673:	
	movf	((fputc@fp)),w
	btfsc	status,2
	goto	u1301
	goto	u1300
u1301:
	goto	l1677
u1300:
	
l1675:	
	movf	((fputc@fp)),w
	btfss	status,2
	goto	u1311
	goto	u1310
u1311:
	goto	l1679
u1310:
	line	13
	
l1677:	
	movf	(fputc@c),w
	fcall	_putch
	line	14
	goto	l896
	line	15
	
l1679:	
	movf	(fputc@fp),w
	addlw	09h
	movwf	fsr0
	bcf	status, 7	;select IRP bank0
	movf	indf,w
	movwf	(??_fputc+0)+0+0
	incf	fsr0,f
	movf	indf,w
	movwf	(??_fputc+0)+0+1
	movf	((??_fputc+0)+0),w
iorwf	((??_fputc+0)+1),w
	btfsc	status,2
	goto	u1321
	goto	u1320
u1321:
	goto	l1683
u1320:
	
l1681:	
	movf	(fputc@fp),w
	addlw	09h
	movwf	fsr0
	movf	indf,w
	movwf	(??_fputc+0)+0+0
	incf	fsr0,f
	movf	indf,w
	movwf	(??_fputc+0)+0+1
	movf	(fputc@fp),w
	addlw	02h
	movwf	fsr0
	movf	indf,w
	movwf	(??_fputc+2)+0+0
	incf	fsr0,f
	movf	indf,w
	movwf	(??_fputc+2)+0+1
	movf	1+(??_fputc+2)+0,w
	xorlw	80h
	movwf	(??_fputc+4)+0
	movf	1+(??_fputc+0)+0,w
	xorlw	80h
	subwf	(??_fputc+4)+0,w
	skipz
	goto	u1335
	movf	0+(??_fputc+0)+0,w
	subwf	0+(??_fputc+2)+0,w
u1335:

	skipnc
	goto	u1331
	goto	u1330
u1331:
	goto	l896
u1330:
	line	18
	
l1683:	
	movf	(fputc@fp),w
	addlw	02h
	movwf	fsr
	bcf	status, 7	;select IRP bank0
	movf	indf,w
	movwf	(??_fputc+0)+0
	movf	(fputc@fp),w
	movwf	fsr0
	movf	indf,w
	addwf	(??_fputc+0)+0,w
	movwf	(??_fputc+1)+0
	movf	0+(??_fputc+1)+0,w
	movwf	fsr0
	movf	(fputc@c),w
	movwf	indf
	line	20
	movf	(fputc@fp),w
	addlw	02h
	movwf	fsr0
	movlw	01h
	addwf	indf,f
	incf	fsr0,f
	skipnc
	incf	indf,f
	line	24
	
l896:	
	return
	callstack 0
GLOBAL	__end_of_fputc
	__end_of_fputc:
	signat	_fputc,8314
	global	_putch

;; *************** function _putch *****************
;; Defined at:
;;		line 7 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/putch.c"
;; Parameters:    Size  Location     Type
;;  c               1    wreg     unsigned char 
;; Auto vars:     Size  Location     Type
;;  c               1    0[COMMON] unsigned char 
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       0       0       0       0
;;      Locals:         0       0       0       0       0
;;      Temps:          0       0       0       0       0
;;      Totals:         0       0       0       0       0
;;Total ram usage:        0 bytes
;; Hardware stack levels used: 1
;; This function calls:
;;		Nothing
;; This function is called by:
;;		_fputc
;; This function uses a non-reentrant model
;;
psect	text27,local,class=CODE,delta=2,merge=1,group=3
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/putch.c"
	line	7
global __ptext27
__ptext27:	;psect for function _putch
psect	text27
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/putch.c"
	line	7
	
_putch:	
;incstack = 0
;; hardware stack exceeded
	callstack 0
; Regs used in _putch: [wreg]
	line	9
	
l907:	
	return
	callstack 0
GLOBAL	__end_of_putch
	__end_of_putch:
	signat	_putch,4217
	global	_lcd_set_cursor

;; *************** function _lcd_set_cursor *****************
;; Defined at:
;;		line 29 in file "lcd.c"
;; Parameters:    Size  Location     Type
;;  row             1    wreg     unsigned char 
;;  col             1    3[COMMON] unsigned char 
;; Auto vars:     Size  Location     Type
;;  row             1    4[COMMON] unsigned char 
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg, status,2, status,0, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         1       0       0       0       0
;;      Locals:         3       0       0       0       0
;;      Temps:          0       0       0       0       0
;;      Totals:         4       0       0       0       0
;;Total ram usage:        4 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 1
;; This function calls:
;;		_lcd_send_cmd
;; This function is called by:
;;		_lcd_show_zone
;;		_main
;; This function uses a non-reentrant model
;;
psect	text28,local,class=CODE,delta=2,merge=1,group=0
	file	"lcd.c"
	line	29
global __ptext28
__ptext28:	;psect for function _lcd_set_cursor
psect	text28
	file	"lcd.c"
	line	29
	
_lcd_set_cursor:	
;incstack = 0
	callstack 5
; Regs used in _lcd_set_cursor: [wreg+status,2+status,0+pclath+cstack]
	movwf	(lcd_set_cursor@row)
	line	30
	
l2095:	
	movf	((lcd_set_cursor@row)),w
	btfsc	status,2
	goto	u2051
	goto	u2050
u2051:
	goto	l2099
u2050:
	
l2097:	
	movlw	0C0h
	movwf	(_lcd_set_cursor$186)
	movlw	0
	movwf	((_lcd_set_cursor$186))+1
	goto	l2101
	
l2099:	
	movlw	080h
	movwf	(_lcd_set_cursor$186)
	movlw	0
	movwf	((_lcd_set_cursor$186))+1
	
l2101:	
	movf	(lcd_set_cursor@col),w
	addwf	(_lcd_set_cursor$186),w
	fcall	_lcd_send_cmd
	line	31
	
l118:	
	return
	callstack 0
GLOBAL	__end_of_lcd_set_cursor
	__end_of_lcd_set_cursor:
	signat	_lcd_set_cursor,8313
	global	_lcd_send_string

;; *************** function _lcd_send_string *****************
;; Defined at:
;;		line 25 in file "lcd.c"
;; Parameters:    Size  Location     Type
;;  str             2    3[COMMON] PTR const unsigned char 
;;		 -> STR_10(17), STR_9(17), lcd_show_zone@line2(17), lcd_show_zone@line1(17), 
;; Auto vars:     Size  Location     Type
;;		None
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, btemp+1, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         2       0       0       0       0
;;      Locals:         0       0       0       0       0
;;      Temps:          0       0       0       0       0
;;      Totals:         2       0       0       0       0
;;Total ram usage:        2 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 1
;; This function calls:
;;		_lcd_send_char
;; This function is called by:
;;		_lcd_show_zone
;;		_main
;; This function uses a non-reentrant model
;;
psect	text29,local,class=CODE,delta=2,merge=1,group=0
	line	25
global __ptext29
__ptext29:	;psect for function _lcd_send_string
psect	text29
	file	"lcd.c"
	line	25
	
_lcd_send_string:	
;incstack = 0
	callstack 5
; Regs used in _lcd_send_string: [wreg-fsr0h+status,2+status,0+btemp+1+pclath+cstack]
	line	26
	
l2103:	
	goto	l2109
	
l2105:	
	movf	(lcd_send_string@str+1),w
	movwf	btemp+1
	movf	(lcd_send_string@str),w
	movwf	fsr0
	fcall	stringtab
	fcall	_lcd_send_char
	
l2107:	
	movlw	01h
	addwf	(lcd_send_string@str),f
	skipnc
	incf	(lcd_send_string@str+1),f
	movlw	0
	addwf	(lcd_send_string@str+1),f
	
l2109:	
	movf	(lcd_send_string@str+1),w
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	movwf	btemp+1
	movf	(lcd_send_string@str),w
	movwf	fsr0
	fcall	stringtab
	xorlw	0
	skipz
	goto	u2061
	goto	u2060
u2061:
	goto	l2105
u2060:
	line	27
	
l111:	
	return
	callstack 0
GLOBAL	__end_of_lcd_send_string
	__end_of_lcd_send_string:
	signat	_lcd_send_string,4217
	global	_lcd_send_char

;; *************** function _lcd_send_char *****************
;; Defined at:
;;		line 16 in file "lcd.c"
;; Parameters:    Size  Location     Type
;;  ch              1    wreg     unsigned char 
;; Auto vars:     Size  Location     Type
;;  ch              1    2[COMMON] unsigned char 
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       0       0       0       0
;;      Locals:         1       0       0       0       0
;;      Temps:          2       0       0       0       0
;;      Totals:         3       0       0       0       0
;;Total ram usage:        3 bytes
;; Hardware stack levels used: 1
;; This function calls:
;;		Nothing
;; This function is called by:
;;		_lcd_send_string
;; This function uses a non-reentrant model
;;
psect	text30,local,class=CODE,delta=2,merge=1,group=0
	line	16
global __ptext30
__ptext30:	;psect for function _lcd_send_char
psect	text30
	file	"lcd.c"
	line	16
	
_lcd_send_char:	
;incstack = 0
	callstack 5
; Regs used in _lcd_send_char: [wreg]
	movwf	(lcd_send_char@ch)
	line	17
	
l2047:	
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	bsf	(74/8),(74)&7	;volatile
	line	18
	
l2049:	
	movf	(lcd_send_char@ch),w
	movwf	(8)	;volatile
	line	19
	
l2051:	
	bcf	(73/8),(73)&7	;volatile
	line	20
	asmopt push
asmopt off
movlw	6
movwf	((??_lcd_send_char+0)+0+1)
	movlw	48
movwf	((??_lcd_send_char+0)+0)
	u3237:
decfsz	((??_lcd_send_char+0)+0),f
	goto	u3237
	decfsz	((??_lcd_send_char+0)+0+1),f
	goto	u3237
	nop
asmopt pop

	line	21
	
l2053:	
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	bsf	(73/8),(73)&7	;volatile
	line	22
	asmopt push
asmopt off
movlw	6
movwf	((??_lcd_send_char+0)+0+1)
	movlw	48
movwf	((??_lcd_send_char+0)+0)
	u3247:
decfsz	((??_lcd_send_char+0)+0),f
	goto	u3247
	decfsz	((??_lcd_send_char+0)+0+1),f
	goto	u3247
	nop
asmopt pop

	line	23
	
l105:	
	return
	callstack 0
GLOBAL	__end_of_lcd_send_char
	__end_of_lcd_send_char:
	signat	_lcd_send_char,4217
	global	_lcd_init

;; *************** function _lcd_init *****************
;; Defined at:
;;		line 38 in file "lcd.c"
;; Parameters:    Size  Location     Type
;;		None
;; Auto vars:     Size  Location     Type
;;		None
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg, status,2, status,0, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       0       0       0       0
;;      Locals:         0       0       0       0       0
;;      Temps:          2       0       0       0       0
;;      Totals:         2       0       0       0       0
;;Total ram usage:        2 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 1
;; This function calls:
;;		_lcd_send_cmd
;; This function is called by:
;;		_main
;; This function uses a non-reentrant model
;;
psect	text31,local,class=CODE,delta=2,merge=1,group=0
	line	38
global __ptext31
__ptext31:	;psect for function _lcd_init
psect	text31
	file	"lcd.c"
	line	38
	
_lcd_init:	
;incstack = 0
	callstack 6
; Regs used in _lcd_init: [wreg+status,2+status,0+pclath+cstack]
	line	40
	
l2267:	
	bsf	status, 5	;RP0=1, select bank1
	bcf	status, 6	;RP1=0, select bank1
	bcf	(1097/8)^080h,(1097)&7	;volatile
	line	41
	bcf	(1098/8)^080h,(1098)&7	;volatile
	line	42
	
l2269:	
	clrf	(136)^080h	;volatile
	line	43
	clrf	(137)^080h	;volatile
	line	46
	
l2271:	
	movlw	low(06h)
	movwf	(159)^080h	;volatile
	line	49
	
l2273:	
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	bsf	(73/8),(73)&7	;volatile
	line	50
	
l2275:	
	bcf	(74/8),(74)&7	;volatile
	line	51
	
l2277:	
	clrf	(8)	;volatile
	line	53
	asmopt push
asmopt off
movlw	65
movwf	((??_lcd_init+0)+0+1)
	movlw	238
movwf	((??_lcd_init+0)+0)
	u3257:
decfsz	((??_lcd_init+0)+0),f
	goto	u3257
	decfsz	((??_lcd_init+0)+0+1),f
	goto	u3257
	nop
asmopt pop

	line	56
	
l2279:	
	movlw	low(038h)
	fcall	_lcd_send_cmd
	line	57
	
l2281:	
	movlw	low(0Ch)
	fcall	_lcd_send_cmd
	line	58
	
l2283:	
	movlw	low(06h)
	fcall	_lcd_send_cmd
	line	59
	
l2285:	
	movlw	low(01h)
	fcall	_lcd_send_cmd
	line	60
	asmopt push
asmopt off
movlw	6
movwf	((??_lcd_init+0)+0+1)
	movlw	48
movwf	((??_lcd_init+0)+0)
	u3267:
decfsz	((??_lcd_init+0)+0),f
	goto	u3267
	decfsz	((??_lcd_init+0)+0+1),f
	goto	u3267
	nop
asmopt pop

	line	61
	
l124:	
	return
	callstack 0
GLOBAL	__end_of_lcd_init
	__end_of_lcd_init:
	signat	_lcd_init,89
	global	_lcd_clear

;; *************** function _lcd_clear *****************
;; Defined at:
;;		line 33 in file "lcd.c"
;; Parameters:    Size  Location     Type
;;		None
;; Auto vars:     Size  Location     Type
;;		None
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg, status,2, status,0, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       0       0       0       0
;;      Locals:         0       0       0       0       0
;;      Temps:          2       0       0       0       0
;;      Totals:         2       0       0       0       0
;;Total ram usage:        2 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 1
;; This function calls:
;;		_lcd_send_cmd
;; This function is called by:
;;		_main
;; This function uses a non-reentrant model
;;
psect	text32,local,class=CODE,delta=2,merge=1,group=0
	line	33
global __ptext32
__ptext32:	;psect for function _lcd_clear
psect	text32
	file	"lcd.c"
	line	33
	
_lcd_clear:	
;incstack = 0
	callstack 6
; Regs used in _lcd_clear: [wreg+status,2+status,0+pclath+cstack]
	line	34
	
l2293:	
	movlw	low(01h)
	fcall	_lcd_send_cmd
	line	35
	
l2295:	
	asmopt push
asmopt off
movlw	6
movwf	((??_lcd_clear+0)+0+1)
	movlw	48
movwf	((??_lcd_clear+0)+0)
	u3277:
decfsz	((??_lcd_clear+0)+0),f
	goto	u3277
	decfsz	((??_lcd_clear+0)+0+1),f
	goto	u3277
	nop
asmopt pop

	line	36
	
l121:	
	return
	callstack 0
GLOBAL	__end_of_lcd_clear
	__end_of_lcd_clear:
	signat	_lcd_clear,89
	global	_lcd_send_cmd

;; *************** function _lcd_send_cmd *****************
;; Defined at:
;;		line 7 in file "lcd.c"
;; Parameters:    Size  Location     Type
;;  cmd             1    wreg     unsigned char 
;; Auto vars:     Size  Location     Type
;;  cmd             1    2[COMMON] unsigned char 
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       0       0       0       0
;;      Locals:         1       0       0       0       0
;;      Temps:          2       0       0       0       0
;;      Totals:         3       0       0       0       0
;;Total ram usage:        3 bytes
;; Hardware stack levels used: 1
;; This function calls:
;;		Nothing
;; This function is called by:
;;		_lcd_set_cursor
;;		_lcd_clear
;;		_lcd_init
;; This function uses a non-reentrant model
;;
psect	text33,local,class=CODE,delta=2,merge=1,group=0
	line	7
global __ptext33
__ptext33:	;psect for function _lcd_send_cmd
psect	text33
	file	"lcd.c"
	line	7
	
_lcd_send_cmd:	
;incstack = 0
	callstack 5
; Regs used in _lcd_send_cmd: [wreg]
	movwf	(lcd_send_cmd@cmd)
	line	8
	
l2039:	
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	bcf	(74/8),(74)&7	;volatile
	line	9
	
l2041:	
	movf	(lcd_send_cmd@cmd),w
	movwf	(8)	;volatile
	line	10
	
l2043:	
	bcf	(73/8),(73)&7	;volatile
	line	11
	asmopt push
asmopt off
movlw	6
movwf	((??_lcd_send_cmd+0)+0+1)
	movlw	48
movwf	((??_lcd_send_cmd+0)+0)
	u3287:
decfsz	((??_lcd_send_cmd+0)+0),f
	goto	u3287
	decfsz	((??_lcd_send_cmd+0)+0+1),f
	goto	u3287
	nop
asmopt pop

	line	12
	
l2045:	
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	bsf	(73/8),(73)&7	;volatile
	line	13
	asmopt push
asmopt off
movlw	6
movwf	((??_lcd_send_cmd+0)+0+1)
	movlw	48
movwf	((??_lcd_send_cmd+0)+0)
	u3297:
decfsz	((??_lcd_send_cmd+0)+0),f
	goto	u3297
	decfsz	((??_lcd_send_cmd+0)+0+1),f
	goto	u3297
	nop
asmopt pop

	line	14
	
l102:	
	return
	callstack 0
GLOBAL	__end_of_lcd_send_cmd
	__end_of_lcd_send_cmd:
	signat	_lcd_send_cmd,4217
	global	_keypad_scan

;; *************** function _keypad_scan *****************
;; Defined at:
;;		line 25 in file "keypad.c"
;; Parameters:    Size  Location     Type
;;		None
;; Auto vars:     Size  Location     Type
;;  row_pins        4    6[COMMON] unsigned char [4]
;;  col             1   11[COMMON] unsigned char 
;;  row             1   10[COMMON] unsigned char 
;; Return value:  Size  Location     Type
;;                  1    wreg      unsigned char 
;; Registers used:
;;		wreg, fsr0l, fsr0h, status,2, status,0, pclath, cstack
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       0       0       0       0
;;      Locals:         6       0       0       0       0
;;      Temps:          2       0       0       0       0
;;      Totals:         8       0       0       0       0
;;Total ram usage:        8 bytes
;; Hardware stack levels used: 1
;; Hardware stack levels required when called: 1
;; This function calls:
;;		___bmul
;; This function is called by:
;;		_main
;; This function uses a non-reentrant model
;;
psect	text34,local,class=CODE,delta=2,merge=1,group=0
	file	"keypad.c"
	line	25
global __ptext34
__ptext34:	;psect for function _keypad_scan
psect	text34
	file	"keypad.c"
	line	25
	
_keypad_scan:	
;incstack = 0
	callstack 6
; Regs used in _keypad_scan: [wreg-fsr0h+status,2+status,0+pclath+cstack]
	line	29
	
l2673:	
	bsf	status, 5	;RP0=1, select bank1
	bcf	status, 6	;RP1=0, select bank1
	movf	(keypad_scan@F1012+3)^080h,w
	movwf	(keypad_scan@row_pins+3)
	movf	(keypad_scan@F1012+2)^080h,w
	movwf	(keypad_scan@row_pins+2)
	movf	(keypad_scan@F1012+1)^080h,w
	movwf	(keypad_scan@row_pins+1)
	movf	(keypad_scan@F1012)^080h,w
	movwf	(keypad_scan@row_pins)

	line	31
	
l2675:	
	clrf	(keypad_scan@row)
	line	33
	
l2681:	
	movlw	low(0Fh)
	movwf	(??_keypad_scan+0)+0
	movf	(??_keypad_scan+0)+0,w
	bcf	status, 5	;RP0=0, select bank0
	iorwf	(8),f	;volatile
	line	36
	
l2683:	
	movlw	low(01h)
	movwf	(??_keypad_scan+0)+0
	movf	(keypad_scan@row),w
	addlw	low(keypad_scan@row_pins|((0x00)<<8))&0ffh
	movwf	fsr0
	incf	indf,w
	goto	u3024
u3025:
	clrc
	rlf	(??_keypad_scan+0)+0,f
u3024:
	addlw	-1
	skipz
	goto	u3025
	movf	0+(??_keypad_scan+0)+0,w
	xorlw	0ffh
	movwf	(??_keypad_scan+1)+0
	movf	(??_keypad_scan+1)+0,w
	andwf	(8),f	;volatile
	line	38
	
l2685:	
	asmopt push
asmopt off
	movlw	6
movwf	((??_keypad_scan+0)+0)
	u3307:
decfsz	(??_keypad_scan+0)+0,f
	goto	u3307
	nop
asmopt pop

	line	41
	
l2687:	
	clrf	(keypad_scan@col)
	line	42
	
l2693:	
	movlw	low(01h)
	movwf	(??_keypad_scan+0)+0
	incf	(keypad_scan@col),w
	goto	u3034
u3035:
	clrc
	rlf	(??_keypad_scan+0)+0,f
u3034:
	addlw	-1
	skipz
	goto	u3035
	movf	0+(??_keypad_scan+0)+0,w
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	andwf	(6),w	;volatile
	btfss	status,2
	goto	u3041
	goto	u3040
u3041:
	goto	l2707
u3040:
	line	43
	
l2695:	
	asmopt push
asmopt off
movlw	52
movwf	((??_keypad_scan+0)+0+1)
	movlw	241
movwf	((??_keypad_scan+0)+0)
	u3317:
decfsz	((??_keypad_scan+0)+0),f
	goto	u3317
	decfsz	((??_keypad_scan+0)+0+1),f
	goto	u3317
	nop2
asmopt pop

	line	46
	
l2697:	
	movlw	low(01h)
	movwf	(??_keypad_scan+0)+0
	incf	(keypad_scan@col),w
	goto	u3054
u3055:
	clrc
	rlf	(??_keypad_scan+0)+0,f
u3054:
	addlw	-1
	skipz
	goto	u3055
	movf	0+(??_keypad_scan+0)+0,w
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	andwf	(6),w	;volatile
	btfsc	status,2
	goto	u3061
	goto	u3060
u3061:
	goto	l2697
u3060:
	line	47
	
l2699:	
	asmopt push
asmopt off
movlw	26
movwf	((??_keypad_scan+0)+0+1)
	movlw	248
movwf	((??_keypad_scan+0)+0)
	u3327:
decfsz	((??_keypad_scan+0)+0),f
	goto	u3327
	decfsz	((??_keypad_scan+0)+0+1),f
	goto	u3327
	nop
asmopt pop

	line	50
	
l2701:	
	movlw	low(0Fh)
	movwf	(??_keypad_scan+0)+0
	movf	(??_keypad_scan+0)+0,w
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	iorwf	(8),f	;volatile
	line	52
	
l2703:	
	movlw	low(03h)
	movwf	(___bmul@multiplicand)
	movf	(keypad_scan@row),w
	fcall	___bmul
	addwf	(keypad_scan@col),w
	goto	l150
	line	54
	
l2707:	
	movlw	low(01h)
	movwf	(??_keypad_scan+0)+0
	movf	(??_keypad_scan+0)+0,w
	addwf	(keypad_scan@col),f
	
l2709:	
	movlw	low(03h)
	subwf	(keypad_scan@col),w
	skipc
	goto	u3071
	goto	u3070
u3071:
	goto	l2693
u3070:
	line	55
	
l2711:	
	movlw	low(01h)
	movwf	(??_keypad_scan+0)+0
	movf	(??_keypad_scan+0)+0,w
	addwf	(keypad_scan@row),f
	
l2713:	
	movlw	low(04h)
	subwf	(keypad_scan@row),w
	skipc
	goto	u3081
	goto	u3080
u3081:
	goto	l2681
u3080:
	line	58
	
l2715:	
	movlw	low(0Fh)
	movwf	(??_keypad_scan+0)+0
	movf	(??_keypad_scan+0)+0,w
	iorwf	(8),f	;volatile
	line	59
	
l2717:	
	movlw	low(0FFh)
	line	60
	
l150:	
	return
	callstack 0
GLOBAL	__end_of_keypad_scan
	__end_of_keypad_scan:
	signat	_keypad_scan,89
	global	___bmul

;; *************** function ___bmul *****************
;; Defined at:
;;		line 4 in file "/opt/microchip/xc8/v2.46/pic/sources/c99/common/Umul8.c"
;; Parameters:    Size  Location     Type
;;  multiplier      1    wreg     unsigned char 
;;  multiplicand    1    0[COMMON] unsigned char 
;; Auto vars:     Size  Location     Type
;;  multiplier      1    3[COMMON] unsigned char 
;;  product         1    2[COMMON] unsigned char 
;; Return value:  Size  Location     Type
;;                  1    wreg      unsigned char 
;; Registers used:
;;		wreg, status,2, status,0
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         1       0       0       0       0
;;      Locals:         2       0       0       0       0
;;      Temps:          1       0       0       0       0
;;      Totals:         4       0       0       0       0
;;Total ram usage:        4 bytes
;; Hardware stack levels used: 1
;; This function calls:
;;		Nothing
;; This function is called by:
;;		_lcd_show_zone
;;		_send_uart_all_zones
;;		_keypad_scan
;;		_zones_init
;;		_update_zone_mode
;;		_process_keypress
;; This function uses a non-reentrant model
;;
psect	text35,local,class=CODE,delta=2,merge=1,group=2
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/Umul8.c"
	line	4
global __ptext35
__ptext35:	;psect for function ___bmul
psect	text35
	file	"/opt/microchip/xc8/v2.46/pic/sources/c99/common/Umul8.c"
	line	4
	
___bmul:	
;incstack = 0
	callstack 6
; Regs used in ___bmul: [wreg+status,2+status,0]
	movwf	(___bmul@multiplier)
	line	6
	
l2585:	
	clrf	(___bmul@product)
	line	43
	
l2587:	
	btfss	(___bmul@multiplier),(0)&7
	goto	u2831
	goto	u2830
u2831:
	goto	l2591
u2830:
	line	44
	
l2589:	
	movf	(___bmul@multiplicand),w
	movwf	(??___bmul+0)+0
	movf	(??___bmul+0)+0,w
	addwf	(___bmul@product),f
	line	45
	
l2591:	
	clrc
	rlf	(___bmul@multiplicand),f

	line	46
	
l2593:	
	clrc
	rrf	(___bmul@multiplier),f

	line	47
	movf	((___bmul@multiplier)),w
	btfss	status,2
	goto	u2841
	goto	u2840
u2841:
	goto	l2587
u2840:
	line	50
	
l2595:	
	movf	(___bmul@product),w
	line	51
	
l341:	
	return
	callstack 0
GLOBAL	__end_of___bmul
	__end_of___bmul:
	signat	___bmul,8313
	global	_keypad_init

;; *************** function _keypad_init *****************
;; Defined at:
;;		line 15 in file "keypad.c"
;; Parameters:    Size  Location     Type
;;		None
;; Auto vars:     Size  Location     Type
;;		None
;; Return value:  Size  Location     Type
;;                  1    wreg      void 
;; Registers used:
;;		wreg, status,2, status,0
;; Tracked objects:
;;		On entry : 0/0
;;		On exit  : 0/0
;;		Unchanged: 0/0
;; Data sizes:     COMMON   BANK0   BANK1   BANK3   BANK2
;;      Params:         0       0       0       0       0
;;      Locals:         0       0       0       0       0
;;      Temps:          1       0       0       0       0
;;      Totals:         1       0       0       0       0
;;Total ram usage:        1 bytes
;; Hardware stack levels used: 1
;; This function calls:
;;		Nothing
;; This function is called by:
;;		_main
;; This function uses a non-reentrant model
;;
psect	text36,local,class=CODE,delta=2,merge=1,group=0
	file	"keypad.c"
	line	15
global __ptext36
__ptext36:	;psect for function _keypad_init
psect	text36
	file	"keypad.c"
	line	15
	
_keypad_init:	
;incstack = 0
	callstack 7
; Regs used in _keypad_init: [wreg+status,2+status,0]
	line	17
	
l2291:	
	movlw	low(0F0h)
	movwf	(??_keypad_init+0)+0
	movf	(??_keypad_init+0)+0,w
	bsf	status, 5	;RP0=1, select bank1
	bcf	status, 6	;RP1=0, select bank1
	andwf	(136)^080h,f	;volatile
	line	18
	movlw	low(0Fh)
	movwf	(??_keypad_init+0)+0
	movf	(??_keypad_init+0)+0,w
	bcf	status, 5	;RP0=0, select bank0
	bcf	status, 6	;RP1=0, select bank0
	iorwf	(8),f	;volatile
	line	21
	movlw	low(07h)
	movwf	(??_keypad_init+0)+0
	movf	(??_keypad_init+0)+0,w
	bsf	status, 5	;RP0=1, select bank1
	bcf	status, 6	;RP1=0, select bank1
	iorwf	(134)^080h,f	;volatile
	line	23
	
l137:	
	return
	callstack 0
GLOBAL	__end_of_keypad_init
	__end_of_keypad_init:
	signat	_keypad_init,89
global	___latbits
___latbits	equ	2
	global	btemp
	btemp set 07Eh

	DABS	1,126,2	;btemp
	global	wtemp0
	wtemp0 set btemp+0
	end
