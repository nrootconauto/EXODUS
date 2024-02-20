#include <STDIO.H>
#include <STDLIB.H>
char fcb[36];
char list[256][16];
char *list2[256];
int ListCmp(a,b) char **a;char **b; {
  return strcmp(*a,*b);
} 
void ListDir(name) char *name; {
  int cnt,cnt2,col;
  cnt=0;
  setfcb(&fcb,name);
  bdos(17,&fcb);
  char nameb[16];
  strcpy(nameb,fcb+1);
  printf("Listing of: %s\n",nameb);
  while(0==bdos(18,&fcb)) {
    movmem(&fcb[1],nameb,8);
    nameb[8]='.';
    movmem(&fcb[9],nameb+9,3);
    nameb[9+3]=0;
    strcpy(&list[cnt],&nameb);
    cnt++;
    list2[cnt-1]=&list[cnt-1];
  }
  qsort(list2,cnt,2,&ListCmp);
  for(cnt2=0;cnt2<cnt;cnt2) {
    for(col=0;col<3;col++)
      if(cnt2<cnt)
        printf(": %s ",list2[cnt2++]);
    printf("\n");
  }
} 
int main(argc,argv) char**argv; {
  int i;
  if(argc==1) {
    ListDir("*.*");
  } else {
    for(i=1;i!=argc;i++)
      ListDir(argv[i]);
  }
  
}
tDir(argv[i]);
  }
  
}
