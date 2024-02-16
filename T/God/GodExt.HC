#help_index "God"

MemSet(&god,0,sizeof(CGodGlbls));
god.doodle_fifo	=FifoU8New(2048*8);
god.fifo	=FifoU8New(2048*8);

extern U0 GodBiblePassage(I64 num_lines=20);
extern U0 GodBitsIns(I64 num_bits,I64 n);
extern U0 GodDoodle(U8 *hex=NULL);
extern U0 GodSong();
extern U0 GodWord(I64 bits=17);
