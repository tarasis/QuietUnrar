//
//  QuietUnrarAppDelegate.h
//  QuietUnrar
//
//  Created by Robert McGovern on 2009/09/06.
//  Copyright 2009 Tarasis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum
{
	kVKC_Shift		= 56,
	kVKC_Option		= 58,
	kVKC_Control		= 59,
	kVKC_rShift		= 60,		/*	Right-hand modifiers; not implemented */
	kVKC_rOption		= 61,
	kVKC_rControl		= 62,
	kVKC_Command		= 55,
};

#define KEYMAP_GET(m, index) ((((uint8_t*)(m))[(index) >> 3] & (1L << ((index) & 7))) ? 1 : 0)

#define BUF_LEN 64000

@interface QuietUnrarAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *__weak window;
	NSView *__weak passwordView;
	
	NSSecureTextField * __weak passwordField;
}

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSView *passwordView;
@property (weak) IBOutlet NSSecureTextField * passwordField;

- (BOOL) extractRarWith:(NSString *) filename;
- (BOOL) shouldFileBeReplaced:(NSString *) filename;
- (void) alertUserOfMissing:(const char *) volume;
- (NSString *) requestArchivePassword;

@end
