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
@synthesize disprock;
@synthesize pathname;
@synthesize basedir;
@synthesize filename;
@synthesize dirname;
@synthesize filetype;
@synthesize rock;
@synthesize textmode;

/* Find the user's Documents directory. 
 */
+ (NSString *) documentsDirectory {
	/* We use an old-fashioned way of locating the Documents directory. (The NSFileManager method for this is iOS 4.0 and later.) */
	
	NSArray *dirlist = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if (!dirlist || [dirlist count] == 0) {
		[GlkLibrary strictWarning:@"unable to locate Documents directory."];
		return nil;
	}
	return [dirlist objectAtIndex:0];
}

/* Convert paths in the bundle or Documents directory to use the token $APP or $DOC instead of the literal pathname. This is necessary for serialization. (I think in iOS8 these directories are randomized on every run.)
 */
+ (NSString *) relativizePath:(NSString *)path
{
	NSString *prefix;
	
	prefix = [NSBundle mainBundle].bundlePath;
	if ([path hasPrefix:prefix]) {
		NSRange range = NSMakeRange(0, prefix.length);
		NSString *res = [path stringByReplacingCharactersInRange:range withString:@"$APP"];
		//NSLog(@"relativizePath: converted %@ to %@", path, res);
		return res;
	}
	prefix = [GlkFileRef documentsDirectory];
	if ([path hasPrefix:prefix]) {
		NSRange range = NSMakeRange(0, prefix.length);
		NSString *res = [path stringByReplacingCharactersInRange:range withString:@"$DOC"];
		//NSLog(@"relativizePath: converted %@ to %@", path, res);
		return res;
	}
	NSLog(@"relativizePath: warning: unable to deal with path: %@", path);
	return path;
}

/* Convert $APP or $DOC paths to real paths. Used in deserialization. 
 */
+ (NSString *) unrelativizePath:(NSString *)path
{
	NSString *res = nil;
	if ([path hasPrefix:@"$APP"]) {
		NSRange range = NSMakeRange(0, 4);
		res = [path stringByReplacingCharactersInRange:range withString:[NSBundle mainBundle].bundlePath];
	}
	else if ([path hasPrefix:@"$DOC"]) {
		NSRange range = NSMakeRange(0, 4);
		res = [path stringByReplacingCharactersInRange:range withString:[GlkFileRef documentsDirectory]];
	}
	else {
		NSLog(@"unrelativizePath: warning: got absolute path: %@", path);
		res = path;
	}
	//NSLog(@"unrelativizePath: converted %@ to %@", path, res);
	return res;
}

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
		
		self.tag = [library generateTag];
		rock = frefrock;
		
		textmode = ((usage & fileusage_TextMode) != 0);
		filetype = (usage & fileusage_TypeMask);
		self.filename = filenameval;
		self.basedir = basedirval;
		
		self.dirname = [GlkFileRef subDirOfBase:basedir forUsage:usage gameid:library.gameId];
		self.pathname = [dirname stringByAppendingPathComponent:filename];
		//NSLog(@"created fileref with pathname %@", pathname);
		
		[library.filerefs addObject:self];
		
		if (library.dispatch_register_obj)
			disprock = (*library.dispatch_register_obj)(self, gidisp_Class_Fileref);
	}
	
	return self;
}

- (id) initWithCoder:(NSCoder *)decoder {
	self.tag = [decoder decodeObjectForKey:@"tag"];
	inlibrary = YES;
	// self.library will be set later

	rock = [decoder decodeInt32ForKey:@"rock"];
	// disprock is handled by the app
	
	self.filename = [decoder decodeObjectForKey:@"filename"];
	self.basedir = [GlkFileRef unrelativizePath:[decoder decodeObjectForKey:@"basedir"]];
	self.dirname = [GlkFileRef unrelativizePath:[decoder decodeObjectForKey:@"dirname"]];
	self.pathname = [GlkFileRef unrelativizePath:[decoder decodeObjectForKey:@"pathname"]];
	filetype = [decoder decodeInt32ForKey:@"filetype"];
	textmode = [decoder decodeBoolForKey:@"textmode"];
	
	return self;
}

- (void) dealloc {
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

}

- (NSString *) description {
	return [NSString stringWithFormat:@"<%@ (tag %@, rock %d): 0x%lx>", self.class, self.tag, self.rock, (long)self];
}

- (void) encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:tag forKey:@"tag"];
	
	[encoder encodeInt32:rock forKey:@"rock"];
	// disprock is handled by the app
	
	[encoder encodeObject:filename forKey:@"filename"];
	[encoder encodeObject:[GlkFileRef relativizePath:basedir] forKey:@"basedir"];
	[encoder encodeObject:[GlkFileRef relativizePath:dirname] forKey:@"dirname"];
	[encoder encodeObject:[GlkFileRef relativizePath:pathname] forKey:@"pathname"];

	[encoder encodeInt32:filetype forKey:@"filetype"];
	[encoder encodeBool:textmode forKey:@"textmode"];
}

- (void) filerefDelete {
	if (library.dispatch_unregister_obj)
		(*library.dispatch_unregister_obj)(self, gidisp_Class_Fileref, disprock);
		
	if (![library.filerefs containsObject:self])
		[NSException raise:@"GlkException" format:@"GlkFileRef was not in library filerefs list"];
	[library.filerefs removeObject:self];
	inlibrary = NO;
}


@end
