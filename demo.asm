;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;			课设题目：单片机与PC机的全双工串口通信
;
;			功能描述:S1~S4按键分别对应4个不同功能
;
;			S1:环境温度数据采集，实时显示到LCD并发送到串口        
;			S2:与PC的全双工通信实验，LCD与LED实时显示PC发来的数据
;			S3:电子钢琴，由PC机键盘控制单片机发出9个音符,同时可以实时显示按下的琴键
;			S4:简易电报，通过把S4按下的长短转化为0和1，凑够8位数据则转化为ASCII字符发送给PC机
;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



;-----------------------------数据定义----------------------------------------
RS		EQU	P2.6					;通过RS确定是写数据还是写命令
RW		EQU	P3.6					;RW读/写控制端设置,写模式为低电平
E		EQU	P2.7					;给E一个高脉冲将数据送入液晶控制器，完成写操作

B20OK 	BIT 00H						;成功初始化18B20标志位
DQ		BIT P3.7					;18B20引脚
TEMP_L	EQU 36H						;读出温度的低8位
TEMP_H 	EQU 35H						;读出温度的高8位
TEMP_0C EQU 37H						;处理后的温度值
TEMP_PD EQU 38H  					;温度的小数位
;-----------------------------主程序------------------------------------		
	ORG	00H
	AJMP MAIN
	ORG 30H		
MAIN:	
	ACALL	INIT_LCD        		;LCD初始化
	ACALL	HELLO_LCD				;主界面显示
	ACALL   LED_CHECK				;LED灯自检
	ACALL   INIT_SERIAL_PORT		;配置串口
	ACALL	BEEP_CHECK				;蜂鸣器自检
	ACALL   MODE_CHOOSE_OUT			;循环等待用户选择模式
		
	
;------------------------------LCD初始化---------------------------------
INIT_LCD:		
    ACALL CLEAR_LCD 				;清屏
	MOV P0,#38H						;显示功能(两行显示，5×7点阵)
	ACALL ENABLE
	MOV P0,#0FH						;显示开关控制(显示光标，光标闪烁)
	ACALL ENABLE
	MOV P0,#06H						;设置光标自动+1
	ACALL ENABLE
	RET						    
;----------------------------LCD显示主界面-------------------------------
; 
;               效果：第一行显示HELLO WORLD,第二行显示作者
;		
HELLO_LCD:							;显示HELLO WORLD
    MOV P0,#80H						;设置LCD第一行的开始位置
	ACALL ENABLE					
    MOV R1,#0	    				;从0开始显示TABLE1中的值
	MOV	DPTR,#TABLE1				;准备到TABLE1取码
HELLO_LCD_LOOP:						;循环逐一把TABLE1中的字符显示在第一行
  	MOV A,R1       
	MOVC A,@A+DPTR
	MOV R2,#50						;设置字符打印的时间间隔为50ms
	ACALL  WRITE_LCD          		;显示到LCD
	INC R1							
	CJNE A,#00H,HELLO_LCD_LOOP		;是否到00H,到的话结束打印
	MOV R1,#00H


AUTHOR_LCD:							;显示作者
	MOV P0,#0C0H					;设置LCD第一行的开始位置
	ACALL ENABLE					
    MOV R1,#0	    				;从0开始显示TABLE0中的值
	MOV	DPTR,#TABLE0				;准备到TABLE0取码	
AUTHOR_LCD_LOOP:
	MOV A,R1       
	MOVC A,@A+DPTR
	MOV R2,#50						;设置字符打印的时间间隔为50ms
	ACALL  WRITE_LCD          		;显示到LCD
	INC R1							
	CJNE A,#00H,AUTHOR_LCD_LOOP		;是否到00H,到的话结束打印
	MOV R1,#00H					
	RET

;------------------------------LED灯自检----------------------------------
; 
;        效果：LED等按顺序逐个点亮，循环一遍,之后全部一起闪烁一下
;
LED_CHECK:
	MOV A,#0FEH      				;设置初始灯LED0亮
