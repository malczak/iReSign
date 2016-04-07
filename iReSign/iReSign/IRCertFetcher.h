//
//  IRCertFetcher.h
//  iReSign
//
//  Created by Mateusz Malczak on 06/04/16.
//  Copyright © 2016 nil. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IRCertFetcher : NSObject

- (void)getCertsSyncWithCompletion: (void (^)(NSArray *)) completeBlock;

- (void)getCertsWithCompletion: (void (^)(NSArray *)) completeBlock;

@end
