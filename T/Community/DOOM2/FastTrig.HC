#ifndef  FAST_TRIG
#define FAST_TRIG "fast"
#define FCos Cos
#define FSin Sin
#define FArg Arg
#endif
//https://www.flipcode.com/archives/Fast_Approximate_Distance_Functions.shtml
F64 ApproxDist(F64 a,F64 b) {
  if(a<0.) a=-a;
  if(b<0.) b=-b;
  F64 max,min,approx;
  if(a<b) max=b,min=a;
  else max=a,min=b;
  approx=max*1007+min*441;
  if(approx<min*16)
    approx-=max*40;
  return (approx+512)/(1<<10);
}