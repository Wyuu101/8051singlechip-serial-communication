;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;			������Ŀ����Ƭ����PC����ȫ˫������ͨ��
;
;			��������:S1~S4�����ֱ��Ӧ4����ͬ����
;
;			S1:�����¶����ݲɼ���ʵʱ��ʾ��LCD�����͵�����        
;			S2:��PC��ȫ˫��ͨ��ʵ�飬LCD��LEDʵʱ��ʾPC����������
;			S3:���Ӹ��٣���PC�����̿��Ƶ�Ƭ������9������,ͬʱ����ʵʱ��ʾ���µ��ټ�
;			S4:���׵籨��ͨ����S4���µĳ���ת��Ϊ0��1���չ�8λ������ת��ΪASCII�ַ����͸�PC��
;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



;-----------------------------���ݶ���----------------------------------------
RS		EQU	P2.6					;ͨ��RSȷ����д���ݻ���д����
RW		EQU	P3.6					;RW��/д���ƶ�����,дģʽΪ�͵�ƽ
E		EQU	P2.7					;��Eһ�������彫��������Һ�������������д����

B20OK 	BIT 00H						;�ɹ���ʼ��18B20��־λ
DQ		BIT P3.7					;18B20����
TEMP_L	EQU 36H						;�����¶ȵĵ�8λ
TEMP_H 	EQU 35H						;�����¶ȵĸ�8λ
TEMP_0C EQU 37H						;�������¶�ֵ
TEMP_PD EQU 38H  					;�¶ȵ�С��λ
;-----------------------------������------------------------------------		
	ORG	00H
	AJMP MAIN
	ORG 30H		
MAIN:	
	ACALL	INIT_LCD        		;LCD��ʼ��
	ACALL	HELLO_LCD				;��������ʾ
	ACALL   LED_CHECK				;LED���Լ�
	ACALL   INIT_SERIAL_PORT		;���ô���
	ACALL	BEEP_CHECK				;�������Լ�
	ACALL   MODE_CHOOSE_OUT			;ѭ���ȴ��û�ѡ��ģʽ
		
	
;------------------------------LCD��ʼ��---------------------------------
INIT_LCD:		
    ACALL CLEAR_LCD 				;����
	MOV P0,#38H						;��ʾ����(������ʾ��5��7����)
	ACALL ENABLE
	MOV P0,#0FH						;��ʾ���ؿ���(��ʾ��꣬�����˸)
	ACALL ENABLE
	MOV P0,#06H						;���ù���Զ�+1
	ACALL ENABLE
	RET						    
;----------------------------LCD��ʾ������-------------------------------
; 
;               Ч������һ����ʾHELLO WORLD,�ڶ�����ʾ����
;		
HELLO_LCD:							;��ʾHELLO WORLD
    MOV P0,#80H						;����LCD��һ�еĿ�ʼλ��
	ACALL ENABLE					
    MOV R1,#0	    				;��0��ʼ��ʾTABLE1�е�ֵ
	MOV	DPTR,#TABLE1				;׼����TABLE1ȡ��
HELLO_LCD_LOOP:						;ѭ����һ��TABLE1�е��ַ���ʾ�ڵ�һ��
  	MOV A,R1       
	MOVC A,@A+DPTR
	MOV R2,#50						;�����ַ���ӡ��ʱ����Ϊ50ms
	ACALL  WRITE_LCD          		;��ʾ��LCD
	INC R1							
	CJNE A,#00H,HELLO_LCD_LOOP		;�Ƿ�00H,���Ļ�������ӡ
	MOV R1,#00H


AUTHOR_LCD:							;��ʾ����
	MOV P0,#0C0H					;����LCD��һ�еĿ�ʼλ��
	ACALL ENABLE					
    MOV R1,#0	    				;��0��ʼ��ʾTABLE0�е�ֵ
	MOV	DPTR,#TABLE0				;׼����TABLE0ȡ��	
AUTHOR_LCD_LOOP:
	MOV A,R1       
	MOVC A,@A+DPTR
	MOV R2,#50						;�����ַ���ӡ��ʱ����Ϊ50ms
	ACALL  WRITE_LCD          		;��ʾ��LCD
	INC R1							
	CJNE A,#00H,AUTHOR_LCD_LOOP		;�Ƿ�00H,���Ļ�������ӡ
	MOV R1,#00H					
	RET

;------------------------------LED���Լ�----------------------------------
; 
;        Ч����LED�Ȱ�˳�����������ѭ��һ��,֮��ȫ��һ����˸һ��
;
LED_CHECK:
	MOV A,#0FEH      				;���ó�ʼ��LED0��
