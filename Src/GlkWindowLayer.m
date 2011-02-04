//
//  GlkWindowLayer.m
//  IosGlk
//
//  Created by Andrew Plotkin on 1/31/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import "GlkLibrary.h"
#import "GlkWindow.h"
#import "GlkStream.h"

winid_t glk_window_open(winid_t splitwin, glui32 method, glui32 size, glui32 wintype, glui32 rock) 
{
	GlkLibrary *library = [GlkLibrary singleton];
	GlkWindow *newwin;
	GlkWindowPair *oldparent;
	glui32 val;
	CGRect box;
	
	if (!library.rootwin) {
		if (splitwin) {
			[GlkLibrary strictWarning:@"window_open: ref must be NULL"];
			return nil;
		}
		oldparent = NULL;

		box = library.bounds;
	}
	else {
		if (!splitwin) {
			[GlkLibrary strictWarning:@"window_open: ref must not be NULL"];
			return nil;
		}

		val = (method & winmethod_DivisionMask);
		if (val != winmethod_Fixed && val != winmethod_Proportional) {
			[GlkLibrary strictWarning:@"window_open: invalid method (not fixed or proportional)"];
			return nil;
		}

		val = (method & winmethod_DirMask);
		if (val != winmethod_Above && val != winmethod_Below
			&& val != winmethod_Left && val != winmethod_Right) {
			[GlkLibrary strictWarning:@"window_open: invalid method (bad direction)"];
			return nil;
		}

		box = splitwin.bbox;

		oldparent = splitwin.parent;
		if (oldparent && oldparent.type != wintype_Pair) {
			[GlkLibrary strictWarning:@"window_open: parent window is not Pair"];
			return nil;
		}

	}

	newwin = [GlkWindow windowWithType:wintype rock:rock];
	
	if (!splitwin) {
		library.rootwin = newwin;
		[newwin windowRearrange:box];
		/* redraw everything, which is just the new first window */
		//gli_windows_redraw();
	}
	else {
		/* create pairwin, with newwin as the key */
		GlkWindowPair *pairwin;
		pairwin = [[[GlkWindowPair alloc] initWithMethod:method keywin:newwin size:size] autorelease];

		pairwin.child1 = splitwin;
		pairwin.child2 = newwin;

		splitwin.parent = pairwin;
		newwin.parent = pairwin;
		pairwin.parent = oldparent;

		if (oldparent) {
			GlkWindowPair *parentwin = (GlkWindowPair *)oldparent;
			if (parentwin.child1 == splitwin)
				parentwin.child1 = pairwin;
			else
				parentwin.child2 = pairwin;
		}
		else {
			library.rootwin = pairwin;
		}
		
		[pairwin windowRearrange:box];
		/* redraw the new pairwin and all its contents */
		//gli_window_redraw(pairwin);
	}

	return newwin;
}

void glk_window_close(winid_t win, stream_result_t *result)
{
	if (!win) {
		[GlkLibrary strictWarning:@"window_close: invalid ref"];
		return;
	}
	
	GlkLibrary *library = win.library;

	if (win == library.rootwin || win.parent == nil) {
		/* close the root window, which means all windows. */

		library.rootwin = nil;

		/* begin (simpler) closation */

		[win.stream fillResult:result];
		[win windowCloseRecurse:YES];
		/* redraw everything */
		//gli_windows_redraw();
	}
	else {
		/* have to jigger parent */
		GlkWindow *sibwin;
		GlkWindowPair *pairwin, *grandparwin;

		pairwin = win.parent;
		if (win == pairwin.child1) {
			sibwin = pairwin.child2;
		}
		else if (win == pairwin.child2) {
			sibwin = pairwin.child1;
		}
		else {
			[GlkLibrary strictWarning:@"window_close: window tree is corrupted"];
			return;
		}

		CGRect box = pairwin.bbox;

		grandparwin = pairwin.parent;
		if (!grandparwin) {
			library.rootwin = sibwin;
			sibwin.parent = nil;
		}
		else {
			if (grandparwin.child1 == pairwin)
				grandparwin.child1 = sibwin;
			else
				grandparwin.child2 = sibwin;
			sibwin.parent = grandparwin;
		}

		/* Begin closation */

		[win.stream fillResult:result];

		/* Close the child window (and descendants), so that key-deletion can
			crawl up the tree to the root window. */
		[win windowCloseRecurse:YES];

		/* This probably isn't necessary, but the child *is* gone, so just
			in case. */
		if (win == pairwin.child1) {
			pairwin.child1 = nil;
		}
		else if (win == pairwin.child2) {
			pairwin.child2 = nil;
		}

		/* Now we can delete the parent pair. */
		[pairwin windowCloseRecurse:NO];

		BOOL keydamage_flag = NO;
		for (GlkWindow *wx=sibwin; wx; wx=wx.parent) {
			if (wx.type == wintype_Pair) {
				GlkWindowPair *dwx = (GlkWindowPair *)wx;
				if (dwx.keydamage) {
					keydamage_flag = YES;
					dwx.keydamage = NO;
				}
			}
		}

		if (keydamage_flag) {
			box = library.bounds;
			[library.rootwin windowRearrange:box];
			//gli_windows_redraw();
		}
		else {
			[sibwin windowRearrange:box];
			//gli_window_redraw(sibwin);
		}
	}
}

