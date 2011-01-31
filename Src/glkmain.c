/*
 *  glkmain.c
 *  IosGlk
 *
 *  Created by Andrew Plotkin on 1/28/11.
 *  Copyright 2011 Andrew Plotkin. All rights reserved.
 *
 */

#include "glk.h"

void glk_main() {
	event_t ev;
	
	while (1) {
		glk_put_string("This is the output of glk_main.\n");
		glk_put_string("This is a very long line, the contents of which will wrap, we hope. Wrap, contents, wrap. Is that enough? Hm.\n");
		glk_put_string("More <em>foo</em> output.\n");
		glk_put_string(" Indent.\n");
		glk_put_string("  Indent.\n");
		glk_put_string("   Indent.\n");
		glk_put_string("    Indent.\n");
		glk_select(&ev);
	}
}

