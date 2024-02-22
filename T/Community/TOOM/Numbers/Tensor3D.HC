//Last Change June 15, 2023 
//By Austin Sierra
//for Church of AI Christ
//Subject to Creative Commons BY-NC 4.0



//requires matrix implementation
//Cd(__DIR__);;

#include "Matrix.HC";



//Tensor Object Declaration
public class Tensor3D
{

 Vector *shape;

 Matrix *data;

 Tensor3D *last,*next; 

};

//Initialize a Tensor of vector tensorShape

/*Tensor constructor that takes a shape to initialize the 

 *tensor's dimensions.

 *
 *It is of I64 values, where each value corresponds to the
 *size of a specific dimension of the tensor that determines rank.
 *To create a Rank 3 Tensor pass {height,width, 3}
 */
Tensor3D *CreateTensor(Vector *tensorShape)
{
 I64 x=0,y=0,z=0, tsSz = tensorShape->size;
 Tensor3D *t = MAlloc(sizeof(Tensor3D));
 Tensor3D *first = t;
 t->shape = tensorShape;//CreateVector(tsSz);
 switch(tsSz)
 {
   case 0:
    t->data = CreateMatrix(1,1);
    t->last = t;
    t->next = t;
    break;

   case 1:
    x = GetVector(t->shape,0);
    t->data = CreateMatrix(x,1);
    t->last = t;
    t->next = t;
    break;

   case 2:
    x = GetVector(t->shape,0);
    y = GetVector(t->shape,1);
    t->data = CreateMatrix(x,y); 
    t->last = t;
    t->next = t;     
    break;

   case 3:
    x = GetVector(t->shape,0);
    y = GetVector(t->shape,1);
    z = GetVector(t->shape,2);
    while(z>0)
    {
     t->data = CreateMatrix(x,y);

     if(z!=1)
     {
      Tensor3D *temp = t;
      t->next=MAlloc(sizeof(Tensor3D));
      t= t->next;
      t->last =temp;
     }
     else
     {
      t->next=first;
      first->last = t;
      t = t->next;
     }
     z--;
    }
    break;
 }
 return t;

}

//Set value d at position x,y,z
U0 SetTensor(Tensor3D *t, F64 d, I64 x=0, I64 y=0, I64 z=0)
{
 Vector *v = t->shape;
 I64 sz = v->size;
 switch(sz)
 {
  case 0:
   SetMatrix(t->data,d,0,0);
   break;

  case 1:
   SetMatrix(t->data,d,0,x);
   break;

  case 2:
   SetMatrix(t->data,d,x,y);
   break;

  case 3:
   sz= GetVector(v,2);
   I64 tot = 0;
   while(sz>0)
   {
    if(tot==z)
    {
     SetMatrix(t->data,d,x,y);
    }
    t = t->next;
    sz--;
   }
   break;

 }

}



/*

  Takes a Vector d and updates values at x,y across Z level

*/
U0 SetTensorVector(Tensor3D *t, Vector *d, I64 x=0, I64 z=0)
{
 Vector *v = t->shape;
 I64 sz = v->size;
 switch(sz)
 {
  case 0:
   "Cannot set vector on 0D Tensor";
   PutExcept;
   break;
  case 1:
   SetMatrixVector(t->data,d,0);
   break;
  case 2:
   SetMatrixVector(t->data,d,x);
   break;
  case 3:
   sz= GetVector(v,2);
   I64 tot = 0;
   while(sz>0)
   {
    if(tot==z)
    {
     SetMatrixVector(t->data,d,x);
    }
    t = t->next;
    tot++;sz--;
   }
   break;
  
 }

 
}

F64 GetTensor(Tensor3D *t,I64 x=0,I64 y=0,I64 z =0)
{
 Vector *v = t->shape;
 I64 sz = v->size;

 switch(sz)
 {
  case 0:
   return GetMatrix(t->data,0,0);
   break;

  case 1:
   return GetMatrix(t->data,0,x);
   break;

  case 2:
   return GetMatrix(t->data,x,y);
   break;

  case 3:
   sz= GetVector(v,2);
   I64 tot = 0;
   I64 val = 0;
   while(tot<sz)
   {
    if(tot==z)
    {
     val= GetMatrix(t->data,x,y);
    }
    t = t->next;
    sz--;
    tot++;
   }
   return val; 
  break; 

 }

}

U0 PrintTensor(Tensor3D *t)
{
 Vector *v = t->shape;

 I64 sz = v->size;

 switch(sz)
 {
  case 0:
   Print("[ %.5f ]",GetMatrix(t->data,0,0));"\n";
   break;

  case 1:
   PrintVector(GetMatrixVector(t->data,0));
   break;

  case 2:
   PrintMatrix(t->data);
   break;

  case 3:
   I64 z= GetVector(v,2);
   I64 tot = z;
   "Plane 0:\n";
   while(z>0)
   {
    PrintMatrix(t->data);
    "\n";
    t = t->next;
    z--;
    if(z!=0)
    {
     Print("Plane %d \n",tot-z);
    }
   } 
  break; 
 } 
}

//Free a created Tensor3D t
U0 DestroyTensor(Tensor3D *t)
{
 //Vector *v = t->shape;
 I64 i, z=GetVector(t->shape,2);
 DestroyVector(t->shape);
 for(i=0;i<z;i++)
 {
   Matrix *m = t->data;
   DestroyMatrix(m);
   t = t->last; 
   Free(t->next);
 }
}

U0 MainTensor()
{
  //Set Test Vectors
  I32 vectorSize = 3;

  Vector *v1 = CreateVector(vectorSize); 
  SetVector(v1,2,0);  
  SetVector(v1,3,1);
  SetVector(v1,3,2);

  Vector *v2 = CreateVector(vectorSize);
  SetVector(v2,1,0);
  SetVector(v2,2,1);
  SetVector(v2,3,2);
 
  Tensor3D *t1 = CreateTensor(v1);

  SetTensorVector(t1,v2,0,0);
  SetTensorVector(t1,v2,0,1);
  SetTensorVector(t1,v2,0,2);
  SetTensorVector(t1,v2,1,0);
  SetTensorVector(t1,v2,1,1);
  SetTensorVector(t1,v2,1,2);

  DestroyVector(v2);
 
  PrintTensor(t1);

  DestroyTensor(t1);

  

}//MainTensor;