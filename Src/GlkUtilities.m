//
//  GlkUtilities.m
//  IosGlk
//
//  Created by Andrew Plotkin on 2/2/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import "GlkUtilities.h"


NSString *StringFromRect(CGRect rect) {
	return [NSString stringWithFormat:@"%.1fx%.1f at %.1f,%.1f", 
		rect.size.width, rect.size.height, rect.origin.x, rect.origin.y];
}

