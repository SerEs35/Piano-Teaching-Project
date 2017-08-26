;Sergio Espinal 2015
;---------------------

#include "p16F1719.inc"

; CONFIG1
; __config 0x3FE4
 __CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_ON & _FCMEN_ON
; CONFIG2
; __config 0x3EFF
 __CONFIG _CONFIG2, _WRT_OFF & _PPS1WAY_OFF & _ZCDDIS_ON & _PLLEN_OFF & _STVREN_ON & _BORV_LO & _LPBOR_OFF & _LVP_ON
;-------------------------------------------------------------------------------
;equ is commonly used to assign a variable name to
;an address location in RAM
;Because set directive values may be altered by later set directives, 
;set is particularly useful when defining a variable in a 
;loop (e.g., a while loop.) 

 ;Result_conversion   equ	
;............................................ 
group1	     idata	0x020	;udata
ADC_pin		    res	    1	;flag used to select ADC0 or ADC1. This determines which player's keyboard is sensing
device		    res	    1
clef		    res	    1	;0x01: bass, 0x02: treble
math_logic	    res	    1	;temp variable used to store bits of information like Z or C when performing comparison of two numbers 	    
Result_conversion   res	    2	;temp variable
key_button	    res	    2	;stores the value of the ADC output when a key is pressed
   
rg_flag		    res	    1	;0x00: host,  0x01: client 

tcounter	    res	    2	;temp variable used on delay functions
time_flag	    res	    1	; should be a bit	 

temp_compare	    res	    2	;for ADC result conversion comparison
	    
key_status_flag	    res	    1	;0x01: photo_treble  0x02:   0x03:   0x04: RG buttons

byte_data	    res	    1	;temp variable for fetching memory data
audio_data	    res	    3	;temp variable for audio output

init_addr	    res	    3	;audio file starting address
end_addr	    res	    4	;audio file ending address    

iter_i		    res	    1
iter_j		    res	    2		  

		    
group2	    idata	0x120
Result_temp	    res	    2	
	    
;------------------------------------------------------------------------------- 
RES_VECT  CODE    0x0000            ; processor reset vector
    pagesel START
    GOTO    START                   ; go to beginning of program

; TODO ADD INTERRUPTS HERE IF USED
INT_VECT  CODE   0x0004
    pagesel MyISR  
    call    MyISR
 
  RETFIE
;-------------------------------------------------------------------------------      
;------------------------------------------------------------------------------- 
Setup_Oscillator
    
    banksel OSCCON

    ;set postscaler for oscillator to run at 8MHz    
    bcf	    OSCCON, 0x3	    ;OSCCONbits.IRCF0 = 0
    bsf	    OSCCON, 0x4	    ;OSCCONbits.IRCF1 = 1
    bsf	    OSCCON, 0x5	    ;OSCCONbits.IRCF2 = 1
    bsf	    OSCCON, 0x6	    ;OSCCONbits.IRCF3 = 1
    
 
    bcf	    OSCCON, 0x0	    ;OSCCONbits.SCS0 = 0
    bcf	    OSCCON, 0x1	    ;OSCCONbits.SCS1 = 0
   
    ;enable 4xPLL  SPLLEN
    bsf	    OSCCON, 0x7
	
    ;Add delay here
    call    delay_10_ms
    
    bcf	    OSCTUNE, 0x0    ;OSCTUNEbits.TUN0 = 0
    bcf	    OSCTUNE, 0x1    ;OSCTUNEbits.TUN1 = 0
    bcf	    OSCTUNE, 0x2    ;OSCTUNEbits.TUN2 = 0
    bcf	    OSCTUNE, 0x3    ;OSCTUNEbits.TUN3 = 0
    bcf	    OSCTUNE, 0x4    ;OSCTUNEbits.TUN4 = 0
    bcf	    OSCTUNE, 0x5    ;OSCTUNEbits.TUN5 = 0
    
    return
;;-------------------------------------------------------------------------------
    
Setup_Timer0
    
    banksel OPTION_REG

    bsf	    OPTION_REG, 0x6
    bcf	    OPTION_REG, 0x5	;OPTION_REGbits.TMR0CS = 0 //Timer0 used as a incremental timer, FOSC/4
    bcf	    OPTION_REG, 0x4	;OPTION_REGbits.TMR0SE = 0 //Incremental on low to high transition T0CKI
    bcf	    OPTION_REG, 0x3	;OPTION_REGbits.PSA = 0    //prescaler assigned to Timer0
	
    ;setting the prescaler to 1:256
    bsf	    OPTION_REG, 0x0	;OPTION_REGbits.PS0 = 1
    bsf	    OPTION_REG, 0x1	;OPTION_REGbits.PS1 = 1
    bsf	    OPTION_REG, 0x2	;OPTION_REGbits.PS2 = 1
    
    return
;;-------------------------------------------------------------------------------
;;-------------------------------------------------------------------------------    

Setup_ADC
    
    banksel ADCON0
    bcf	    ADCON0, 0x0	    ;ADCON0bits.ADON = 0; // make sure that ADC is off
    
    banksel	ADC_pin	    ;if ADC_pin = 0, it is client's turn
    btfss	ADC_pin, 0	    ;skip if cleared
	goto    set_adc_client
    
    goto    set_adc_host
    
;student's side----------
set_adc_client   ;chn: AN14 at RC2
    
    banksel ADCON0
    bcf	    ADCON0, 0x02
    bsf	    ADCON0, 0x03
    bsf	    ADCON0, 0x04
    bsf	    ADCON0, 0x05
    bcf	    ADCON0, 0x06

    goto    _exit_adc_setup
    
;professor's side----------   
set_adc_host   ;chn: AN17 at RC5

    banksel ADCON0
    bsf	    ADCON0, 0x02    ;ADCON0bits.CHS0 = 1
    bcf	    ADCON0, 0x03    ;ADCON0bits.CHS1 = 0
    bcf	    ADCON0, 0x04    ;ADCON0bits.CHS2 = 0
    bcf	    ADCON0, 0x05    ;ADCON0bits.CHS3 = 0
    bsf	    ADCON0, 0x06    ;ADCON0bits.CHS4 = 1
    
    goto    _exit_adc_setup    
       
    
_exit_adc_setup
    
    bcf	    ADCON1, 0x04
    bsf	    ADCON1, 0x05	;ADCON1bits.ADCS,;clock source: Fosc/64
    bsf	    ADCON1, 0x06

;    bsf	    ADCON1, 0x04
;    bsf	    ADCON1, 0x05	;internal oscillator FRC
;    bsf	    ADCON1, 0x06
    
    bsf	    ADCON1, 0x07	;ADCON1bits.ADFM = 1 , MSB ADRESH:2 + ADRESL:8  LSB
    
    bsf	    ADCON0, 0x00	;ADCON0bits.ADON = 1;
    
;....insert delay of 5 us here for Acquisition Time
;it could be more than 5us due to the input resistance
;..................
   call	    delay_10_ms 
   
;The time to complete one bit conversion is defined as
;TAD. One full 10-bit conversion requires 11.5 TAD
;periods
;FOSC/32 ADCS<010>  1.0us
	
;So:  1us * 11.5 TAD = 	11.5us for a 10-bit conversion
    return
    
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;Preparing the SPI module... 
Setup_SPI				;2
	
    banksel SSP1CON1			;?			
    bcf	    SSP1CON1, SSPEN ;		;1
    bsf	    SSP1CON1, 0
    
    banksel LATD			;?
    bsf	    LATD, LATD1 ;SS~ Memory unselected		;1
    bsf	    LATD, LATD3 ;SS~ DAC unselected		;1
    bcf	    LATE, LATE2 ;SS~ AMP off		;1
    
    banksel RC3PPS			;?
    movlw   b'00010000'; // SCK		;1
    movwf   RC3PPS			;1
    
    banksel RC6PPS
    movlw   b'00010001' ; // SDO	;1    
    movwf   RC6PPS			;1
    
    banksel SSPDATPPS			;?
    movlw   b'00010100'	;// RC4 , SDI	;1
    movwf   SSPDATPPS			;1

    return
    
;-------------------------------------------------------------------------------  
;This function is used configure the SPI flags to 
;communicate with either the Memory unit or DAC unit
SPI_change_MEM_DAC			;2
    
    banksel SSP1CON1			;2			
    bcf	    SSP1CON1, SSPEN ;		;1  
   
    banksel device			;2
    btfsc   device, 0x00		;2 , *3   ;;9 or 10 for memory
	goto	_memory			
	
_dac		;device=0			
	banksel	SSP1STAT		;2
	bcf	SSP1STAT, 0x06	;CKE	;1
	bcf	SSP1STAT, 0x04	;CKP	;1
	bcf	SSP1STAT, 0x07	;SMP	;1
	goto	_continue		;2   ;;7
	
_memory		;device= 1			
	banksel	SSP1STAT		;2
	bsf	SSP1STAT, CKE	;CKE	;1   
	bcf	SSP1STAT, CKP	;CKP	;1
	bsf	SSP1STAT, SMP	;SMP	;1  
        nop				;1  ;;6
    
_continue    

    banksel SSP1CON1
    bsf	    SSP1CON1, 0
    bsf	    SSP1CON1, SSPEN	    

    return			    ;2   
;					:DAC:9+7+2+1+2 = 21
;					 MEM:10+6+2+1+2 = 21
    
;;-------------------------------------------------------------------------------    
;Sets the interrupts for the uC
Set_Interrupts

    banksel TMR0
    clrf    TMR0
    
    bsf	    INTCON, TMR0IE
    bsf	    INTCON, PEIE    ;enable peripheral input interrupt
    bsf	    INTCON, IOCIE   ;//enable interrupt-on-change
    
    banksel PIE1
    ;bsf	    PIE1, TMR1IE
    bsf	    PIE1, SSP1IE    ;
    
    banksel PIE1
    bsf	    PIE2, OSFIE	    ;enable Oscillator Fail interrupt
    
    banksel IOCAN
    bsf	    IOCAN, IOCAN0
    bsf	    IOCAN, IOCAN1
    bcf	    IOCAN, IOCAN2
    bsf	    IOCAN, IOCAN3
    bsf	    IOCAN, IOCAN4
    bcf	    IOCAN, IOCAN5

    
    bsf	    IOCAP, IOCAP6
    bsf	    IOCAP, IOCAP7
    
    bsf	    INTCON, GIE
    
    return
