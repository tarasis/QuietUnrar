//
//  TDNUserDefaults.h
//  QuietUnrar
//
//  Created by Robert McGovern on 2021/05/31.
//

#import <Foundation/Foundation.h>
#import "FSUserDefaults.h"

NS_ASSUME_NONNULL_BEGIN

@interface TDNUserDefaults : FSUserDefaults

@property (nonatomic) BOOL playSounds;
@property (nonatomic) BOOL showNotification;
@property (nonatomic) BOOL hideDock;
@property (nonatomic) BOOL notificationsAllowed;

@end

NS_ASSUME_NONNULL_END
