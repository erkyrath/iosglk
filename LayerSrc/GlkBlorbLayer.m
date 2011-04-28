/* GlkBlorbLayer.m: Public API for Blorb file manipulation
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	This file contains the public Glk functions dealing with Blorb files.
	
	(The "layer" files connect the C-linkable API to the ObjC implementation layer. This is therefore an ObjC file that defines C functions in terms of ObjC method calls.)
*/

#include "glk.h"
#include "gi_blorb.h"

/* This is called from the interpreter setup code. It will eventually allow the library to extract image/sound resources from Blorb files. (Note that it will be faster to pre-extract everything, although we don't have that set up yet.) */

static giblorb_map_t *blorbmap = 0; /* NULL */

giblorb_err_t giblorb_set_resource_map(strid_t file)
{
	giblorb_err_t err;

	err = giblorb_create_map(file, &blorbmap);
	if (err) {
		blorbmap = 0; /* NULL */
		return err;
	}

	return giblorb_err_None;
}

giblorb_map_t *giblorb_get_resource_map()
{
	return blorbmap;
}
