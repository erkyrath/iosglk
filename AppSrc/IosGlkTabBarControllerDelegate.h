//
//  IosGlkUITabBarControllerDelegate.h
//  iosglulxe
//
//  Created by Administrator on 2022-11-30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NotesViewController, SettingsViewController;

@interface IosGlkTabBarControllerDelegate : NSObject <UITabBarControllerDelegate>

@property (nonatomic, assign) NotesViewController *notesvc;
@property (nonatomic, assign) SettingsViewController *settingsvc;
@property (nonatomic, weak) IBOutlet UITabBarController *tabBarController;

@end

NS_ASSUME_NONNULL_END
