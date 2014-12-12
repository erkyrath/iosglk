/* GlkFileTypes.m: Miscellaneous file-related objc classes
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/


#import "GlkFileTypes.h"

@implementation GlkFileRefPrompt

@synthesize usage;
@synthesize fmode;
@synthesize dirname;
@synthesize filename;
@synthesize pathname;

- (id) initWithUsage:(glui32)usageval fmode:(glui32)fmodeval dirname:(NSString *)dirnameval {
	self = [super init];
	
	if (self) {
		usage = usageval;
		fmode = fmodeval;
		self.dirname = dirnameval;
		self.filename = nil;
		self.pathname = nil;
	}
	
	return self;
}

- (void) dealloc {
	self.dirname = nil;
	self.filename = nil;
	self.pathname = nil;
	[super dealloc];
}

@end

@implementation GlkFileThumb

@synthesize label;
@synthesize filename;
@synthesize pathname;
@synthesize usage;
@synthesize modtime;
@synthesize isfake;

/* Returns the recommended Glk file suffix for a file usage. (We store files in our directories with no suffix, but this might be important when interacting with other apps.) 
 */
+ (NSString *) suffixForFileUsage:(glui32)usage {
	switch (usage) {
		case fileusage_SavedGame:
			return @".glksave";
		case fileusage_Transcript:
			return @".txt";
		case fileusage_InputRecord:
			return @".txt";
		case fileusage_Data:
		default:
			return @".glkdata";
	}
}

/* Returns a localization key for a file usage. If localize is given, localize using that subkey. See Localizable.strings file for subkeys.
	(E.g.: [GlkFileThumb labelForFileUsage:fileusage_Transcript localize:@".placeholders"] returns the string @"transcripts".)
 */
+ (NSString *) labelForFileUsage:(glui32)usage localize:(NSString *)key {
	NSString *res = nil;
	
	switch (usage) {
		case fileusage_SavedGame:
			res = @"use.save";
			break;
		case fileusage_Transcript:
			res = @"use.transcript";
			break;
		case fileusage_InputRecord:
			res = @"use.input";
			break;
		case fileusage_Data:
		default:
			res = @"use.data";
	}
	
	if (key) {
		NSString *lockey = [NSString stringWithFormat:@"%@.%@", res, key];
		res = NSLocalizedString(lockey, nil);
	}
	
	return res;
}

- (void) dealloc {
	self.label = nil;
	self.filename = nil;
	self.pathname = nil;
	self.modtime = nil;
	[super dealloc];
}

- (NSComparisonResult) compareModTime:(GlkFileThumb *)other {
	return [other.modtime compare:modtime];
}

/* Copy the file (which must exist) to a temporary directory, with a filename suitable for exporting: the human-readable label, the recommended Glk suffix, and no slashes or backslashes. Returns the temporary pathname, or nil if there is an unexpected problem.
 
 This is a synchronous copy, so it may be slow for large files.
 If a temporary file with the given name already exists, it is replaced.
 The caller is responsible for deleting the temporary file after use.
 */
- (NSString *) exportTempFile {
	if (isfake || !pathname) {
		NSLog(@"exportTempFile: not a real file.");
		return nil;
	}
	
	NSString *tempdir = NSTemporaryDirectory();
	if (!tempdir) {
		NSLog(@"exportTempFile: no temporary directory available.");
		return nil;
	}
	
	NSString *val = [self.label stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (!val.length)
		val = @"file";
	val = [val stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	val = [val stringByReplacingOccurrencesOfString:@"\\" withString:@"-"];
	val = [val stringByAppendingString:[GlkFileThumb suffixForFileUsage:usage]];
	NSString *temppath = [tempdir stringByAppendingPathComponent:val];
	
	NSFileManager *manager = [NSFileManager defaultManager];
	
	if ([manager isDeletableFileAtPath:temppath]) {
		[[NSFileManager defaultManager] removeItemAtPath:temppath error:nil];
	}
	
	NSError *error = nil;
	[manager copyItemAtPath:self.pathname toPath:temppath error:&error];
	if (error) {
		NSLog(@"exportTempFile: copy failed: %@", error);
		return nil;
	}
	
	return temppath;
}

@end

