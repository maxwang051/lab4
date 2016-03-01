;****************** main.s ***************
; Program written by: ***Your Names**update this***
; Date Created: 1/22/2016 
; Last Modified: 1/22/2016 
; Section ***Tuesday 1-2***update this***
; Instructor: ***Ramesh Yerraballi**update this***
; Lab number: 4
; Brief description of the program
;   If the switch is presses, the LED toggles at 8 Hz
; Hardware connections
;  PE1 is switch input  (1 means pressed, 0 means not pressed)
;  PE0 is LED output (1 activates external LED on protoboard) 
;Overall functionality of this system is the similar to Lab 3, with three changes:
;1-  initialize SysTick with RELOAD 0x00FFFFFF 
;2-  add a heartbeat to PF2 that toggles every time through loop 
;3-  add debugging dump of input, output, and time
; Operation
;	1) Make PE0 an output and make PE1 an input. 
;	2) The system starts with the LED on (make PE0 =1). 
;   3) Wait about 62 ms
;   4) If the switch is pressed (PE1 is 1), then toggle the LED once, else turn the LED on. 
;   5) Steps 3 and 4 are repeated over and over



SWITCH              	EQU 0x40024008  ;PE1
LED                 	EQU 0x40024004  ;PE0
SYSCTL_RCGCGPIO_R       EQU 0x400FE608
SYSCTL_RCGC2_GPIOE      EQU 0x00000010   ; port E Clock Gating Control
SYSCTL_RCGC2_GPIOF      EQU 0x00000020   ; port F Clock Gating Control
GPIO_PORTE_DATA_R       EQU 0x400243FC
GPIO_PORTE_DIR_R        EQU 0x40024400
GPIO_PORTE_AFSEL_R      EQU 0x40024420
GPIO_PORTE_PUR_R        EQU 0x40024510
GPIO_PORTE_DEN_R        EQU 0x4002451C
GPIO_PORTF_DATA_R       EQU 0x400253FC
GPIO_PORTF_DIR_R        EQU 0x40025400
GPIO_PORTF_AFSEL_R      EQU 0x40025420
GPIO_PORTF_DEN_R        EQU 0x4002551C
NVIC_ST_CTRL_R          EQU 0xE000E010
NVIC_ST_RELOAD_R        EQU 0xE000E014
NVIC_ST_CURRENT_R       EQU 0xE000E018
COUNT					EQU 0x0003C8C0
           THUMB
           AREA    DATA, ALIGN=4
SIZE       EQU    50
;You MUST use these two buffers and two variables
;You MUST not change their names
;These names MUST be exported
           EXPORT DataBuffer  
           EXPORT TimeBuffer  
           EXPORT DataPt [DATA,SIZE=4] 
           EXPORT TimePt [DATA,SIZE=4]
DataBuffer SPACE  SIZE*4
TimeBuffer SPACE  SIZE*4
DataPt     SPACE  4
TimePt     SPACE  4

    
      ALIGN          
      AREA    |.text|, CODE, READONLY, ALIGN=2
      THUMB
      EXPORT  Start
      IMPORT  TExaS_Init


Start BL   TExaS_Init  ; running at 80 MHz, scope voltmeter on PD3
	LDR R0, =SYSCTL_RCGCGPIO_R
	LDR R1, [R0]
	ORR R1, #0x30
	STR R1, [R0]
	NOP
	NOP
	; initialize Port E
	LDR R0, =GPIO_PORTE_DIR_R
	LDR R1, [R0]
	ORR R1, #0x01
	BIC R1, #0x02
	STR R1, [R0]

	LDR R0, =GPIO_PORTE_AFSEL_R
	LDR R1, [R0]
	BIC R1, #0x03
	STR R1, [R0]

	LDR R0, =GPIO_PORTE_DEN_R
	LDR R1, [R0]
	ORR R1, #0x03
	STR R1, [R0]
; initialize Port F
	LDR R0, =GPIO_PORTF_DIR_R
	LDR R1, [R0]
	ORR R1, #0x04
	STR R1, [R0]
	
	LDR R0, =GPIO_PORTF_AFSEL_R
	LDR R1, [R0]
	BIC R1, #0x04
	STR R1, [R0]
	
	LDR R0, =GPIO_PORTF_DEN_R
	LDR R1, [R0]
	ORR R1, #0x04
	STR R1, [R0]
; initialize debugging dump, including SysTick
	BL Debug_Init 				; initialize buffers, buffer pointers, and enable systick

      CPSIE  I    ; TExaS voltmeter, scope runs on interrupts - GETS STUCK HERE WHY???????????????????
