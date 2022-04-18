//
//  TDNUnarchiver.m
//  QuietUnrar
//
//  Created by Robert McGovern on 2021/05/31.
//

#import <Foundation/Foundation.h>
#import "TDNUnarchiver.h"
#import "QuietUnrarAppDelegate.h"

#import <UnrarKit/UnrarKit.h>
#import "libunrar/dll.hpp"
#import "libunrar/rardefs.hpp"

#import <wchar.h>

//@interface TDNUnarchiver ()
//
//@end

@implementation TDNUnarchiver

@synthesize quietUnrar;
static QuietUnrarAppDelegate * quietUnrarClassPtr;

#pragma mark - Callback Functions

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
int CALLBACK changeVolume(char * volumeName, int mode) {
    if (mode == RAR_VOL_ASK)
        [quietUnrarClassPtr alertUserOfMissing:volumeName];

    return 0;
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
int CALLBACK generalCallbackFunction(UINT message, LPARAM userData, LPARAM parameterOne, LPARAM parameterTwo) {
    NSLog(@"into generalCallbackFunction");
    if (message == UCM_NEEDPASSWORDW) {
        NSLog(@"file requires a password ...");
        NSString * password = [quietUnrarClassPtr requestArchivePassword];

        if (password) {
            wchar_t const *passwordAsWChar = (const wchar_t *)[password cStringUsingEncoding:NSUTF32LittleEndianStringEncoding];
            wcscpy((wchar_t *) parameterOne, passwordAsWChar);
            return 1;
        } else {
            return -1;
        }
    }

    return 0;

    /*
     You need to copy the password string to buffer with P1 address
     and P2 size.

     This password string must use little endian Unicode encoding in case
     UCM_NEEDPASSWORDW message. Namely, it must be wchar_t and not UTF-8.

     case UCM_NEEDPASSWORDW:
          {
            wchar_t *eol;
            printf("\nPassword required: ");

            // fgetws may fail to read non-English characters from stdin
            // in some compilers. In this case use something more appropriate
            // for Unicode input.
            fgetws((wchar_t *)P1,(int)P2,stdin);

            eol=wcspbrk((wchar_t *)P1,L"\r\n");
            if (eol!=NULL)
              *eol=0;
          }
          return(1);
     */
}

#pragma mark Public Methods
- (BOOL) extractArchiveWithFilename:(NSString *) filename {
    // Add code to distinguish filetypes and pass of to relevant unarchiver
//    return [self extractRARArchiveWithFilename:filename];
    return [self extractRarUsingUnrarKitWithFilename: filename];
}

#pragma mark Extraction Methods
- (BOOL) extractRARArchiveWithFilename:(NSString *) filename {
    quietUnrarClassPtr = quietUnrar;

    char commentBuffer[BUF_LEN];
    BOOL extractionSuccessful = YES;
    struct RARHeaderData headerData;
    NSString * lastExtractedFilename = @"";
    NSString * currentFilename;

    //Determine the folder we should extract the archive to. This by default
    //is the <folderContainingTheArchive>/<archiveNameWithPathExtension>
    NSString * folderToExtractTo = [filename stringByDeletingPathExtension];

    // Open the Archive for extraction, we set the open result to 3 so we can see it has changed
    char * filenameCString = (char *)[filename cStringUsingEncoding:NSISOLatin1StringEncoding];
    struct RAROpenArchiveData arcData = { filenameCString, RAR_OM_EXTRACT, 3, &commentBuffer[0], BUF_LEN, 0, 0};

    HANDLE archive = RAROpenArchive(&arcData);
    //NSLog(@"Opening Archive %s with result %d", filenameCString, arcData.OpenResult);

    // set call backs for if password needed or need to change volume
    RARSetChangeVolProc(archive, &changeVolume);
    RARSetCallback(archive, &generalCallbackFunction, (LPARAM)archive);

    while (RARReadHeader(archive, &headerData) == ERAR_SUCCESS) {
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
                isDir                                                    ||
                ![quietUnrar shouldFileBeReplaced:currentFilename]) {
                extractFile = NO;
            }
        }

//        NSLog(@"Last filename %@, currentFilename %@, equality %d", lastExtractedFilename, currentFilename, [lastExtractedFilename isEqualToString:currentFilename]);

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

- (BOOL) extractRarUsingUnrarKitWithFilename:(NSString *) filename {
    NSError *archiveError = nil;
    NSError *error = nil;

    URKArchive *archive = [[URKArchive alloc] initWithPath:filename error:&archiveError];

    if (archiveError != nil) {
        NSLog(@"Error with archive: %@", archiveError.localizedDescription);
        return false;
    }
    //NSArray<URKFileInfo*> *fileInfosInArchive = [archive listFileInfo:&error];
    if (archive.isPasswordProtected) {

        __block NSString *givenPassword = nil;
        dispatch_sync(dispatch_get_main_queue(), ^{
            givenPassword = [quietUnrar requestArchivePassword];
        });

        if (givenPassword != nil) {
            archive.password = givenPassword;
        }
    }

    NSString * folderToExtractTo = [filename stringByDeletingPathExtension];

    BOOL extractFilesSuccessful = [archive extractFilesTo: folderToExtractTo
                                                overwrite:NO
                                                    error:&error];

    if (error != nil) {
        NSLog(@"Error extracting archive: %@", error.localizedDescription);
    }

    return extractFilesSuccessful;
}

@end