LED_CHECK_LOOP:
	MOV P1,A
	MOV R2,#200	 					;ѭ��λ���ӳ�200ms
	ACALL DELAY
	RL A							;ʵ��LED����������
	JB P1.7,LED_CHECK_LOOP
	MOV A,#0FFH						;�Լ����ȫ��Ϩ��
	MOV P1,A        				

	MOV R2,#200	 	 			 	;200ms��ȫ����
	ACALL DELAY
	MOV A,#00H		 
	MOV P1,A

	MOV A,#0FFH					    ;200ms��ȫ����
	MOV R2,#200	 	
	ACALL DELAY
	MOV P1,A

	CLR A							;�Լ��������ۼ���������
	RET

;------------------------------�������Լ�---------------------------------
; 
;        				Ч������������������2��
;				  ����˵����BEEP�ӳ���ɽ���R2��R3��R4��������
;			R2�Ƿ��͵ķ�������R3�Ǽ�ʱ����ֵ��8λ��R4�Ǽ�ʱ����ֵ��8λ
;
BEEP_CHECK:
	MOV R3,#08CH 				    ;���ü�������ֵ
	MOV R4,#0FAH
	MOV R2,#60					    ;���÷���60������
	ACALL BEEP					    ;���÷������ӳ���

	MOV R2,#100		   				;�ȴ�100ms
	ACALL DELAY

	MOV R3,#08CH 	   				;�ٴη���
	MOV R4,#0FAH
	MOV R2,#60
	ACALL BEEP
	RET

;---------------------------���ô��ڲ������빤����ʽ-----------------------
INIT_SERIAL_PORT:
	CLR EA
	MOV TMOD,#21H 					;���ö�ʱ��0λ������ʽ0����ʱ��1Ϊ������ʽ2
	MOV TL1,#0FDH					;��ʱ��װ��ֵ��������9600
	MOV TH1,#0FDH  	
	SETB TR1						;������ʱ��1
	MOV SCON,#40H 					;���ô��пڷ�ʽ1,����ʱREN��Ϊ0���ݲ���������ź� 
	RET

;-------------------------��������ѭ���ȴ��û�ѡ��ģʽ----------------------
;
;				Ч��:�û�����S1~S3���������ת����Ӧ����ִ��
;				S1:�¶����ݲɼ���
;				S2:��PC��ȫ˫������ͨ��
;				S3:���̿��Ƶ�����
;				S4:���׵籨��
;
MODE_CHOOSE_OUT:
	S1_O:
			JB P3.2,S2_O
			MOV R2,#10	   			;�ӳ�10msȥ����������
			ACALL DELAY
			JB P3.2,S2_O
			AJMP S1_DOWN
	S2_O:
			JB P3.3,S3_O
			MOV R2,#10	   			;�ӳ�10msȥ����������
			ACALL DELAY
			JB P3.3,S3_O
			AJMP S2_DOWN
	S3_O:
		    JB P3.4,S4_O
			MOV R2,#10	   			;�ӳ�10msȥ����������
			ACALL DELAY
			JB P3.4,S4_O
			AJMP S3_DOWN
	S4_O:
			JB P3.5,MODE_CHOOSE_OUT
			MOV R2,#10	   			;�ӳ�10msȥ����������
			ACALL DELAY
			JB P3.5,MODE_CHOOSE_OUT
			MOV R5,#00H
			AJMP S4_DOWN


;----------------------------S1�����µȴ��û�ѡ��ģʽ-----------------------
MODE_CHOOSE_INS1:
S2_1:
		JB P3.3,S3_1
		MOV R2,#10	   				;�ӳ�10msȥ����������
		ACALL DELAY
		JB P3.3,S3_1
		CLR REN		   				;�رմ��ڽ���
		MOV P1,#0FFH   				;�ر�LED
		ACALL CLEAR_REG				;����Ĵ�����
		AJMP S2_DOWN
S3_1:
	    JB P3.4,S4_1
		MOV R2,#10	   				;�ӳ�10msȥ����������
		ACALL DELAY
		JB P3.4,S4_1
		CLR REN		   				;�رմ��ڽ���
		MOV P1,#0FFH   				;�ر�LED
		ACALL CLEAR_REG				;����Ĵ�����
		AJMP S3_DOWN
