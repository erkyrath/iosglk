/* GlkDispatchLayer.m: Public API for the dispatch layer
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	This file contains the public Glk functions dealing with setting up call dispatch.
	
	(The "layer" files connect the C-linkable API to the ObjC implementation layer. This is therefore an ObjC file that defines C functions in terms of ObjC method calls.)
*/

#import "GlkLibrary.h"
#import "GlkWindow.h"
#import "GlkStream.h"
#import "GlkFileRef.h"
#include "glk.h"
#include "gi_dispa.h"

void gidispatch_set_object_registry(
	gidispatch_rock_t (*regi)(void *obj, glui32 objclass),
	void (*unregi)(void *obj, glui32 objclass, gidispatch_rock_t objrock))
{
	GlkLibrary *library = [GlkLibrary singleton];
	
	library.dispatch_register_obj = regi;
	library.dispatch_unregister_obj = unregi;

	winid_t win;
	strid_t str;
	frefid_t fref;

	if (library.dispatch_register_obj) {
		/* It's now necessary to go through all existing objects, and register them. */
		for (win = glk_window_iterate(NULL, NULL);
			win;
			win = glk_window_iterate(win, NULL)) {
			win.disprock = (*library.dispatch_register_obj)(win, gidisp_Class_Window);
		}
		for (str = glk_stream_iterate(NULL, NULL);
			str;
			str = glk_stream_iterate(str, NULL)) {
			str.disprock = (*library.dispatch_register_obj)(str, gidisp_Class_Stream);
		}
		for (fref = glk_fileref_iterate(NULL, NULL);
			fref;
			fref = glk_fileref_iterate(fref, NULL)) {
			fref.disprock = (*library.dispatch_register_obj)(fref, gidisp_Class_Fileref);
		}
	}
}

void gidispatch_set_retained_registry(
	gidispatch_rock_t (*regi)(void *array, glui32 len, char *typecode),
	void (*unregi)(void *array, glui32 len, char *typecode, gidispatch_rock_t objrock))
{
	GlkLibrary *library = [GlkLibrary singleton];
	
	library.dispatch_register_arr = regi;
	library.dispatch_unregister_arr = unregi;
}

gidispatch_rock_t gidispatch_get_objrock(void *obj, glui32 objclass)
{
	switch (objclass) {
		case gidisp_Class_Window: {
			winid_t win = (winid_t)obj;
			return win.disprock;
		}
		case gidisp_Class_Stream: {
			strid_t str = (strid_t)obj;
			return str.disprock;
		}
		case gidisp_Class_Fileref: {
			frefid_t fref = (frefid_t)obj;
			return fref.disprock;
		}
		default: {
			gidispatch_rock_t dummy;
			dummy.num = 0;
			return dummy;
		}
	}
}