;;-------------------------------------------------------------------------------    

Set_IO_Pins
    
    banksel OPTION_REG
    
    bcf	    OPTION_REG, NOT_WPUEN
   
    movlw   b'11011011'
    movwf   TRISA

    clrf    TRISB
    
    movlw   b'00110100'
    movwf   TRISC
    
    clrf    TRISD

    bcf	    TRISE, 0
    bcf	    TRISE, 1
    bcf	    TRISE, 2
    
    
    banksel PORTA
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD
    clrf    PORTE
    
    
    banksel LATA
    clrf    LATA
    clrf    LATB
    clrf    LATC
    clrf    LATD
    clrf    LATE
    
    
    banksel ANSELA
    clrf    ANSELA
    clrf    ANSELB
    clrf    ANSELC    
    bsf	    ANSELC, 2
    bsf	    ANSELC, 5
    
    clrf    ANSELD
    clrf    ANSELE
    ;......................
    banksel WPUA
    movlw   b'00011011'
    movwf   WPUA
    
    clrf    WPUB
    clrf    WPUC
    clrf    WPUD
    
    bcf	    WPUE, 0
    bcf	    WPUE, 1
    bcf	    WPUE, 2
   ; bcf	    WPUE, 3
    
    banksel INLVLA
    movlw   b'00000100'
    movwf   INLVLA
    
    bcf	    INLVLC, 0x2   ;ADC0
    bcf	    INLVLC, 0x5	  ;ADC1
    bcf	    INLVLC, 4
    
    return
;;-------------------------------------------------------------------------------    
;;-------------------------------------------------------------------------------
;Interrupt Service Routine//////////////////////////////////////////////////////      
MyISR
    ;.................................................
_TMR0_ISR    

    ;if(INTCONbits.TMR0IE && INTCONbits.TMR0IF)
    btfss   INTCON, TMR0IF	;if it is set, it will go to the next btfss
    goto    _IOC_ISR		;else it will exit
	btfss   INTCON, TMR0IE
	goto	_IOC_ISR

    ;if(time_flag == 1 && tcounter < 305)
    ;............................................
    banksel time_flag
    btfss   time_flag, 0x0
	goto    _skip_tcounter
    
    ;   xlow < ylow     ylow - xlow
    ; is tcounter < 0x31  ?   k - W  :  0x31 - tcounter
    movlw   tcounter	    ;low end
    sublw   0x31	    ;subtract both low ends , 0 to 255
    btfsc   STATUS, Z	    ;if sub gives zero, Z = 1
    bsf	    math_logic, 0
    
        ;   xhigh < yhigh
    ; is tcounter < 0x31  ?   k - W  :  0x31 - tcounter
    movlw   tcounter+1	    ;high end
    sublw   0x01	    ;subtract both high ends , 0 to 255
    btfsc   STATUS, Z
    bsf	    math_logic, 1
    
    ;   xl == yl
    ; is tcounter < 0x01  ?   k - W  :  0x31 - tcounter
    movlw   tcounter	    ;low end
    xorlw   0x31	    ;compare both low ends , 0 to 255
    btfss   STATUS, Z
    bsf	    math_logic, 2
    
        ;   xh == yh
    ; is tcounter < 0x01  ?   k - W  :  0x31 - tcounter
    movlw   tcounter+1	    ;high end
    xorlw   0x01	    ;compare both high ends , 0 to 255
    btfsc   STATUS, Z
    bsf	    math_logic, 3
    ; zzzz
    ; 0000 : tcounter < 0x0131    <- continue
    ; 0000 : tcounter > 0x0131	  <- cannot determine unless using Carry
    ; 1100 : tcounter == 0x0131   <- stop here
    
    movlw   b'00001100'
    xorwf   math_logic, W
    btfsc   STATUS, Z	    ; if it is the same, z= 1
	    goto	_skip_tcounter

	movlw   0x01
	addwf   tcounter, F
	btfsc   STATUS, C
	incf	tcounter+1
	
_skip_tcounter
    
    bcf	    INTCON, TMR0IF

;....................................................    
;.................................................    
;  Function to Handle Interrupt-on-change
    ;if(INTCONbits.IOCIE && INTCONbits.IOCIF)
_IOC_ISR    
    
    btfss   INTCON, IOCIF
    goto    _OSFIF_ISR
	btfss   INTCON, IOCIE
	goto    _OSFIF_ISR
	
;key_status_flag = 0; // used for access to different levels of if's
;/*
; 0: Only phototransistors    **_IOC_ISR
; 1: ADC input, Host/Client
; 2: ----------------
; 3: Play keynote
; 4: Only Red and Green buttons  ** _IOC_ISR
; */	

	banksel key_status_flag	    ;Red or Green Buttons
	movlw   0x04
	xorwf   key_status_flag, W
	btfsc   STATUS, Z
	    goto	_key_flag_is_4 ; Edited : _to_g1
	
	banksel	key_status_flag    ;to IR triggers
	movlw	0x00
	xorwf	key_status_flag
	btfsc	STATUS, Z    
	    goto	_key_flag_is_0		    
	    
	goto	_key_flag_not_
	
_key_flag_is_4
 nop
_to_g1	
	    banksel	IOCAF
	    btfss	IOCAF, IOCAF3
	    goto	_to_r1
	    
	    ;... Only 1 LED per user can be activated
	    ;... check if Red_2 (R2) is already lit
	    banksel	rg_flag
	    btfsc	rg_flag, 0x01
		goto	_key_flag_not_
		
	    ;......turn ON G2 LED
	    banksel	rg_flag
	    btfsc	rg_flag, 0x00	    ;check if G1 is already lit
		goto	_key_flag_not_	    ;if it is not, then proceed..
	    bsf		rg_flag, 0x00
	    bsf		rg_flag, 0x02	    ;allow G2 only, excludes R2 
	    
	    banksel	LATD
	    bsf		LATD, LATD4
	    ;....................

	    call    key_jump_to_ADC1
	    
	    goto    _key_flag_not_	
	    
_to_r1
	    banksel	IOCAF
	    btfss	IOCAF, IOCAF4
	    goto	_to_g2
	    ;... Only 1 LED per user can be activated
	    ;... check if G1 is already lit
	    banksel	rg_flag
	    btfsc	rg_flag, 0x00
		goto	_key_flag_not_
		
	    ;......turn ON R1 LED
	    banksel	rg_flag
	    btfsc	rg_flag, 0x01	    ;check if R1 is already lit
		goto	_key_flag_not_	    ;if it is not, then proceed..
	    bsf		rg_flag, 0x01
	    bsf		rg_flag, 0x03	    ;allow R2 only, excludes G2
	    
	    banksel	LATD
	    bsf		LATD, LATD5
	    ;.................... 
	    
	    call    key_jump_to_ADC1
	    
	    goto	_key_flag_not_
;...................
	    
_to_g2
	    banksel	IOCAF
	    btfss	IOCAF, IOCAF0
	    goto	_to_r2
	    
	    ;...Check if G2 is set.....
	    banksel	rg_flag
	    btfss	rg_flag, 0x02
		goto    _key_flag_not_
		
	    clrf	rg_flag
	    clrf	key_status_flag
	    ;.........................
	    
	    ;..turn ON G2 LED.........
	    banksel	LATC
	    bsf		LATC, LATC7	    
	    
	    ;..........................
	    ;..Add Delay of 5 secs.....
	    
	    call    delay_5_s
	    ;.........................
	    ;.turn OFF G1 and G2 LEDs..

	    banksel	LATD
	    bcf		LATD, LATD4
		
	    banksel	LATC
	    bcf		LATC, LATC7		

	    banksel LATB	    ;turn ON the IR emitters
	    bsf	    LATB, LATB6	
	    bsf	    LATB, LATB7
	    
		goto	_key_flag_not_
		
_to_r2
	    banksel	IOCAF
	    btfss	IOCAF, IOCAF1
	    goto	_key_flag_not_
	    
	    ;...Check if R2 is set.....
	    banksel	rg_flag
	    btfss	rg_flag, 0x03
		goto    _key_flag_not_
		
	    clrf	rg_flag
	    clrf	key_status_flag
	    ;.........................
	    
	    ;..turn ON R2 LED.........
	    banksel	LATD
	    bsf		LATD, LATD2	    
	    
	    ;..........................
	    ;..Add Delay of 5 secs.....
	    call    delay_5_s
	    ;.........................
	    ;.turn OFF R1 and R2 LEDs..
	    banksel	LATD
	    bcf		LATD, LATD5
	    bcf		LATD, LATD2
	    ;...................	
	    banksel LATB	    ;turn ON the IR emitters
	    bsf	    LATB, LATB6	
	    bsf	    LATB, LATB7
		goto    _key_flag_not_
	    

;//Check if a button has triggered an interrupt already serviced
	    
_key_flag_is_0
	  nop  
_bass_clef_photo_1

    banksel	IOCAF
    btfss	IOCAF, IOCAF7
	goto	_treble_clef_photo_2
	
	banksel	clef
	movlw	0x01	    ;bass clef
	movwf	clef
	bsf	key_status_flag, 0x00	;phototransistors
	
;.................................	
;	banksel	LATE	    ;turn OFF the LED0
;	bcf	LATE, LATE1
;
;	banksel	LATE	    ;turn ON the LED0
;	bsf	LATE, LATE0
	
	banksel   PWM3CON
	bcf	  PWM3CON, 7
	
	banksel   TRISE
	bcf	  TRISE, TRISE0
	bsf	  TRISE, TRISE1
	
	banksel   PWM3CON
	bsf	  PWM3CON, 7
;..................................
	
	;......................
	banksel	LATB	    ;turn OFF the IR emitters
	bcf	LATB, LATB6	
	bcf	LATB, LATB7
	;......................
	banksel	IOCAF
	bcf	IOCAF, IOCAF7
	
    goto    _OSFIF_ISR
	
_treble_clef_photo_2

    banksel	IOCAF
    btfss	IOCAF, IOCAF6
	goto	_key_flag_not_ 
	
	banksel	clef
	movlw	0x02    
	movwf	clef
	bsf	key_status_flag, 0x00 ;phototransistors
