/* GlkFileRefLayer.m: Public API for file-reference objects
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	This file contains the public Glk functions dealing with file references.
	
	(The "layer" files connect the C-linkable API to the ObjC implementation layer. This is therefore an ObjC file that defines C functions in terms of ObjC method calls. Like all the Glk functions, these must be called from the VM thread, not the main thread.)
	
	The storage of files is a subtle matter. We do not use file suffixes (although Darwin/iOS is vaguely in favor of them). Instead, the type of a file is distinguished by where it lives. (This wouldn't make sense on a desktop OS, but for iOS, it's fine -- the user will never see this structure.)
	
	All files live in ~/Documents, except for temporary files, which go in NSTemporaryDirectory. That's the "base directory". Whichever the base directory is, the file lives in a subdirectory of it: "GlkData", "GlkInputRecord", "GlkTranscript", or "GlkSavedGame_...".
	
	The last case is special because saved games are namespaced by the game identity -- you can't save in one game and then restore that file into a different game. The game identity is stored as the gameid property on the GlkLibrary. (This distinction is meaningless if your Glk application handles only a single game, of course. But if you're writing an interpreter packaged with many games, you'll want to set gameid to a unique string before starting one of them.)
	
	To make things worse, any filename typed in by the user (at a prompt) gets encoded using the StringToDumbEncoding algorithm. This allows the user to use any character at all, including slashes. The file-selection UI presents both these encoded filenames and "normal" filenames, if it encounters them.
	
	(The encoded form starts with two underscores, which means that a game could generate such a string by hand if it wanted, but really, do we care? Maybe. Not today.)
*/

#import "GlkLibrary.h"
#import "GlkFileRef.h"
#import "GlkAppWrapper.h"
#import "GlkFileTypes.h"

void glk_fileref_destroy(frefid_t fref)
{
	if (!fref) {
		[GlkLibrary strictWarning:@"fileref_destroy: invalid ref"];
		return;
	}
	[fref filerefDelete];
}

frefid_t glk_fileref_create_temp(glui32 usage, glui32 rock)
{
	/* We are going to generate the filename based off the current date and a counter. The counter is just in case this function is called twice in the same clock tick, which I think is impossible, but whatever -- it's cheap. */
	static glui32 temp_file_counter = 0;

	NSDate *date = [NSDate date];
	NSString *tempname = [NSString stringWithFormat:@"_glk_temp_%f-%d", [date timeIntervalSince1970], temp_file_counter++];
	tempname = [tempname stringByReplacingOccurrencesOfString:@"." withString:@"-"];
	NSString *tempdir = NSTemporaryDirectory();

	GlkFileRef *fref = [[GlkFileRef alloc] initWithBase:tempdir filename:tempname type:usage rock:rock];
	if (!fref) {
		[GlkLibrary strictWarning:@"fileref_create_temp: unable to create file ref."];
		return NULL;
	}

	return fref;
}

frefid_t glk_fileref_create_from_fileref(glui32 usage, frefid_t oldfref, glui32 rock)
{
	if (!oldfref) {
		[GlkLibrary strictWarning:@"fileref_create_from_fileref: invalid ref"];
		return NULL;
	}

	GlkFileRef *fref = [[GlkFileRef alloc] initWithBase:oldfref.basedir filename:oldfref.filename type:usage rock:rock];
	if (!fref) {
		[GlkLibrary strictWarning:@"fileref_create_from_fileref: unable to create file ref."];
		return NULL;
	}

	return fref;
}

