asm {
//************************************
_D3_NORM::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RDX,U64 SF_ARG1[RBP]
	FLD	U64 [RDX]
	FMUL	ST0,ST0
	FLD	U64 8[RDX]
	FMUL	ST0,ST0
	FADDP	ST1,ST0
	FLD	U64 16[RDX]
	FMUL	ST0,ST0
	FADDP	ST1,ST0
	FSQRT
	FSTP	U64 SF_ARG1[RBP]
	MOV	RAX,U64 SF_ARG1[RBP]
	POP	RBP
	RET1	8
//************************************
_D3_NORM_SQR::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RDX,U64 SF_ARG1[RBP]
	FLD	U64 [RDX]
	FMUL	ST0,ST0
	FLD	U64 8[RDX]
	FMUL	ST0,ST0
	FADDP	ST1,ST0
	FLD	U64 16[RDX]
	FMUL	ST0,ST0
	FADDP	ST1,ST0
	FSTP	U64 SF_ARG1[RBP]
	MOV	RAX,U64 SF_ARG1[RBP]
	POP	RBP
	RET1	8
//************************************
_D3_DIST::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RDX,U64 SF_ARG1[RBP]
	MOV	RBX,U64 SF_ARG2[RBP]
	FLD	U64 [RDX]
	FSUB	ST0,U64 [RBX]
	FMUL	ST0,ST0
	FLD	U64 8[RDX]
	FSUB	ST0,U64 8[RBX]
	FMUL	ST0,ST0
	FADDP	ST1,ST0
	FLD	U64 16[RDX]
	FSUB	ST0,U64 16[RBX]
	FMUL	ST0,ST0
	FADDP	ST1,ST0
	FSQRT
	FSTP	U64 SF_ARG1[RBP]
	MOV	RAX,U64 SF_ARG1[RBP]
	POP	RBP
	RET1	16
//************************************
_D3_DIST_SQR::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RDX,U64 SF_ARG1[RBP]
	MOV	RBX,U64 SF_ARG2[RBP]
	FLD	U64 [RDX]
	FSUB	ST0,U64 [RBX]
	FMUL	ST0,ST0
	FLD	U64 8[RDX]
	FSUB	ST0,U64 8[RBX]
	FMUL	ST0,ST0
	FADDP	ST1,ST0
	FLD	U64 16[RDX]
	FSUB	ST0,U64 16[RBX]
	FMUL	ST0,ST0
	FADDP	ST1,ST0
	FSTP	U64 SF_ARG1[RBP]
	MOV	RAX,U64 SF_ARG1[RBP]
	POP	RBP
	RET1	16
//************************************
_D3_CROSS::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RAX,U64 SF_ARG1[RBP]
	MOV	RDX,U64 SF_ARG2[RBP]
	MOV	RBX,U64 SF_ARG3[RBP]

	FLD	U64 8[RDX]
	FMUL	ST0,U64 16[RBX]
	FLD	U64 16[RDX]
	FMUL	ST0,U64 8[RBX]
	FSUBP	ST1,ST0
	FSTP	U64 [RAX]

	FLD	U64 [RDX]
	FMUL	ST0,U64 16[RBX]
	FLD	U64 16[RDX]
	FMUL	ST0,U64 [RBX]
	FSUBRP	ST1,ST0
	FSTP	U64 8[RAX]

	FLD	U64 [RDX]
	FMUL	ST0,U64 8[RBX]
	FLD	U64 8[RDX]
	FMUL	ST0,U64 [RBX]
	FSUBP	ST1,ST0
	FSTP	U64 16[RAX]

	POP	RBP
	RET1	24
//************************************
_D3_DOT::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RDX,U64 SF_ARG1[RBP]
	MOV	RBX,U64 SF_ARG2[RBP]
	FLD	U64 [RDX]
	FMUL	ST0,U64 [RBX]
	FLD	U64 8[RDX]
	FMUL	ST0,U64 8[RBX]
	FADDP	ST1,ST0
	FLD	U64 16[RDX]
	FMUL	ST0,U64 16[RBX]
	FADDP	ST1,ST0
	FSTP	U64 SF_ARG1[RBP]
	MOV	RAX,U64 SF_ARG1[RBP]
	POP	RBP
	RET1	16
//************************************
_D3_ADD::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RAX,U64 SF_ARG1[RBP]
	MOV	RDX,U64 SF_ARG2[RBP]
	MOV	RBX,U64 SF_ARG3[RBP]
	FLD	U64 [RDX]
	FADD	ST0,U64 [RBX]
	FSTP	U64 [RAX]
	FLD	U64 8[RDX]
	FADD	ST0,U64 8[RBX]
	FSTP	U64 8[RAX]
	FLD	U64 16[RDX]
	FADD	ST0,U64 16[RBX]
	FSTP	U64 16[RAX]
	POP	RBP
	RET1	24
//************************************
_D3_SUB::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RAX,U64 SF_ARG1[RBP]
	MOV	RDX,U64 SF_ARG2[RBP]
	MOV	RBX,U64 SF_ARG3[RBP]
	FLD	U64 [RDX]
	FSUB	ST0,U64 [RBX]
	FSTP	U64 [RAX]
	FLD	U64 8[RDX]
	FSUB	ST0,U64 8[RBX]
	FSTP	U64 8[RAX]
	FLD	U64 16[RDX]
	FSUB	ST0,U64 16[RBX]
	FSTP	U64 16[RAX]
	POP	RBP
	RET1	24
//************************************
_D3_MUL::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RAX,U64 SF_ARG1[RBP]
	MOV	RBX,U64 SF_ARG3[RBP]
	FLD	U64 SF_ARG2[RBP]
	FLD	ST0
	FMUL	ST0,U64 [RBX]
	FSTP	U64 [RAX]
	FLD	ST0
	FMUL	ST0,U64 8[RBX]
	FSTP	U64 8[RAX]
	FMUL	ST0,U64 16[RBX]
	FSTP	U64 16[RAX]
	POP	RBP
	RET1	24
//************************************
_D3_DIV::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RAX,U64 SF_ARG1[RBP]
	MOV	RBX,U64 SF_ARG2[RBP]
	FLD	U64 SF_ARG3[RBP]
	FLD	ST0
	FDIVR	ST0,U64 [RBX]
	FSTP	U64 [RAX]
	FLD	ST0
	FDIVR	ST0,U64 8[RBX]
	FSTP	U64 8[RAX]
	FDIVR	ST0,U64 16[RBX]
	FSTP	U64 16[RAX]
	POP	RBP
	RET1	24
//************************************
_D3_ZERO::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RAX,U64 SF_ARG1[RBP]
	XOR	RDX,RDX
	MOV	U64 [RAX],RDX
	MOV	U64 8[RAX],RDX
	MOV	U64 16[RAX],RDX
	POP	RBP
	RET1	8
//************************************
_D3_COPY::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RAX,U64 SF_ARG1[RBP]
	MOV	RBX,U64 SF_ARG2[RBP]
	MOV	RDX,U64 [RBX]
	MOV	U64 [RAX],RDX
	MOV	RDX,U64 8[RBX]
	MOV	U64 8[RAX],RDX
	MOV	RDX,U64 16[RBX]
	MOV	U64 16[RAX],RDX
	POP	RBP
	RET1	16
//************************************
_D3_EQU::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RAX,U64 SF_ARG1[RBP]
	MOV	RDX,U64 SF_ARG2[RBP]
	MOV	U64 [RAX],RDX
	MOV	RDX,U64 SF_ARG3[RBP]
	MOV	U64 8[RAX],RDX
	MOV	RDX,U64 SF_ARG4[RBP]
	MOV	U64 16[RAX],RDX
	POP	RBP
	RET1	32
//************************************
_D3_ADD_EQU::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RAX,U64 SF_ARG1[RBP]
	MOV	RBX,U64 SF_ARG2[RBP]
	FLD	U64 [RAX]
	FADD	ST0,U64 [RBX]
	FSTP	U64 [RAX]
	FLD	U64 8[RAX]
	FADD	ST0,U64 8[RBX]
	FSTP	U64 8[RAX]
	FLD	U64 16[RAX]
	FADD	ST0,U64 16[RBX]
	FSTP	U64 16[RAX]
	POP	RBP
	RET1	16
//************************************
_D3_SUB_EQU::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RAX,U64 SF_ARG1[RBP]
	MOV	RBX,U64 SF_ARG2[RBP]
	FLD	U64 [RAX]
	FSUB	ST0,U64 [RBX]
	FSTP	U64 [RAX]
	FLD	U64 8[RAX]
	FSUB	ST0,U64 8[RBX]
	FSTP	U64 8[RAX]
	FLD	U64 16[RAX]
	FSUB	ST0,U64 16[RBX]
	FSTP	U64 16[RAX]
	POP	RBP
	RET1	16
//************************************
_D3_MUL_EQU::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RAX,U64 SF_ARG1[RBP]
	FLD	U64 SF_ARG2[RBP]
	FLD	ST0
	FMUL	ST0,U64 [RAX]
	FSTP	U64 [RAX]
	FLD	ST0
	FMUL	ST0,U64 8[RAX]
	FSTP	U64 8[RAX]
	FMUL	ST0,U64 16[RAX]
	FSTP	U64 16[RAX]
	POP	RBP
	RET1	16
//************************************
_D3_DIV_EQU::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RAX,U64 SF_ARG1[RBP]
	FLD	U64 SF_ARG2[RBP]
	FLD	ST0
	FDIVR	ST0,U64 [RAX]
	FSTP	U64 [RAX]
	FLD	ST0
	FDIVR	ST0,U64 8[RAX]
	FSTP	U64 8[RAX]
	FDIVR	ST0,U64 16[RAX]
	FSTP	U64 16[RAX]
	POP	RBP
	RET1	16
//************************************
_D3_UNIT::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RAX,U64 SF_ARG1[RBP]
	FLD	U64 [RAX]
	FMUL	ST0,ST0
	FLD	U64 8[RAX]
	FMUL	ST0,ST0
	FADDP	ST1,ST0
	FLD	U64 16[RAX]
	FMUL	ST0,ST0
	FADDP	ST1,ST0
	FSQRT
	FST	U64 SF_ARG1[RBP]
	MOV	RBX,SF_ARG1[RBP]
	TEST	RBX,RBX
	JZ	@@05
	FLD	ST0
	FDIVR	ST0,U64 [RAX]
	FSTP	U64 [RAX]
	FLD	ST0
	FDIVR	ST0,U64 8[RAX]
	FSTP	U64 8[RAX]
	FDIVR	ST0,U64 16[RAX]
	FSTP	U64 16[RAX]
	POP	RBP
	RET1	8
@@05:	FFREE	ST0
	FINCSTP
	POP	RBP
	RET1	8
//************************************
_SQR::
	PUSH	RBP
	MOV	RBP,RSP
	FLD	U64 SF_ARG1[RBP]
	FMUL	ST0,ST0
	FSTP	U64 SF_ARG1[RBP]
	MOV	RAX,U64 SF_ARG1[RBP]
	POP	RBP
	RET1	8
//************************************
//  1.: 0x3FF0000000000000ÄÂÄ|0x8000000000000000 (sign bit)
// -1.: 0xBFF0000000000000ÄÙ
// -0.==0|0x8000000000000000, so remove sign bit and test
_SIGN::
	MOV	RAX,0x8[RSP]
	MOV	RCX,RAX
	//SHR	RAX,63 //faster on older processors
	//SHL	RAX,63
	MOV	RDX,-0. // faster on newer ones
	AND	RAX,RDX
	MOV	RDX,1.
	OR	RAX,RDX
	BTR	RCX,63//sign bit
	TEST	RCX,RCX
	CMOVZ	RAX,RCX
	RET1	8
//************************************
_ARG::
	PUSH	RBP
	MOV	RBP,RSP
	FLD	U64 SF_ARG2[RBP]
	FLD	U64 SF_ARG1[RBP]
@@05:	FPATAN
	FSTSW
	TEST	AX,0x400
	JNZ	@@05
	FSTP	U64 SF_ARG1[RBP]
	MOV	RAX,U64 SF_ARG1[RBP]
	POP	RBP
	RET1	16
//************************************
_ROUND::
	PUSH	RBP
	MOV	RBP,RSP
	SUB	RSP,8
	FSTCW	U16 -8[RBP]
	MOV	AX,U16 -8[RBP]
	MOV	U16 -6[RBP],AX
	AND	AX,~0x0C00
	MOV	U16 -8[RBP],AX
	FLDCW	U16 -8[RBP]

	FLD	U64 SF_ARG1[RBP]
	FRNDINT
	FSTP	U64 SF_ARG1[RBP]
	MOV	RAX,U64 SF_ARG1[RBP]

	FLDCW	U16 -6[RBP]
	LEAVE
	RET1	8
//************************************
_TRUNC::
	PUSH	RBP
	MOV	RBP,RSP
	SUB	RSP,8
	FSTCW	U16 -8[RBP]
	MOV	AX,U16 -8[RBP]
	MOV	U16 -6[RBP],AX
	OR	AX,0x0C00
	MOV	U16 -8[RBP],AX
	FLDCW	U16 -8[RBP]

	FLD	U64 SF_ARG1[RBP]
	FRNDINT
	FSTP	U64 SF_ARG1[RBP]
	MOV	RAX,U64 SF_ARG1[RBP]

	FLDCW	U16 -6[RBP]
	LEAVE
	RET1	8
//************************************
_FLOOR::
	PUSH	RBP
	MOV	RBP,RSP
	SUB	RSP,8
	FSTCW	U16 -8[RBP]
	MOV	AX,U16 -8[RBP]
	MOV	U16 -6[RBP],AX
	AND	AX,~0x0C00
	OR	AX,0x0400
	MOV	U16 -8[RBP],AX
	FLDCW	U16 -8[RBP]

	FLD	U64 SF_ARG1[RBP]
	FRNDINT
	FSTP	U64 SF_ARG1[RBP]
	MOV	RAX,U64 SF_ARG1[RBP]

	FLDCW	U16 -6[RBP]
	LEAVE
	RET1	8
//************************************
_CEIL::
	PUSH	RBP
	MOV	RBP,RSP
	SUB	RSP,8
	FSTCW	U16 -8[RBP]
	MOV	AX,U16 -8[RBP]
	MOV	U16 -6[RBP],AX
	AND	AX,~0x0C00
	OR	AX,0x0800
	MOV	U16 -8[RBP],AX
	FLDCW	U16 -8[RBP]

	FLD	U64 SF_ARG1[RBP]
	FRNDINT
	FSTP	U64 SF_ARG1[RBP]
	MOV	RAX,SF_ARG1[RBP]

	FLDCW	U16 -6[RBP]
	LEAVE
	RET1	8
//************************************
SYS_POW::
// RAX=RDX`RAX
	PUSH	RBP
	MOV	RBP,RSP
	SUB	RSP,24
	TEST	RAX,RAX	//To power of zero?
	JNZ	@@05
	MOV	RAX,1.0
	JMP	@@20
@@05:	TEST	RDX,RDX	//zero to a power?
	JNZ	@@10
	XOR	RAX,RAX
	JMP	@@20
@@10:	MOV	RCX,RAX //RCX=pow
	MOV	U64 -8[RBP],RDX
	MOV	U64 -16[RBP],RAX
	FSTCW	U16 -24[RBP]
	MOV	AX,U16 -24[RBP]
	MOV	U16 -22[RBP],AX
	OR	AX,0x0C00
	MOV	U16 -24[RBP],AX
	FLDCW	U16 -24[RBP]
	FLD	U64 -16[RBP]
	FLD	U64 -8[RBP]
	FABS	//base should be pos
	FYL2X	// y*log2(x)
	FST	U64 -8[RBP]
	FRNDINT
	FLD	U64 -8[RBP]
	FSUBRP	ST1,ST0
	F2XM1
	FLD1
	FADDP	ST1,ST0
	FSTP	U64 -16[RBP]
	FLD	U64 -8[RBP]
	FLD	U64 -16[RBP]
	FSCALE	// ST0<<ST1
	TEST	RDX,RDX //was base neg?
	JGE	@@15
	MOV	U64 -16[RBP],RCX
	FLD	U64 -16[RBP]
	FISTTP	U64 -16[RBP]
	TEST	U64 -16[RBP],1
	JZ	@@15	//was pow odd?
	FCHS
@@15:	FSTP	U64 -8[RBP]
	FFREE	ST0
	FINCSTP
	FLDCW	U16 -22[RBP]
	MOV	RAX,U64 -8[RBP]
@@20:	LEAVE
	RET
//************************************
_POW::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RAX,U64 SF_ARG2[RBP]
	MOV	RDX,U64 SF_ARG1[RBP]
	CALL	SYS_POW
	POP	RBP
	RET1	16
//************************************
_POW10::
	PUSH	RBP
	MOV	RBP,RSP
	SUB	RSP,16
	FSTCW	U16 -8[RBP]
	MOV	AX,U16 -8[RBP]
	MOV	U16 -6[RBP],AX
	OR	AX,0x0C00
	MOV	U16 -8[RBP],AX
	FLDCW	U16 -8[RBP]

	FLDL2T
	FLD	U64 SF_ARG1[RBP]
	FMULP	ST1,ST0
	FST	U64 SF_ARG1[RBP]
	FRNDINT
	FLD	U64 SF_ARG1[RBP]
	FSUBRP	ST1,ST0
	F2XM1
	FLD1
	FADDP	ST1,ST0
	FSTP	U64 -16[RBP]
	FLD	U64 SF_ARG1[RBP]
	FLD	U64 -16[RBP]
	FSCALE	// ST0<<ST1
	FSTP	U64 -16[RBP]
	FFREE	ST0
	FINCSTP

	FLDCW	U16 -6[RBP]
	MOV	RAX,U64 -16[RBP]
	LEAVE
	RET1	8
//************************************
_EXP::
	PUSH	RBP
	MOV	RBP,RSP
	SUB	RSP,16
	FSTCW	U16 -8[RBP]
	MOV	AX,U16 -8[RBP]
	MOV	U16 -6[RBP],AX
	OR	AX,0x0C00
	MOV	U16 -8[RBP],AX
	FLDCW	U16 -8[RBP]

	FLDL2E
	FLD	U64 SF_ARG1[RBP]
	FMULP	ST1,ST0
	FST	U64 SF_ARG1[RBP]
	FRNDINT
	FLD	U64 SF_ARG1[RBP]
	FSUBRP	ST1,ST0
	F2XM1
	FLD1
	FADDP	ST1,ST0
	FSTP	U64 -16[RBP]
	FLD	U64 SF_ARG1[RBP]
	FLD	U64 -16[RBP]
	FSCALE	// ST0<<ST1
	FSTP	U64 -16[RBP]
	FFREE	ST0
	FINCSTP

	FLDCW	U16 -6[RBP]
	MOV	RAX,U64 -16[RBP]
	LEAVE
	RET1	8
//************************************
_LOG10::
	PUSH	RBP
	MOV	RBP,RSP
	FLDLG2
	FLD	U64 SF_ARG1[RBP]
	FYL2X	// y*log2(x)
	FSTP	U64 SF_ARG1[RBP]
	MOV	RAX,U64 SF_ARG1[RBP]
	POP	RBP
	RET1	8
//************************************
_LOG2::
	PUSH	RBP
	MOV	RBP,RSP
	FLD1
	FLD	U64 SF_ARG1[RBP]
	FYL2X	// y*log2(x)
	FSTP	U64 SF_ARG1[RBP]
	MOV	RAX,U64 SF_ARG1[RBP]
	POP	RBP
	RET1	8
//************************************
_LN::
	PUSH	RBP
	MOV	RBP,RSP
	FLDLN2
	FLD	U64 SF_ARG1[RBP]
	FYL2X	// y*log2(x)
	FSTP	U64 SF_ARG1[RBP]
	MOV	RAX,U64 SF_ARG1[RBP]
	POP	RBP
	RET1	8
//************************************
_FLDCW::
	PUSH	RBP
	MOV	RBP,RSP
	FLDCW	U16 SF_ARG1[RBP]
	POP	RBP
	RET1	8
//************************************
_FSTCW::
	PUSH	RBP
	MOV	RBP,RSP
	SUB	RSP,8
	FSTCW	U16 -8[RBP]
	MOVZX	RAX,U16 -8[RBP]
	LEAVE
	RET
//************************************
_FSTSW::
	XOR	RAX,RAX
	FSTSW
	RET
//************************************
_FCLEX::
	FCLEX
	RET
}

