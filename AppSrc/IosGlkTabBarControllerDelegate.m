//
//  IosGlkUITabBarControllerDelegate.m
//  iosglulxe
//
//  Created by Administrator on 2022-11-30.
//

#import "NotesViewController.h"
#import "SettingsViewController.h"
#import "IosGlkViewController.h"
#import "IosGlkSceneDelegate.h"

#import "IosGlkTabBarControllerDelegate.h"

@implementation IosGlkTabBarControllerDelegate

/* UITabBarController delegate method */
- (void) tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewc {
    if (![viewc isKindOfClass:[UINavigationController class]])
        return;
    UINavigationController *navc = (UINavigationController *)viewc;
    NSArray *viewcstack = navc.viewControllers;
    if (!viewcstack || !viewcstack.count)
        return;
    UIViewController *rootviewc = viewcstack[0];
    NSLog(@"### tabBarController did select %@ (%@)", navc, rootviewc);

    if (rootviewc != self.notesvc) {
        /* If the notesvc was drilled into the transcripts view or subviews, pop out of there. */
        [self.notesvc.navigationController popToRootViewControllerAnimated:NO];
    }
    if (rootviewc != self.settingsvc) {
        /* If the settingsvc was drilled into a web subview, pop out of there. */
        [self.settingsvc.navigationController popToRootViewControllerAnimated:NO];
    }

    NSUserActivity *currentUserActivity = tabBarController.view.window.windowScene.userActivity;
    if (currentUserActivity == nil) {
        IosGlkSceneDelegate *sceneDelegate = (IosGlkSceneDelegate *)tabBarController.view.window.windowScene.delegate;
        if (sceneDelegate) {
            currentUserActivity = [[NSUserActivity alloc] initWithActivityType:[sceneDelegate mainSceneActivityType]];
        }
    }


    if (currentUserActivity) {
        [currentUserActivity addUserInfoEntriesFromDictionary:@{@"selectedTabIndex" : @(tabBarController.selectedIndex)}];

        NSLog(@"TabBarControllerDelegate Stored selected tab index in user activity as %ld", tabBarController.selectedIndex);
    }
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    NSLog(@"tabBarController:shouldSelectViewController:");
    NSUInteger index = tabBarController.selectedIndex;
    NSLog(@"tabBarController.selectedIndex: %ld", index);

//    UINavigationController *navc = (UINavigationController *)tabBarController.selectedViewController;
//    if ([navc.viewControllers[0] isKindOfClass:[IosGlkViewController class]]) {
//        [((IosGlkViewController *)navc.viewControllers[0] ) updateUserActivity:nil];
//    } else {
//        NSLog(@"Wanted IosGlkViewController, got %@", NSStringFromClass([navc.viewControllers[0] class]));
//    }
    if (index == 1) {
        // load data appropriate for coming from the 2nd tab
    } else if (index == 2) {
        // load data appropriate for coming from the 3rd tab
    }
    return YES;
}

- (NotesViewController *)notesvc {
    if (_notesvc == nil) {
        for (UIViewController *vc in _tabBarController.viewControllers) {
            if ([vc isKindOfClass:[NotesViewController class]])
                _notesvc = (NotesViewController *)vc;
        }
    }
    return _notesvc;
}

- (SettingsViewController *)settingsvc {
    if (_settingsvc == nil) {
        for (UIViewController *vc in _tabBarController.viewControllers) {
            if ([vc isKindOfClass:[SettingsViewController class]])
                _settingsvc = (SettingsViewController *)vc;
        }
    }
    return _settingsvc;
}

@end