LED_CHECK_LOOP:
	MOV P1,A
	MOV R2,#200	 					;循环位移延迟200ms
	ACALL DELAY
	RL A							;实现LED灯轮流点亮
	JB P1.7,LED_CHECK_LOOP
	MOV A,#0FFH						;自检完毕全部熄灯
	MOV P1,A        				

	MOV R2,#200	 	 			 	;200ms后全部亮
	ACALL DELAY
	MOV A,#00H		 
	MOV P1,A

	MOV A,#0FFH					    ;200ms后全部灭
	MOV R2,#200	 	
	ACALL DELAY
	MOV P1,A

	CLR A							;自检完毕清空累加器并返回
	RET

;------------------------------蜂鸣器自检---------------------------------
; 
;        				效果：蜂鸣器连续发声2次
;				  解释说明：BEEP子程序可接收R2、R3、R4三个参数
;			R2是发送的方波数，R3是计时器初值低8位，R4是计时器初值高8位
;
BEEP_CHECK:
	MOV R3,#08CH 				    ;设置计数器初值
	MOV R4,#0FAH
	MOV R2,#60					    ;设置发送60个方波
	ACALL BEEP					    ;调用蜂鸣器子程序

	MOV R2,#100		   				;等待100ms
	ACALL DELAY

	MOV R3,#08CH 	   				;再次发声
	MOV R4,#0FAH
	MOV R2,#60
	ACALL BEEP
	RET

;---------------------------配置串口波特率与工作方式-----------------------
INIT_SERIAL_PORT:
	CLR EA
	MOV TMOD,#21H 					;设置定时器0位工作方式0，定时器1为工作方式2
	MOV TL1,#0FDH					;定时器装初值，波特率9600
	MOV TH1,#0FDH  	
	SETB TR1						;启动定时器1
	MOV SCON,#40H 					;设置串行口方式1,但此时REN仍为0，暂不允许接收信号 
	RET

;-------------------------主界面下循环等待用户选择模式----------------------
;
;				效果:用户按下S1~S3任意键可跳转到相应功能执行
;				S1:温度数据采集器
;				S2:与PC机全双工串口通信
;				S3:键盘控制电子琴
;				S4:简易电报机
;
MODE_CHOOSE_OUT:
	S1_O:
			JB P3.2,S2_O
			MOV R2,#10	   			;延迟10ms去除抖动干扰
			ACALL DELAY
			JB P3.2,S2_O
			AJMP S1_DOWN
	S2_O:
			JB P3.3,S3_O
			MOV R2,#10	   			;延迟10ms去除抖动干扰
			ACALL DELAY
			JB P3.3,S3_O
			AJMP S2_DOWN
	S3_O:
		    JB P3.4,S4_O
			MOV R2,#10	   			;延迟10ms去除抖动干扰
			ACALL DELAY
			JB P3.4,S4_O
			AJMP S3_DOWN
	S4_O:
			JB P3.5,MODE_CHOOSE_OUT
			MOV R2,#10	   			;延迟10ms去除抖动干扰
			ACALL DELAY
			JB P3.5,MODE_CHOOSE_OUT
			MOV R5,#00H
			AJMP S4_DOWN


;----------------------------S1功能下等待用户选择模式-----------------------
MODE_CHOOSE_INS1:
S2_1:
		JB P3.3,S3_1
		MOV R2,#10	   				;延迟10ms去除抖动干扰
		ACALL DELAY
		JB P3.3,S3_1
		CLR REN		   				;关闭串口接收
		MOV P1,#0FFH   				;关闭LED
		ACALL CLEAR_REG				;清除寄存器组
		AJMP S2_DOWN
S3_1:
	    JB P3.4,S4_1
		MOV R2,#10	   				;延迟10ms去除抖动干扰
		ACALL DELAY
		JB P3.4,S4_1
		CLR REN		   				;关闭串口接收
		MOV P1,#0FFH   				;关闭LED
		ACALL CLEAR_REG				;清除寄存器组
		AJMP S3_DOWN
