/* GlkFileRefLayer.m: Public API for file-reference objects
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	This file contains the public Glk functions dealing with file references.
	
	(The "layer" files connect the C-linkable API to the ObjC implementation layer. This is therefore an ObjC file that defines C functions in terms of ObjC method calls. Like all the Glk functions, these must be called from the VM thread, not the main thread.)
	
	### Currently all temporary files go in NSTemporaryDirectory, and everything else goes in ~/Documents. This needs rethinking. I suspect that, if the library is used for multiple games, then save files should go in ~/Documents/Games/$GAME, and all other files should go in ~/Documents/Glk. (Transcripts and data files exist in a common pool between games.) (But maybe transcripts, command records, and data files should be segregated in three different directories?)
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
	NSString *pathname = [tempdir stringByAppendingPathComponent:tempname];

	GlkFileRef *fref = [[GlkFileRef alloc] initWithPath:pathname type:usage rock:rock];
	if (!fref) {
		[GlkLibrary strictWarning:@"fileref_create_temp: unable to create file ref."];
		return NULL;
	}

	return [fref autorelease];
}

frefid_t glk_fileref_create_from_fileref(glui32 usage, frefid_t oldfref, glui32 rock)
{
	if (!oldfref) {
		[GlkLibrary strictWarning:@"fileref_create_from_fileref: invalid ref"];
		return NULL;
	}

	GlkFileRef *fref = [[GlkFileRef alloc] initWithPath:oldfref.pathname type:usage rock:rock];
	if (!fref) {
		[GlkLibrary strictWarning:@"fileref_create_from_fileref: unable to create file ref."];
		return NULL;
	}

	return [fref autorelease];
}

frefid_t glk_fileref_create_by_name(glui32 usage, char *name, glui32 rock)
{
	NSString *filename = [NSString stringWithCString:name encoding:NSISOLatin1StringEncoding];
	
	/* Take out all '/' and '.' characters, and make sure the length is greater than zero. (Taking out dots is not that necessary, but it avoids the edge cases of "." and "..".) */
	filename = [filename stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	filename = [filename stringByReplacingOccurrencesOfString:@"." withString:@"-"];
	if ([filename length] == 0)
		filename = @"X";
		
	/* We use an old-fashioned way of locating the Documents directory. (The NSManager method for this is iOS 4.0 and later.) */
	
	NSArray *dirlist = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if (!dirlist || [dirlist count] == 0) {
		[GlkLibrary strictWarning:@"fileref_create_by name: unable to locate Documents directory."];
		return nil;
	}
	NSString *dir = [dirlist objectAtIndex:0];
	NSString *pathname = [dir stringByAppendingPathComponent:filename];

	GlkFileRef *fref = [[GlkFileRef alloc] initWithPath:pathname type:usage rock:rock];
	if (!fref) {
		[GlkLibrary strictWarning:@"fileref_create_by_name: unable to create file ref."];
		return NULL;
	}

	return [fref autorelease];
}

frefid_t glk_fileref_create_by_prompt(glui32 usage, glui32 fmode, glui32 rock)
{
	GlkLibrary *library = [GlkLibrary singleton];
	GlkAppWrapper *appwrap = [GlkAppWrapper singleton];
	GlkFileRefPrompt *prompt = [[GlkFileRefPrompt alloc] initWithUsage:usage fmode:fmode]; // retained
	
	/* We call selectEvent, which will block and put up the file-selection UI. */
	library.specialrequest = prompt;
	[appwrap selectEvent:nil special:prompt];
	NSString *pathname = [[prompt.pathname retain] autorelease];
	
	library.specialrequest = nil;
	[prompt release];
	
	if (!pathname) {
		/* The file selection was cancelled. */
		return NULL;
	}
	
	GlkFileRef *fref = [[GlkFileRef alloc] initWithPath:pathname type:usage rock:rock];
	if (!fref) {
		[GlkLibrary strictWarning:@"fileref_create_by_prompt: unable to create file ref."];
		return NULL;
	}

	return [fref autorelease];
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

