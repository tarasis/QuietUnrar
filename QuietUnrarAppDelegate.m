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

QuietUnrarAppDelegate * quietUnrar; 

int changeVolume(char * volumeName, int mode);
int callbackFunction(UINT message, LPARAM userData, LPARAM parameterOne, LPARAM parameterTwo);

int changeVolume(char * volumeName, int mode) {
	NSLog(@"Volume Name: %s and mode %d", volumeName, mode);
	
	if (mode == RAR_VOL_ASK)
	{
		[(QuietUnrarAppDelegate *) quietUnrar alertUserOfMissing:volumeName];
	}
	
}

int callbackFunction(UINT message, LPARAM userData, LPARAM parameterOne, LPARAM parameterTwo) {
	NSLog(@"Callback Function, args: %d, %D, %D, %D", message, userData, parameterOne, parameterTwo);
}


@implementation QuietUnrarAppDelegate

@synthesize window;

- (void) applicationWillFinishLaunching:(NSNotification *)notification {
	KeyMap map;
	GetKeys(map);
	NSLog(@"Shift or Right Shift: %d", KEYMAP_GET(map, kVKC_Shift) || KEYMAP_GET(map, kVKC_rShift));	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Having extracted our file or not, quit. Though should not if error is displayed.
	[[NSApplication sharedApplication] terminate:self];
}

//- (BOOL)application:(id)sender openFileWithoutUI:(NSString *)filename {
//	NSLog(@"openFileWithoutUI with file: %@", filename);
//	return YES;
//}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
	NSLog(@"openFile: %@", filename);
	
	[self extractRarWith:filename];
	
	// Always return YES even if there is an error to avoid dialog indicating unable to
	// handle files of type RAR if the archive is corrupt or part of it is missing
	return YES;
}

//- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
//	for (NSString * filename in filenames) {
//		NSLog(@"openFiles: %@", filename);
//	}
//	
//	// If we get passed files don't open the UI
//	[sender replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
//}

- (BOOL) extractRarWith:(NSString *) filename {
	quietUnrar = (void *) self;
	char commentBuffer[BUF_LEN];
	BOOL extractionSuccessful = YES;
	
	//Determine the folder we should extract the archive to. This by default
	//is the <folderContainingTheArchive>/<archiveNameWithPathExtension>
	NSString * defaultFolderToExtractTo = [filename stringByDeletingPathExtension];
	
	char * filenameCString = (char *)[filename cStringUsingEncoding:NSISOLatin1StringEncoding];
	
	// Open the Archive for extraction, we set the open result to 3 so we can see it has changed
	struct RAROpenArchiveData arcData = { filenameCString, RAR_OM_EXTRACT, 3, &commentBuffer[0], BUF_LEN, 0, 0};	
	HANDLE archive = RAROpenArchive(&arcData);
	NSLog(@"Opening Archive %s with result %d", filenameCString, arcData.OpenResult);
	
	// set call backs for if password needed or need to change volume
	RARSetChangeVolProc(archive, &changeVolume);
	//RARSetCallback(archive, &callbackFunction, 0);
	
	//
	struct RARHeaderData headerData;
	NSString * lastExtractedFilename = @"";
	NSString * currentFilename;
	
	while (RARReadHeader(archive, &headerData) != ERAR_END_ARCHIVE) {
		NSLog(@"Attempting to extract %s to %@", headerData.FileName, defaultFolderToExtractTo);
		
		int processResult = 0;
		BOOL extractFile = YES;
		currentFilename = [NSString stringWithCString:(const char *) headerData.FileName encoding:NSISOLatin1StringEncoding];
		
		NSFileManager * fileManager = [NSFileManager defaultManager];
		
		if ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/%s", defaultFolderToExtractTo, headerData.FileName]] ) {
			// If we have already processed the file once and the user has told us to skip
			// don't ask them again, even though we've changed volumes. Otherwise
			// ask the user what to do.
			if ([lastExtractedFilename isEqualToString:currentFilename] || ![self shouldFileBeReplaced:currentFilename]) {
				extractFile = NO;
			}
		}
		
//		NSLog(@"Last filename %@, currentFilename %@, equality %d", lastExtractedFilename, currentFilename, [lastExtractedFilename isEqualToString:currentFilename]);
		
		if (extractFile) {
			NSLog(@"...Extracting");
			processResult = RARProcessFile(archive, RAR_EXTRACT, (char *) [defaultFolderToExtractTo cStringUsingEncoding:NSISOLatin1StringEncoding], NULL);
		} else {
			NSLog(@"...Skipping as already exists");
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
	
	int closeResult = RARCloseArchive(archive);
	NSLog(@"Closing Archive %s with result %d", filenameCString, closeResult);

	return extractionSuccessful;
}

- (BOOL) shouldFileBeReplaced:(NSString *) filename {
	BOOL result = NO;
	
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"Overwrite"];
	[alert addButtonWithTitle:@"Skip"];
	[alert setMessageText:[NSString stringWithFormat:@"Overwrite %@?", filename]];
	[alert setInformativeText:[NSString stringWithFormat:@"The file already exists. Do you wish to extract it again, overwriting the original file?", filename]];
	[alert setAlertStyle:NSWarningAlertStyle];
	
	if ([alert runModal] == NSAlertFirstButtonReturn) {
		result = YES;
	}
	
	[alert release];
	
	return result;
}

- (void) alertUserOfMissing:(const char *) volume {
	NSLog(@"Alerting user of missing volume");
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:[NSString stringWithFormat:@"Archive part %s is missing.", volume]];
	[alert setInformativeText:@"Unable to extract all files from RAR archive as part of it is missing"];
	[alert setAlertStyle:NSCriticalAlertStyle];
	
	[alert runModal];

	[alert release];
}

@end
