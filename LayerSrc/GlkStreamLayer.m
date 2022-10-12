/* GlkStreamLayer.m: Public API for stream objects
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	This file contains the public Glk functions dealing with streams and string-printing.
	
	(The "layer" files connect the C-linkable API to the ObjC implementation layer. This is therefore an ObjC file that defines C functions in terms of ObjC method calls. Like all the Glk functions, these must be called from the VM thread, not the main thread.)
*/

#import "GlkLibrary.h"
#import "GlkWindow.h"
#import "GlkStream.h"

strid_t glk_stream_open_memory(char *buf, glui32 buflen, glui32 fmode,
	glui32 rock)
{
	if (fmode != filemode_Read
		&& fmode != filemode_Write
		&& fmode != filemode_ReadWrite) {
		[GlkLibrary strictWarning:@"stream_open_memory: illegal filemode"];
		return NULL;
	}

	strid_t str = [[GlkStreamMemory alloc] initWithMode:fmode rock:rock buf:buf len:buflen];
	return str;
}

strid_t glk_stream_open_memory_uni(glui32 *buf, glui32 buflen, glui32 fmode,
	glui32 rock)
{
	if (fmode != filemode_Read
		&& fmode != filemode_Write
		&& fmode != filemode_ReadWrite) {
		[GlkLibrary strictWarning:@"stream_open_memory_uni: illegal filemode"];
		return NULL;
	}

	strid_t str = [[GlkStreamMemory alloc] initUniWithMode:fmode rock:rock buf:buf len:buflen];
	return str;
}

strid_t glk_stream_open_file(frefid_t fref, glui32 fmode, glui32 rock)
{
	if (!fref) {
		[GlkLibrary strictWarning:@"stream_open_file: invalid ref"];
		return NULL;
	}
	
	strid_t str = [[GlkStreamFile alloc] initWithMode:fmode rock:rock unicode:NO fileref:fref];
	if (!str)
		return NULL;
	return str;
}

strid_t glk_stream_open_file_uni(frefid_t fref, glui32 fmode, glui32 rock)
{
	if (!fref) {
		[GlkLibrary strictWarning:@"stream_open_file_uni: invalid ref"];
		return NULL;
	}
	
	strid_t str = [[GlkStreamFile alloc] initWithMode:fmode rock:rock unicode:YES fileref:fref];
	if (!str)
		return NULL;
	return str;
}

void glk_stream_close(strid_t str, stream_result_t *result)
{
	if (!str) {
		[GlkLibrary strictWarning:@"stream_close: invalid ref"];
		return;
	}

	if (str.type == strtype_Window) {
		[GlkLibrary strictWarning:@"stream_close: cannot close window stream"];
		return;
	}

	[str fillResult:result];
	[str streamDelete];
}

strid_t glk_stream_iterate(strid_t str, glui32 *rock) 
{
	GlkLibrary *library = [GlkLibrary singleton];

	if (!str) {
		if (library.streams.count)
			str = [library.streams objectAtIndex:0];
		else
			str = nil;
	}
	else {
		NSUInteger pos = [library.streams indexOfObject:str];
		if (pos == NSNotFound) {
			str = nil;
			[GlkLibrary strictWarning:@"glk_stream_iterate: unknown stream ref"];
		}
		else {
			pos++;
			if (pos >= library.streams.count)
				str = nil;
			else 
				str = [library.streams objectAtIndex:pos];
		}
	}
	
	if (str) {
		if (rock)
			*rock = str.rock;
		return str;
	}

	if (rock)
		*rock = 0;
	return NULL;
}

glui32 glk_stream_get_rock(strid_t str)
{
	if (!str) {
		[GlkLibrary strictWarning:@"stream_get_rock: invalid ref"];
		return 0;
	}

	return str.rock;
}


void glk_stream_set_current(strid_t str)
{
	GlkLibrary *library = [GlkLibrary singleton];
	library.currentstr = str;
}

strid_t glk_stream_get_current()
{
	GlkLibrary *library = [GlkLibrary singleton];
	return library.currentstr;
}

void glk_stream_set_position(strid_t str, glsi32 pos, glui32 seekmode)
{
	if (!str) {
		[GlkLibrary strictWarning:@"stream_set_position: invalid ref"];
		return;
	}
	
	[str setPosition:pos seekmode:seekmode];
}