;...........................................	
	
	banksel   PWM3CON
	bcf	  PWM3CON, 7
	
	banksel   TRISE
	bsf	  TRISE, TRISE0
	bcf	  TRISE, TRISE1
	
	banksel   PWM3CON
	bsf	  PWM3CON, 7
	
	;.....................
	banksel	LATB	    ;turn OFF the IR emitters
	bcf	LATB, LATB6	
	bcf	LATB, LATB7
	;.....................
	banksel	IOCAF
	bcf	IOCAF, IOCAF6

    goto    _OSFIF_ISR	
 
    
_key_flag_not_    

	banksel	IOCAF
	bcf	IOCAF, IOCAF0;
	bcf	IOCAF, IOCAF1;
	bcf	IOCAF, IOCAF3;
	bcf	IOCAF, IOCAF4;
	bcf	IOCAF, IOCAF6;
	bcf	IOCAF, IOCAF7;			    

    goto    _exit_ISR    
    
;.........................................
    
_OSFIF_ISR   ;Fail-safe clock flag
    
    banksel	PIR2
    btfss	PIR2, OSFIF   ;external clock failed
	goto	_SSPIF_ISR
	
    banksel	PIE2
    btfss	PIE2, OSFIE
	goto	_SSPIF_ISR
	
	banksel	PIR2
	bcf	PIR2, OSFIF
;................................................. 
_SSPIF_ISR

    banksel	PIR1
    btfss	PIR1, SSP1IF
	goto	_exit_ISR
	
    banksel	PIE1
    btfss	PIE1, SSP1IE
	goto	_exit_ISR
	
	banksel	PIR1
	bcf	PIR1, SSP1IF	

	
;................................................. 
_TMR2IF_ISR

    banksel	PIR1
    btfss	PIR1, TMR2IF
	goto	_exit_ISR
		
	banksel	PIR1
	bcf	PIR1, TMR2IF	
	
_exit_ISR
	
    return
;;-------------------------------------------------------------------------------    

delay_5_s
    
    ;it uses tcounter, and tcounter+1 at delay_10_ms
    banksel tcounter
    clrf    tcounter
    
delay_5_s_in_1   
    call    delay_10_ms
    incf    tcounter
    movlw   d'250'
    xorwf   tcounter, W
    btfss   STATUS, Z
        goto    delay_5_s_in_1      


    clrf tcounter	
    
delay_5_s_in_2   
    call    delay_10_ms
    incf    tcounter
    movlw   d'250'
    xorwf   tcounter, W
    btfss   STATUS, Z
        goto    delay_5_s_in_2   	
	
    return
    
;;-------------------------------------------------------------------------------    
 
delay_10_ms
    
	banksel tcounter+1
        clrf	tcounter+1  
	
_10_ms_loop  
        
	incf	tcounter+1
	movlw   d'65'
	movwf   byte_data

	call    delay_us 

	movlw   d'200'
	xorwf	tcounter+1, W
	btfss	STATUS, Z
	    goto    _10_ms_loop 
    return
;;-------------------------------------------------------------------------------    

;;-------------------------------------------------------------------------------   
;Function to check if a button has been pressed. It checks an 
;averaged value against a pre-defined value. This pre-defined 
;value represents a voltage level, and was found by implementing
;a custom function that turns ON the White LEDS, giving a determined
;binary code for each button pressed.... 
 
Check_ADC_Result
    
    banksel key_button
    clrf    key_button
    
    btfss   ADC_pin, 0
	goto	_client_side
    goto    _host_side
    
    
_host_side

;call    toggle_R2
    
if_less_than_0x43_host    
    banksel temp_compare
    movlw   0x43
    movwf   temp_compare
    
    call    function_compare_2
    
    ;---comparison here
    movf   math_logic, W    ; 00110000 : Result_conversion < 4
    xorlw   b'00000010'
    btfsc   STATUS, Z
	goto	_exit_Check_ADC_Result
    ;------------------

if_equal_to_0x43_host
    banksel temp_compare
    movlw   0x43
    movwf   temp_compare

    call    function_compare_2

    ;---comparison here
	call	mini_function_xor_2
	btfss   STATUS, Z
	goto    if_equal_to_0x51_host
    ;------------------
    
    banksel key_button
    movlw   0x43
    movwf   key_button

    call    key_jump_to_Play_Keynote
    call    LED_shutdown

    ;-------Turn LED ON----------
    banksel LATB
    bsf	    LATB, LATB5
    ;----------------------------
    
    goto    _exit_Check_ADC_Result    
    ;------------------
    

if_equal_to_0x51_host   
    banksel temp_compare
    movlw   0x51
    movwf   temp_compare

    call    function_compare_2

    ;---comparison here
	call	mini_function_xor_2
	btfss   STATUS, Z
	goto    if_equal_to_0x5A_host
    ;------------------
    
    banksel key_button
    movlw   0x51
    movwf   key_button

    call    key_jump_to_Play_Keynote
    call    LED_shutdown
    
    banksel LATB
    bsf	    LATB, LATB4
    
    goto    _exit_Check_ADC_Result    
        ;------------------

if_equal_to_0x5A_host    
    banksel temp_compare
    movlw   0x5A
    movwf   temp_compare

    call    function_compare_2

    ;---comparison here
	call	mini_function_xor_2
	btfss   STATUS, Z
	goto    if_equal_to_0x61_host
    ;------------------
    
    banksel key_button
    movlw   0x5A
    movwf   key_button

    call    key_jump_to_Play_Keynote
    call    LED_shutdown
    
    banksel LATB
    bsf	    LATB, LATB3
    
    goto    _exit_Check_ADC_Result    
    ;------------------

if_equal_to_0x61_host   
    banksel temp_compare
    movlw   0x61
    movwf   temp_compare

    call    function_compare_2

    ;---comparison here
    call	mini_function_xor_2
    btfss   STATUS, Z
	goto    if_equal_to_0x65_host
    ;------------------
    
    banksel key_button
    movlw   0x61
    movwf   key_button
    
    call    key_jump_to_Play_Keynote
    call    LED_shutdown
    
    banksel LATB
    bsf	    LATB, LATB2
    
    goto    _exit_Check_ADC_Result        
    ;------------------

if_equal_to_0x65_host    ;this one and the 0x66 handle the same keynote C4 Middle C
    banksel temp_compare
    movlw   0x65
    movwf   temp_compare

    call    function_compare_2

    ;---comparison here
    call	mini_function_xor_2
    btfss   STATUS, Z
	goto    if_equal_to_0x66_host
    ;------------------
    
    banksel key_button
    movlw   0x66
    movwf   key_button

    call    key_jump_to_Play_Keynote
    call    LED_shutdown
    
    banksel LATB
    bsf	    LATB, LATB1
    
    goto    _exit_Check_ADC_Result        
    ;------------------    
    
    
if_equal_to_0x66_host    
    banksel temp_compare
    movlw   0x66
    movwf   temp_compare

    call    function_compare_2

    ;---comparison here
    call	mini_function_xor_2
    btfss   STATUS, Z
	goto    if_equal_to_0x69_host
    ;------------------
    
    banksel key_button
    movlw   0x66
    movwf   key_button

    call    key_jump_to_Play_Keynote
    call    LED_shutdown
    
    banksel LATB
    bsf	    LATB, LATB1
    
    goto    _exit_Check_ADC_Result        
    ;------------------

if_equal_to_0x69_host    
    banksel temp_compare
    movlw   0x69
    movwf   temp_compare

    call    function_compare_2

    ;---comparison here
    call	mini_function_xor_2
    btfss   STATUS, Z
	goto    if_equal_to_0x6C_host
    ;------------------
    
    banksel key_button
    movlw   0x69
    movwf   key_button
    
    call    key_jump_to_Play_Keynote
    call    LED_shutdown
   
    banksel LATB
    bsf	    LATB, LATB0
    
    goto    _exit_Check_ADC_Result        
    ;------------------

if_equal_to_0x6C_host    
    banksel temp_compare
    movlw   0x6C
    movwf   temp_compare

    call    function_compare_2

    ;---comparison here
    call	mini_function_xor_2
    btfss   STATUS, Z
	goto    if_equal_to_0x6F_host
    ;------------------
    
    banksel key_button
    movlw   0x6C
    movwf   key_button

    call    key_jump_to_Play_Keynote
    call    LED_shutdown
    
    banksel LATD
    bsf	    LATD, LATD7
    
    goto    _exit_Check_ADC_Result        
    ;------------------

if_equal_to_0x6F_host    
    ;if(Result_conversion == 512 ) ;0x0200
    banksel temp_compare
    movlw   0x6F
    movwf   temp_compare

    call    function_compare_2
    
    ;---comparison here
    call	mini_function_xor_2
    btfss   STATUS, Z
	goto    _exit_Check_ADC_Result
    ;------------------
    
    banksel key_button
    movlw   0x6F
    movwf   key_button

    call    key_jump_to_Play_Keynote
    call    LED_shutdown
    
    banksel LATD
    bsf	    LATD, LATD6
    
    goto    _exit_Check_ADC_Result        
    ;------------------
    
    
_client_side;=====================================

if_less_than_0x43_client    
    banksel temp_compare
    movlw   0x43
    movwf   temp_compare

    call    function_compare_2
    
    
    ;---comparison here
    movf   math_logic, W    ; 00110000 : Result_conversion < 4
    xorlw   b'00000010'
    btfss   STATUS, Z
	goto	if_equal_to_0x43_client

    clrf	Result_conversion
    clrf	Result_conversion+1
    
    goto	_exit_Check_ADC_Result
    
    ;------------------

if_equal_to_0x43_client
    banksel temp_compare
    movlw   0x43
    movwf   temp_compare
 
    call    function_compare_2

    ;---comparison here
	call	mini_function_xor_2
	btfss   STATUS, Z
	goto    if_equal_to_0x51_client
    ;------------------

    ;-----Turn LED ON------------
    banksel LATB
    bsf	    LATB, LATB5
    ;----------------------------
 
    
    ;----------set flags for GR---------
    call    key_jump_to_GR
    
    goto    _exit_Check_ADC_Result    
    ;------------------
    