S4_1:
		JB P3.5,S_NONE_1
		MOV R2,#10	   				;延迟10ms去除抖动干扰
		ACALL DELAY
		JB P3.5,S_NONE_1
		CLR REN		   				;关闭串口接收
		MOV P1,#0FFH   				;关闭LED
		ACALL CLEAR_REG				;清除寄存器组
		AJMP S4_DOWN
S_NONE_1:
		RET
	
;----------------------------S2功能下等待用户选择模式-----------------------

MODE_CHOOSE_INS2:
S1_2:
		JB P3.2,S3_2
		MOV R2,#10	   				;延迟10ms去除抖动干扰
		ACALL DELAY
		JB P3.2,S3_2
		CLR REN		   				;关闭串口接收
		MOV P1,#0FFH   				;关闭LED
		ACALL CLEAR_REG				;清除寄存器组
		AJMP S1_DOWN
S3_2:
	    JB P3.4,S4_2
		MOV R2,#10	   				;延迟10ms去除抖动干扰
		ACALL DELAY
		JB P3.4,S4_2
		CLR REN		   				;关闭串口接收
		MOV P1,#0FFH   				;关闭LED
		ACALL CLEAR_REG				;清除寄存器组
		AJMP S3_DOWN
S4_2:
		JB P3.5,S_NONE_2
		MOV R2,#10	   				;延迟10ms去除抖动干扰
		ACALL DELAY
		JB P3.5,S_NONE_2
		CLR REN		   				;关闭串口接收
		MOV P1,#0FFH   				;关闭LED
		ACALL CLEAR_REG				;清除寄存器组
		AJMP S4_DOWN
S_NONE_2:
		RET

;----------------------------S3功能下等待用户选择模式-----------------------
MODE_CHOOSE_INS3:
S1_3:
		JB P3.2,S2_3
		MOV R2,#10	   				;延迟10ms去除抖动干扰
		ACALL DELAY
		JB P3.2,S2_3
		CLR REN		   				;关闭串口接收
		MOV P1,#0FFH   				;关闭LED
		ACALL CLEAR_REG			    ;清除寄存器组
		MOV P0,#0FH					;显示开关控制,开启光标
		ACALL ENABLE	
		AJMP S1_DOWN
S2_3:
	    JB P3.3,S4_3
		MOV R2,#10	   				;延迟10ms去除抖动干扰
		ACALL DELAY
		JB P3.3,S4_3
		CLR REN		   				;关闭串口接收
		MOV P1,#0FFH   				;关闭LED
		ACALL CLEAR_REG				;清除寄存器组
		MOV P0,#0FH					;显示开关控制,开启光标
		ACALL ENABLE	
		AJMP S2_DOWN
S4_3:
		JB P3.5,S_NONE_3
		MOV R2,#10	   				;延迟10ms去除抖动干扰
		ACALL DELAY
		JB P3.5,S_NONE_3
		CLR REN		   				;关闭串口接收
		MOV P1,#0FFH   				;关闭LED
		ACALL CLEAR_REG				;清除寄存器组
		MOV P0,#0FH					;显示开关控制,开启光标
		ACALL ENABLE	
		AJMP S4_DOWN
S_NONE_3:
		RET


