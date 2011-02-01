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
	//CGRect box;
	
	if (!library.rootwin) {
		if (splitwin) {
			[GlkLibrary strict_warning:@"window_open: ref must be NULL"];
			return nil;
		}
		oldparent = NULL;

		//box = content_box;
	}
	else {
		if (!splitwin) {
			[GlkLibrary strict_warning:@"window_open: ref must not be NULL"];
			return nil;
		}

		val = (method & winmethod_DivisionMask);
		if (val != winmethod_Fixed && val != winmethod_Proportional) {
			[GlkLibrary strict_warning:@"window_open: invalid method (not fixed or proportional)"];
			return nil;
		}

		val = (method & winmethod_DirMask);
		if (val != winmethod_Above && val != winmethod_Below
			&& val != winmethod_Left && val != winmethod_Right) {
			[GlkLibrary strict_warning:@"window_open: invalid method (bad direction)"];
			return nil;
		}

		//box = splitwin->bbox;

		oldparent = splitwin.parent;
		if (oldparent && oldparent.type != wintype_Pair) {
			[GlkLibrary strict_warning:@"window_open: parent window is not Pair"];
			return nil;
		}

	}

	newwin = [GlkWindow windowWithType:wintype rock:rock];
	
	if (!splitwin) {
		library.rootwin = newwin;
		//gli_window_rearrange(newwin, &box);
		/* redraw everything, which is just the new first window */
		//gli_windows_redraw();
	}
	else {
		/* create pairwin, with newwin as the key */
		GlkWindowPair *pairwin;
		pairwin = [[[GlkWindowPair alloc] initWithType:wintype rock:rock method:method keywin:newwin size:size] autorelease];

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
		
		//gli_window_rearrange(pairwin, &box);
		/* redraw the new pairwin and all its contents */
		//gli_window_redraw(pairwin);
	}

	return newwin;
}

void glk_window_close(winid_t win, stream_result_t *result)
{
	if (!win) {
		[GlkLibrary strict_warning:@"window_close: invalid ref"];
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
		//grect_t box;
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
			[GlkLibrary strict_warning:@"window_close: window tree is corrupted"];
			return;
		}

		//box = pairwin->bbox;

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

		/*
		if (keydamage_flag) {
			box = content_box;
			gli_window_rearrange(gli_rootwin, &box);
			gli_windows_redraw();
		}
		else {
			gli_window_rearrange(sibwin, &box);
			gli_window_redraw(sibwin);
		}
		*/
	}
}

