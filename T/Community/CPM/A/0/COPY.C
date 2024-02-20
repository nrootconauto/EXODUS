#include <STDIO.H>
#include <STDLIB.H>
char buf[0x80];
int main(argc,argv) char **argv; {
  int new,old;
  if(argc!=3) {
    printf("USAGE IS COPY.COM old new\n");
    exit();
  }
  new=creat(argv[2]);
  old=open(argv[1],2);
  while(0<read(old,buf,1)) {
    write(new,buf,1);
  }
  close(new);
  close(old);
  printf("COPYed %s to %s\n",argv[1],argv[2]);
  exit();
}
]);
  exit();
}