;-------------------------S4功能实现与等待用户选择模式-----------------------
;
;			效果:根据S4按下的时间自动打印0或1到LCD上，并且有LED灯指示
;				 当凑齐8位数据时，将数据作为一个字节通过串口发送到PC
;
;			说明:该功能下R5用于标记状态，R6用于记录接收到几位数据，
;				 R7用于缓存数据位，填满则发送
;				  
MODE_CHOOSE_INS4:
	S1_4:
			JB P3.2,S2_4
			MOV R2,#10	   			;延迟10ms去除抖动干扰
			ACALL DELAY
			JB P3.2,S2_4
			CLR REN		   			;关闭串口接收
			MOV P1,#0FFH   			;关闭LED
			ACALL CLEAR_REG			;清除寄存器组
			MOV P0,#0FH				;显示开关控制,开启光标
			ACALL ENABLE	
			AJMP S1_DOWN
	S2_4:
		    JB P3.3,S3_4
			MOV R2,#10	   			;延迟10ms去除抖动干扰
			ACALL DELAY
			JB P3.3,S3_4
			CLR REN		   			;关闭串口接收
			MOV P1,#0FFH   			;关闭LED
			ACALL CLEAR_REG			;清除寄存器组
			MOV P0,#0FH				;显示开关控制,开启光标
			ACALL ENABLE	
			AJMP S2_DOWN
	S3_4:
			JB P3.4,S4_4
			MOV R2,#10	   			;延迟10ms去除抖动干扰
			ACALL DELAY
			JB P3.4,S4_4
			CLR REN		   			;关闭串口接收
			MOV P1,#0FFH   			;关闭LED
			ACALL CLEAR_REG			;清除寄存器组
			MOV P0,#0FH				;显示开关控制,开启光标
			ACALL ENABLE	
			AJMP S3_DOWN

									;处理S4
	S4_4:
			JB P3.5,S1_4
			CJNE R5,#00H,S1_4
			MOV R2,#10	   			;延迟10ms去除抖动干扰
			ACALL DELAY
			JB P3.5,S1_4
			MOV R2,#160				;160ms后仍为低电平，则认为是长按
			ACALL DELAY
			JB P3.5,SHORT_PRESS		;否则就是短按

	LONG_PRESS:						;长按
			CLR P1.3				;按下则LED1灯亮
			MOV R3,#08EH 			;蜂鸣器发声
			MOV R4,#0FCH
			MOV R2,#200				;200个方波
			ACALL BEEP

			SETB CY					;CY位置1
			MOV B,#31H
			LJMP CHECK_OVERFLOW

	SHORT_PRESS:
			CLR P1.0				;按下则LED4灯亮
			MOV R3,#08EH 			;蜂鸣器发声
			MOV R4,#0FCH
			MOV R2,#50				;50个方波
			ACALL BEEP

			CLR CY	 			    ;CY位置0 
			MOV B,#30H
				  
			
	CHECK_OVERFLOW:
			
			;MOV R5,#01H				;添加标记，如果满8位，方便S4_LCD1清屏后直接返回该处
			MOV A,B					;用于暂存A的值，避免被SAVE_BITS修改
			INC R6				    ;R6用于记录是否凑够8位
			MOV 00H,C				;位寻址，把CY内容暂存，因为CJNE会改变CY
			CJNE R6,#09H,SAVE_BITS	;如果还没满8位，就把当前内容缓存

			MOV SBUF,R7				;如果已满8位，就将这个字节通过串口发送
			CLR TI
			CLR P1.7				;点亮发送提示灯，持续100ms
			MOV R2,#100
			ACALL DELAY
			SETB P1.7
			ACALL CLEAR_LCD			;清屏，继续接收电报
			AJMP S4_LCD1
	
	
	SAVE_BITS:
			MOV R2,#2				
			ACALL WRITE_LCD			;把新接收到的0(30H)或1(31H)显示到LCD
			MOV C,00H
			MOV A,R7				;更新寄存器R1的缓存内容
			RLC A
			MOV R7,A
			JNB P3.5,$				;等待按键松开置为高电平，才允许继续等待下一个低电平信号,避免重复检测
			SETB P1.0	  			;松开按键同时灭掉LED灯
			SETB P1.3
			;MOV R5,#00H			;清除标记

			AJMP MODE_CHOOSE_INS4	;继续等待按键按下