S4_1:
		JB P3.5,S_NONE_1
		MOV R2,#10	   				;�ӳ�10msȥ����������
		ACALL DELAY
		JB P3.5,S_NONE_1
		CLR REN		   				;�رմ��ڽ���
		MOV P1,#0FFH   				;�ر�LED
		ACALL CLEAR_REG				;����Ĵ�����
		AJMP S4_DOWN
S_NONE_1:
		RET
	
;----------------------------S2�����µȴ��û�ѡ��ģʽ-----------------------

MODE_CHOOSE_INS2:
S1_2:
		JB P3.2,S3_2
		MOV R2,#10	   				;�ӳ�10msȥ����������
		ACALL DELAY
		JB P3.2,S3_2
		CLR REN		   				;�رմ��ڽ���
		MOV P1,#0FFH   				;�ر�LED
		ACALL CLEAR_REG				;����Ĵ�����
		AJMP S1_DOWN
S3_2:
	    JB P3.4,S4_2
		MOV R2,#10	   				;�ӳ�10msȥ����������
		ACALL DELAY
		JB P3.4,S4_2
		CLR REN		   				;�رմ��ڽ���
		MOV P1,#0FFH   				;�ر�LED
		ACALL CLEAR_REG				;����Ĵ�����
		AJMP S3_DOWN
S4_2:
		JB P3.5,S_NONE_2
		MOV R2,#10	   				;�ӳ�10msȥ����������
		ACALL DELAY
		JB P3.5,S_NONE_2
		CLR REN		   				;�رմ��ڽ���
		MOV P1,#0FFH   				;�ر�LED
		ACALL CLEAR_REG				;����Ĵ�����
		AJMP S4_DOWN
S_NONE_2:
		RET

;----------------------------S3�����µȴ��û�ѡ��ģʽ-----------------------
MODE_CHOOSE_INS3:
S1_3:
		JB P3.2,S2_3
		MOV R2,#10	   				;�ӳ�10msȥ����������
		ACALL DELAY
		JB P3.2,S2_3
		CLR REN		   				;�رմ��ڽ���
		MOV P1,#0FFH   				;�ر�LED
		ACALL CLEAR_REG			    ;����Ĵ�����
		MOV P0,#0FH					;��ʾ���ؿ���,�������
		ACALL ENABLE	
		AJMP S1_DOWN
S2_3:
	    JB P3.3,S4_3
		MOV R2,#10	   				;�ӳ�10msȥ����������
		ACALL DELAY
		JB P3.3,S4_3
		CLR REN		   				;�رմ��ڽ���
		MOV P1,#0FFH   				;�ر�LED
		ACALL CLEAR_REG				;����Ĵ�����
		MOV P0,#0FH					;��ʾ���ؿ���,�������
		ACALL ENABLE	
		AJMP S2_DOWN
S4_3:
		JB P3.5,S_NONE_3
		MOV R2,#10	   				;�ӳ�10msȥ����������
		ACALL DELAY
		JB P3.5,S_NONE_3
		CLR REN		   				;�رմ��ڽ���
		MOV P1,#0FFH   				;�ر�LED
		ACALL CLEAR_REG				;����Ĵ�����
		MOV P0,#0FH					;��ʾ���ؿ���,�������
		ACALL ENABLE	
		AJMP S4_DOWN
S_NONE_3:
		RET


