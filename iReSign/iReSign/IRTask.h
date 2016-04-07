//
//  IRTask.h
//  iReSign
//
//  Created by Mateusz Malczak on 07/04/16.
//  Copyright © 2016 nil. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IRTask : NSObject

-(instancetype) initWithLaunchPath: (NSString*) launchPath arguments: (NSArray*) args;

-(instancetype) initWithLaunchPath: (NSString*) launchPath arguments: (NSArray*) args workingDir: (NSString*) dir;

-(void) runAsync:(void(^)(IRTask*, NSPipe*)) completionHandler;

-(void) runSync:(void(^)(IRTask*, NSPipe*)) completionHandler;

-(void) runAndWait:(BOOL) wait completion:(void(^)(IRTask*, NSPipe*)) completionHandler;
  
@end