;-----------------------功能具体实现----------------------------------
;
;		  效果:实时获取当前温度并显示在LCD，同时用串口发给PC
;
S1_DOWN:
		SETB REN					;允许串口接收
		MOV P0,#0CH					;显示开关控制,关闭光标和光标闪烁
		ACALL ENABLE		
	S1_DOWN_LOOP:
		ACALL MODE_CHOOSE_INS1
		MOV R2,#255					;延迟510ms，减少刷新速度
		ACALL DELAY
		MOV R2,#255
		ACALL DELAY
		ACALL CLEAR_LCD             ;清屏
	S1_LCD1:	
        MOV P0,#80H					;第一行的开始位置
		ACALL ENABLE				;推送指令
        MOV R0,#0	    			;从0开始显示TABLE7中的值
		MOV	DPTR,#TABLE7			;到TABLE7取码
    S1_LCD1_LOOP:					;把TABLE7的内容逐字节显示到第一行
      	MOV A,R0       
		MOVC A,@A+DPTR
		MOV R2,#2
		ACALL  WRITE_LCD  			;显示到LCD
		INC R0			  
		CJNE A,#00H,S1_LCD1_LOOP	;是否到00H,到的话结束读取
		MOV R0,#00H		  			;置空R0
			
	S1_LCD2:
		MOV P0,#0C0H	 			;设置第二行的开始位置
		ACALL ENABLE	 			;推送指令	
					  	
;
;		获取温度并显示在第二行
;
		LCALL GET_TEMP				;调用GET_TEMP
		LCALL TEMP_XCH				;调用温度转换TEMP_XCH
		MOV A,TEMP_0C				;温度值给A		
		MOV B,#10					;分开温度十位
		DIV AB 						;A对10做除法

		ADD A,#30H					;商给第一位
		MOV SBUF,A					;发送给串口
		CLR TI
		MOV R2,#2
		ACALL WRITE_LCD				;显示到LCD
		JNB TI,$
		

		MOV A,B						;余数给第二位
		ADD A,#30H
		MOV SBUF,A					;发送给串口
		CLR TI
		MOV R2,#2
		ACALL WRITE_LCD	   			;显示到LCD
		JNB TI,$

		MOV A,#2EH		  			;小数点
		MOV SBUF,A					;发送给串口
		CLR TI
		MOV R2,#2
		ACALL WRITE_LCD				;显示到LCD
		JNB TI,$

		MOV A,TEMP_PD				;温度的小数给A
		MOV DPTR,#TABLE8
		MOVC A,@A+DPTR	
		ADD A,#30H
		MOV SBUF,A					;发送给串口
		CLR TI
		MOV R2,#2
		ACALL WRITE_LCD				;显示到LCD
		JNB TI,$

		MOV A,#0DFH		  			;°符号
		MOV R2,#2
		ACALL WRITE_LCD			    

		MOV A,#43H		  			;C符号
		MOV R2,#2
		ACALL WRITE_LCD	

		MOV A,#2CH					;逗号
	   	MOV SBUF,A					;发送给串口
		CLR TI
		JNB TI,$

	  LJMP S1_DOWN_LOOP


;--------------------------S2子程序功能实现--------------------------------
;
;   效果:实时获取PC发来的数据并显示在LCD，同时用串口把接收到的数据发给PC
;
S2_DOWN:  
		SETB REN					;允许串口接收
		ACALL CLEAR_LCD             
	S2_LCD1:	
        MOV P0,#80H					;第一行的开始位置
		ACALL ENABLE				;推送指令
        MOV R0,#0	    			;从0开始显示TABLE2中的值
		MOV	DPTR,#TABLE2			;到TABLE2取码
    S2_LCD1_LOOP:					;把TABLE2的内容逐字节显示到第一行
      	MOV A,R0       
		MOVC A,@A+DPTR
		MOV R2,#2
		ACALL  WRITE_LCD  			;显示到LCD
		INC R0			  
		CJNE A,#00H,S2_LCD1_LOOP	;是否到00H,到的话结束读取
		MOV R0,#00H		  			;置空R0						 
	S2_LCD2:
		MOV P0,#0C0H	 			;设置第二行的开始位置
		ACALL ENABLE	 			;推送指令
		CJNE R1,#10H,S2_LCD2_LOOP  	;如果是从第二行溢出跳转而来，就直接继续显示接收到的字节，否则串口直接等待下一个数据
		MOV R1,#00H				   	
		LJMP S2_LCD2_NOT_FLOW
	S2_LCD2_LOOP:					;串口、按键循环等待
		ACALL MODE_CHOOSE_INS2	
		JNB RI,S2_LCD2_LOOP
		INC R1
		CJNE R1,#10H,S2_LCD2_NOT_FLOW
		
		ACALL CLEAR_LCD			   	;如果第二行满了就清屏重载
		AJMP S2_LCD1	
	S2_LCD2_NOT_FLOW:		   
		MOV A,SBUF
		MOV P1,A;
		MOV R2,#2
		ACALL  WRITE_LCD 			;把接收到的字符显示到LCD  
		CLR RI

		MOV SBUF,A
		JNB TI,$
		CLR TI
		LJMP S2_LCD2_LOOP

		
