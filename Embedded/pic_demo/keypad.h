/*
 * keypad.h - Keypad Driver Header
 *
 * PICGenios keypad matrix (from board source):
 * Rows: RD3=row0, RD2=row1, RD1=row2, RD0=row3
 * Cols: RB0=col0, RB1=col1, RB2=col2
 *
 * Key mapping:
 * [0]=1  [1]=2  [2]=3
 * [3]=4  [4]=5  [5]=6
 * [6]=7  [7]=8  [8]=9
 * [9]=*  [10]=0 [11]=#
 *
 * Our mapping:
 * [0]=T1+ [1]=T2+ [2]=T3+
 * [3]=T1- [4]=T2- [5]=T3-
 * [6]=P1+ [7]=P2+ [8]=P3+
 * [9]=P1- [10]=P2-[11]=P3-
 */
#ifndef KEYPAD_H
#define KEYPAD_H

#include <xc.h>

void          keypad_init(void);
unsigned char keypad_scan(void);

#endif