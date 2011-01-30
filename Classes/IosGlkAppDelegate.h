//
//  IosGlkAppDelegate.h
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IosGlkViewController;
@class GlkLibrary;
@class GlkAppWrapper;

@interface IosGlkAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
	IosGlkViewController *viewController;
	
	GlkLibrary *library;
	GlkAppWrapper *glkapp;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet IosGlkViewController *viewController;

@property (nonatomic, retain) GlkLibrary *library;
@property (nonatomic, retain) GlkAppWrapper *glkapp;

+ (IosGlkAppDelegate *) singleton;

@end