;--------------------------S3子程序功能实现--------------------------------
;
;电子琴：电脑数字按键1~9可以控制单片机发出对应的9个不同音调，并把琴键实时显示在LCD 
;
S3_DOWN:
		SETB REN					;允许串口接收
		MOV P0,#0CH					;显示开关控制,,关闭光标和光标闪烁
		ACALL ENABLE							   
        ACALL CLEAR_LCD 
	S3_LCD1:	
        MOV P0,#80H					;第一行的开始位置
		ACALL ENABLE				;使能指令
        MOV R0,#0	    			;从0开始显示TABLE3中的值
		MOV	DPTR,#TABLE3			;到TABLE3取码
    S3_LCD1_LOOP:					;把TABLE3的内容逐字节显示到第一行
      	MOV A,R0       
		MOVC A,@A+DPTR
		MOV R2,#2
		ACALL  WRITE_LCD  			;显示到LCD
		INC R0			  
		CJNE A,#00H,S3_LCD1_LOOP	;是否到00H,到的话结束读取
		MOV R0,#00H		  			;置空R0
		CJNE R1,#01H,S3_LCD2_LOOP   ;如果不是由于输入1~9转跳过来的，那么就重启串口接受，否则回到原位继续显示按键
		AJMP  DRAW_PIANO_LED
	S3_LCD2_LOOP:					;串口、按键循环等待
		ACALL MODE_CHOOSE_INS3	
		JNB RI,S3_LCD2_LOOP
		MOV A,SBUF
		MOV R1,#00H					
									;判断输入的数据是否是1~9,如果不是就不理会，继续等待下一个数据
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
		INC R1		   				;标记,表明是由于按下1~9而请求的清屏
		ACALL CLEAR_LCD
		LJMP S3_LCD1		 
	DRAW_PIANO_LED:	    			;显示钢琴按键
		MOV A,SBUF
		MOV P1,A					;把接收到的有效信号发给LED					
		SUBB A,#31H
		MOV B,A

	BEEP_PIANO:						;对应发出声音
		MOV DPTR,#TABLE5
		MOVC A,@A+DPTR
		MOV R3,A

		MOV A,B
		MOV DPTR,#TABLE6
		MOVC A,@A+DPTR
		MOV R4,A

		MOV R2,#40
		ACALL BEEP

	DRAW_PIANO_KEY:					;绘制钢琴按键

		MOV A,B


		ADD A,#0C6H
		MOV P0,A	 				;设置第二行的开始位置
		ACALL ENABLE
		MOV A,#0FFH					;钢琴按键图标
		MOV R2,#2
	    ACALL  WRITE_LCD  			;显示到LCD
		CLR RI						;允许继续接收数据
		LJMP S3_LCD2_LOOP


