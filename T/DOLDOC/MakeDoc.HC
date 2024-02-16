#exe {Cd("DOLDOC");};;

#help_index "DolDoc"

/*
TempleOS DolDoc's can have "cursor movement" cmds which can move the cursor up
the scrn and layer on existing text.  It can also have callback funs which
supply live, changing text.  For these reasons, you can't assume you know
where the vis portion of the document is and must process much
of the document each time it is placed on the scrn, becoming CPU
intensive on big documents.
See $LK,"::/Doc/DolDocOverview.DD"$
*/

//Hash Types


public class CDolDocGlbls
{
  CHashTable *hash;
  I64	dft_de_flags		[DOCT_TYPES_NUM],
	type_flags_nontag_invis [(DOCT_TYPES_NUM+63)/64],
	type_flags_form		[(DOCT_TYPES_NUM+63)/64],
	type_flags_data		[(DOCT_TYPES_NUM+63)/64],
	type_flags_chk_dup	[(DOCT_TYPES_NUM+63)/64],
	clean_scan_codes	[4];
  I32	dft_type_flags		[DOCT_TYPES_NUM];
} doldoc;
MemSet(&doldoc,0,sizeof(CDolDocGlbls));

#help_index "God"


#include "DocExt.HC"
#include "DocBin.HC"
#include "DocNew.HC"
#include "DocForm.HC"
#include "DocDblBuf.HC"
#include "DocPlain.HC"
#include "DocInit.HC"
#include "DocHighlight.HC"
#include "DocRecalcLib.HC"
#include "DocRecalc.HC"
#include "DocFile.HC"
#include "DocClipBoard.HC"
#include "DocRun.HC"
#include "DocGet.HC"
#include "DocChar.HC"
#include "DocFind.HC"
#include "DocLink.HC"
#include "DocEd.HC"
#include "DocPopUp.HC"
#include "DocGr.HC"
#//include "DocMacro.HC"
#include "DocWidgetWiz.HC"
#include "DocPutKey.HC"
#include "DocPutS.HC"
#include "DocCodeTools.HC"
#include "DocTree.HC"
#include "DocTerm.HC"

I64 __GetStr2(I64 flags=0) {
	return __GetStr;
}
if(!__IsCmdLine)
	fp_getstr2=&DocGetStr2;
else
	fp_getstr2=&__GetStr2;
fp_doc_put=&DocPut;

#exe {Cd("..");};;