;-------------------------S4����ʵ����ȴ��û�ѡ��ģʽ-----------------------
;
;			Ч��:����S4���µ�ʱ���Զ���ӡ0��1��LCD�ϣ�������LED��ָʾ
;				 ������8λ����ʱ����������Ϊһ���ֽ�ͨ�����ڷ��͵�PC
;
;			˵��:�ù�����R5���ڱ��״̬��R6���ڼ�¼���յ���λ���ݣ�
;				 R7���ڻ�������λ����������
;				  
MODE_CHOOSE_INS4:
	S1_4:
			JB P3.2,S2_4
			MOV R2,#10	   			;�ӳ�10msȥ����������
			ACALL DELAY
			JB P3.2,S2_4
			CLR REN		   			;�رմ��ڽ���
			MOV P1,#0FFH   			;�ر�LED
			ACALL CLEAR_REG			;����Ĵ�����
			MOV P0,#0FH				;��ʾ���ؿ���,�������
			ACALL ENABLE	
			AJMP S1_DOWN
	S2_4:
		    JB P3.3,S3_4
			MOV R2,#10	   			;�ӳ�10msȥ����������
			ACALL DELAY
			JB P3.3,S3_4
			CLR REN		   			;�رմ��ڽ���
			MOV P1,#0FFH   			;�ر�LED
			ACALL CLEAR_REG			;����Ĵ�����
			MOV P0,#0FH				;��ʾ���ؿ���,�������
			ACALL ENABLE	
			AJMP S2_DOWN
	S3_4:
			JB P3.4,S4_4
			MOV R2,#10	   			;�ӳ�10msȥ����������
			ACALL DELAY
			JB P3.4,S4_4
			CLR REN		   			;�رմ��ڽ���
			MOV P1,#0FFH   			;�ر�LED
			ACALL CLEAR_REG			;����Ĵ�����
			MOV P0,#0FH				;��ʾ���ؿ���,�������
			ACALL ENABLE	
			AJMP S3_DOWN

									;����S4
	S4_4:
			JB P3.5,S1_4
			CJNE R5,#00H,S1_4
			MOV R2,#10	   			;�ӳ�10msȥ����������
			ACALL DELAY
			JB P3.5,S1_4
			MOV R2,#160				;160ms����Ϊ�͵�ƽ������Ϊ�ǳ���
			ACALL DELAY
			JB P3.5,SHORT_PRESS		;������Ƕ̰�

	LONG_PRESS:						;����
			CLR P1.3				;������LED1����
			MOV R3,#08EH 			;����������
			MOV R4,#0FCH
			MOV R2,#200				;200������
			ACALL BEEP

			SETB CY					;CYλ��1
			MOV B,#31H
			LJMP CHECK_OVERFLOW

	SHORT_PRESS:
			CLR P1.0				;������LED4����
			MOV R3,#08EH 			;����������
			MOV R4,#0FCH
			MOV R2,#50				;50������
			ACALL BEEP

			CLR CY	 			    ;CYλ��0 
			MOV B,#30H
				  
			
	CHECK_OVERFLOW:
			
			;MOV R5,#01H				;��ӱ�ǣ������8λ������S4_LCD1������ֱ�ӷ��ظô�
			MOV A,B					;�����ݴ�A��ֵ�����ⱻSAVE_BITS�޸�
			INC R6				    ;R6���ڼ�¼�Ƿ�չ�8λ
			MOV 00H,C				;λѰַ����CY�����ݴ棬��ΪCJNE��ı�CY
			CJNE R6,#09H,SAVE_BITS	;�����û��8λ���Ͱѵ�ǰ���ݻ���

			MOV SBUF,R7				;�������8λ���ͽ�����ֽ�ͨ�����ڷ���
			CLR TI
			CLR P1.7				;����������ʾ�ƣ�����100ms
			MOV R2,#100
			ACALL DELAY
			SETB P1.7
			ACALL CLEAR_LCD			;�������������յ籨
			AJMP S4_LCD1
	
	
	SAVE_BITS:
			MOV R2,#2				
			ACALL WRITE_LCD			;���½��յ���0(30H)��1(31H)��ʾ��LCD
			MOV C,00H
			MOV A,R7				;���¼Ĵ���R1�Ļ�������
			RLC A
			MOV R7,A
			JNB P3.5,$				;�ȴ������ɿ���Ϊ�ߵ�ƽ������������ȴ���һ���͵�ƽ�ź�,�����ظ����
			SETB P1.0	  			;�ɿ�����ͬʱ���LED��
			SETB P1.3
			;MOV R5,#00H			;������

			AJMP MODE_CHOOSE_INS4	;�����ȴ���������


;-----------------------���ܾ���ʵ��----------------------------------
;
;		  Ч��:ʵʱ��ȡ��ǰ�¶Ȳ���ʾ��LCD��ͬʱ�ô��ڷ���PC
;
S1_DOWN:
		SETB REN					;�����ڽ���
		MOV P0,#0CH					;��ʾ���ؿ���,�رչ��͹����˸
		ACALL ENABLE		
	S1_DOWN_LOOP:
		ACALL MODE_CHOOSE_INS1
		MOV R2,#255					;�ӳ�510ms������ˢ���ٶ�
		ACALL DELAY
		MOV R2,#255
		ACALL DELAY
		ACALL CLEAR_LCD             ;����
	S1_LCD1:	
        MOV P0,#80H					;��һ�еĿ�ʼλ��
		ACALL ENABLE				;����ָ��
        MOV R0,#0	    			;��0��ʼ��ʾTABLE7�е�ֵ
		MOV	DPTR,#TABLE7			;��TABLE7ȡ��
    S1_LCD1_LOOP:					;��TABLE7���������ֽ���ʾ����һ��
      	MOV A,R0       
		MOVC A,@A+DPTR
		MOV R2,#2
		ACALL  WRITE_LCD  			;��ʾ��LCD
		INC R0			  
		CJNE A,#00H,S1_LCD1_LOOP	;�Ƿ�00H,���Ļ�������ȡ
		MOV R0,#00H		  			;�ÿ�R0
			
	S1_LCD2:
		MOV P0,#0C0H	 			;���õڶ��еĿ�ʼλ��
		ACALL ENABLE	 			;����ָ��	
					  	