frefid_t glk_fileref_create_by_name(glui32 usage, char *name, glui32 rock)
{
	NSString *filename = [NSString stringWithCString:name encoding:NSISOLatin1StringEncoding];
	
	/* Take out all '/' and '.' characters, and make sure the length is greater than zero. (Taking out dots is not that necessary, but it avoids the edge cases of "." and "..".) */
	filename = [filename stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	filename = [filename stringByReplacingOccurrencesOfString:@"." withString:@"-"];
	if ([filename length] == 0)
		filename = @"X";
		
	NSString *dir = [GlkFileRef documentsDirectory];
	if (!dir)
		return nil;

	GlkFileRef *fref = [[GlkFileRef alloc] initWithBase:dir filename:filename type:usage rock:rock];
	if (!fref) {
		[GlkLibrary strictWarning:@"fileref_create_by_name: unable to create file ref."];
		return NULL;
	}

	return fref;
}

frefid_t glk_fileref_create_by_prompt(glui32 usage, glui32 fmode, glui32 rock)
{
	GlkLibrary *library = [GlkLibrary singleton];

	NSString *basedir = [GlkFileRef documentsDirectory];
	if (!basedir)
		return nil;
	NSString *dirname = [GlkFileRef subDirOfBase:basedir forUsage:usage gameid:library.gameId];

	GlkAppWrapper *appwrap = [GlkAppWrapper singleton];
	GlkFileRefPrompt *prompt = [[GlkFileRefPrompt alloc] initWithUsage:usage fmode:fmode dirname:dirname]; // retained
	dirname = nil;
	basedir = nil;
	
	/* We call selectEvent, which will block and put up the file-selection UI. Note that the autorelease pool gets wiped, which is why we've retained the prompt object above! */
	library.specialrequest = prompt;
	[appwrap selectEvent:nil special:prompt];
	NSString *filename = prompt.filename;
	NSString *pathnamecheck = prompt.pathname;
	
	library.specialrequest = nil;
	if (!filename) {
		/* The file selection was cancelled. */
		return NULL;
	}
	
	GlkFileRef *fref = [[GlkFileRef alloc] initWithBase:[GlkFileRef documentsDirectory] filename:filename type:usage rock:rock];
	if (!fref) {
		[GlkLibrary strictWarning:@"fileref_create_by_prompt: unable to create file ref."];
		return NULL;
	}
	
	if (![pathnamecheck isEqualToString:fref.pathname])
		NSLog(@"Selected pathname %@ did not match %@!", pathnamecheck, fref.pathname);

	return fref;
}

frefid_t glk_fileref_iterate(frefid_t fref, glui32 *rock) 
{
	GlkLibrary *library = [GlkLibrary singleton];

	if (!fref) {
		if (library.filerefs.count)
			fref = [library.filerefs objectAtIndex:0];
		else
			fref = nil;
	}
	else {
		NSUInteger pos = [library.filerefs indexOfObject:fref];
		if (pos == NSNotFound) {
			fref = nil;
			[GlkLibrary strictWarning:@"glk_fileref_iterate: unknown fileref ref"];
		}
		else {
			pos++;
			if (pos >= library.filerefs.count)
				fref = nil;
			else 
				fref = [library.filerefs objectAtIndex:pos];
		}
	}
	
	if (fref) {
		if (rock)
			*rock = fref.rock;
		return fref;
	}

	if (rock)
		*rock = 0;
	return NULL;
}

glui32 glk_fileref_get_rock(frefid_t fref)
{
	if (!fref) {
		[GlkLibrary strictWarning:@"fileref_get_rock: invalid ref"];
		return 0;
	}

	return fref.rock;
}

glui32 glk_fileref_does_file_exist(frefid_t fref)
{
	if (!fref) {
		[GlkLibrary strictWarning:@"fileref_does_file_exist: invalid ref"];
		return 0;
	}

	BOOL isdir = YES;
	BOOL exists = [fref.library.filemanager fileExistsAtPath:fref.pathname isDirectory:&isdir];

	if (exists && !isdir)
		return 1;
	else
		return 0;
}

void glk_fileref_delete_file(frefid_t fref)
{
	if (!fref) {
		[GlkLibrary strictWarning:@"fileref_delete_file: invalid ref"];
		return;
	}

	BOOL isdir = YES;
	BOOL exists = [fref.library.filemanager fileExistsAtPath:fref.pathname isDirectory:&isdir];
	if (exists && isdir) {
		/* Forget it. The removal function works recursively on directories, and we shouldn't be doing this to a directory anyhow. */
		return;
	}
	
	[fref.library.filemanager removeItemAtPath:fref.pathname error:nil];
}