;--------------------------S4子程序初始功能实现--------------------------------	
;
; 简易电报:通过把S4按下的长短转化为0和1，凑够8位数据则转化为ASCII字符发送给PC机
;	
S4_DOWN:

		SETB REN					;允许串口接收
		MOV R7,#00H
		MOV R6,#00H					
		MOV P0,#0EH					;显示开关控制,关闭光标和光标闪烁
		ACALL ENABLE							   
        ACALL CLEAR_LCD 
	S4_LCD1:	
        MOV P0,#80H					;第一行的开始位置
		ACALL ENABLE				;使能指令
        MOV R0,#0	    			;从0开始显示TABLE4中的值
		MOV	DPTR,#TABLE4			;到TABLE4取码
    S4_LCD1_LOOP:					;把TABLE3的内容逐字节显示到第一行
      	MOV A,R0       
		MOVC A,@A+DPTR
		MOV R2,#2
		ACALL  WRITE_LCD  			;显示到LCD
		INC R0			  
		CJNE A,#00H,S4_LCD1_LOOP	;是否到00H,到的话结束读取
		MOV R0,#00H		  			;置空R0
		MOV P0,#0C0H				;光标换到第二行
		ACALL ENABLE				
		CJNE R6,#09H,JMP_MODE_CHOOSE_INS4
		MOV R6,#00H				    ;如果R6满了就把R6清零并且返回之前的地方，把接受的数据继续显示在第二行开头
	   	AJMP CHECK_OVERFLOW
	JMP_MODE_CHOOSE_INS4:		    ;否则等待其他按键按下
		AJMP MODE_CHOOSE_INS4





;=========================LCD显示屏相关子程序==========================
;----------------------------清屏子程序----------------------------------
CLEAR_LCD:
        MOV P0,#01H				    ;清屏
		ACALL ENABLE

;----------------------------送命令子程序--------------------------------
ENABLE: CLR RS 						;送命令
		CLR RW
		CLR E
		MOV R2,#2
		ACALL DELAY
		SETB E
		RET
;---------------------------送显示数据子程序-----------------------------
WRITE_LCD:
     	MOV P0,A 					;数据送显示
		SETB RS
		CLR RW
		CLR E
		ACALL DELAY
		SETB E
		RET


;---------------------------------------------------------




;============================通用功能子程序=================================

;---------------------可传参蜂鸣器---------------------------
;
;	外部可传入R2(方波数)、R3(定时器低八位)、R4(定时器高八位)
;

BEEP:
	 SETB TR0
BEEP_LOOP:	     
     MOV TL0,R3       			    ;写入计数初值
     MOV TH0,R4
     CLR TF0
BEEP_WAIT: 
     JNB TF0,BEEP_WAIT
     CPL P2.4			 			;蜂鸣器响           
     DJNZ R2,BEEP_LOOP
	 RET  

;-------------------------清除寄存器组------------------------	
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

;-------------外部可传参的毫秒级延时子程序---------------------
;
;			效果:外部传入R2，子程序就延迟R2毫秒
;
DELAY: 					

D1:		MOV R3,#05
D2:		MOV R4,#100
		DJNZ R4,$
		DJNZ R3,D2
		DJNZ R2,D1
		RET
;-----------------------延时20微秒子程序-----------------------
DELAY_20US:
		MOV R7,#10
		DJNZ R7,$
		RET

;---------------------延时500微秒子程序------------------------		
DELAY_500US:
		MOV R7,#2
YS500:
		MOV R6,#250
		DJNZ R6,$
		DJNZ R7,YS500
		RET




;===========================温度传感器相关操作子程序========================

;--------------------18B20读出转换后的温度----------------------
GET_TEMP: 
		LCALL INIT_1820				;调用初始化程序
		SETB DQ
		JB B20OK,S22				;若DS18B20存在则开始发指令操作
		LJMP GET_TEMP				;若DS18B20不存在则返回
S22:
		LCALL DELAY_20US				;延时20uS
		MOV A,#0CCH 				;跳过ROM匹配-0CC
		LCALL WRITE_1820			;写18B20
		MOV A,#44H 					;发出温度转换指令
		LCALL WRITE_1820			;写18B20
		NOP
		LCALL DELAY_500US			;延时500MS*2
		LCALL DELAY_500US