;
;		��ȡ�¶Ȳ���ʾ�ڵڶ���
;
		LCALL GET_TEMP				;����GET_TEMP
		LCALL TEMP_XCH				;�����¶�ת��TEMP_XCH
		MOV A,TEMP_0C				;�¶�ֵ��A		
		MOV B,#10					;�ֿ��¶�ʮλ
		DIV AB 						;A��10������

		ADD A,#30H					;�̸���һλ
		MOV SBUF,A					;���͸�����
		CLR TI
		MOV R2,#2
		ACALL WRITE_LCD				;��ʾ��LCD
		JNB TI,$
		

		MOV A,B						;�������ڶ�λ
		ADD A,#30H
		MOV SBUF,A					;���͸�����
		CLR TI
		MOV R2,#2
		ACALL WRITE_LCD	   			;��ʾ��LCD
		JNB TI,$

		MOV A,#2EH		  			;С����
		MOV SBUF,A					;���͸�����
		CLR TI
		MOV R2,#2
		ACALL WRITE_LCD				;��ʾ��LCD
		JNB TI,$

		MOV A,TEMP_PD				;�¶ȵ�С����A
		MOV DPTR,#TABLE8
		MOVC A,@A+DPTR	
		ADD A,#30H
		MOV SBUF,A					;���͸�����
		CLR TI
		MOV R2,#2
		ACALL WRITE_LCD				;��ʾ��LCD
		JNB TI,$

		MOV A,#0DFH		  			;�����
		MOV R2,#2
		ACALL WRITE_LCD			    

		MOV A,#43H		  			;C����
		MOV R2,#2
		ACALL WRITE_LCD	

		MOV A,#2CH					;����
	   	MOV SBUF,A					;���͸�����
		CLR TI
		JNB TI,$

	  LJMP S1_DOWN_LOOP


;--------------------------S2�ӳ�����ʵ��--------------------------------
;
;   Ч��:ʵʱ��ȡPC���������ݲ���ʾ��LCD��ͬʱ�ô��ڰѽ��յ������ݷ���PC
;
S2_DOWN:  
		SETB REN					;�����ڽ���
		ACALL CLEAR_LCD             
	S2_LCD1:	
        MOV P0,#80H					;��һ�еĿ�ʼλ��
		ACALL ENABLE				;����ָ��
        MOV R0,#0	    			;��0��ʼ��ʾTABLE2�е�ֵ
		MOV	DPTR,#TABLE2			;��TABLE2ȡ��
    S2_LCD1_LOOP:					;��TABLE2���������ֽ���ʾ����һ��
      	MOV A,R0       
		MOVC A,@A+DPTR
		MOV R2,#2
		ACALL  WRITE_LCD  			;��ʾ��LCD
		INC R0			  
		CJNE A,#00H,S2_LCD1_LOOP	;�Ƿ�00H,���Ļ�������ȡ
		MOV R0,#00H		  			;�ÿ�R0						 
	S2_LCD2:
		MOV P0,#0C0H	 			;���õڶ��еĿ�ʼλ��
		ACALL ENABLE	 			;����ָ��
		CJNE R1,#10H,S2_LCD2_LOOP  	;����Ǵӵڶ��������ת��������ֱ�Ӽ�����ʾ���յ����ֽڣ����򴮿�ֱ�ӵȴ���һ������
		MOV R1,#00H				   	
		LJMP S2_LCD2_NOT_FLOW
	S2_LCD2_LOOP:					;���ڡ�����ѭ���ȴ�
		ACALL MODE_CHOOSE_INS2	
		JNB RI,S2_LCD2_LOOP
		INC R1
		CJNE R1,#10H,S2_LCD2_NOT_FLOW
		
		ACALL CLEAR_LCD			   	;����ڶ������˾���������
		AJMP S2_LCD1	
	S2_LCD2_NOT_FLOW:		   
		MOV A,SBUF
		MOV P1,A;
		MOV R2,#2
		ACALL  WRITE_LCD 			;�ѽ��յ����ַ���ʾ��LCD  
		CLR RI

		MOV SBUF,A
		JNB TI,$
		CLR TI
		LJMP S2_LCD2_LOOP

		
