//
//  IosGlkSceneDelegate.h
//  iosglulxe
//
//  Created by Administrator on 2022-11-05.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface IosGlkSceneDelegate : UIResponder <UIWindowSceneDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (readonly, strong) NSString *mainSceneActivityType;

@end

NS_ASSUME_NONNULL_END