void glk_window_get_arrangement(winid_t win, glui32 *method, glui32 *size, winid_t *keywin)
{
	GlkWindowPair *dwin;
	glui32 val;

	if (!win) {
		[GlkLibrary strictWarning:@"window_get_arrangement: invalid ref"];
		return;
	}

	if (win.type != wintype_Pair) {
		[GlkLibrary strictWarning:@"window_get_arrangement: not a Pair window"];
		return;
	}

	dwin = (GlkWindowPair *)dwin;

	val = dwin.dir | dwin.division;
	if (!dwin.hasborder)
		val |= winmethod_NoBorder;

	if (size)
		*size = dwin.size;
	if (keywin) {
		if (dwin.key)
			*keywin = dwin.key;
		else
			*keywin = nil;
	}
	if (method)
		*method = val;
}

void glk_window_set_arrangement(winid_t win, glui32 method, glui32 size, winid_t keywin) 
{
	//###
}

winid_t glk_window_iterate(winid_t win, glui32 *rock) 
{
	GlkLibrary *library = [GlkLibrary singleton];

	if (!win) {
		if (library.windows.count)
			win = [library.windows objectAtIndex:0];
		else
			win = nil;
	}
	else {
		NSUInteger pos = [library.windows indexOfObject:win];
		if (pos == NSNotFound) {
			win = nil;
			[GlkLibrary strictWarning:@"glk_window_iterate: unknown window ref"];
		}
		else {
			pos++;
			if (pos >= library.windows.count)
				win = nil;
			else 
				win = [library.windows objectAtIndex:pos];
		}
	}
	
	if (win) {
		if (rock)
			*rock = win.rock;
		return win;
	}

	if (rock)
		*rock = 0;
	return NULL;
}


glui32 glk_window_get_rock(winid_t win)
{
	if (!win) {
		[GlkLibrary strictWarning:@"window_get_rock: invalid ref"];
		return 0;
	}

	return win.rock;
}

winid_t glk_window_get_root()
{
	GlkLibrary *library = [GlkLibrary singleton];
	return library.rootwin;
}

winid_t glk_window_get_parent(winid_t win)
{
	if (!win) {
		[GlkLibrary strictWarning:@"window_get_parent: invalid ref"];
		return nil;
	}
	
	return win.parent;
}

winid_t glk_window_get_sibling(winid_t win)
{
	GlkWindowPair *parwin;

	if (!win) {
		[GlkLibrary strictWarning:@"window_get_sibling: invalid ref"];
		return nil;
	}
	
	parwin = win.parent;
	if (!parwin)
		return nil;

	if (parwin.child1 == win)
		return parwin.child2;
	if (parwin.child2 == win)
		return parwin.child1;
	return nil;
}

glui32 glk_window_get_type(winid_t win)
{
	if (!win) {
		[GlkLibrary strictWarning:@"window_get_type: invalid ref"];
		return 0;
	}
	
	return win.type;
}

strid_t glk_window_get_stream(winid_t win)
{
	if (!win) {
		[GlkLibrary strictWarning:@"window_get_stream: invalid ref"];
		return nil;
	}

	return win.stream;
}

strid_t glk_window_get_echo_stream(winid_t win)
{
	if (!win) {
		[GlkLibrary strictWarning:@"window_get_echo_stream: invalid ref"];
		return nil;
	}

	return win.echostream;
}

void glk_window_set_echo_stream(winid_t win, strid_t str)
{
	if (!win) {
		[GlkLibrary strictWarning:@"window_set_echo_stream: invalid ref"];
		return;
	}

	win.echostream = str;
}

void glk_set_window(winid_t win)
{
	GlkLibrary *library = [GlkLibrary singleton];
	if (!win) {
		library.currentstr = nil;
	}
	else {
		library.currentstr = win.stream;
	}
}