;--------------------------S3�ӳ�����ʵ��--------------------------------
;
;�����٣��������ְ���1~9���Կ��Ƶ�Ƭ��������Ӧ��9����ͬ�����������ټ�ʵʱ��ʾ��LCD 
;
S3_DOWN:
		SETB REN					;�����ڽ���
		MOV P0,#0CH					;��ʾ���ؿ���,,�رչ��͹����˸
		ACALL ENABLE							   
        ACALL CLEAR_LCD 
	S3_LCD1:	
        MOV P0,#80H					;��һ�еĿ�ʼλ��
		ACALL ENABLE				;ʹ��ָ��
        MOV R0,#0	    			;��0��ʼ��ʾTABLE3�е�ֵ
		MOV	DPTR,#TABLE3			;��TABLE3ȡ��
    S3_LCD1_LOOP:					;��TABLE3���������ֽ���ʾ����һ��
      	MOV A,R0       
		MOVC A,@A+DPTR
		MOV R2,#2
		ACALL  WRITE_LCD  			;��ʾ��LCD
		INC R0			  
		CJNE A,#00H,S3_LCD1_LOOP	;�Ƿ�00H,���Ļ�������ȡ
		MOV R0,#00H		  			;�ÿ�R0
		CJNE R1,#01H,S3_LCD2_LOOP   ;���������������1~9ת�������ģ���ô���������ڽ��ܣ�����ص�ԭλ������ʾ����
		AJMP  DRAW_PIANO_LED
	S3_LCD2_LOOP:					;���ڡ�����ѭ���ȴ�
		ACALL MODE_CHOOSE_INS3	
		JNB RI,S3_LCD2_LOOP
		MOV A,SBUF
		MOV R1,#00H					
									;�ж�����������Ƿ���1~9,������ǾͲ���ᣬ�����ȴ���һ������
	CMP1:						
		CJNE A,#31H,CMP_WITH_1
		LJMP PIANO_KEY_DOWN
		
	CMP_WITH_1:
		JNB CY,CMP9
		CLR RI
		LJMP S3_LCD2_LOOP
	CMP9:
		CJNE A,#39H,CMP_WITH_9
		LJMP PIANO_KEY_DOWN

	CMP_WITH_9:
		JB CY,PIANO_KEY_DOWN 
		CLR RI
		LJMP S3_LCD2_LOOP

    PIANO_KEY_DOWN:
		INC R1		   				;���,���������ڰ���1~9�����������
		ACALL CLEAR_LCD
		LJMP S3_LCD1		 
	DRAW_PIANO_LED:	    			;��ʾ���ٰ���
		MOV A,SBUF
		MOV P1,A					;�ѽ��յ�����Ч�źŷ���LED					
		SUBB A,#31H
		MOV B,A

	BEEP_PIANO:						;��Ӧ��������
		MOV DPTR,#TABLE5
		MOVC A,@A+DPTR
		MOV R3,A

		MOV A,B
		MOV DPTR,#TABLE6
		MOVC A,@A+DPTR
		MOV R4,A

		MOV R2,#40
		ACALL BEEP

	DRAW_PIANO_KEY:					;���Ƹ��ٰ���

		MOV A,B


		ADD A,#0C6H
		MOV P0,A	 				;���õڶ��еĿ�ʼλ��
		ACALL ENABLE
		MOV A,#0FFH					;���ٰ���ͼ��
		MOV R2,#2
	    ACALL  WRITE_LCD  			;��ʾ��LCD
		CLR RI						;���������������
		LJMP S3_LCD2_LOOP