F64 Clamp(F64 d,F64 lo,F64 hi)
{//Clamp to F64 [] range.
  if (d<lo)
    return lo;
  if (d>hi)
    return hi;
  return d;
}

F64 Min(F64 n1,F64 n2)
{//Min of two F64s.
  if (n1<=n2)
    return n1;
  else
    return n2;
}

F64 Max(F64 n1,F64 n2)
{//Max of two F64s.
  if (n1>=n2)
    return n1;
  else
    return n2;
}

F64 Pow10I64(I64 i)
{//F64 int powers of ten.
  if (i>308)
    return inf;
  else if (i<-308)
    return 0.0;
  else
    return pow10_I64[i+309];
}

U64 FloorU64(U64 num,U64 to)
{//Int multiples of num.
  return num-num%to;
}

U64 CeilU64(U64 num,U64 to)
{//Int multiples of num.
  num+=to-1;
  return num-num%to;
}

I64 RoundI64(I64 num,I64 to)
{//Int multiples of num.
  return num-num%to;
}

I64 FloorI64(I64 num,I64 to)
{//Int multiples of num.
  if (num>=0)
    return num-num%to;
  else {
    num++;
    return num-num%to-to;
  }
}

I64 CeilI64(I64 num,I64 to)
{//Int multiples of num.
  if (num>=0) {
    num+=to-1;
    return num-num%to;
  } else {
    num+=to-1;
    return num-num%to-to;
  }
}