if_equal_to_0x51_client    
   
    banksel temp_compare
    movlw   0x51
    movwf   temp_compare
   
    call    function_compare_2

    ;---comparison here
	call	mini_function_xor_2
	btfss   STATUS, Z
	goto    if_equal_to_0x5A_client
    ;------------------

    ;-----Turn LED ON------------
    banksel LATB
    bsf	    LATB, LATB4

    
    ;----------set flags for GR---------
    call    key_jump_to_GR
    
    goto    _exit_Check_ADC_Result    
        ;------------------

if_equal_to_0x5A_client    
    banksel temp_compare
    movlw   0x5A
    movwf   temp_compare
    
    call    function_compare_2

    ;---comparison here
	call	mini_function_xor_2
	btfss   STATUS, Z
	goto    if_equal_to_0x61_client
    ;------------------

    banksel LATB
    bsf	    LATB, LATB3

    ;----------set flags for GR---------
    call    key_jump_to_GR
 

    goto    _exit_Check_ADC_Result    
    ;------------------

if_equal_to_0x61_client    
    ;if(Result_conversion == 32 && key_button == 32) ;0x0020
    banksel temp_compare
    movlw   0x61
    movwf   temp_compare

    call    function_compare_2

    ;---comparison here
    call    mini_function_xor_2
    btfss   STATUS, Z
	goto    if_equal_to_0x65_client
    ;------------------
    ;----Turn LED ON---------------
    banksel LATB
    bsf	    LATB, LATB2
    ;------------------------------

    ;----------set flags for GR---------
    call    key_jump_to_GR
    
    goto    _exit_Check_ADC_Result        
    ;------------------

if_equal_to_0x65_client    
    banksel temp_compare
    movlw   0x65
    movwf   temp_compare

    call    function_compare_2

    ;---comparison here
    call	mini_function_xor_2
    btfss   STATUS, Z
	goto    if_equal_to_0x66_client
    ;------------------

    ;------------Turn LED ON-------------
    banksel LATB	
    bsf	    LATB, LATB1
    ;------------------------------------

    ;----------set flags for GR---------
    call    key_jump_to_GR  
    
    goto    _exit_Check_ADC_Result        
    ;------------------    
    
    
if_equal_to_0x66_client    
    banksel temp_compare
    movlw   0x66
    movwf   temp_compare

    call    function_compare_2

    ;---comparison here
    call	mini_function_xor_2
    btfss   STATUS, Z
	goto    if_equal_to_0x69_client
    ;------------------

    ;------------Turn LED ON-------------
    banksel LATB	
    bsf	    LATB, LATB1
    ;------------------------------------

    ;----------set flags for GR---------
    call    key_jump_to_GR  
    
    goto    _exit_Check_ADC_Result        
    ;------------------

if_equal_to_0x69_client    
    ;if(Result_conversion == 128 ) ;0x0080
    banksel temp_compare
    movlw   0x69
    movwf   temp_compare

    call    function_compare_2

    ;---comparison here
    call    mini_function_xor_2
    btfss   STATUS, Z
	goto    if_equal_to_0x6C_client
    ;------------------

    ;---Turn LED ON-----------
    banksel LATB	
    bsf	    LATB, LATB0
    ;-------------------------

    
    ;----------set flags for GR---------
    call    key_jump_to_GR
    
    goto    _exit_Check_ADC_Result        
    ;------------------

if_equal_to_0x6C_client    
    ;if(Result_conversion == 256 ) ;0x0100
    banksel temp_compare
    movlw   0x6C
    movwf   temp_compare

    call    function_compare_2

    ;---comparison here
    call    mini_function_xor_2
    btfss   STATUS, Z
	goto    if_equal_to_0x6F_client
    ;------------------

    ;----------Turn LED ON---------
    banksel LATD	
    bsf	    LATD, LATD7
    ;------------------------------
        
;----------set flags for GR---------
    call    key_jump_to_GR
    
    goto    _exit_Check_ADC_Result        
    ;------------------

if_equal_to_0x6F_client    
  
    banksel temp_compare
    movlw   0x6F
    movwf   temp_compare

    call    function_compare_2
    
    ;---comparison here
    call    mini_function_xor_2
    btfss   STATUS, Z
	goto    _exit_Check_ADC_Result
    ;------------------
    
    ;----Turn LED ON---------
    banksel LATD	
    bsf	    LATD, LATD6
    ;-----------------------

    ;----------set flags for GR---------
    call    key_jump_to_GR
    
    goto    _exit_Check_ADC_Result        
    ;------------------    


_exit_Check_ADC_Result
    
    return    
;-------------------------------------------------------------------------------
key_jump_to_GR ; this is to prepare the jump to ADC1
    
    banksel key_status_flag
    movlw    0x04
    movwf    key_status_flag    ;must go back to setup ADC
   
    return
    
;-------------------------------------------------------------------------------  
  
key_jump_to_ADC1 ; this is to prepare the jump to ADC1
    
    banksel key_status_flag
    clrf    key_status_flag
    incf    key_status_flag    ;must go back to setup ADC
    bsf	    ADC_pin, 0x0
    
    return
    
;-------------------------------------------------------------------------------  

key_jump_to_Play_Keynote  ; this is to prepare the jump for ADC0
    
    banksel key_status_flag
    
    movlw   0x03
    movwf   key_status_flag  ; for Play_Keynote
    bcf	    ADC_pin, 0x0
    
    return

;-------------------------------------------------------------------------------  

LED_shutdown    
    banksel LATD
    bcf	    LATD, LATD6
    bcf	    LATD, LATD7
    bcf	    LATB, LATB0
    bcf	    LATB, LATB1
    bcf	    LATB, LATB2
    bcf	    LATB, LATB3
    bcf	    LATB, LATB4
    bcf	    LATB, LATB5
    
    return
;-------------------------------------------------------------------------------    

mini_function_xor_2
   
    banksel math_logic
    movf    math_logic, W   
    xorlw   b'00000111'
   ; btfss   STATUS, Z
   ; nop
    
    return     
;-------------------------------------------------------------------------------
   
function_compare
    
    banksel Result_conversion
    clrf    math_logic
    movf    Result_conversion, W	    ;low end
    subwf   temp_compare, W	    ;subtract both low ends , 0 to 255
    btfsc   STATUS, Z
    bsf	    math_logic, 0
    btfsc   STATUS, C
    bsf	    math_logic, 4
    
    ;   xh < yh
    ; is tcounter < 0x31  ?   k - W  :  0x31 - tcounter
    movf    Result_conversion+1, W	    ;high end
    subwf   temp_compare+1, W	    ;subtract both high ends , 0 to 255
    btfsc   STATUS, Z
    bsf	    math_logic, 1
    btfsc   STATUS, C
    bsf	    math_logic, 5
    
    
    bcf	    STATUS, C
    ;   xl == yl
    movf    Result_conversion, W	    ;low end
    xorwf   temp_compare, W	    
    btfsc   STATUS, Z
    bsf	    math_logic, 2
    btfsc   STATUS, C
    bsf	    math_logic, 6
    
    ;   xh == yh
    movf    Result_conversion+1, W	    ;high end
    xorwf   temp_compare+1 , W	    
    btfsc   STATUS, Z
    bsf	    math_logic, 3
    btfsc   STATUS, C
    bsf	    math_logic, 7
    
    
    ; cccczzzz
    ; 00110000 : Result_conversion < 4    
    ; 00000000 : Result_conversion > 4	  
    ; 00001111 : Result_conversion = 4    

    return

;-------------------------------------------------------------------------------
function_compare_2
    ;0000 cz cz
    ;....................................
    bcf	    STATUS, C
    
    banksel Result_conversion   
    clrf    math_logic
    movf    Result_conversion, W	    ;low end only
    subwf   temp_compare, W	    
    btfsc   STATUS, Z
    bsf	    math_logic, 0
    btfsc   STATUS, C
    bsf	    math_logic, 1
    
    bcf	    STATUS, C
    ;   xl == yl
    movf    Result_conversion, W	    ;low end
    xorwf   temp_compare, W	    
    btfsc   STATUS, Z
    bsf	    math_logic, 2
    btfsc   STATUS, C
    bsf	    math_logic, 3
        
    ; 0000czcz
    ; 00000000 : result > temp    
    ; 00000010 : result < temp	  
    ; 00000111 : Result_conversion = temp    

    return
;;-------------------------------------------------------------------------------    
SPI_Tx_Rx		    ;2
;function used to start SPI communication and receive a byte

    banksel SSP1BUF	    ;2
    movf    SSP1BUF ,W	    ;1
    
    banksel byte_data	    ;2
    movf    byte_data, W    ;1
    
    banksel SSP1BUF	    ;2
    movwf   SSP1BUF	    ;1   ..11
    
loop_BF		
  btfss   SSP1STAT, BF      ;1,1,1,1,1,1,1,1,1,1,1,2
	goto loop_BF	    ;2,2,2,2,2,2,2,2,2,2,2
			    ;...35

    banksel SSP1BUF         ;2
    movf    SSP1BUF ,W	    ;1
    banksel byte_data	    ;1
    movwf   byte_data	    ;1
  
    return		    ;2  ...7
			    ;total: 125ns * (11+35+7) = 6.625us
;;-------------------------------------------------------------------------------    
Play_Keynote
; it uses key_note, clef, init and end address, and a variable for looping

;turn off the interrupts
 banksel	    INTCON
 bcf	    INTCON, GIE	
			    
    banksel device
    clrf    device
 ;if(clef == 1)
 
    movlw   0x01
    xorwf   clef, W
    btfsc   STATUS, Z
	goto	_clef_1
	
 ;if(clef == 2)   
    movlw   0x02
    xorwf   clef, W
    btfsc   STATUS, Z
	goto	_clef_2
	
;..............
;If a keynote is determined, the audio memory location range [init, end] is loaded...
_clef_1   ;bass_clef

_key_6F_1  
    movlw   0x6F
    movwf   temp_compare

    ;compares key_button and temp_compare
    ;compares if equal, and sets Z if it is equal
    call    function_compare_key_note	
    
    btfss   STATUS, Z
	goto	_key_6C_1
;%C3:    360,506     476,993
    movlw   0x3A
    movwf   init_addr
    movlw   0x80
    movwf   init_addr+1
    movlw   0x05
    movwf   init_addr+2
    
    movlw   0x41
    movwf   end_addr
    movlw   0x47
    movwf   end_addr+1
    movlw   0x07
    movwf   end_addr+2
    
	goto	_to_mem_dac
	