;--------------------------S4�ӳ����ʼ����ʵ��--------------------------------	
;
; ���׵籨:ͨ����S4���µĳ���ת��Ϊ0��1���չ�8λ������ת��ΪASCII�ַ����͸�PC��
;	
S4_DOWN:

		SETB REN					;�����ڽ���
		MOV R7,#00H
		MOV R6,#00H					
		MOV P0,#0EH					;��ʾ���ؿ���,�رչ��͹����˸
		ACALL ENABLE							   
        ACALL CLEAR_LCD 
	S4_LCD1:	
        MOV P0,#80H					;��һ�еĿ�ʼλ��
		ACALL ENABLE				;ʹ��ָ��
        MOV R0,#0	    			;��0��ʼ��ʾTABLE4�е�ֵ
		MOV	DPTR,#TABLE4			;��TABLE4ȡ��
    S4_LCD1_LOOP:					;��TABLE3���������ֽ���ʾ����һ��
      	MOV A,R0       
		MOVC A,@A+DPTR
		MOV R2,#2
		ACALL  WRITE_LCD  			;��ʾ��LCD
		INC R0			  
		CJNE A,#00H,S4_LCD1_LOOP	;�Ƿ�00H,���Ļ�������ȡ
		MOV R0,#00H		  			;�ÿ�R0
		MOV P0,#0C0H				;��껻���ڶ���
		ACALL ENABLE				
		CJNE R6,#09H,JMP_MODE_CHOOSE_INS4
		MOV R6,#00H				    ;���R6���˾Ͱ�R6���㲢�ҷ���֮ǰ�ĵط����ѽ��ܵ����ݼ�����ʾ�ڵڶ��п�ͷ
	   	AJMP CHECK_OVERFLOW
	JMP_MODE_CHOOSE_INS4:		    ;����ȴ�������������
		AJMP MODE_CHOOSE_INS4





;=========================LCD��ʾ������ӳ���==========================
;----------------------------�����ӳ���----------------------------------
CLEAR_LCD:
        MOV P0,#01H				    ;����
		ACALL ENABLE

;----------------------------�������ӳ���--------------------------------
ENABLE: CLR RS 						;������
		CLR RW
		CLR E
		MOV R2,#2
		ACALL DELAY
		SETB E
		RET
;---------------------------����ʾ�����ӳ���-----------------------------
WRITE_LCD:
     	MOV P0,A 					;��������ʾ
		SETB RS
		CLR RW
		CLR E
		ACALL DELAY
		SETB E
		RET


;---------------------------------------------------------




;============================ͨ�ù����ӳ���=================================

;---------------------�ɴ��η�����---------------------------
;
;	�ⲿ�ɴ���R2(������)��R3(��ʱ���Ͱ�λ)��R4(��ʱ���߰�λ)
;

BEEP:
	 SETB TR0
BEEP_LOOP:	     
     MOV TL0,R3       			    ;д�������ֵ
     MOV TH0,R4
     CLR TF0
BEEP_WAIT: 
     JNB TF0,BEEP_WAIT
     CPL P2.4			 			;��������           
     DJNZ R2,BEEP_LOOP
	 RET  

;-------------------------����Ĵ�����------------------------	
CLEAR_REG:
	  MOV R0,#00H
	  MOV R1,#00H
	  MOV R2,#00H
	  MOV R3,#00H
	  MOV R4,#00H
	  MOV R5,#00H
	  MOV R6,#00H
	  MOV R7,#00H
	  RET

;-------------�ⲿ�ɴ��εĺ��뼶��ʱ�ӳ���---------------------
;
;			Ч��:�ⲿ����R2���ӳ�����ӳ�R2����
;
DELAY: 					

D1:		MOV R3,#05
D2:		MOV R4,#100
		DJNZ R4,$
		DJNZ R3,D2
		DJNZ R2,D1
		RET
;-----------------------��ʱ20΢���ӳ���-----------------------
DELAY_20US:
		MOV R7,#10
		DJNZ R7,$
		RET

;---------------------��ʱ500΢���ӳ���------------------------		
DELAY_500US:
		MOV R7,#2
YS500:
		MOV R6,#250
		DJNZ R6,$
		DJNZ R7,YS500
		RET




;===========================�¶ȴ�������ز����ӳ���========================

;--------------------18B20����ת������¶�----------------------
GET_TEMP: 
		LCALL INIT_1820				;���ó�ʼ������
		SETB DQ
		JB B20OK,S22				;��DS18B20������ʼ��ָ�����
		LJMP GET_TEMP				;��DS18B20�������򷵻�
S22:
		LCALL DELAY_20US				;��ʱ20uS
		MOV A,#0CCH 				;����ROMƥ��-0CC
		LCALL WRITE_1820			;д18B20
		MOV A,#44H 					;�����¶�ת��ָ��
		LCALL WRITE_1820			;д18B20
		NOP
		LCALL DELAY_500US			;��ʱ500MS*2
		LCALL DELAY_500US
CBA:
		LCALL INIT_1820 			;��ʼ��18B20
		JB B20OK,ABC				;��DS18B20������ʼ��ȡ
		LJMP CBA					;��DS18B20�������򷵻����³�ʼ��
ABC:
		CALL DELAY_20US
		MOV A,#0CCH 				;����ROMƥ��-0CC
		LCALL WRITE_1820
		MOV A,#0BEH 				;���ݴ���ָ��
		LCALL WRITE_1820
		LCALL READ_1820 			;����READ_1820
		RET