//See $LK,"::/Doc/Credits.DD"$.
#define LIN_CONGRUE_A	6364136223846793005
#define LIN_CONGRUE_C	1442695040888963407

I16 RandI16()
{//Random I16.
  I64 res=Fs->rand_seed;
  res=LIN_CONGRUE_A*res^(res&0xFFFFFFFF0000)>>16+LIN_CONGRUE_C;
  if (!Bt(&Fs->task_flags,TASKf_NONTIMER_RAND))
    res^=GetTSC;
  Fs->rand_seed=res;
  return res.i16[0];
}

U16 RandU16()
{//Random U16.
  I64 res=Fs->rand_seed;
  res=LIN_CONGRUE_A*res^(res&0xFFFFFFFF0000)>>16+LIN_CONGRUE_C;
  if (!Bt(&Fs->task_flags,TASKf_NONTIMER_RAND))
    res^=GetTSC;
  Fs->rand_seed=res;
  return res.u16[0];
}

I32 RandI32()
{//Random I32.
  I64 res=Fs->rand_seed;
  res=LIN_CONGRUE_A*res^(res&0xFFFFFFFF0000)>>16+LIN_CONGRUE_C;
  if (!Bt(&Fs->task_flags,TASKf_NONTIMER_RAND))
    res^=GetTSC;
  Fs->rand_seed=res;
  return res.i32[0];
}