_key_6C_1
    movlw   0x6C
    movwf   temp_compare

    ;compares if equal, and sets Z if it is equal
    
    call    function_compare_key_note	
    
    btfss   STATUS, Z
	goto	_key_69_1
	
;%D3:    662,590     789,689
    movlw   0x3E
    movwf   init_addr
    movlw   0x1C
    movwf   init_addr+1
    movlw   0x0A
    movwf   init_addr+2
    
    movlw   0xB9
    movwf   end_addr
    movlw   0x0C
    movwf   end_addr+1
    movlw   0x0C
    movwf   end_addr+2
    
	goto	_to_mem_dac
	
_key_69_1
    movlw   0x69
    movwf   temp_compare

    ;compares if equal, and sets Z if it is equal
    
    call    function_compare_key_note	
    
    btfss   STATUS, Z
	goto	_key_66_1
;%E3:    885,688     994,485
    movlw   0xB8
    movwf   init_addr
    movlw   0x83
    movwf   init_addr+1
    movlw   0x0D
    movwf   init_addr+2
    
    movlw   0xB5
    movwf   end_addr
    movlw   0x2C
    movwf   end_addr+1
    movlw   0x0F
    movwf   end_addr+2
    
	goto	_to_mem_dac
	
_key_66_1
    movlw   0x66
    movwf   temp_compare

    ;compares if equal, and sets Z if it is equal
    
    call    function_compare_key_note	
    
    btfss   STATUS, Z
	goto	_key_61_1
;%F3:    1,077,684   1,192,881
    movlw   0xB4
    movwf   init_addr
    movlw   0x71
    movwf   init_addr+1
    movlw   0x10
    movwf   init_addr+2
    
    movlw   0xB1
    movwf   end_addr
    movlw   0x33
    movwf   end_addr+1
    movlw   0x12
    movwf   end_addr+2
    
	goto	_to_mem_dac
	
_key_61_1
    movlw   0x61
    movwf   temp_compare
    
    ;compares if equal, and sets Z if it is equal
    
    call    function_compare_key_note	
    
    btfss   STATUS, Z
	goto	_key_5A_1
;%G3:    1,279,090   1,395,079
    movlw   0x72
    movwf   init_addr
    movlw   0x84
    movwf   init_addr+1
    movlw   0x13
    movwf   init_addr+2
    
    movlw   0x87
    movwf   end_addr
    movlw   0x49
    movwf   end_addr+1
    movlw   0x15
    movwf   end_addr+2
    
	goto	_to_mem_dac
	
_key_5A_1
    movlw   0x5A
    movwf   temp_compare
    
    ;compares if equal, and sets Z if it is equal
    
    call    function_compare_key_note	
    
    btfss   STATUS, Z
	goto	_key_51_1
;%A3:    0           98,111
    movlw   0x00
    movwf   init_addr
    movlw   0x00
    movwf   init_addr+1
    movlw   0x00
    movwf   init_addr+2
    
    movlw   0x3F
    movwf   end_addr
    movlw   0x7F
    movwf   end_addr+1
    movlw   0x01
    movwf   end_addr+2
    
	goto	_to_mem_dac
	
_key_51_1
    movlw   0x51
    movwf   temp_compare

    ;compares if equal, and sets Z if it is equal
    
    call    function_compare_key_note	
    
    btfss   STATUS, Z
	goto	_key_43_1
;%B3:    181,310     277,308
    movlw   0x3E
    movwf   init_addr
    movlw   0xC4
    movwf   init_addr+1
    movlw   0x02
    movwf   init_addr+2
    
    movlw   0x3B
    movwf   end_addr
    movlw   0x3B
    movwf   end_addr+1
    movlw   0x04
    movwf   end_addr+2
    
	goto	_to_mem_dac
	
_key_43_1
    movlw   0x43
    movwf   temp_compare

    ;compares if equal, and sets Z if it is equal
   
    call    function_compare_key_note	
    
    btfss   STATUS, Z
	goto	_exit_play_note
;%C4:    476,994     585,791   middle C
    movlw   0x42
    movwf   init_addr
    movlw   0x47
    movwf   init_addr+1
    movlw   0x07
    movwf   init_addr+2
    
    movlw   0x3F
    movwf   end_addr
    movlw   0xF0
    movwf   end_addr+1
    movlw   0x08
    movwf   end_addr+2
    
	goto	_to_mem_dac
	
;........    
_clef_2   ;treble_clef
    
_key_43_2
    movlw   0x43
    movwf   temp_compare

    ;compares if equal, and sets Z if it is equal
    
    call    function_compare_key_note	
    
    btfss   STATUS, Z
	goto	_key_51_2
;%C4:    476,994     585,791   middle C
    movlw   0x42
    movwf   init_addr
    movlw   0x47
    movwf   init_addr+1
    movlw   0x07
    movwf   init_addr+2
    
    movlw   0x3F
    movwf   end_addr
    movlw   0xF0
    movwf   end_addr+1
    movlw   0x08
    movwf   end_addr+2
    
	goto	_to_mem_dac
	
_key_51_2
    movlw   0x51
    movwf   temp_compare

    ;compares if equal, and sets Z if it is equal
    
    call    function_compare_key_note	
    
    btfss   STATUS, Z
	goto	_key_5A_2
;%D4:    789,690     885,687
    movlw   0xBA
    movwf   init_addr
    movlw   0x0C
    movwf   init_addr+1
    movlw   0x0C
    movwf   init_addr+2
    
    movlw   0xB7
    movwf   end_addr
    movlw   0x83
    movwf   end_addr+1
    movlw   0x0D
    movwf   end_addr+2
    
	goto	_to_mem_dac
	
_key_5A_2
    movlw   0x5A
    movwf   temp_compare

    ;compares if equal, and sets Z if it is equal
    
    call    function_compare_key_note	
    
    btfss   STATUS, Z
	goto	_key_61_2
;%E4:    994,486     1,077,683
    movlw   0xB6
    movwf   init_addr
    movlw   0x2C
    movwf   init_addr+1
    movlw   0x0F
    movwf   init_addr+2
    
    movlw   0xB3
    movwf   end_addr
    movlw   0x71
    movwf   end_addr+1
    movlw   0x10
    movwf   end_addr+2
    
	goto	_to_mem_dac
	
_key_61_2
    movlw   0x61
    movwf   temp_compare

    ;compares if equal, and sets Z if it is equal
    
    call    function_compare_key_note	
    
    btfss   STATUS, Z
	goto	_key_66_2
;%F4:    1,192,882   1,279,089
    movlw   0xB2
    movwf   init_addr
    movlw   0x33
    movwf   init_addr+1
    movlw   0x12
    movwf   init_addr+2
    
    movlw   0x71
    movwf   end_addr
    movlw   0x84
    movwf   end_addr+1
    movlw   0x13
    movwf   end_addr+2
    
	goto	_to_mem_dac
	
_key_66_2
    movlw   0x66
    movwf   temp_compare

    ;compares if equal, and sets Z if it is equal
    
    call    function_compare_key_note	
    
    btfss   STATUS, Z
	goto	_key_69_2
;%G4:    1,395,080   1,478,277
    movlw   0x88
    movwf   init_addr
    movlw   0x49
    movwf   init_addr+1
    movlw   0x15
    movwf   init_addr+2
    
    movlw   0x85
    movwf   end_addr
    movlw   0x8E
    movwf   end_addr+1
    movlw   0x16
    movwf   end_addr+2
    
	goto	_to_mem_dac
	
_key_69_2
    movlw   0x69
    movwf   temp_compare

    ;compares if equal, and sets Z if it is equal
    
    call    function_compare_key_note	
    
    btfss   STATUS, Z
	goto	_key_6C_2
;%A4:    98,112      181,309
    movlw   0x40
    movwf   init_addr
    movlw   0x7F
    movwf   init_addr+1
    movlw   0x01
    movwf   init_addr+2
    
    movlw   0x3D
    movwf   end_addr
    movlw   0xC4
    movwf   end_addr+1
    movlw   0x02
    movwf   end_addr+2
    
	goto	_to_mem_dac
	
_key_6C_2
    movlw   0x6C
    movwf   temp_compare

    ;compares if equal, and sets Z if it is equal
    
    call    function_compare_key_note	
    
    btfss   STATUS, Z
	goto	_key_6F_2
;%B4:    277,309     360,505
    movlw   0x3C
    movwf   init_addr
    movlw   0x3B
    movwf   init_addr+1
    movlw   0x04
    movwf   init_addr+2
    
    movlw   0x39
    movwf   end_addr
    movlw   0x80
    movwf   end_addr+1
    movlw   0x05
    movwf   end_addr+2
    
	goto	_to_mem_dac
	
_key_6F_2
    movlw   0x6F
    movwf   temp_compare

    ;compares if equal, and sets Z if it is equal
    
    call    function_compare_key_note	
    
    btfss   STATUS, Z
	goto	_exit_play_note
;%C5:    585,792     662,589
    movlw   0x40
    movwf   init_addr
    movlw   0xF0
    movwf   init_addr+1
    movlw   0x08
    movwf   init_addr+2
    
    movlw   0x3D
    movwf   end_addr
    movlw   0x1C
    movwf   end_addr+1
    movlw   0x0A
    movwf   end_addr+2
    
	goto	_to_mem_dac
	
;........

;......................................
_to_mem_dac
	
;Turn ON the Amp first. Must wait for 10 ms
    banksel LATE
    bsf	    LATE, LATE2 ;SS~ AMP on

    ;----Delay of ~10ms--------
    call	delay_10_ms
    call	delay_10_ms
    ;-------------------------
    
_to_mem_dac_in    
; fetch data from memory and send to DAC
;setup for memory
    banksel device				    ;2
    bsf     device, 0x00	;select memory	    ;1	    
    call    SPI_change_MEM_DAC			    ;21
;...............................................    
    banksel LATD				    ;2
    bcf	    LATD, LATD1  ;enable SS for memory	    ;1   :27
       
    ;send command for reading, and address: 32 bits
    ;[0x03] [23... ][... ][ ...0]
    banksel byte_data				    ;2
    movlw   0x03				    ;1
    movwf   byte_data				    ;1   :31