;-------------------------DS18B20��ʼ������---------------------
INIT_1820:
		SETB DQ
		NOP
		CLR DQ
		MOV R0,#80H
TSR1:
		DJNZ R0,TSR1 				;��ʱus,����us���Ը�λ
		SETB DQ
		MOV R0,#25H 				;96US-25H
TSR2:
		DJNZ R0,TSR2
		JNB DQ,TSR3					;��18B20���ڣ��򷵻ش����ź�
									;��ʱ����TSR3���ñ�־λ
		LJMP TSR4 					;��������TSR4����λΪ������
TSR3:
		SETB B20OK 					;�ñ�־λ,��ʾDS1820����
		LJMP TSR5
TSR4:
		CLR B20OK 					;���־λ,��ʾDS1820������
		LJMP TSR7
TSR5:
		MOV R0,#06BH 				;200US
TSR6:
		DJNZ R0,TSR6 				;��ʱ
TSR7:
		SETB DQ
		RET

;-------------------------------DS18B20������--------------------
READ_1820:
		MOV R4,#2 					;���¶ȸ�λ�͵�λ��DS18B20�ж���
		MOV R1,#36H 				;��λ����36H(TEMP_L),��λ����35H(TEMP_H)
RE0:
		MOV R2,#8					;��1�ֽ�8λ��ѭ������Ϊ8
RE1:
		CLR C						;���CYλ
		SETB DQ						;������������
		NOP 
		NOP							;��2us
		CLR DQ						;������������
		NOP 
		NOP 
		NOP							;��3us
		SETB DQ						;��������������
		MOV R3,#7					;��7us
		DJNZ R3,$
		MOV C,DQ					;������ʱ�������ŵĵ�ƽ״̬
									;����CY��
		MOV R3,#23					;��23us
		DJNZ R3,$
		RRC A						;ѭ�����ƣ���CY�������λ
		DJNZ R2,RE1					;���ؼ�����ȡ��һλ
		MOV @R1,A					;����ȡ�����ݴ���35H��36H
		DEC R1						;��һ�ν��󽫵�ַ��һ��Ϊ35H
		DJNZ R4,RE0					;���ض��ڶ��ֽ�
		RET

;--------------------------DS18B20д����--------------------------
WRITE_1820:
		MOV R2,#8					;д1�ֽ�8λ��ѭ������Ϊ8
		CLR C						;���CYλ
WR1:
		CLR DQ						;������������
		MOV R3,#6					;��ʱ6us
		DJNZ R3,$
		RRC A						;�����WRITE_1820ǰ�����ݷ���ACC��
									;ͨ����ACC���Ҵ���λѭ��λ��
									;��CYλ��������ȡ��ÿһλ
		MOV DQ,C					;��һλ�͵���������
		MOV R3,#23					;��ʱ23us
		DJNZ R3,$
		SETB DQ						;������������
		NOP
		DJNZ R2,WR1					;���ش���һλ
		SETB DQ						;д��һ�ֽں������������ţ����⸴λ
		RET


;---------------����DS18B20�ж������¶����ݽ���ת��-----------------

TEMP_XCH:
		MOV A,#0F0H
		ANL A,TEMP_L 				;��ȥ�¶ȵ�λ��С��������λ�¶���ֵ
		SWAP A						;����λ�͵���λ����λ��
		MOV TEMP_0C,A				;����TEMP_0C
		MOV A,TEMP_H
		ANL A,#07H
		SWAP A
		ORL A,TEMP_0C				;��λ����¶�ֵ
		
		MOV TEMP_0C,A 				;����任����¶�����
		MOV A,#0FH	   	
		ANL A,TEMP_L
		MOV TEMP_PD,A				;�����ĵ���λ
		RET
		
	

TABLE0:	DB "        By X_32mx",00H
TABLE1: DB "HELLO WORLD! :D ",00H
TABLE2: DB "Comm with PC    ",00H
TABLE3: DB "Piano 123456789 ",00H
TABLE4:	DB "Telegraph       ",00H
TABLE5: DB 21H,0E1H,8CH,0D8H,68H,0E9H,05BH,8EH,0E8H
TABLE6: DB 0F9H,0F9H,0FAH,0FAH,0FBH,0FBH,0FCH,0FCH,0FDH
TABLE7: DB "Temperature     ",00H
TABLE8:	DB 0,1,1,2,3,3,4,4,5,5,6,7,8,8,9,9
		END		