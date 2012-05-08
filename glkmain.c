/* glkmain.c: Sample Glk program
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#include <stdio.h>
#include <string.h>
#include "glk.h"
#include "iosglk_startup.h"

void iosglk_startup_code() {
}

extern void nslogc(char *str);

static winid_t mainwin = NULL;
static winid_t statwin = NULL;
static int movecounter = 1;

static void redraw_statwin(void);

void glk_main() {
	event_t ev;
	char buf[256];
	char inbuf[256];
	
	mainwin = glk_window_open(NULL, 0, 0, wintype_TextBuffer, 111);
	statwin = glk_window_open(mainwin, winmethod_Above+winmethod_Fixed, 1, wintype_TextGrid, 222);
	
	glk_set_window(mainwin);
	glk_put_string("Welcome to...\n");
	glk_set_style(style_Header);
	glk_put_string("The IosGlk Sample App\n");
	glk_set_style(style_Normal);
	glk_put_string("\nThis is not an IF program; it's just a shell which demonstrates some simple window behavior.\n\n");
	glk_put_char('>');
	
	glk_request_line_event(mainwin, inbuf, 128, 0);
	
	while (1) {
		redraw_statwin();
		glk_select(&ev);

		if (ev.type == evtype_LineInput) {
			movecounter++;
			glk_set_window(mainwin);
			glk_put_string("You typed \"");
			glk_put_buffer(inbuf, ev.val1);
			glk_put_string("\".\n");
			inbuf[ev.val1] = '\0';
			if (!strcmp(inbuf, "load") || !strcmp(inbuf, "restore")) {
				glk_put_string("Load at file...\n");
				frefid_t fileref = glk_fileref_create_by_prompt(fileusage_SavedGame|fileusage_BinaryMode, filemode_Read, 123);
				sprintf(buf, "Created fileref %x!\n", (glui32)fileref);
				glk_put_string(buf);
			}
			if (!strcmp(inbuf, "save") || !strcmp(inbuf, "store")) {
				glk_put_string("Save at file...\n");
				frefid_t fileref = glk_fileref_create_by_prompt(fileusage_SavedGame|fileusage_BinaryMode, filemode_Write, 123);
				sprintf(buf, "Created fileref %x!\n", (glui32)fileref);
				glk_put_string(buf);
				if (fileref) {
					strid_t str = glk_stream_open_file(fileref, filemode_Write, 1);
					glk_stream_close(str, NULL);
				}
			}
			if (!strcmp(inbuf, "long")) {
				glk_put_string("This is a long string. Hopefully long enough to get some wrapping action.\n\n");
				glk_put_string("This is another long string. Hopefully long enough to get some wrapping action.\n\n");
				glk_put_string("This is a long string. Hopefully long enough to get some wrapping action.\n\n");
				glk_put_string("This is another long string. Hopefully long enough to get some wrapping action.\n");
			}
			if (!strcmp(inbuf, "exit")) {
				glk_exit(); // does not return
			}
			if (!strcmp(inbuf, "quit")) {
				return;
			}
			if (!strcmp(inbuf, "char")) {
				glk_put_string("Type a char>");
				glk_request_char_event_uni(mainwin);
				continue;
			}
			if (!strcmp(inbuf, "clear")) {
				glk_window_clear(mainwin);
			}
			glk_put_char('>');
			glk_request_line_event(mainwin, inbuf, 128, 0);
			continue;
		}
		
		if (ev.type == evtype_CharInput) {
			glk_set_window(mainwin);
			glk_put_char('\n');
			glk_put_string("You typed '");
			glk_put_char_uni(ev.val1);
			glk_put_string("'.\n");
			glk_put_char('>');
			glk_request_line_event(mainwin, inbuf, 128, 0);
			continue;
		}
		
		if (ev.type == evtype_Timer) {
			glk_cancel_line_event(mainwin, &ev);
			glk_set_window(mainwin);
			glk_put_string("Timer interrupt!\n");
			glk_put_char('>');
			glk_request_line_event(mainwin, inbuf, 128, 0);
			continue;
		}
	}
}

static void redraw_statwin(void) {
	glui32 wid, hgt;
	char buf[256];

	glk_window_get_size(statwin, &wid, &hgt);

	glk_set_window(statwin);
	glk_window_clear(statwin);
	
	sprintf(buf, "Move %d", movecounter);
	glk_window_move_cursor(statwin, 1, 0);
	glk_put_string(buf);
	
	sprintf(buf, "Width %d", wid);
	glk_window_move_cursor(statwin, wid-(strlen(buf)+1), 0);
	glk_put_string(buf);
	
	glk_set_window(mainwin);
}


