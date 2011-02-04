/*
 *  glkmain.c
 *  IosGlk
 *
 *  Created by Andrew Plotkin on 1/28/11.
 *  Copyright 2011 Andrew Plotkin. All rights reserved.
 *
 */

#include "glk.h"

#define NULL (0)

void glk_main() {
	event_t ev;
	char buf[256];
	
	//glk_request_timer_events(4000);

	winid_t mainwin = glk_window_open(NULL, 0, 0, wintype_TextBuffer, 111);

	glk_put_string("This is the output of glk_main.\n");
	glk_put_string("This is a very long line, the contents of which will wrap, we hope. Wrap, contents, wrap. Is that enough? Hm.\n");
	glk_put_string("More output 5 < 10.\n");
	glk_put_string(" Indent.\n");
	glk_put_string("  Indent.\n");
	glk_put_string("   Indent.\n");
	glk_put_string("    Indent.\n");

	winid_t statwin = glk_window_open(mainwin, winmethod_Above+winmethod_Fixed, 5, wintype_TextBuffer, 222);
	glk_put_string("Status line!\n");
	
	/*
	winid_t wx = NULL;
	while (1) {
		glui32 rock = 1;
		wx = glk_window_iterate(wx, &rock);
		if (!wx)
			break;
		sprintf(buf, "Window %x has type %d, rock %d, sibling %x\n", (glui32)wx, glk_window_get_type(wx), rock, glk_window_get_sibling(wx));
		glk_put_string(buf);
	}
	*/
		
	glk_select(&ev);
}

