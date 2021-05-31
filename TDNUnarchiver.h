//
//  TDNUnarchiver.h
//  QuietUnrar
//
//  Created by Robert McGovern on 2021/05/31.
//

#ifndef Unarchiver_h
#define Unarchiver_h

@interface TDNUnarchiver : NSObject

@property QuietUnrarAppDelegate * quietUnrar;

- (BOOL) extractArchiveWithFilename:(NSString *) filename;

@end


#endif /* Unarchiver_h */
