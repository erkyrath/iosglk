/* GlkMiscLayer.m: Public API for miscellany
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	This file contains the public Glk functions dealing with miscellaneous things that don't fit anywhere else.
	
	(The "layer" files connect the C-linkable API to the ObjC implementation layer. This is therefore an ObjC file that defines C functions in terms of ObjC method calls. Like all the Glk functions, these must be called from the VM thread, not the main thread.)
*/

#import "GlkLibrary.h"
#include "glk.h"

glui32 glk_gestalt(glui32 id, glui32 val)
{
	return glk_gestalt_ext(id, val, NULL, 0);
}

glui32 glk_gestalt_ext(glui32 id, glui32 val, glui32 *arr, glui32 arrlen)
{
	switch (id) {

		case gestalt_Version:
			/* This implements Glk spec version 0.7.1. */
			return 0x00000701;

		//### the rest of them
		
		default:
			return 0;
			
	}
}

/* None of these stylehint methods were ever good for much. We now have better options. */

void glk_stylehint_set(glui32 wintype, glui32 styl, glui32 hint, glsi32 val)
{
}

void glk_stylehint_clear(glui32 wintype, glui32 styl, glui32 hint)
{
}

glui32 glk_style_distinguish(winid_t win, glui32 styl1, glui32 styl2)
{
	return 0;
}

glui32 glk_style_measure(winid_t win, glui32 styl, glui32 hint, glui32 *result)
{
	return 0;
}


