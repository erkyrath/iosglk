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
	
	glk_request_timer_events(4000);
	while (1) {
		winid_t mainwin = glk_window_open(NULL, 0, 0, wintype_TextBuffer, 111);

		glk_put_string("This is the output of glk_main.\n");
		glk_put_string("This is a very long line, the contents of which will wrap, we hope. Wrap, contents, wrap. Is that enough? Hm.\n");
		glk_put_string("More output 5 < 10.\n");
		glk_put_string(" Indent.\n");
		glk_put_string("  Indent.\n");
		glk_put_string("   Indent.\n");
		glk_put_string("    Indent.\n");

		winid_t statwin = glk_window_open(mainwin, winmethod_Above+winmethod_Fixed, 5, wintype_TextBuffer, 222);
		glk_put_string("Status line!");
		
		glk_select(&ev);
		
		glk_put_string("A turn occurs.\n");
		glk_window_close(mainwin, NULL);
		mainwin = NULL;
		glk_window_close(statwin, NULL);
		statwin = NULL;
		glk_select(&ev);
	}
	
	//glk_window_close(mainwin);
}

