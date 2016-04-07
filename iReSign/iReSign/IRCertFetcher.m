//
//  IRCertFetcher.m
//  iReSign
//
//  Created by Mateusz Malczak on 06/04/16.
//  Copyright © 2016 nil. All rights reserved.
//

#import "IRCertFetcher.h"
#import "IRTask.h"

@interface IRCertFetcher ()

@property (nonatomic, copy) void (^completeBlock)(NSArray*);

@property (nonatomic, strong) IRTask *certTask;

@end


@implementation IRCertFetcher

- (void)getCertsSyncWithCompletion: (void (^)(NSArray *)) completeBlock {
  [self getCertsSync:YES withCompletion:completeBlock];
}

- (void)getCertsWithCompletion: (void (^)(NSArray *)) completeBlock {
  [self getCertsSync:NO withCompletion:completeBlock];
}

- (void)getCertsSync: (BOOL) waitForTask withCompletion: (void (^)(NSArray *)) completeBlock {
  
  self.completeBlock = completeBlock;
  
  NSLog(@"Getting Certificate IDs");
//  [statusLabel setStringValue:@"Getting Signing Certificate IDs"];
  
  __weak IRCertFetcher* weakSelf = self;
  void (^handler)(IRTask*, NSPipe*) = ^(IRTask *task, NSPipe *pipe) {
    [weakSelf readCerts:[pipe fileHandleForReading]];
  };
  
  self.certTask = [[IRTask alloc] initWithLaunchPath:@"/usr/bin/security"
                                           arguments:@[@"find-identity", @"-v", @"-p", @"codesigning"]];
  [self.certTask runAndWait:waitForTask completion:handler];
}

- (void)readCerts:(NSFileHandle*)streamHandle {
  @autoreleasepool {
    
    NSString *securityResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
    // Verify the security result
    if (securityResult == nil || securityResult.length < 1) {
      // Nothing in the result, return
      return;
    }
    NSArray *rawResult = [securityResult componentsSeparatedByString:@"\""];
    NSMutableArray *tempGetCertsResult = [NSMutableArray arrayWithCapacity:20];
    for (int i = 0; i <= [rawResult count] - 2; i+=2) {
      
      NSLog(@"i:%d", i+1);
      if (rawResult.count - 1 < i + 1) {
        // Invalid array, don't add an object to that position
      } else {
        // Valid object
        [tempGetCertsResult addObject:[rawResult objectAtIndex:i+1]];
      }
    }
//
//    void (^b)(NSArray*) = self.completeBlock;
//    dispatch_async(dispatch_get_main_queue(), ^(){
//      b(tempGetCertsResult);
//    });
    self.completeBlock(tempGetCertsResult);
    self.completeBlock = nil;
  }
}

-(void)dealloc {
  NSLog(@"Dead");
}

@end
