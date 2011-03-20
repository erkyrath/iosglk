/* glkmain.c: Sample Glk program
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#include <stdio.h>
#include "glk.h"

extern void nslogc(char *str);

static glui32 ustring[] = {
	0x48, 0x3B1, 0x141, 0x141, 0x2641, ' ',
	0x30A2, 0x30A3, 0x30A5, '.', 0
};

void glk_main() {
	event_t ev;
	char buf[256];
	char inbuf[256];
	//glui32 uinbuf[256];
	
	winid_t mainwin = glk_window_open(NULL, 0, 0, wintype_TextBuffer, 111);
	glk_set_window(mainwin);

	glk_put_string("This is the output of ");
	glk_set_style(style_Emphasized);
	glk_put_string("glk_main");
	glk_set_style(style_Normal);
	glk_put_string(".\n");
	glk_put_string("  This (*) is a very long line--the contents of which will wrap, we hope. Wrap, contents, wrap. Is that enough? Hm.\n");
	/*
	glk_put_char('*');
	glk_put_char_uni('*');
	glk_put_char(0xe5);
	glk_put_char_uni(0xe5);
	glk_put_buffer_uni(ustring, 6);
	glk_put_string_uni(ustring);
	glk_put_char('\n');
	*/
	//glk_put_string("\nFoo: More-long-line-stuff-and-even-more");
	//glk_set_style(style_Emphasized);
	//glk_put_string("-foo");
	//glk_set_style(style_Normal);
	//glk_put_string("-and-even-more-1-and-even-more-and-even-more-2-and-even-more-and-even-more-3-and-even-more-and-even-more-4.\n");
	/*
	glk_put_string(" Indent.\n");
	glk_put_string("  ");
	glk_set_style(style_Emphasized);
	glk_put_string("Indent.");
	glk_set_style(style_Normal);
	glk_put_string("\n");
	glk_put_string("   ");
	glk_set_style(style_Subheader);
	glk_put_string("Indent.");
	glk_set_style(style_Normal);
	glk_put_string("\n");
	glk_put_string("    Indent.\n");
	*/
		
	//glk_select(&ev);
	
	winid_t statwin = glk_window_open(mainwin, winmethod_Above+winmethod_Fixed, 2, wintype_TextGrid, 222);
	glk_set_window(statwin);
	//glk_set_style(style_Preformatted);
	//glk_window_move_cursor(statwin, 1, 0);
	glk_put_string("Status\n line!");
	glk_window_move_cursor(statwin, 1, 0);
	glk_put_string_uni(ustring);
	glk_window_move_cursor(statwin, 5, 0);
	glk_put_char('-');
	
	glk_set_window(mainwin);
	/*
	strid_t sx = NULL;
	while (1) {
		glui32 rock = 1;
		sx = glk_stream_iterate(sx, &rock);
		if (!sx)
			break;
		sprintf(buf, "Stream %x has rock %d, position %d\n", (glui32)sx, rock, glk_stream_get_position(sx));
		glk_put_string(buf);
	}
	*/

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
	
	/*
	frefid_t fx = NULL;
	while (1) {
		glui32 rock = 1;
		fx = glk_fileref_iterate(fx, &rock);
		if (!fx)
			break;
		sprintf(buf, "Fileref %x has rock %d\n", (glui32)fx, rock);
		glk_put_string(buf);
	}
	*/

	glk_set_window(mainwin);
	glk_put_char('>');
		
	//glk_request_timer_events(2000);
	//glk_request_line_event(mainwin, inbuf, 32, 0);
	//glk_request_char_event_uni(mainwin);
	
	while (1) {
		glk_select(&ev);
		if (ev.type == 99) {
			if (ev.val1 < 240) {
				glk_set_window(mainwin);
				glk_put_string("INPUT\nResponse.\nDaemon.\n");
				glk_put_char('>');
			}
			else {
				/*
				glk_cancel_line_event(mainwin, &ev);
				glk_set_window(mainwin);
				glk_put_string("You were typing \"");
				glk_put_buffer(inbuf, ev.val1);
				glk_put_string("\".\n");
				*/
				//sleep(3);
				glk_select_poll(&ev);
				glk_set_window(statwin);
				glk_window_move_cursor(statwin, 0, 0);
				glk_put_string("Polled event type ");
				glk_put_char(ev.type + '0');
				//nslogc("Requesting line input...");
				//glk_request_line_event(mainwin, inbuf, 32, 0);
				//glk_request_line_event(statwin, inbuf, 32, 0);
			}
			continue;
		}
		
		/*
		glk_set_window(mainwin);
		glk_put_string("Line.\n");
		*/

		if (ev.type == evtype_LineInput) {
			glk_set_window(mainwin);
			glk_put_string("You typed \"");
			glk_put_buffer(inbuf, ev.val1);
			//glk_put_buffer_uni(uinbuf, ev.val1);
			glk_put_string("\".\n");
			glk_put_char('>');
			glk_request_line_event(mainwin, inbuf, 32, 0);
			//glk_request_line_event_uni(mainwin, uinbuf, 32, 0);
			continue;
		}
		
		if (ev.type == evtype_CharInput) {
			glk_set_window(mainwin);
			glk_put_string("You typed '");
			glk_put_char_uni(ev.val1);
			glk_put_string("'.\n");
			glk_put_char('>');
			glk_request_char_event_uni(mainwin);
			//glk_request_line_event_uni(mainwin, uinbuf, 32, 0);
			continue;
		}
		
		if (ev.type == evtype_Timer) {
			glk_cancel_line_event(mainwin, &ev);
			glk_set_window(mainwin);
			glk_put_string("Timer interrupt!\n");
			glk_put_char('>');
			inbuf[0] = 'x'; inbuf[1] = 'y'; inbuf[2] = 'z';
			glk_request_line_event(mainwin, inbuf, 32, 3);
			continue;
		}
		
		if (ev.type == evtype_Arrange) {
			glk_set_window(statwin);
			glk_window_move_cursor(statwin, 3, 1);
			static int counter = 0;
			glui32 xval, yval;
			glk_window_get_size(statwin, &xval, &yval);
			sprintf(buf, "%d: %dx%d", ++counter, xval, yval);
			glk_set_style(style_Subheader);
			glk_put_string(buf);
			continue;
		}
	}
}

