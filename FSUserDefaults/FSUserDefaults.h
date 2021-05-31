//
//  FSUserDefaults.h
//
//  Created by Christian Floisand.
//  Copyright © 2017 Flyingsand. All rights reserved.
//
//  ABSTRACT:
//  This class facilitates the use of Apple's NSUserDefaults class for storing and retrieving user default data without
//  all the boilerplate and tedious code that typically goes with using NSUserDefaults as-is. This is accomplished by
//  utilizing dynamic properties together with the Objective-C runtime so that simple dot syntax can be used to
//  access individual user defaults easily.
//
//  USAGE:
//  Simply subclass this class, and add user default properties to the class' interface, then declare them as @dynamic
//  in the class implementation.
//  e.g.:
//
//  (MyUserDefaults.h)
//
//  @interface MyUserDefaults : FSUserDefaults
//  @property (nonatomic, strong) NSString *aDefaultString;
//  @end
//
//  (MyUserDefaults.m)
//
//  @implementation MyUserDefaults
//  @dynamic aDefaultString;
//  @end
//
//  (MyViewController.m)
//
//  - (void)viewDidLoad {
//      [super viewDidLoad];
//      MyUserDefaults *defaults = ...
//      defaults.aDefaultString = @"New Setting";
//  }
//

#import <Foundation/Foundation.h>


@interface FSUserDefaults : NSObject
@property (nonatomic, strong, readonly) NSUserDefaults *userDefaults;

+ (instancetype)sharedInstance;
- (instancetype)initWithSuiteName:(NSString *)suiteName;

@end