loop  BL   Debug_Capture
;heartbeat
; Delay
	LDR R0, =COUNT
again
    SUBS R0, #1
    BNE again
	
	B    loop


;------------Debug_Init------------
; Initializes the debugging instrument
; Input: none
; Output: none
; Modifies: none
; Note: push/pop an even number of registers so C compiler is happy
Debug_Init
; set buffers to 0xFFFFFFFF	
	MOV R0, #50						; set count equal to number of elements in array
	LDR R1, =DataBuffer				; R1 <- starting address of data array
	LDR R2, =TimeBuffer				; R2 <- starting address of time array
	MOV R3, #0xFFFFFFFF				; R3 <- data we'll be storing
lp	CMP R0, #0						; reached end of array?
	BEQ L1							; if yes, end loop
	STR R3, [R1]					; otherwise store the data into the address held by R1 (current DATA array address)
	STR R3, [R2]					; store the data into the address held by R2 (current TIME array address)
	ADD R1, #4						; increment data array pointer to next element
	ADD R2, #4						; increment time array pointer to next element
	SUB R0, #1						; subtract 1 from count
	B lp	

; initialize pointers
L1	LDR R0, =DataPt					; get address of data pointer
	LDR R1, =DataBuffer				; get address of first element
	STR R1, [R0]					; store address of first element in pointer address
	
	LDR R0, =TimePt					; get address of time pointer
	LDR R1, =TimeBuffer				; get address of first element
	STR R1, [R0]					; store address of first element in pointer address
      
; init SysTick
	; disable SysTick during setup
    LDR R1, =NVIC_ST_CTRL_R         ; R1 = &NVIC_ST_CTRL_R
    MOV R0, #0                      ; R0 = 0
    STR R0, [R1]                    ; [R1] = R0 = 0
    ; maximum reload value
    LDR R1, =NVIC_ST_RELOAD_R       ; R1 = &NVIC_ST_RELOAD_R
    LDR R0, =0x00FFFFFF       ; R0 = NVIC_ST_RELOAD_M
    STR R0, [R1]                    ; [R1] = R0 = NVIC_ST_RELOAD_M
    ; any write to current clears it
    LDR R1, =NVIC_ST_CURRENT_R      ; R1 = &NVIC_ST_CURRENT_R
    MOV R0, #0                      ; R0 = 0
    STR R0, [R1]                    ; [R1] = R0 = 0
    ; enable SysTick with core clock
    LDR R1, =NVIC_ST_CTRL_R         ; R1 = &NVIC_ST_CTRL_R
	MOV R0, #0x05
    STR R0, [R1]                    ; [R1] = R0 = (NVIC_ST_CTRL_ENABLE|NVIC_ST_CTRL_CLK_SRC)
      BX LR

;------------Debug_Capture------------
; Dump Port E and time into buffers
; Input: none
; Output: none
; Modifies: none
; Note: push/pop an even number of registers so C compiler is happy
Debug_Capture
	PUSH {R0, R1, R2, R3, R4, R12}	; push needed registers to stack (R4 not needed but has to be even number of registers)
	LDR R0, =DataPt					; R0 <- data array pointer to first element
	LDR R1, =TimePt					; R1 <- time array pointer to first element
lp2	LDR R2, =TimeBuffer				; R2 <- starting address of array
	ADD R2, #200					; add 50 to get the ending address of the array
	CMP R1, R2						; check to see if we have gone past the bounds of the array
	BGT L2							; if yes then return
	
	LDR R2, =GPIO_PORTE_DATA_R		; R2 <- PORT E data address
	LDR R3, [R2]					; R3 <- PORT E data
	BIC R3, #0xFC					; mask everything except PE0 and PE1
	MOV R12, R3						; create a copy of the data into R12
	BIC R12, #0x01					; clear everything but PE1
	LSL R12, #3						; shift PE1 by 3 bits
	ORR R3, R12, R3					; store the result back into R3
	BIC R3, #0xEE					; get rid of the original PE1 that was in bit 1
	STR R3, [R0]					; store data into data array
	
	LDR R2, =NVIC_ST_CURRENT_R		; R2 <- current clock time address
	LDR R3, [R2]					; R3 <- current clock time
	STR R3, [R1]					; store current time into the time array - hopefully - not sure this works
	
	ADD R0, #4						; increment the pointers to the next element in the array
	ADD R1, #4
	B lp2							; loop
	
	POP {R0, R1, R2, R3, R4, R12}
	

L2    BX LR


    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file
        