//
//  FSUserDefaults.h
//
//  Created by Christian Floisand.
//  Copyright © 2017 Flyingsand. All rights reserved.
//

#import "FSUserDefaults.h"
#import <objc/runtime.h>
#import <objc/message.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrlcpy-strlcat-size"

#define TYPE_ENCODING_STRING_SETTER "v@:_"
#define TYPE_ENCODING_STRING_GETTER "_@:"

#define SELECTOR_SETTER_BOOL "setBool:forKey:"
#define SELECTOR_SETTER_int "setInteger:forKey:"
#define SELECTOR_SETTER_float "setFloat:forKey:"
#define SELECTOR_SETTER_double "setDouble:forKey:"
#define SELECTOR_SETTER_id "setObject:forKey:"
#define SELECTOR_SETTER_NSURL "setURL:forKey:"

#define SELECTOR_GETTER_BOOL "boolForKey:"
#define SELECTOR_GETTER_int "integerForKey:"
#define SELECTOR_GETTER_float "floatForKey:"
#define SELECTOR_GETTER_double "doubleForKey:"
#define SELECTOR_GETTER_id "objectForKey:"
#define SELECTOR_GETTER_NSURL "URLForKey:"

#define SELECTOR_STRING_SETTER(type) SELECTOR_SETTER_ ## type
#define SELECTOR_STRING_GETTER(type) SELECTOR_GETTER_ ## type

#define METHOD_NAME_SETTER(type) type ## Setter
#define METHOD_NAME_GETTER(type) type ## Getter

static const char *
CopyPropertyNameFromSetter(const char *setterName) {
    char *propertyName = malloc(sizeof(char) * (strlen(setterName) - 3));
    strlcpy(propertyName, setterName + 3, strlen(setterName) - 3);
    propertyName[0] = tolower(propertyName[0]);
    return propertyName;
}

static bool
IsPropertyURL(const char *attr) {
    attr += 3;
    static const char *URLClassName = "NSURL";
    size_t compareLen = MIN(strlen(attr), strlen(URLClassName));
    bool isUrl = strncmp(attr, URLClassName, compareLen) == 0;
    
    return isUrl;
}

#define METHOD_IMPLEMENTATION_SETTER(tname, type) void METHOD_NAME_SETTER(tname)(id self, SEL _cmd, type value) { \
    const char *selectorString = SELECTOR_STRING_SETTER(tname);                     \
    SEL setterSelector = sel_registerName(selectorString);                          \
    const char *propertyName = CopyPropertyNameFromSetter(sel_getName(_cmd));       \
    NSCAssert([self isKindOfClass:[FSUserDefaults class]], @"");                    \
    NSUserDefaults *userDefaults = ((FSUserDefaults *)self).userDefaults;           \
    ((void(*)(id,SEL,type,id))objc_msgSend)(userDefaults, setterSelector, value, [NSString stringWithUTF8String:propertyName]); \
    free((void *)propertyName);                                                     \
}

#define METHOD_IMPLEMENTATION_GETTER(tname, type) type METHOD_NAME_GETTER(tname)(id self, SEL _cmd) { \
    const char *selectorString = SELECTOR_STRING_GETTER(tname);                     \
    SEL getterSelector = sel_registerName(selectorString);                          \
    NSCAssert([self isKindOfClass:[FSUserDefaults class]], @"");                    \
    NSUserDefaults *userDefaults = ((FSUserDefaults *)self).userDefaults;           \
    return ((type(*)(id,SEL,id))objc_msgSend)(userDefaults, getterSelector, [NSString stringWithUTF8String:sel_getName(_cmd)]); \
}

#define GENERATE_SETTER_GETTER_METHOD_PAIR(tname, type) \
    METHOD_IMPLEMENTATION_SETTER(tname, type)           \
    METHOD_IMPLEMENTATION_GETTER(tname, type)

GENERATE_SETTER_GETTER_METHOD_PAIR(BOOL, BOOL)
GENERATE_SETTER_GETTER_METHOD_PAIR(int, int)
GENERATE_SETTER_GETTER_METHOD_PAIR(float, float)
GENERATE_SETTER_GETTER_METHOD_PAIR(double, double)
GENERATE_SETTER_GETTER_METHOD_PAIR(id, id)
GENERATE_SETTER_GETTER_METHOD_PAIR(NSURL, NSURL*)


@implementation FSUserDefaults

+ (instancetype)sharedInstance {
    static id _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [self new];
        ((FSUserDefaults *)_instance)->_userDefaults = [NSUserDefaults standardUserDefaults];
    });
    return _instance;
}

- (instancetype)init {
    return (self = [self initWithSuiteName:nil]);
}

- (instancetype)initWithSuiteName:(NSString *)suiteName {
    self = [super init];
    if (self) {
        _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    }
    return self;
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    const char *selectorName = sel_getName(sel);
    const char *propertyName = selectorName;
    BOOL isSetter = NO;
    
    if ((strlen(selectorName) > 3) && (strncmp("set", selectorName, 3) == 0)) {
        propertyName = CopyPropertyNameFromSetter(selectorName);
        isSetter = YES;
    }
    
    objc_property_t property = class_getProperty(self, propertyName);
    if (isSetter) {
        free((void *)propertyName);
    }
    
    if (property != NULL) {
        const char *propertyAttrs = property_getAttributes(property);
        char propertyType = propertyAttrs[1];
        
        const char *methodTypeString;
        int index;
        if (isSetter) {
            methodTypeString = TYPE_ENCODING_STRING_SETTER;
            index = 3;
        } else {
            methodTypeString = TYPE_ENCODING_STRING_GETTER;
            index = 0;
        }
        
        char *typeEncodingString = malloc(sizeof(char) * (strlen(methodTypeString) + 1));
        strlcpy(typeEncodingString, methodTypeString, strlen(methodTypeString) + 1);
        typeEncodingString[index] = propertyType;
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpointer-type-mismatch"
        IMP methodImpl;
        switch (propertyType) {
            case 'c':
            case 'B':
                methodImpl = (IMP)(isSetter ? METHOD_NAME_SETTER(BOOL) : METHOD_NAME_GETTER(BOOL));
                break;
            case 's':
            case 'i':
            case 'l':
            case 'q':
            case 'S':
            case 'I':
            case 'L':
            case 'Q':
                methodImpl = (IMP)(isSetter ? METHOD_NAME_SETTER(int) : METHOD_NAME_GETTER(int));
                break;
            case 'f':
                methodImpl = (IMP)(isSetter ? METHOD_NAME_SETTER(float) : METHOD_NAME_GETTER(float));
                break;
            case 'd':
                methodImpl = (IMP)(isSetter ? METHOD_NAME_SETTER(double) : METHOD_NAME_GETTER(double));
                break;
            case '@':
                if (IsPropertyURL(propertyAttrs)) {
                    methodImpl = (IMP)(isSetter ? METHOD_NAME_SETTER(NSURL) : METHOD_NAME_GETTER(NSURL));
                } else {
                    methodImpl = (IMP)(isSetter ? METHOD_NAME_SETTER(id) : METHOD_NAME_GETTER(id));
                }
                break;
            default:
                NSAssert(NO, @"[FSUserDefaults] Unhandled property type.");
                break;
        }
#pragma clang diagnostic pop
        
        class_addMethod(self, sel, methodImpl, typeEncodingString);
        free(typeEncodingString);
        
        return YES;
    }
    
    return [super resolveInstanceMethod:sel];
}

@end

#pragma clang diagnostic pop
