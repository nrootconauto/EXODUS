/*Asm labels can only be defined once
in a task.<F5> will spawn a new task
each time, so you don't get redefine
error, like when repeatedly #including
it from the cmd line.
*/

U0 AsmAndC3()
{
  I64 i;
  for (i=0;i<3;i++) {
    "Meaning of life:";
    MOV	AL,0x41
    STC
    ADC	AL,0 //Round-about way to make the not-special constant, 0x42.
    MOVZX EAX,AL
    PUSH 16
    PUSH RAX
    CALL &PutHex
    PUSH 300
    CALL &Sleep    
    '\n';
  }
}

AsmAndC3;
