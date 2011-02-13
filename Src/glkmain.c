/* glkmain.c: Sample Glk program
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#include "glk.h"

#define NULL (0)
extern void nslogc(char *str);

static glui32 ustring[] = {
	0x48, 0x3B1, 0x141, 0x141, 0x2641, ' ',
	0x30A2, 0x30A3, 0x30A5, '.', 0
};

void glk_main() {
	event_t ev;
	//char buf[256];
	//glui32 ubuf[256];
	
	//glk_request_timer_events(4000);

	winid_t mainwin = glk_window_open(NULL, 0, 0, wintype_TextBuffer, 111);
	glk_set_window(mainwin);

	glk_put_string("This is the output of ");
	glk_set_style(style_Emphasized);
	glk_put_string("glk_main");
	glk_set_style(style_Normal);
	glk_put_string(".\n");
	glk_put_string("This is a very long line, the contents of which will wrap, we hope. Wrap, contents, wrap. Is that enough? Hm.\n");
	glk_put_char('*');
	glk_put_char_uni('*');
	glk_put_char(0xe5);
	glk_put_char_uni(0xe5);
	glk_put_buffer_uni(ustring, 6);
	glk_put_string_uni(ustring);
	glk_put_char('\n');
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
	
	/*
	strid_t bufstr = glk_stream_open_memory(buf, 256, filemode_Write, 321);
	glk_stream_set_current(bufstr);
	glk_put_string("I am a message on the buffer.");
	stream_result_t streamres;
	glui32 streampos = glk_stream_get_position(bufstr);
	glk_stream_close(bufstr, &streamres);
	
	glk_set_window(mainwin);
	glk_put_char('"'); glk_put_buffer(buf, streampos); glk_put_char('"'); glk_put_char('\n');
	sprintf(buf, "### streampos %d, res.read %d, res.written %d\n", streampos, streamres.readcount, streamres.writecount);
	glk_put_string(buf);
	*/

	/*
	strid_t bufstr = glk_stream_open_memory_uni(ubuf, 256, filemode_Write, 321);
	glk_stream_set_current(bufstr);
	glk_put_string_uni(ustring);
	stream_result_t streamres;
	glui32 streampos = glk_stream_get_position(bufstr);
	glk_stream_close(bufstr, &streamres);
	
	glk_set_window(mainwin);
	glk_put_char('"'); glk_put_buffer_uni(ubuf, streampos); glk_put_char('"'); glk_put_char('\n');
	sprintf(buf, "### streampos %d, res.read %d, res.written %d\n", streampos, streamres.readcount, streamres.writecount);
	glk_put_string(buf);
	*/
	
	winid_t statwin = glk_window_open(mainwin, winmethod_Above+winmethod_Fixed, 5, wintype_TextGrid, 222);
	glk_set_window(statwin);
	//glk_set_style(style_Preformatted);
	//glk_window_move_cursor(statwin, 1, 0);
	glk_put_string("Status\n line!");
	glk_window_move_cursor(statwin, 1, 0);
	glk_put_string_uni(ustring);
	glk_window_move_cursor(statwin, 5, 0);
	glk_put_char('-');
	
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
		
	glk_select(&ev);
}

