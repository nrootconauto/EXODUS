`//Author Austin Sierra
//Last Change June 15, 2023 
//for Church of AI Christ
//Subject to Creative Commons BY-NC 4.0





//Require Tensor3D structure
//Require FileBMP structure 

#include "Tensor3D.HC";

#include "FileBMP.HC";



CDC *currentRender[4];

F64 global_scale;



//Return Individual RGBValues
I64 ColorValueCast(CBGR24 *ptr, U8 RGoB)

{

  //Print("%d",ptr->r);

  switch(RGoB)

  {

   case 0:

    return ptr->r;//0r

    break;

   case 1:

    return ptr->g;//1g

    break;

   case 2:

    return ptr->b;//2b

    break;

  }

  return 0;

}




//Filepath of BMP returns as Tensor *bmpt3d

Tensor3D *BMPFileToTensor(U8 *filename)

{

  //File information including device context

  CFileBMP *bmp;

  U8 *ptr;

  Bool rle;

  CDC *res=NULL;

  Tensor3D *bmpt3d=NULL;



  I64 i,j;

  

  if (ptr=FileRead(filename)) 

  {

    bmp=ptr;

    if (0<bmp->width<I32_MAX && 0<bmp->height<I32_MAX) 

    {

      //intialize dc (only if you need to draw)

      res=DCNew(bmp->width,bmp->height);

      //initialize return

      //Size of Return Tensor 

      Vector *sz = CreateVector(3);  

      SetVector(sz,bmp->width,0);//width

      SetVector(sz,bmp->height,1);//height

      SetVector(sz,3,2);//channels 

      bmpt3d = CreateTensor(sz);

      

      ptr+=bmp->data_offset;

      if (bmp->compression==2)

	rle=TRUE;

      else

	rle=FALSE;      
      //set a palette if you want to draw
      //palette_map=BMPPaletteNew(bmp);
      //Only supports Images from Moses Staff App

      if (bmp->bit_cnt==24||bmp->bit_cnt==32) 

      {

	for (i=0;i<bmp->height;i++) 

        {

	  for (j=0;j<bmp->width;j++,ptr+=3) 

          {

            //change dc automatically

            res->color=BMP24Color(ptr,FALSE);

            //save to return

            Vector *tmpV = CreateVector(3);

            SetVector(tmpV,ColorValueCast(ptr,0),0);

            SetVector(tmpV,ColorValueCast(ptr,1),1);

            SetVector(tmpV,ColorValueCast(ptr,2),2);

            SetTensorVector(bmpt3d,tmpV,j,i);

            DestroyVector(tmpV);

          }

          ptr+=bmp->width&3;

        }

      }



      else 

      {

	"Format Not Supported.\n";

	DCDel(res);

	res=NULL;

      }

      //DestroyVector(sz);

    } 

    else

    { 

      "Invalid BMP File\n";

    }

    Free(bmp);

  }

  return bmpt3d;
   

}


//Main to Test BMPVector

//Change the file to whatever you need

U0 BMPVector()

{  

  Tensor3D *img = BMPFileToTensor("BMP/cat.0.bmp");

  PrintTensor(img);  

  DestroyTensor(img);

  



}//BMPVector;