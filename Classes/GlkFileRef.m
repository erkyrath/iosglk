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
@synthesize filetype;
@synthesize rock;
@synthesize textmode;

- (id) initWithType:(glui32)usage rock:(glui32)frefrock {
	self = [super init];
	
	if (self) {
		self.library = [GlkLibrary singleton];
		inlibrary = YES;
		
		self.tag = [library newTag];
		rock = frefrock;
		
		textmode = ((usage & fileusage_TextMode) != 0);
		filetype = (usage & fileusage_TypeMask);
				
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
