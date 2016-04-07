//
//  IRTask.m
//  iReSign
//
//  Created by Mateusz Malczak on 07/04/16.
//  Copyright © 2016 nil. All rights reserved.
//

#import "IRTask.h"

@interface IRTask ()

@property (nonatomic, strong) NSTask *task;

@property (nonatomic, copy) void (^completionHandler)(IRTask*, NSPipe*);

@end

@implementation IRTask

-(instancetype) initWithLaunchPath: (NSString*) launchPath arguments: (NSArray*) args {
  return [self initWithLaunchPath:launchPath arguments:args workingDir:nil];
}

-(instancetype) initWithLaunchPath: (NSString*) launchPath arguments: (NSArray*) args workingDir: (NSString*) dir {
  self = [super init];
  if(self) {
    self.task = [self createTask];
    self.task.launchPath = launchPath;
    self.task.arguments = args;
    if(dir) {
      self.task.currentDirectoryPath = dir;
    }
  }
  return self;
}

-(void) runAsync:(void(^)(IRTask*, NSPipe*)) completionHandler {
  [self runAndWait:NO completion:completionHandler];
}

-(void) runSync:(void(^)(IRTask*, NSPipe*)) completionHandler {
  [self runAndWait:YES completion:completionHandler];
}

-(void) runAndWait:(BOOL) wait completion:(void(^)(IRTask*, NSPipe*)) completionHandler {
  if([self.task isRunning]) {
    return;
  }
  
  self.completionHandler = completionHandler;
  [self.task launch];
  
  if(wait) {
    [self.task waitUntilExit];
  }
}

-(NSTask*) createTask {
  NSTask* task = [[NSTask alloc] init];

  NSPipe *pipe=[NSPipe pipe];
  task.standardOutput = pipe;
  task.standardError = pipe;
  
  task.terminationHandler = [self getTerminationHandler];

  return task;
}

-(void(^)(NSTask *)) getTerminationHandler {
  __weak IRTask *weakSelf = self;
  return ^(NSTask *task) {
    __strong IRTask *strongSelf = weakSelf;
    if(strongSelf) {
      NSPipe *pipe = task.standardOutput;
      if(strongSelf.completionHandler) {
        strongSelf.completionHandler(strongSelf, pipe);
      }
      [strongSelf terminate];
    }
  };
}

-(void) terminate {
  self.completionHandler = nil;

  if([self.task isRunning]) {
    [self.task terminate];
  }
  
  self.task.standardOutput = nil;
  self.task.standardError = nil;
  self.task.terminationHandler = nil;
  self.task = nil;
}

@end
