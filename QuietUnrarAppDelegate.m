//
//  QuietUnrarAppDelegate.m
//  QuietUnrar
//
//  Created by Robert McGovern on 2009/09/06.
//  Copyright 2009 Tarasis. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "QuietUnrarAppDelegate.h"
#import "libunrar/dll.hpp"

#pragma mark Callbacks
// Declartions that are not to be part of the public interface.
// The two methods are for callbacks passed to the RAR library
QuietUnrarAppDelegate * quietUnrar;

int changeVolume(char * volumeName, int mode);
int callbackFunction(UINT message, LPARAM userData, LPARAM parameterOne, LPARAM parameterTwo);

// Called everytime a new volume (part) of the RAR is needed.
// mode will either be
// RAR_VOL_NOTIFY that just notifies us that the volume has changed
// RAR_VOL_ASK indicates that a volume is needed and the library is asking for it.
// 
// in both case volumeName is that name of the volume (for instance .r00)
//
// Note in the event of a volume being missing, there is no way to indicate to the
// library that you have found it. You would need to block the copy, let the user find the 
// volume, copy it to where the other volumes are and unblock to let the library
// continue processing
int changeVolume(char * volumeName, int mode) {
	if (mode == RAR_VOL_ASK)
		[(QuietUnrarAppDelegate *) quietUnrar alertUserOfMissing:volumeName];
}

// Multipurpose callback function that is called un changing a volume, when data is being processed
// and when a password is required. This is indicated by the message parameter
//
// UCM_CHANGEVOLUME sent when changing volumes
// UCM_PROCESSDATA sent as each file in the archive is being extracted in chunks, useful for progress bars
// UCM_NEEDPASSWORD sent when the library discovers a password is needed.
//
// The userData param is a pointer to something we supplied when the callback was registered. In my
// case I am passing in the pointer to the archive data so that the requestArchivePassword method
// can supply the password to the RAR library via RARSetPassword
//
// parameterOne & parameterTwo have different meanings depending on what message is passed.
int callbackFunction(UINT message, LPARAM userData, LPARAM parameterOne, LPARAM parameterTwo) {
	if (message == UCM_NEEDPASSWORD) {
		NSString * password = [(QuietUnrarAppDelegate *) quietUnrar requestArchivePassword];
		if (password)
			RARSetPassword((HANDLE)userData, (char *) [password cStringUsingEncoding:NSISOLatin1StringEncoding]);
	}
}

#pragma mark
@implementation QuietUnrarAppDelegate

@synthesize window, passwordView, passwordField;

- (void) applicationWillFinishLaunching:(NSNotification *)notification {
	// The following is used to determine is the left or right shift keys were depressed
	// as the application was launched. Could be used to display a gui on Application start.
	KeyMap map;
	GetKeys(map);
	if (KEYMAP_GET(map, kVKC_Shift) || KEYMAP_GET(map, kVKC_rShift))
		NSLog(@"Shift or Right Shift");	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Having extracted our file or not, quit. Though should not if error is displayed.
	[[NSApplication sharedApplication] terminate:self];
}

// Call one at a time for each file selected when app is run
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
	//NSLog(@"openFile: %@", filename);
	
	[self extractRarWith:filename];
	
	// Always return YES even if there is an error to avoid dialog indicating unable to
	// handle files of type RAR if the archive is corrupt or part of it is missing
	return YES;
}

