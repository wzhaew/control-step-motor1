        ORG     0000H
        AJMP    MAIN
        ORG     0003H
        AJMP    WZD0
        ORG     000BH
        AJMP    TZD0

MAIN:   MOV     SP,#70H
        SETB    IT0
        MOV     TMOD,#01H      ;定时器方式1
        MOV     IE,#10000011B  ;开放T0与INT0中断
        MOV     TH0,#0FCH      ;定时器初值，1ms溢出中断
        MOV     TL0,#17H
        MOV     R1,#32H        ;R1数据指针
        MOV     31H,#08H       ;位寄存器
        MOV     55H,#0FFH
        MOV     56H,#0AH
        CLR     20H
        CLR     21H
       ; MOV    32H,#2          ;32H~35H为数据缓冲区
       ; MOV    33H,#0
       ; MOV    34H,#4
       ; MOV    35H,#9
        MOV     R6,#00H        ;数据寄存器 高字节
        MOV     R7,#00H        ;数据寄存器 低字节
        LCALL   HB2
        SETB    TR0            ;打开定时器
     
        MOV     50H,#00H       ;触发端A上一次值（历史）寄存器
        SETB    P1.4           ;触发端A
        SETB    P1.5           ;触发端B
        
        
        
        
WZHHH:  JNB     20H,ECODE

BJ1:    LCALL   HB2             ;步进电机驱动程序
        CJNE    R6,#00H,B1
        CJNE    R7,#00H,B1
        SJMP    WZH1
        
B1:     MOV     P2,#0F6H
        LCALL   DELAY
        MOV     P2,#0F7H
        LCALL   DELAY
        MOV     P2,#0F3H
        LCALL   DELAY
        MOV     P2,#0FBH
        LCALL   DELAY
        MOV     P2,#0F9H
        LCALL   DELAY
        MOV     P2,#0FDH
        LCALL   DELAY
        MOV     P2,#0FCH
        LCALL   DELAY
        MOV     P2,#0FEH
        LCALL   DELAY
        JNB     20H,WZHHH
        DJNZ    56H,B1
        MOV     56H,#0AH
        
B7:     MOV     A,R7
        SUBB    A,#1
        MOV     R7,A
        JNC     BJ1
        CJNE    R6,#00H,B6
        SJMP    WZH1
B6:     DEC     R6 
        AJMP    BJ1
        MOV     P2,#0FFH  

WZH1:   JB      20H,WZH1
        
        
        
        
ECODE:  MOV     C,P1.4         ;扫描编码器服务函数
        JC      W1
        CLR     A
        SJMP    W2
W1:     MOV     A,#0FFH
W2:     CJNE    A,50H,W3
        SJMP    WZHHH           ;ECODE
W3:     MOV     50H,A
        MOV     C,P1.4
        JC      W4
        MOV     C,P1.5
        JNC     W5
        CLR     C
        CLR     A
        MOV     A,R7
        ADD     A,#1
        MOV     R7,A
        CLR     A
        ADDC    A,R6
        MOV     R6,A
        SJMP    W4
W5:     CJNE    R6,#00H,W7
        CJNE    R7,#00H,W7
        SJMP    W4
W7:     MOV     A,R7
        SUBB    A,#1
        MOV     R7,A
        JNC     W4
        CJNE    R6,#00H,W6
        SJMP    W4
W6:     DEC     R6 
W4:     LCALL   HB2
        AJMP    WZHHH         ;ECODE


        
WZD0:   CLR     EX0
        PUSH    PSW             ;只用来产生允许输入标志位
        PUSH    A   
        CPL     20H
        POP     A
        POP     PSW
        
        RETI



TZD0:   CLR     TR0             ;定时器T0溢出中断服务函数
        PUSH    PSW             ;此函数主要为数码管显示
        PUSH    A
        MOV     42H,R2
        MOV     43H,R3
        MOV     R2,#08H
        MOV     R3,#02H
        MOV     A,@R1
        MOV     DPTR,#TAB
        MOVC    A,@A+DPTR

LOOP:   MOV     C,ACC.7         ;单字节串行移位函数
        MOV     P1.0,C          ;P1.0~DIO  P1.1~RCLK  P1.2~SCLK
        RL      A
        CLR     P1.2
        NOP
        NOP
        SETB    P1.2
        DJNZ    R2,LOOP
        MOV     R2,#08H

        MOV     A,31H           ;位码
        DJNZ    R3,LOOP
        CLR     P1.1
        NOP
        NOP
        SETB    P1.1

        CLR     C
        MOV     A,31H
        RRC     A
        MOV     31H,A
        JNC     JJ1
        MOV     31H,#08H
JJ1:    INC     R1
        CJNE    R1,#36H,CC1
        MOV     R1,#32H
CC1:    MOV     TH0,#0FCH       ;定时器初值，1ms溢出中断
        MOV     TL0,#17H

        MOV     R2,42H
        MOV     R3,43H
        DJNZ    55H,WDWD       ;外部中断软件消抖
        MOV     55H,#0FFH    
        SETB    EX0     
WDWD:   POP     A
        POP     PSW
        SETB    TR0
        RETI




HB2:    MOV     40H,R6
        MOV     41H,R7
        CLR     A               ;双字节十六进制整数化为三字节
        MOV     R3,A            ;BCD码入口：R6,R7 出口：R3,R4,R5
        MOV     R4,A
        MOV     R5,A
        MOV     R2,#10H
HB3:    MOV     A,R7
        RLC     A
        MOV     R7,A
        MOV     A,R6
        RLC     A
        MOV     R6,A
        MOV     A,R5
        ADDC    A,R5
        DA      A
        MOV     R5,A
        MOV     A,R4
        ADDC    A,R4
        DA      A
        MOV     R4,A
        MOV     A,R3
        ADDC    A,R3
        MOV     R3,A
        DJNZ    R2,HB3      ;转完
        ; CLR     A
        MOV     R6,40H
        MOV     R7,41H
        MOV     A,R5        ; 32H~35H为数据缓冲区
        MOV     35H,A       ;将转换好的各位送入对应缓冲区
        ANL     35H,#0FH
        SWAP    A
        MOV     34H,A
        ANL     34H,#0FH
        MOV     A,R4
        MOV     33H,A
        ANL     33H,#0FH
        SWAP    A
        MOV     32H,A
        ANL     32H,#0FH
        RET



DELAY:  MOV     R4,#2    ;1ms延时子程序
D1:     MOV     R5,#250   ;50us延时
        DJNZ    R5,$
        DJNZ    R4,D1
        RET

        LJMP    MAIN

TAB:    DB      0C0H,0F9H,0A4H,0B0H,99H ;0,1,2,3,4
        DB      92H,82H,0F8H,80H,90H    ;5,6,7,8,9
        DB      88H,83H,0C6H,0A1H,86H   ;A,B,C,D,E
        DB      8EH,0BFH,8CH,0FFH       ;F,-,P,暗