;-------------------------    
    call    SPI_Tx_4_bytes			    ;...174
;-------------------------							;113	    
;read data: send a dummy value to memory..
    banksel byte_data				    ;2  	    
    clrf    byte_data				    ;1   //177
    
;-------------------------    
    call    SPI_Rx_2_bytes;16 bits stored in audio_data   ;89
;-------------------------							;164
    banksel LATD				    ;2
    bsf	    LATD, LATD1  ;disable SS for memory     ;1   :269   //
;................................................    
;setup for DAC
    banksel device				    ;2
    bcf     device , 0x00	;select DAC         ;1
    call    SPI_change_MEM_DAC			    ;21
;............................................							;293
    banksel LATD				    ;2
    bcf	    LATD, LATD3  ;enable SS for DAC	    ;1    :296
    
    ;send to DAC: 24 bits
    banksel byte_data				    ;2				    
    clrf    byte_data				    ;1
;--------------------------------    
    call    SPI_Tx_3_bytes			    ;130   //429
;--------------------------------    
    banksel LATD				    ;2
    bsf	    LATD, LATD3  ; disable dac
    
    banksel math_logic			    
    clrf    math_logic				    ;1  //430
;.........................
;increment once to compensate for the offset in  SPI_Rx_2_bytes
    
    bcf	   STATUS, Z				    ;1
    
    incf   init_addr				    ;1
    
    btfsc   STATUS, Z				    ;2    //5
	incf   init_addr+1			    
    
	btfsc   STATUS, Z			    ;2    //7
	    incf   init_addr+2	    
    
_comparing_address	    
    ;banksel init_addr			    
    movf    init_addr, W			    ;1
    xorwf   end_addr, W				    ;1
	btfsc   STATUS, Z			    ;2   //11
	bsf	math_logic,0x00			    
	
    movf    init_addr+1, W			    ;1
    xorwf   end_addr+1, W			    ;1
	btfsc   STATUS, Z			    ;2    //15
	bsf	math_logic,0x01			    
	
    movf    init_addr+2, W			    ;1
    xorwf   end_addr+2, W			    ;1
	btfsc   STATUS, Z			    ;2    //19
	bsf	math_logic,0x02			    
    
    movf   math_logic, W			    ;1
    xorlw   b'00000111'				    ;1
    btfsc   STATUS, Z				    ;2    //23
	goto	_exit_play_note			    
    
    ;----------------------------------
    ;must be incremented again for next byte
	
    incf   init_addr				    ;1
    
    btfsc   STATUS, Z				    ;2    //26
	incf   init_addr+1			    
    
	btfsc   STATUS, Z			    ;2    //28
	    incf   init_addr+2	
    ;----------------------------------
    
;total: 125ns*(430 + 28 + 2) = 57.5us
;1/16000 =  62.5us
;62.5-57.5 = 5 us delay    , about 44 instruction cycles
    
;5: about 4.75us :
    banksel byte_data	     
    movlw   d'5'	    
    movwf   byte_data
    call    delay_us    
   
;...........................	        
	goto	_to_mem_dac_in			    ;2    //25   	                           
;........................................	

_exit_play_note	
	
   ;Turn the Amp OFF
    banksel LATE
    bcf	    LATE, LATE2 ;SS~ AMP off


;;............................................... 
    
    banksel LATD				    ;2
    bsf	    LATD, LATD3  ; disable dac
    ;...................................................    
    
    banksel SSP1CON1						
    bcf	    SSP1CON1, SSPEN ;	
    
    ;turn on the interrupts
    banksel INTCON
    bsf	    INTCON, GIE	
 
    
    return

;-------------------------------------------------------------------------------    
;-------------------------------------------------------------------------------
;SSPBUFF must be read before transmitting data				    ;Tcyc
;reading it clears BF (uC SPI buffer)
SPI_Tx_3_bytes			    ;2

    banksel SSP1BUF		    
    movf    SSP1BUF, W		    
    
    banksel byte_data		    ;2
    movf    byte_data, W	    ;1 
    
    banksel SSP1BUF		    ;2
    movwf   SSP1BUF		    ;1   //8
;..............................................     
loop_3_1			    
    btfss   SSP1STAT, BF	    ;1,1,1,1,1,1,1,1,1,1,1,2
	goto loop_3_1		    ;2,2,2,2,2,2,2,2,2,2,2 
	                            ;...35   
;.............................................. 				    
    movf    SSP1BUF ,W		    ;1   //44
    
    banksel audio_data		    ;2
    movf    audio_data+1, W	    ;1
    
    banksel SSP1BUF		    ;2
    movwf   SSP1BUF		    ;1    :50 
;..............................................     
loop_3_2			    
    btfss   SSP1STAT, BF	    ;1,1,1,1,1,1,1,1,1,1,1,2
	goto loop_3_2		    ;2,2,2  :6
	                            ;...35   
;.............................................. 				    
    movf    SSP1BUF ,W		    ;1  //86
    
    banksel byte_data		    ;2
    movf    audio_data, W	    ;1    //89
    
    banksel SSP1BUF		    ;2
    movwf   SSP1BUF		    ;1   :92
;..............................................    
loop_3_3			    
    btfss   SSP1STAT, BF	    ;1,1,1,1,1,1,1,1,1,1,1,2 
	goto loop_3_3		    ;2,2,2,2,2,2,2,2,2,2,2 
	                            ; ...35   
;..............................................				    
    banksel SSP1BUF		    ;2   //127
    movf    SSP1BUF ,W		    ;1
      
    return			    ;2     //130
  
;-------------------------------------------------------------------------------
  				    ;Tcyc
SPI_Tx_4_bytes			    ;2

    banksel SSP1BUF		    ;2
    movf    SSP1BUF, W		    ;1
    
    banksel byte_data		    ;2
    movf    byte_data, W	    ;1    ;8
    
    banksel SSP1BUF		    ;2
    movwf   SSP1BUF		    ;1   : 11
;.........................................................    
loop_4_1			    ;SCK: Fosc/16= 500ns, 32*125ns = 4us 
    btfss   SSP1STAT, BF	    ;1,1,1,1,1,1,1,1,1,1,1,2 
	goto loop_4_1		    ;2,2,2,2,2,2,2,2,2,2,2  
				    ; ...35
;.........................................................   				    
    movf    SSP1BUF ,W		    ;1  //47
    
    banksel init_addr		    ;2 
    movf    init_addr+2, W	    ;1
    
    banksel SSP1BUF		    ;2
    movwf   SSP1BUF		    ;1    :53
;.........................................................       
loop_4_2			    
    btfss   SSP1STAT, BF	    ;1,1,1,1,1,1,1,1,1,1,1,2
	goto loop_4_2		    ;2,2,2,2,2,2,2,2,2,2,2 
				    ;..35
;......................................................... ;...11    //41
    movf    SSP1BUF ,W		    ;1  //88
    
    banksel init_addr		    ;2
    movf    init_addr+1, W	    ;1
    
    banksel SSP1BUF		    ;2
    movwf   SSP1BUF		    ;1    //94
;.........................................................       
loop_4_3			    
    btfss   SSP1STAT, BF	    ;1,1,1,1,1,1,1,1,1,1,1,2
	goto loop_4_3		    ;2,2,2,2,2,2,2,2,2,2,2
	                            ;...35
;.........................................................   				    
    movf    SSP1BUF ,W		    ;1 //130
    
    banksel init_addr		    ;2
    movf    init_addr, W	    ;1
    
    banksel SSP1BUF		    ;2
    movwf   SSP1BUF		    ;1    :136
    ;last byte of address sent.. waiting for data...
;.........................................................       
loop_4_4			    
    btfss   SSP1STAT, BF	    ;1,1,1,1,1,1,1,1,1,1,1,2
	goto loop_4_4		    ;2,2,2,2,2,2,2,2,2,2,2
	                            ;...35  
;.........................................................   				    
    ;read buffer to clear it
    banksel SSP1BUF
    movf    SSP1BUF ,W		    ;1  //172

    return			    ;2   //174

				       
;-------------------------------------------------------------------------------
  				    ;Tcyc
SPI_Rx_2_bytes			    ;2

;    banksel SSP1BUF		    
;    movf    SSP1BUF, W		    
    
;    banksel byte_data		    ;
    movf    byte_data, W	    ;1
    
    banksel SSP1BUF		    ;2
    movwf   SSP1BUF		    ;1   :6
;............................    
loop_2_1			    
    btfss   SSP1STAT, BF	    ;1,1,1,1,1,1,1,1,1,1,1,2
	goto loop_2_1		    ;2,2,2,2,2,2,2,2,2,2,2
				    ;...35   
;...........................				    
    movf    SSP1BUF ,W		    ;1  //41
    
    banksel audio_data		    ;2
    movwf   audio_data		    ;1

    movf    byte_data, W	    ;1
    banksel SSP1BUF		    ;2
    movwf   SSP1BUF		    ;1   :48
;...........................    
loop_2_2			    
    btfss   SSP1STAT, BF	    ;1,1,1,1,1,1,1,1,1,1,1,2
	goto loop_2_2		    ;2,2,2,2,2,2,2,2,2,2,2
				    ;...35
;...........................				    
    movf    SSP1BUF ,W		    ;1 // 84
    
    banksel audio_data		    ;2
    movwf   audio_data+1	    ;1    
    
    return			    ;2   :89

				   
;-------------------------------------------------------------------------------
    
function_compare_key_note


    bcf	    STATUS, C
    banksel key_button    
    clrf    math_logic
    movf    key_button, W	    ;low end only
    subwf   temp_compare, W	    
    btfsc   STATUS, Z
    bsf	    math_logic, 0
    btfsc   STATUS, C
    bsf	    math_logic, 1
    
    bcf	    STATUS, C
    ;   xl == yl
    movf    key_button, W	    ;low end
    xorwf   temp_compare, W	    
    btfsc   STATUS, Z
    bsf	    math_logic, 2
    btfsc   STATUS, C
    bsf	    math_logic, 3
    
    ; 0000czcz
    ; 00000000 : key_button > temp    
    ; 00000010 : key_button < temp	  
    ; 00000111 : key_button = temp    
    
    call    mini_function_xor_2
    
    return
    