#pragma mark "Main" 
- (BOOL) extractRarWith:(NSString *) filename {
	quietUnrar = (void *) self;
	char commentBuffer[BUF_LEN];
	BOOL extractionSuccessful = YES;
	
	//Determine the folder we should extract the archive to. This by default
	//is the <folderContainingTheArchive>/<archiveNameWithPathExtension>
	NSString * folderToExtractTo = [filename stringByDeletingPathExtension];
	
	char * filenameCString = (char *)[filename cStringUsingEncoding:NSISOLatin1StringEncoding];
	
	// Open the Archive for extraction, we set the open result to 3 so we can see it has changed
	struct RAROpenArchiveData arcData = { filenameCString, RAR_OM_EXTRACT, 3, &commentBuffer[0], BUF_LEN, 0, 0};	
	HANDLE archive = RAROpenArchive(&arcData);
	//NSLog(@"Opening Archive %s with result %d", filenameCString, arcData.OpenResult);
	
	// set call backs for if password needed or need to change volume
	RARSetChangeVolProc(archive, &changeVolume);
	RARSetCallback(archive, &callbackFunction, (LPARAM)archive);
	
	//
	struct RARHeaderData headerData;
	NSString * lastExtractedFilename = @"";
	NSString * currentFilename;
	
	while (RARReadHeader(archive, &headerData) != ERAR_END_ARCHIVE) {
		//NSLog(@"Attempting to extract %s to %@", headerData.FileName, folderToExtractTo);
		
		int processResult = 0;
		BOOL extractFile = YES;
		BOOL isDir;
		currentFilename = [NSString stringWithCString:(const char *) headerData.FileName encoding:NSISOLatin1StringEncoding];
		
		NSFileManager * fileManager = [NSFileManager defaultManager];
		
		if ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/%s", folderToExtractTo, headerData.FileName] isDirectory:&isDir] ) {
			// If we have already processed the file once and the user has told us to skip
			// don't ask them again, even though we've changed volumes. Otherwise
			// ask the user what to do.
			if ([lastExtractedFilename isEqualToString:currentFilename] || 
				isDir													||
				![self shouldFileBeReplaced:currentFilename]) {
				extractFile = NO;
			}
		}
		
//		NSLog(@"Last filename %@, currentFilename %@, equality %d", lastExtractedFilename, currentFilename, [lastExtractedFilename isEqualToString:currentFilename]);
		
		if (extractFile) {
			//NSLog(@"...Extracting");
			processResult = RARProcessFile(archive, RAR_EXTRACT, (char *) [folderToExtractTo cStringUsingEncoding:NSISOLatin1StringEncoding], NULL);
		} else {
			//NSLog(@"...Skipping as already exists");
			processResult = RARProcessFile(archive, RAR_SKIP, NULL, NULL);
			// Curious behavior by the lib, you have SKIP a file number of times (4 in my test example) before
			// it is skipped. However if you extract it is only processed once.
		}
		
		if (processResult != 0) {
			NSLog(@"Error: Process Result was %d", processResult);
			extractionSuccessful = NO;
			break;
			// DISPLAY ERROR DIALOG, ALERT THE USER
		}
		
		lastExtractedFilename = currentFilename;

	}
	
	RARCloseArchive(archive);
	//NSLog(@"Closing Archive %s with result %d", filenameCString, closeResult);

	return extractionSuccessful;
}

// Presents a dialog to the user allowing them to Skip a file or overwrite an existing version
// returns YES or NO
- (BOOL) shouldFileBeReplaced:(NSString *) filename {
	BOOL result = NO;
	
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"Overwrite"];
	NSButton * skipButton = [alert addButtonWithTitle:@"Skip"];
	[skipButton setKeyEquivalent:@"\e"];
	[alert setMessageText:[NSString stringWithFormat:@"Overwrite %@?", filename]];
	[alert setInformativeText:[NSString stringWithFormat:@"The file already exists. Do you wish to extract it again, overwriting the original file?", filename]];
	[alert setAlertStyle:NSWarningAlertStyle];
	
	if ([alert runModal] == NSAlertFirstButtonReturn) {
		result = YES;
	}
	
	[alert release];
	
	return result;
}

// Indicate to the user that part of the RAR volume is missing.
- (void) alertUserOfMissing:(const char *) volume {
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:[NSString stringWithFormat:@"Archive part %s is missing.", volume]];
	[alert setInformativeText:@"Unable to extract all files from RAR archive as part of it is missing"];
	[alert setAlertStyle:NSCriticalAlertStyle];
	
	[alert runModal];

	[alert release];
}

// Creates a dialog with a custom view with a NSSecureTextField which is displayed
// to the user so they can provide a password. Returns the entered password or nil
- (NSString *) requestArchivePassword {
	if (!passwordView) {
		[NSBundle loadNibNamed:@"PasswordView" owner:self];
	}
	
	NSString * password = nil;
	
	NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Archive Requires a password"];
    [alert setInformativeText:@"To extract the contents of this archive a password is required."];
	[alert setAccessoryView:passwordView];
    [alert setAlertStyle:NSWarningAlertStyle];
	
	if ([alert runModal] == NSAlertFirstButtonReturn) {
		password = [passwordField stringValue];
		[password autorelease];
	}
	
	[alert release];
	
	return password;
}

@end
