//
//  GlkStreamLayer.m
//  IosGlk
//
//  Created by Andrew Plotkin on 2/3/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import "GlkLibrary.h"
#import "GlkWindow.h"
#import "GlkStream.h"

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

void glk_put_string(char *str) {
	//[win putCString:str]; //###
}

void glk_set_style(glui32 styl) {
	//win.style = styl; //###
}

