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
		glk_put_string("\nThis is the output of glk_main.\n");
		glk_select(&ev);
	}
}