CBA:
		LCALL INIT_1820 			;初始化18B20
		JB B20OK,ABC				;若DS18B20存在则开始读取
		LJMP CBA					;若DS18B20不存在则返回重新初始化
ABC:
		CALL DELAY_20US
		MOV A,#0CCH 				;跳过ROM匹配-0CC
		LCALL WRITE_1820
		MOV A,#0BEH 				;读暂存器指令
		LCALL WRITE_1820
		LCALL READ_1820 			;跳至READ_1820
		RET
;-------------------------DS18B20初始化程序---------------------
INIT_1820:
		SETB DQ
		NOP
		CLR DQ
		MOV R0,#80H
TSR1:
		DJNZ R0,TSR1 				;延时us,拉低us，以复位
		SETB DQ
		MOV R0,#25H 				;96US-25H
TSR2:
		DJNZ R0,TSR2
		JNB DQ,TSR3					;若18B20存在，则返回存在信号
									;此时跳到TSR3，置标志位
		LJMP TSR4 					;否则跳到TSR4，置位为不存在
TSR3:
		SETB B20OK 					;置标志位,表示DS1820存在
		LJMP TSR5
TSR4:
		CLR B20OK 					;清标志位,表示DS1820不存在
		LJMP TSR7
TSR5:
		MOV R0,#06BH 				;200US
TSR6:
		DJNZ R0,TSR6 				;延时
TSR7:
		SETB DQ
		RET

;-------------------------------DS18B20读函数--------------------
READ_1820:
		MOV R4,#2 					;将温度高位和低位从DS18B20中读出
		MOV R1,#36H 				;低位存入36H(TEMP_L),高位存入35H(TEMP_H)
RE0:
		MOV R2,#8					;读1字节8位，循环次数为8
RE1:
		CLR C						;清除CY位
		SETB DQ						;数据引脚拉高
		NOP 
		NOP							;等2us
		CLR DQ						;数据引脚拉低
		NOP 
		NOP 
		NOP							;等3us
		SETB DQ						;数据引脚再拉高
		MOV R3,#7					;等7us
		DJNZ R3,$
		MOV C,DQ					;读出此时数据引脚的电平状态
									;放入CY中
		MOV R3,#23					;等23us
		DJNZ R3,$
		RRC A						;循环右移，将CY移入最低位
		DJNZ R2,RE1					;返回继续读取下一位
		MOV @R1,A					;将读取的数据存入35H或36H
		DEC R1						;第一次进后将地址减一即为35H
		DJNZ R4,RE0					;返回读第二字节
		RET

;--------------------------DS18B20写函数--------------------------
WRITE_1820:
		MOV R2,#8					;写1字节8位，循环次数为8
		CLR C						;清除CY位
WR1:
		CLR DQ						;数据引脚拉低
		MOV R3,#6					;延时6us
		DJNZ R3,$
		RRC A						;因调用WRITE_1820前将数据发在ACC中
									;通过对ACC向右带进位循环位移
									;读CY位即可依次取出每一位
		MOV DQ,C					;将一位送到数据引脚
		MOV R3,#23					;延时23us
		DJNZ R3,$
		SETB DQ						;数据引脚拉高
		NOP
		DJNZ R2,WR1					;返回传下一位
		SETB DQ						;写完一字节后拉高数据引脚，避免复位
		RET


;---------------将从DS18B20中读出的温度数据进行转换-----------------

TEMP_XCH:
		MOV A,#0F0H
		ANL A,TEMP_L 				;舍去温度低位中小数点后的四位温度数值
		SWAP A						;高四位和低四位交换位置
		MOV TEMP_0C,A				;存入TEMP_0C
		MOV A,TEMP_H
		ANL A,#07H
		SWAP A
		ORL A,TEMP_0C				;按位与得温度值
		
		MOV TEMP_0C,A 				;保存变换后的温度数据
		MOV A,#0FH	   	
		ANL A,TEMP_L
		MOV TEMP_PD,A				;读出的低四位
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