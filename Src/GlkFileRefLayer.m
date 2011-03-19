/* GlkFileRefLayer.m: Public API for file-reference objects
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	This file contains the public Glk functions dealing with file references.
	
	(The "layer" files connect the C-linkable API to the ObjC implementation layer. This is therefore an ObjC file that defines C functions in terms of ObjC method calls. Like all the Glk functions, these must be called from the VM thread, not the main thread.)
*/

#import "GlkLibrary.h"
#import "GlkFileRef.h"

void glk_fileref_destroy(frefid_t fref)
{
	if (!fref) {
		[GlkLibrary strictWarning:@"fileref_destroy: invalid ref"];
		return;
	}
	[fref filerefDelete];
}

