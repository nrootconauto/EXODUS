//Vector Implementation
//Last Change April 22nd, 2023
//Author Austin Sierra for Church of AIChrist
//Subject to Creative Commons BY-NC 4.0
//

//Vector Objection Declaration
public class Vector
{
 I32 size;
 F64 *data;
};//vectors

//Initialize Vector of size size
Vector *CreateVector(I32 size)
{
 Vector *v = MAlloc(sizeof(Vector));
 v->size = size;
 v->data = CAlloc(sizeof(F64)*size,Fs);
 return v;

}


//Reaplce Vector v1 data to value v2
U0 ReplaceVector(Vector *v1, Vector *v2)
{
 I64 i;
 if(v1->size != v2->size)
 {
   "Error:attempting to add vectors of different size.";
 }
 else
 {
  for(i=0;i<v1->size;i++)
  {
   v1->data[i] = v2->data[i];
  }
 }
}


//Set Vector v at data position i to value d
U0 SetVector(Vector *v,F64 d,I32 i)
{

 v->data[i] = d; 

}



//Prints the data values of Vector v

U0 PrintVector(Vector *v)
{
  I32 i;
  "[";
  for(i=0;i<v->size;i++)
  {
    Print("%.2f",v->data[i]);
    if(i<v->size-1){
      ", ";
    }
  }
  "]\n";
}


F64 GetVector(Vector *v, I32 i)
{
 return v->data[i];
}


//Add two vectors of the same size
Vector *AddVectors(Vector *v1, Vector *v2)

{

  I32 i;

  if(v1->size != v2->size){

    "Error: attempt to add vectors of different size.";

    return v1;

  }

  else

  {

    Vector *sum = CreateVector(v1->size);

    for(i=0;i<v1->size;i++)

    {

      sum->data[i] = v1->data[i] + v2->data[i];

    }

    return sum;

  }

}

//Calculate the magnitude (length) of a Vector v,
//i.e. distance from the origin in Euclidean space
F64 MagnitudeVector(Vector *v)
{

  F64 sum = 0;

  I32 i;

  for(i = 0;i<v->size;i++){

    sum+= v->data[i] * v->data[i];

  }

  return Sqrt(sum);

}

//Calculate the dot product of two Vectors v1 and v2
F64 DotProductVectors(Vector *v1, Vector *v2)
{

  F64 product = 0.0;

  I32 i;



  if(v1->size != v2->size)

  {

    "Error: attempt for dot product of vectors of different size.";

    return product;

  }

  else

  {

    for(i=0;i<v1->size;i++)

    {

      product+= v1->data[i] * v2->data[i];

    }

    return product;

  }

}

Vector *ScaleVector(Vector *v, F64 scalar)
{

  Vector* scaled = CreateVector(v->size);

  I32 i;

  for(i =0;i<v->size;i++){

    scaled->data[i] = v->data[i] * scalar;

  }

  return scaled;

}





//Free a created Vector v

U0 DestroyVector(Vector *v)
{

 Free(v->data);
 Free(v);

}

//
// See P_DivlineSide in DOOM
//
I64 SideOfVector2D(Vector *v,CD2 *point) {
  F64 dx=v->data[0],dy=v->data[1];
  F64 left=dy*point->x,right=dx*point->y;
  if(right<left)
    return 0;
  return 1;
}

Bool IsFrontSideOfVector2D(Vector *v,CD2 *point) {
  return SideOfVector2D(v,point)==0;
}

//Main to demo vectors
U0 MainVector()
{

  I32 vectorSize = 3;

  Vector *v1= CreateVector(vectorSize);
  Vector *v2= CreateVector(vectorSize);

  SetVector(v1,1,0);
  SetVector(v1,2,1);
  SetVector(v1,3,2);

  SetVector(v2,4,0);
  SetVector(v2,5,1);
  SetVector(v2,6,2);

  Vector *sum = AddVectors(v1,v2);
  "v1 + v2 = ";
  PrintVector(sum);  

  F64 dot_product = DotProductVectors(v1,v2);
  Print("v1 . v2 = %.5f\n",dot_product);

  Vector *scaled = ScaleVector(v1,2);
  "2 * v1 = ";
  PrintVector(scaled);

  F64 mag = MagnitudeVector(v1);
  Print("|v1| = %.5f\n",mag);  

  DestroyVector(v1);
  DestroyVector(v2);
  DestroyVector(sum);
  DestroyVector(scaled);
}//MainVector;




//note: typecast is postfix, i.e. ToI64();