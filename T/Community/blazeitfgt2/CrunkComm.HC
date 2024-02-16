#ifndef CRUNKCOMM_HC
#define CRUNKCOMM_HC

#define COMM_PORT 0x3F8

#define UART_THR  0
#define UART_RDR  0
#define UART_BRDL 0
#define UART_IER  1
#define UART_BRDH 1
#define UART_IIR  2
#define UART_LCR  3
#define UART_MCR  4
#define UART_LSR  5
#define UART_MSR  6

#define COMM_WAITING InU8(COMM_PORT+UART_LSR)&1

public U0 InitComm() {
  OutU8(COMM_PORT+UART_IER,0);    //Disable all IRQ
  OutU8(COMM_PORT+UART_LCR,0x80); //Enable DLAB (set baud rate divisor)
  OutU8(COMM_PORT+UART_BRDL,1);	//LSB 115200 bit/s
//  OutU8(COMM_PORT+UART_BRDL,2);	//LSB 57600 bit/s
//  OutU8(COMM_PORT+UART_BRDL,3);	//LSB 38400 bit/s
  OutU8(COMM_PORT+UART_BRDH,0);	//MSB
  OutU8(COMM_PORT+UART_LCR,3);	//8-none-1
  OutU8(COMM_PORT+UART_IIR,0xC7); // Enable FIFO, clear, 14-byte threshold
//  OutU8(COMM_PORT+UART_IIR,0x6); // Disable FIFO, clear, 14-byte threshold
  OutU8(COMM_PORT+UART_MCR,0x0F);
}

public U0 CommFlush() {
  while (InU8(COMM_PORT+UART_LSR)&1) {}
}

public Bool CommReadChar(U8 *buf) {
  if (InU8(COMM_PORT+UART_LSR)&1) {
    *buf = InU8(COMM_PORT);
    return TRUE;
  }
  return FALSE;
}

public U0 CommReadLine(U8 *buf) {
  I64 i=0;
  buf[0] = '\0';
  while (buf[i] != '\n') {
    while (InU8(COMM_PORT+UART_LSR)&1) {
      buf[i] = InU8(COMM_PORT);
      if (buf[i] == '\n') break;
      i++;
    }
    Yield;
  }
  buf[i] = '\0';
}

public U0 CommPutChar(U8 b) {
  while (!(InU8(COMM_PORT+UART_LSR) & 0x20))
    Yield;
  OutU8(COMM_PORT+UART_THR,b);
  while (!(InU8(COMM_PORT+UART_LSR) & 0x20))
    Yield;
}

public U0 CommPutS(U8 *st) {
  I64 b;
  while (b=*st++)
    CommPutChar(b);
}

public U0 CommPutBlk(U8 *buf,I64 cnt) {
  while (cnt--)
    CommPutChar(*buf++);
}

public U0 CommPrint(U8 *fmt,...) {
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv);
  Free(buf);
}

#endif