U32 RandU32()
{//Random U32.
  I64 res=Fs->rand_seed;
  res=LIN_CONGRUE_A*res^(res&0xFFFFFFFF0000)>>16+LIN_CONGRUE_C;
  if (!Bt(&Fs->task_flags,TASKf_NONTIMER_RAND))
    res^=GetTSC;
  Fs->rand_seed=res;
  return res.u32[0];
}

I64 RandI64()
{//Random I64.
  I64 res=Fs->rand_seed;
  res=LIN_CONGRUE_A*res^(res&0xFFFFFFFF0000)>>16+LIN_CONGRUE_C;
  if (!Bt(&Fs->task_flags,TASKf_NONTIMER_RAND))
    res^=GetTSC;
  Fs->rand_seed=res;
  return res;
}

U64 RandU64()
{//Random U64.
  I64 res=Fs->rand_seed;
  res=LIN_CONGRUE_A*res^(res&0xFFFFFFFF0000)>>16+LIN_CONGRUE_C;
  if (!Bt(&Fs->task_flags,TASKf_NONTIMER_RAND))
    res^=GetTSC;
  Fs->rand_seed=res;
  return res;
}

F64 Rand()
{//Random F64.
  I64 res=Fs->rand_seed;
  res=LIN_CONGRUE_A*res^(res&0xFFFFFFFF0000)>>16+LIN_CONGRUE_C;
  if (!Bt(&Fs->task_flags,TASKf_NONTIMER_RAND))
    res^=GetTSC;
  Fs->rand_seed=res;
  return (res&0x3FFFFFFFFFFFFFFF)/ToF64(0x4000000000000000);
}

I64 Seed(I64 seed=0,CTask *task=NULL)
{//Set $LK,"Rand",A="MN:Rand"$() seed. Zero for timer-based.
  if (!task) task=Fs;
  if (seed) {
    LBts(&task->task_flags,TASKf_NONTIMER_RAND);
    return task->rand_seed=seed;
  } else {
    LBtr(&task->task_flags,TASKf_NONTIMER_RAND);
    return task->rand_seed^=GetTSC;
  }
}
