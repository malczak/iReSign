//
//  IRResignTask.h
//  iReSign
//
//  Created by Mateusz Malczak on 07/04/16.
//  Copyright © 2016 nil. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IRResignTask;


@protocol IRResignTaskDelegate <NSObject>

@optional

-(void) resignTask:(IRResignTask * _Nonnull)task didSetStatus:(NSString * _Nonnull)string;

@end


@interface IRResignTask : NSObject

@property (nonatomic, strong) NSString * _Nullable appPath;

@property (nonatomic, strong) NSString * _Nullable sourcePath;

@property (nonatomic, strong) NSString * _Nullable provisioningPath;

@property (nonatomic, strong) NSString * _Nullable entitlementPath;

@property (nonatomic, strong) NSString * _Nullable certName;

@property (nonatomic, assign) BOOL changeBundleID;

@property (nonatomic, strong) NSString * _Nullable bundleID;

@property (nullable, assign) id<IRResignTaskDelegate> delegate;

-(void) resign;

@end