;;-------------------------------------------------------------------------------    
Read_ADC_Input

    banksel Result_conversion
    
    clrf    Result_conversion
    clrf    Result_conversion+1
    clrf    iter_i
   
loop_outer_read
    
    banksel ADCON0
    bsf	    ADCON0, ADGO    ;start ADC conversion

loop_inner_read    
    
    btfsc   ADCON0, ADGO    ;must wait here until it is done
	goto	loop_inner_read
	
    ;Result_conversion += (ADRESH <<8 ) | ADRESL; 
    ;combine
    banksel ADRESL
    movf    ADRESL, W
    banksel Result_conversion
    ;movwf   Result_conversion
    addwf   Result_conversion
    
    
    banksel ADRESH
    movf    ADRESH, W
    banksel  Result_conversion
    ;movwf   Result_conversion+1
    addwfc   Result_conversion+1
    
    ;add delay of 10 ms for charging CHold
    ;........................
    call    delay_10_ms
    movlw   d'138'
    movwf   byte_data    
    call    delay_us
    ;........................
_skip_loop_delay 
    
    banksel iter_i
    incf    iter_i
    
    movlw   d'17'   ;17  ;33
    xorwf   iter_i, W
    btfss   STATUS, Z
	goto	loop_outer_read	  ;repeat for 32 iterations
    
    
	
    banksel PIR1
    bcf	    PIR1, ADIF
    
    ;...................
    ;average: divide by 32  or >> 4
    banksel  Result_conversion
    
    lsrf    Result_conversion+1 ,F ; 0->[]->C
    rrf    Result_conversion,F  ;
    
    lsrf    Result_conversion+1,F 
    rrf    Result_conversion,F
    
    lsrf    Result_conversion+1,F
    rrf    Result_conversion,F
    
    lsrf    Result_conversion+1,F
    rrf    Result_conversion,F

    ;.....added:  >> 5
;    ;...................
;    ;shift them to the right 3 times, into L
;    ;for convenience
;
    lsrf    Result_conversion+1,F 
    rrf    Result_conversion,F
    
    lsrf    Result_conversion+1,F
    rrf    Result_conversion,F
    
    lsrf    Result_conversion+1,F
    rrf    Result_conversion,F

    ;...................
    return
;;-------------------------------------------------------------------------------    
Set_Counter
    
    banksel tcounter
    clrf    tcounter
    movlw   0x01
    movwf    time_flag
    
    bcf	    INTCON, TMR0IF
    
    bsf	    INTCON, TMR0IE
    
    banksel TMR0
    clrf    TMR0

    return
;;-------------------------------------------------------------------------------    
;;-------------------------------------------------------------------------------
;Function used to save the audio data in the memory unit. It must be declared in main function   
Program_Flash    

;     Tcyc: 125 ns 
;******************************     
;     BAUD RATE
;     Start bit : 0
;     Data bits : 8
;     Parity:     none
;     Stop bits:  1
;     
;     Bps:  9600
;     1/9600 = 104.167 us per bit
;     
;     1/14400 = 69.44 us per bit
;      
;     1/19200 = 52.0833 us
;*****************************    
    
    call    Setup_Oscillator
    call    Set_IO_Pins
    call    Setup_Timer0

    call    Setup_SPI    
    
    banksel SSP1STAT
    bsf	    SSP1STAT, SMP
    bsf	    SSP1STAT, CKE
    bcf	    SSP1CON1, CKP
    
    banksel SSP1CON1
    bsf	    SSP1CON1, 0  
    
    ;spi master fosc/16 , fastest possible
    ;SCK period: 2*(FOSC/4 +20ns) = 290ns or 3.448 MHz
    ;We need to clock at FOSC/16 = 2MHz < 3.448 MHz
    
    banksel SSP1CON1
    bsf	    SSP1CON1, SSPEN
;-------------------IR Emitters
    banksel TRISB
    bsf	    TRISB, 0x07
    bsf	    TRISB, 0x06
    
    bsf	    TRISA, 2   ;TTL input
    
    banksel WPUB
    bsf	    WPUB, 0x07
    bsf	    WPUB, 0x06
;-------------------  

; wait for pushbutton == 0, since it has wpu    
    banksel PORTA
loop_flash_push    
    btfsc   PORTA, 4
	goto	loop_flash_push   
	
loop_flash_push_red    
    btfsc   PORTA, 3
	goto	loop_flash_push_red 	
;................................   
;send enable write enable command  
    call    write_enable	    ;8.375us
 ;................................
   
; poll status flag from memory    
    call    poll_status_flash       ;15.625us 
;.................................
;Disable protection levels:    
;send write-status-register command  
    banksel LATD
    bcf	    LATD, LATD1	;CE# low 
    
    banksel byte_data
    movlw   0x01				   
    movwf   byte_data

    call    SPI_Tx_Rx	    ;6.625us
    
    banksel byte_data
    movlw   b'00000000'				   
    movwf   byte_data

    call    SPI_Tx_Rx      ;6.625us
    
    banksel LATD
    bsf	    LATD, LATD1	;CE# high   //WREN goes to zero here
 ;.................................
 ; poll status flag from memory    
    call    poll_status_flash   ;15.625us
 ;.................................     
 ;send enable write enable command  
    call    write_enable        ;8.375us
 ;................................
 
;clear the whole memory chip	**************************
 ;   banksel LATE
 ;   bsf	    LATE, LATE0 ;RE0 led ON, just to tell we are here
    bcf	    LATD, LATD1	;CE# low
    
    banksel byte_data
    movlw   0xC7				    
    movwf   byte_data
    
    call    SPI_Tx_Rx
 
    banksel LATD
    bsf	    LATD, LATD1	;CE# high
      
;;.................................    ******************
;; poll status flag from memory    
;    call    poll_status_flash   ;50ms
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    banksel init_addr
    clrf    init_addr
    clrf    init_addr+1
    clrf    init_addr+2
    
    ;clrf    iter_i

;..........HARD CODED...based on Matlab...    
    ;define the size of the complete data to set 
    ;the end address for flash memory programming
    movlw   0x85
    movwf   end_addr	; low
    movlw   0x8E
    movwf   end_addr+1	; middle
    movlw   0x16
    movwf   end_addr+2	; high
;.................................
;
;;*******************************************
loop_start_flash    

;.................................   
 banksel    audio_data			    ;2
 clrf	    audio_data			    ;1
 clrf	    audio_data+1		    ;1
;....................................		;375ns

    movlw   d'69'	    
    movwf   byte_data 
;....................................
; Serial Port sends 8-bits at a time
;wait for incoming start bit:Low level 
    banksel PORTA			    ;2  //0.625 us
loop_flash_1				    
    btfsc   PORTA, 2			    ;2  
	goto	loop_flash_1
;.....................................	
; Add delay of 52.08 us	//////////////
;.....................................	
    call    delay_us  ;52.625us
;.........................  68: 51.875 us  69: 52.625us
    
;.........................  ;52.875 us
 ;every 52 us poll PORTA RA5, 16 times

;Serial Port idle state 1
;loop until there is a low transition
;This zero marks the starting point,
;then comes the 8 bits
;............................
read_serial_input    
;bit 0
    banksel PORTA
    btfsc   PORTA, 2
    bsf	    audio_data, 0x00
;............................0.5us      // 53.375us     
    call    delay_us	
;.....................just this: 52.5us // 105.875us
    
;bit 1
    banksel PORTA
    btfsc   PORTA, 2
    bsf	    audio_data, 0x01
;........................  0.5us  // 106.375us   
    call    delay_us
;........................:52.5us  // 158.875us
    
;bit 2
    banksel PORTA
    btfsc   PORTA, 2
    bsf	    audio_data, 0x02
;........................  0.5us  // 159.375us  
    call    delay_us
;........................:52.5us  // 211.875us
;bit 3
    banksel PORTA
    btfsc   PORTA, 2
    bsf	    audio_data, 0x03
;........................  0.5us  // 212.375us   
    call    delay_us
;........................:52.5us  // 264.875us
;bit 4
    banksel PORTA
    btfsc   PORTA, 2
    bsf	    audio_data, 0x04
;........................  0.5us  // 265.375us   
    call    delay_us
;........................:52.5us  // 317.875us  
;bit 5
    banksel PORTA
    btfsc   PORTA, 2
    bsf	    audio_data, 0x05
;........................  0.5us  // 318.375us  
    call    delay_us   
;........................:52.5us  // 370.875us    
;bit 6
    banksel PORTA
    btfsc   PORTA, 2
    bsf	    audio_data, 0x06
;........................  0.5us  // 371.375usg  
    call    delay_us
;........................:52.5us  // 423.875us    
;bit 7
    banksel PORTA
    btfsc   PORTA, 2
    bsf	    audio_data, 0x07
;........................  0.5us  // 424.375us   
    call    delay_us
;........................:52.5us  // 476.875us 

;..........................
;Byte received. Next, send it to the flash memory unit..	
;.......................... 
 
;................................    
;send enable write enable command  
    call    write_enable	    ;8.375us
;................................ 
    
    banksel LATD		    ;2
    bcf	    LATD, LATD1	;CE# low    ;1

;send command for Byte write. WREN has already been enabled 
    banksel byte_data		    ;2
    movlw   0x02		    ;1		   
    movwf   byte_data		    ;1
    call    SPI_Tx_Rx		    ;3us	    
				    ;125ns*(7)+3us = 3.875us
;send 3 byte of initial address
    movf    init_addr+2, W	    ;1		    
    movwf   byte_data		    ;1
    call    SPI_Tx_Rx		    ;3us
				    ;3.250+3.875 = 7.125us
    movf    init_addr+1, W	    ;1	    
    movwf   byte_data		    ;1
    call    SPI_Tx_Rx		    ;3us
				    ;3.250 + 7.125 = 10.375us
    movf    init_addr, W	    ;1		    
    movwf   byte_data		    ;1
    call    SPI_Tx_Rx		    ;3us
				    ;3.25 + 10.375 = 13.625us
;;...........................    
;send byte

    movf    audio_data, W	    ;1		    
    movwf   byte_data		    ;1
    call    SPI_Tx_Rx		    ;3us
				    ;3.25 + 13.625 = 16.875us
    banksel LATD		    ;2
    bsf	    LATD, LATD1	;CE# high   ;1
				    ;17.25us
