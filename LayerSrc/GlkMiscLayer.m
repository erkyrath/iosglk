/* GlkMiscLayer.m: Public API for miscellany
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	This file contains the public Glk functions dealing with miscellaneous things that don't fit anywhere else.
	
	(The "layer" files connect the C-linkable API to the ObjC implementation layer. This is therefore an ObjC file that defines C functions in terms of ObjC method calls. Like all the Glk functions, these must be called from the VM thread, not the main thread.)
*/

#import "GlkLibrary.h"
#import "GlkAppWrapper.h"
#include "glk.h"

void glk_exit()
{
	/* This does not exit the process -- that would be totally un-iPhone-y. Instead, we call selectEvent in a way that will never return. */
	GlkLibrary *library = [GlkLibrary singleton];
	library.vmexited = YES;
	
	GlkAppWrapper *appwrap = [GlkAppWrapper singleton];
	library.specialrequest = [NSNull null];
	[appwrap selectEvent:nil special:library.specialrequest];
}

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

		case gestalt_CharInput:
			/* This is not a terrific approximation. Return false for function
			   keys, control keys, and the high-bit non-printables. For
			   everything else in the Unicode range, return true. */
			if (val <= keycode_Left && val >= keycode_End)
				return 1;
			if (val >= 0x100000000-keycode_MAXVAL)
				return 0;
			if (val > 0x10FFFF)
				return 0;
			if ((val >= 0 && val < 32) || (val >= 127 && val < 160))
				return 0;
			return 1;

		case gestalt_LineInput:
			/* Same as the above, except no special keys. */
			if (val > 0x10FFFF)
				return 0;
			if ((val >= 0 && val < 32) || (val >= 127 && val < 160))
				return 0;
			return 1;

		case gestalt_CharOutput:
			/* Same thing again. We assume that all printable characters,
			   as well as the placeholders for nonprintables, are one character
			   wide. */
			if ((val > 0x10FFFF)
				|| (val >= 0 && val < 32)
				|| (val >= 127 && val < 160)) {
				if (arr)
					arr[0] = 1;
				return gestalt_CharOutput_CannotPrint;
			}
			if (arr)
				arr[0] = 1;
			return gestalt_CharOutput_ExactPrint;

		case gestalt_MouseInput:
			return 0;

		case gestalt_Timer:
			return 1;

		case gestalt_Graphics:
			return 0;

		case gestalt_DrawImage:
			return 0;

		case gestalt_Sound:
			return 0;

		case gestalt_SoundVolume:
			return 0;

		case gestalt_SoundNotify:
			return 0;

		case gestalt_Hyperlinks:
			return 0;
		
		case gestalt_HyperlinkInput:
			return 0;

		case gestalt_SoundMusic:
			return 0;

		case gestalt_GraphicsTransparency:
			return 0;

		case gestalt_Unicode:
			return 1;

		case gestalt_UnicodeNorm:
			return 1;

		case gestalt_LineInputEcho:
			return 1;

		case gestalt_LineTerminators:
			return 1;

		case gestalt_LineTerminatorKey:
			return 0;

		//case gestalt_DateTime:
		//	return 0;

		default:
			return 0;
			
	}
}

void glk_tick() {
	//### Maybe this should drain the VM thread's NSAutoreleasePool, every N cycles?
}

/* I'm not sure what this should mean on iOS, but I'm not sure anybody's ever used it, so never mind.
*/
void glk_set_interrupt_handler(void (*func)(void)) {
}

/* None of these stylehint methods were ever good for much. We now have better options in mind. */

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