glui32 glk_stream_get_position(strid_t str)
{
	if (!str) {
		[GlkLibrary strictWarning:@"stream_get_position: invalid ref"];
		return 0;
	}
	
	return [str getPosition];
}

void glk_put_char(unsigned char ch)
{
	GlkLibrary *library = [GlkLibrary singleton];
	[library.currentstr putChar:ch];
}

void glk_put_char_stream(strid_t str, unsigned char ch)
{
	[str putChar:ch];
}

void glk_put_char_uni(glui32 ch)
{
	GlkLibrary *library = [GlkLibrary singleton];
	[library.currentstr putUChar:ch];
}

void glk_put_char_stream_uni(strid_t str, glui32 ch)
{
	[str putUChar:ch];
}

void glk_put_string(char *s)
{
	GlkLibrary *library = [GlkLibrary singleton];
	[library.currentstr putCString:s];
}

void glk_put_string_stream(strid_t str, char *s)
{
	[str putCString:s];
}

void glk_put_string_uni(glui32 *us)
{
	GlkLibrary *library = [GlkLibrary singleton];
	[library.currentstr putUString:us];
}

void glk_put_string_stream_uni(strid_t str, glui32 *us)
{
	[str putUString:us];
}

void glk_put_buffer(char *buf, glui32 len)
{
	GlkLibrary *library = [GlkLibrary singleton];
	[library.currentstr putBuffer:buf len:len];
}

void glk_put_buffer_stream(strid_t str, char *buf, glui32 len)
{
	[str putBuffer:buf len:len];
}

void glk_put_buffer_uni(glui32 *ubuf, glui32 len)
{
	GlkLibrary *library = [GlkLibrary singleton];
	[library.currentstr putUBuffer:ubuf len:len];
}

void glk_put_buffer_stream_uni(strid_t str, glui32 *ubuf, glui32 len)
{
	[str putUBuffer:ubuf len:len];
}

void glk_set_style(glui32 val)
{
	/* Very important to keep the style number between 0 and NUMSTYLES. The library code relies on this. */
	if (val >= style_NUMSTYLES)
		val = 0;
		
	GlkLibrary *library = [GlkLibrary singleton];
	[library.currentstr setStyle:val];
}

void glk_set_style_stream(strid_t str, glui32 val)
{
	/* Very important to keep the style number between 0 and NUMSTYLES. The library code relies on this. */
	if (val >= style_NUMSTYLES)
		val = 0;
		
	[str setStyle:val];
}

glsi32 glk_get_char_stream(strid_t str)
{
	if (!str) {
		[GlkLibrary strictWarning:@"get_char_stream: invalid ref"];
		return -1;
	}
	
	return [str getChar:NO];
}

glui32 glk_get_line_stream(strid_t str, char *buf, glui32 len)
{
	if (!str) {
		[GlkLibrary strictWarning:@"get_line_stream: invalid ref"];
		return 0;
	}
	
	return [str getLine:buf buflen:len unicode:NO];
}

glui32 glk_get_buffer_stream(strid_t str, char *buf, glui32 len)
{
	if (!str) {
		[GlkLibrary strictWarning:@"get_buffer_stream: invalid ref"];
		return 0;
	}

	return [str getBuffer:buf buflen:len unicode:NO];
}

glsi32 glk_get_char_stream_uni(strid_t str)
{
	if (!str) {
		[GlkLibrary strictWarning:@"get_char_stream: invalid ref"];
		return -1;
	}
	
	return [str getChar:YES];
}

glui32 glk_get_line_stream_uni(strid_t str, glui32 *buf, glui32 len)
{
	if (!str) {
		[GlkLibrary strictWarning:@"get_line_stream: invalid ref"];
		return 0;
	}
	
	return [str getLine:buf buflen:len unicode:YES];
}

glui32 glk_get_buffer_stream_uni(strid_t str, glui32 *buf, glui32 len)
{
	if (!str) {
		[GlkLibrary strictWarning:@"get_buffer_stream: invalid ref"];
		return 0;
	}

	return [str getBuffer:buf buflen:len unicode:YES];
}