;;..........................    
    call    poll_status_flash	    ;15.625us

;here it must be compared 3 byte init address == end address
    banksel math_logic	     ;1
    clrf    math_logic	     ;1

    movf    end_addr, W	     ;1
    xorwf   init_addr, W     ;1
    btfsc   STATUS, Z	     ;1
    bsf	    math_logic, 0    ;1   ..6

    movf    end_addr+1, W    ;1
    xorwf   init_addr+1, W   ;1
    btfsc   STATUS, Z	     ;1
    bsf	    math_logic, 1    ;1   ..10

    movf    end_addr+2, W    ;1
    xorwf   init_addr+2, W   ;1
    btfsc   STATUS, Z	     ;1
    bsf	    math_logic, 2    ;1

    movlw   b'00000111'	     ;1
    xorwf   math_logic, W    ;1
    btfsc   STATUS, Z	     ;2    ..20
	goto	_exit_loop_5  ;2 if Z=1, it is completed	    

;;...................................    ;125ns*(20) = 2.5us
;;//////////////////////////////////
;increment address
    banksel init_addr		    ;2
    incf    init_addr		    ;1
    
    btfsc   STATUS, Z		    ;2
    incf    init_addr+1
  
    btfsc   STATUS, Z		    ;2
    incf    init_addr+2
				    ;0.875us
    call    toggle_R2  ;toggles G2			    
;;..........................
;; Confirm Data?  If more data, return to the start of reading incoming data cycle    
;;..........................
    goto    loop_start_flash	    ;2  //71.125us
    
;total dead time  =  71.125us
    
;;..........................    
_exit_loop_5

    return
	
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
write_enable			    ;2
   ;................................    
;send enable write enable command  
    banksel LATD		    ;2
    bcf	    LATD, LATD1	;CE# low    ;1
    
    banksel byte_data		    ;2
    movlw   0x06		    ;1		   
    movwf   byte_data		    ;1 ..9

    call    SPI_Tx_Rx		    ;6.625us
    banksel LATD		    ;2
    bsf	    LATD, LATD1	;CE# high   ;1
 ;................................
   return			    ;2
		    ;125ns(14)+6.625us = 8.375us

;-------------------------------------------------------------------------------  
;-------------------------------------------------------------------------------  
poll_status_flash		    ;2
    ;for writing a byte, it takes ~10us
    ;.............................................
loop_flash_status		    
    banksel LATD		    ;2
    bcf	    LATD, LATD1	;CE# low    ;1   
    
    banksel byte_data		    ;2
    movlw   0x05		    ;1		   
    movwf   byte_data		    ;1   .. 7
    
    call    SPI_Tx_Rx		    ;6.625us
    
    movlw   0x00		    ;1	;dummy cycle	    
    movwf   byte_data		    ;1  .......at this point 8us
				    ; add 5.75us aside (35*0.125)
    call    SPI_Tx_Rx		    ;6.625us
    banksel LATD		    ;1
    bsf	    LATD, LATD1	;CE# high   ;1   ..11
    ;;...................................... 14.625us
    banksel byte_data		    ;2   
    btfsc   byte_data, 0x00	    ;1,2
	goto	loop_flash_status   ;2   
				    
    return			    ;2
    ;one loop 0.25us + 0.25us + (14.625us + 0.5us) = 15.625us  
    ;two loops 0.25us + 0.25us + 2*(14.625us) + 2*(0.5us) + 0.125us) = 30.875us
;;-------------------------------------------------------------------------------    
toggle_G2

    banksel LATD
    btfsc   LATD, LATD4
    goto    turn_off_ttl3
    goto    turn_on_ttl3
    
turn_on_ttl3
    bsf	    LATD, LATD4
    goto    exit_on_off_ttl3
    
turn_off_ttl3    
    bcf	    LATD, LATD4
    
exit_on_off_ttl3
 return
 
toggle_R2

    banksel LATD
    btfsc   LATD, LATD5
    goto    turn_off_ttl4
    goto    turn_on_ttl4
    
turn_on_ttl4
    bsf	    LATD, LATD5
    goto    exit_on_off_ttl4
    
turn_off_ttl4    
    bcf	    LATD, LATD5
    
exit_on_off_ttl4
 return 
 
 
toggle_G1

    banksel LATC
    btfsc   LATC, LATC7
    goto    turn_off_ttl5
    goto    turn_on_ttl5
    
turn_on_ttl5
    bsf	    LATC, LATC7
    goto    exit_on_off_ttl5
    
turn_off_ttl5    
    bcf	    LATC, LATC7
    
exit_on_off_ttl5
 return  
 
;;------------------------------------------------------------------------------- 		
delay_us  
    banksel time_flag
    clrf    time_flag
delay_us_in    
    incf    time_flag	
    movf    byte_data, W
    xorwf   time_flag, W
    btfss   STATUS, Z
	goto	delay_us_in
	
    return      
;;-------------------------------------------------------------------------------  
;;------------------------------------------------------------------------------- 
; Function that sets the microcontroller for normal operation
Setup_All

    ;ADC0 or student side goes first
    banksel ADC_pin
    clrf    ADC_pin
    
    clrf    rg_flag
    clrf    key_status_flag
    
    call    Setup_Oscillator
    call    Set_IO_Pins
    call    Set_Interrupts
    
    call    Setup_Timer0
    call    Setup_SPI
    call    delay_10_ms
    
    banksel LATB	    ;turn ON the IR emitters
    bsf	    LATB, LATB6	
    bsf	    LATB, LATB7
    
    call    PWM3_for_IR
    
    return
;;-------------------------------------------------------------------------------

PWM3_for_IR
  ;..............
  ;setup
  banksel   TRISE
  bsf	    TRISE, TRISE0
  bsf	    TRISE, TRISE1
  
  banksel   PWM3CON
  clrf	    PWM3CON
  
  banksel   PR2
  movlw	    0x22
  movwf	    PR2
  
  banksel   PWM3CON
  bsf	    PWM3CON, 4
  
  banksel   PWM3DCH
  movlw	    b'00011111'
  movwf	    PWM3DCH
  
  banksel   PWM3DCL
  bsf	    PWM3DCL, 7
  bsf	    PWM3DCL, 6
  
  ;.............
  ;config Timer2
  banksel   PIR1
  bcf	    PIR1, TMR2IF
  
  banksel   T2CON
  bsf	    T2CON, TMR2ON
  ;..............
  
  ;PPS
  ;................
  banksel   RE0PPS
  movlw	    b'00001110'
  movwf	    RE0PPS
  
  banksel   RE1PPS
  movlw	    b'00001110'
  movwf	    RE1PPS
  ;.................
  
  ;enable PWM
  banksel   PWM3CON
  bsf	    PWM3CON, 7
  ;..............
  return
  
 ;---------------------------------------------------------------------- 

;********************************************************************
;****************This is the idle function of the Firmware***********
;********************************************************************

Super_Function

;key_status_flag = 0; // use for access to different levels of if's
;/*
; 0: Only phototransistors    **_IOC_ISR
; 1: Sets ADC
; 2: Read ADC Host/Client
; 3: Play keynote
; 4: Only Red and Green buttons  ** _IOC_ISR
; */  
_inner_loop_super    
    banksel key_status_flag
    movlw   0x01	
    xorwf   key_status_flag, W
    btfsc   STATUS, Z
	goto	part_A

    ;/////////////////////////////////////
    movlw   0x02
    xorwf   key_status_flag, W
    btfsc   STATUS, Z
	goto	part_B
    ;/////////////////////////////////////
    
    movlw   0x03
    xorwf   key_status_flag, W
    btfsc   STATUS, Z
	goto	part_C	

	goto _inner_loop_super
		
;...................................	
part_A	   ;setups the ADC module
	
    movlw   0x02
    movwf   key_status_flag
    call    Setup_ADC
    call    delay_10_ms
    
    goto    _inner_loop_super
;...................................    
part_B	;Reads from the ADC pins
 
    ;................................    
    call    Read_ADC_Input   ;after some iterations, gets the reading
    call    Check_ADC_Result

	goto	_inner_loop_super
    ;.................................

;...................................	    
part_C

    call    Play_Keynote	;uses result coversion and keybutton
	
    ;---------clear all LEDS-------    
     call    LED_shutdown
    ;------------------------------    
    ;---------------------------------------
    ;//Allow only the Red and Green buttons
    banksel key_status_flag
    movlw   0x04
    movwf   key_status_flag
    clrf    clef
    ;---------------------------------------
    
    goto    _inner_loop_super 
    
   return

;-------------------------------------------------------------------------------      
;-------------------------------------------------------------------------------    
 

;********************************************************************
;****************This is the Main Function of the Firmware***********
;******************************************************************** 
;MAIN_PROG CODE                      ; let linker place main program

START

  call    Setup_All
  call    Super_Function
  ;call   Program_Flash   
  nop  

    GOTO $                          ; loop forever

    END
    
;-------------------------------------------------------------------------------    
    
;%       from        to		initial	    end
;%A3:    0           98,111	00-00-00H   01-7F-3FH
;%A4:    98,112      181,309	01-7F-40    02-C4-3D
;%B3:    181,310     277,307	02-C4-3E    04-3B-3B
;%B4:    277,308     360,505	04-3B-3C    05-80-39
;%C3:    360,506     476,993	05-80-3A    07-47-41
;%C4:    476,994     585,791	07-47-42    08-F0-3F 
;%C5:    585,792     662,589	08-F0-40    0A-1C-3D
;%D3:    662,590     789,689	0A-1C-3E    0C-0C-B9
;%D4:    789,690     885,687	0C-0C-BA    0D-83-B7
;%E3:    885,688     994,485	0D-83-B8    0F-2C-B5
;%E4:    994,486     1,077,683	0F-2C-B6    10-71-B3
;%F3:    1,077,684   1,192,881	10-71-B4    12-33-B1
;%F4:    1,192,882   1,279,089	12-33-B2    13-84-71
;%G3:    1,279,090   1,395,079	13-84-72    15-49-87
;%G4:    1,395,080   1,478,277	15-49-88    16-8E-85
    
;C D  E F  G A  B C
    
    ;15 in total
;C3 D3 E3  F3  G3  A3  B3  C4    Bass        
;C4 D4 E4  F4  G4  A4  B4  C5    Treble
