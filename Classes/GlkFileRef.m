/* GlkFileRef.h: File-reference objc class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	GlkFileRef is the class representing a Glk file reference.
	
	The encapsulation isn't very good in this file, because I kept most of the structure of the C Glk implementations -- specifically GlkTerm. The top-level "glk_" functions remained the same, and can be found in GlkFileRefLayer.c. The internal "gli_" functions have become methods on the ObjC GlkFileRef class. So both layers wind up futzing with GlkFileRef internals.
*/

#import "GlkFileRef.h"
#import "GlkLibrary.h"



@implementation GlkFileRef

@synthesize library;
@synthesize tag;
@synthesize pathname;
@synthesize basedir;
@synthesize filename;
@synthesize dirname;
@synthesize filetype;
@synthesize rock;
@synthesize textmode;

/* Work out the directory for a given type of file, based on the base directory, the usage, and the game identity.
	See the comments on GlkFileRefLayer.m for an explanation.
*/
+ (NSString *) subDirOfBase:(NSString *)basedir forUsage:(glui32)usage gameid:(NSString *)gameid {
	NSString *subdir;
	
	switch (usage & fileusage_TypeMask) {
		case fileusage_SavedGame:
			subdir = [NSString stringWithFormat:@"GlkSavedGame_%@", gameid];
			break;
		case fileusage_InputRecord:
			subdir = @"GlkInputRecord";
			break;
		case fileusage_Transcript:
			subdir = @"GlkTranscript";
			break;
		case fileusage_Data:
		default:
			subdir = @"GlkData";
			break;
	}
	
	NSString *dirname = [basedir stringByAppendingPathComponent:subdir];
	return dirname;
}



- (id) initWithBase:(NSString *)basedirval filename:(NSString *)filenameval type:(glui32)usage rock:(glui32)frefrock {
	self = [super init];
	
	if (self) {
		self.library = [GlkLibrary singleton];
		inlibrary = YES;
		
		self.tag = [library newTag];
		rock = frefrock;
		
		textmode = ((usage & fileusage_TextMode) != 0);
		filetype = (usage & fileusage_TypeMask);
		self.filename = filenameval;
		self.basedir = basedirval;
		
		self.dirname = [GlkFileRef subDirOfBase:basedir forUsage:usage gameid:library.gameid];
		self.pathname = [dirname stringByAppendingPathComponent:filename];
		NSLog(@"created fileref with pathname %@", pathname);
		
		[library.filerefs addObject:self];
		
		if (library.dispatch_register_obj)
			disprock = (*library.dispatch_register_obj)(self, gidisp_Class_Fileref);
	}
	
	return self;
}

- (void) dealloc {
	NSLog(@"GlkFileRef dealloc %x", self);
	
	if (inlibrary)
		[NSException raise:@"GlkException" format:@"GlkFileRef reached dealloc while in library"];
	if (!pathname)
		[NSException raise:@"GlkException" format:@"GlkFileRef reached dealloc with pathname unset"];
	self.pathname = nil;
	self.basedir = nil;
	self.dirname = nil;
	self.filename = nil;
	if (!tag)
		[NSException raise:@"GlkException" format:@"GlkFileRef reached dealloc with tag unset"];
	self.tag = nil;
	
	self.library = nil;

	[super dealloc];
}

- (void) filerefDelete {
	/* We don't want this object to evaporate in the middle of this method. */
	[[self retain] autorelease];
	
	if (library.dispatch_unregister_obj)
		(*library.dispatch_unregister_obj)(self, gidisp_Class_Fileref, disprock);
		
	if (![library.filerefs containsObject:self])
		[NSException raise:@"GlkException" format:@"GlkFileRef was not in library filerefs list"];
	[library.filerefs removeObject:self];
	inlibrary = NO;
}


@end
