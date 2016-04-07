//
//  IRResignTask.m
//  iReSign
//
//  Created by Mateusz Malczak on 07/04/16.
//  Copyright © 2016 nil. All rights reserved.
//

#import "IRResignTask.h"
#import "IRTask.h"

static NSString *kKeyBundleIDPlistApp               = @"CFBundleIdentifier";
static NSString *kKeyBundleIDPlistiTunesArtwork     = @"softwareVersionBundleId";
static NSString *kKeyInfoPlistApplicationProperties = @"ApplicationProperties";
static NSString *kKeyInfoPlistApplicationPath       = @"ApplicationPath";
static NSString *kFrameworksDirName                 = @"Frameworks";
static NSString *kPayloadDirName                    = @"Payload";
static NSString *kProductsDirName                   = @"Products";
static NSString *kInfoPlistFilename                 = @"Info.plist";
static NSString *kiTunesMetadataFileName            = @"iTunesMetadata";

#define STR_EMPTY(str) (!str || [str isEqualTo:@""])

@interface IRResignTask ()

@property (nonatomic, strong) IRTask *task;

@property (nonatomic, strong) NSString *workingPath;

@property (nonatomic, strong) NSString *appName;

@property (nonatomic, assign) BOOL hasFrameworks;

@property (nonatomic, strong) NSMutableArray *frameworks;

@property (nonatomic, strong) NSString* entitlementsResult;

@property (nonatomic, strong) NSString* codesigningResult;

@property (nonatomic, strong) NSString* verificationResult;

@property (nonatomic, strong) NSString* outputFile;

@end

@implementation IRResignTask

-(instancetype) init {
  self = [super init];
  if(self) {
    self.changeBundleID = NO;
    self.hasFrameworks = NO;
  }
  return self;
}

-(void) resign {
  //Save cert name
  
  self.entitlementsResult = nil;
  self.codesigningResult = nil;
  self.verificationResult = nil;
  
  NSString *sourcePath = self.sourcePath;
  self.workingPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.appulize.iresign"];
  
  if (self.certName) {
    if (([[[sourcePath pathExtension] lowercaseString] isEqualToString:@"ipa"]) ||
        ([[[sourcePath pathExtension] lowercaseString] isEqualToString:@"xcarchive"])) {
//      [self disableControls];
      
      NSLog(@"Setting up working directory in %@", self.workingPath);
//      [statusLabel setHidden:NO];
      [self status:@"Setting up working directory"];
      
      [[NSFileManager defaultManager] removeItemAtPath:self.workingPath error:nil];
      [[NSFileManager defaultManager] createDirectoryAtPath:self.workingPath withIntermediateDirectories:TRUE attributes:nil error:nil];
      
      if ([[[sourcePath pathExtension] lowercaseString] isEqualToString:@"ipa"]) {
        if (sourcePath && [sourcePath length] > 0) {
          NSLog(@"Unzipping %@",sourcePath);
          [self status:@"Extracting original app"];
        }
        
        
        __weak typeof(self) weakSelf = self;
        self.task = [[IRTask alloc] initWithLaunchPath:@"/usr/bin/unzip"
                                             arguments:@[@"-q", sourcePath, @"-d", self.workingPath]];
        [self.task runAsync:^(IRTask *task, NSPipe *pipe) {
          [weakSelf checkUnzip];
        }];
        
//        unzipTask = [[NSTask alloc] init];
//        [unzipTask setLaunchPath:@"/usr/bin/unzip"];
//        [unzipTask setArguments:[NSArray arrayWithObjects:@"-q", sourcePath, @"-d", workingPath, nil]];
//        
//        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkUnzip:) userInfo:nil repeats:TRUE];
//        
//        [unzipTask launch];
      }
      else {
        NSString* payloadPath = [self.workingPath stringByAppendingPathComponent:kPayloadDirName];
        
        NSLog(@"Setting up %@ path in %@", kPayloadDirName, payloadPath);
        [self status:[NSString stringWithFormat:@"Setting up %@ path", kPayloadDirName]];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:payloadPath withIntermediateDirectories:TRUE attributes:nil error:nil];
        
        NSLog(@"Retrieving %@", kInfoPlistFilename);
        [self status:[NSString stringWithFormat:@"Retrieving %@", kInfoPlistFilename]];
        
        NSString* infoPListPath = [sourcePath stringByAppendingPathComponent:kInfoPlistFilename];
        
        NSDictionary* infoPListDict = [NSDictionary dictionaryWithContentsOfFile:infoPListPath];
        
        if (infoPListDict != nil) {
          NSString* applicationPath = nil;
          
          NSDictionary* applicationPropertiesDict = [infoPListDict objectForKey:kKeyInfoPlistApplicationProperties];
          
          if (applicationPropertiesDict != nil) {
            applicationPath = [applicationPropertiesDict objectForKey:kKeyInfoPlistApplicationPath];
          }
          
          if (applicationPath != nil) {
            applicationPath = [[sourcePath stringByAppendingPathComponent:kProductsDirName] stringByAppendingPathComponent:applicationPath];
            
            NSLog(@"Copying %@ to %@ path in %@", applicationPath, kPayloadDirName, payloadPath);
            [self status:[NSString stringWithFormat:@"Copying .xcarchive app to %@ path", kPayloadDirName]];
            
            __weak typeof(self) weakSelf = self;
            self.task = [[IRTask alloc] initWithLaunchPath:@"/bin/cp"
                                                 arguments:@[@"-r", applicationPath, payloadPath]];
            [self.task runAsync:^(IRTask *task, NSPipe *pipe) {
              [weakSelf checkCopy];
            }];

//            copyTask = [[NSTask alloc] init];
//            [copyTask setLaunchPath:@"/bin/cp"];
//            [copyTask setArguments:[NSArray arrayWithObjects:@"-r", applicationPath, payloadPath, nil]];
//            
//            [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCopy:) userInfo:nil repeats:TRUE];
//            
//            [copyTask launch];
          }
          else {
//            [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:[NSString stringWithFormat:@"Unable to parse %@", kInfoPlistFilename]];
//            [self enableControls];
            [self status:@"Ready"];
          }
        }
        else {
//          [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:[NSString stringWithFormat:@"Retrieve %@ failed", kInfoPlistFilename]];
//          [self enableControls];
          [self status:@"Ready"];
        }
      }
    }
    else {
//      [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"You must choose an *.ipa or *.xcarchive file"];
//      [self enableControls];
      [self status:@"Please try again"];
    }
  } else {
//    [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"You must choose an signing certificate from dropdown."];
//    [self enableControls];
    [self status:@"Please try again"];
  }
}

- (void)checkUnzip {
  if ([[NSFileManager defaultManager] fileExistsAtPath:[self.workingPath stringByAppendingPathComponent:kPayloadDirName]]) {
    NSLog(@"Unzipping done");
    [self status:@"Original app extracted"];
    
    [self processWorkingDir];
  } else {
//    [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"Unzip failed"];
//    [self enableControls];
    [self status:@"Ready"];
  }
}

- (void)checkCopy {
  NSLog(@"Copy done");
      [self status:@".xcarchive app copied"];
  
  [self processWorkingDir];
}

- (void)processWorkingDir {
  if (self.changeBundleID) {
    [self doBundleIDChange:self.bundleID];
  }
  
  if (STR_EMPTY(self.provisioningPath)) {
    [self doCodeSigning];
  } else {
    [self doProvisioning];
  }
}

- (BOOL)doBundleIDChange:(NSString *)newBundleID {
  BOOL success = YES;
  
  success &= [self doAppBundleIDChange:newBundleID];
  success &= [self doITunesMetadataBundleIDChange:newBundleID];
  
  return success;
}


- (BOOL)doITunesMetadataBundleIDChange:(NSString *)newBundleID {
  NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.workingPath error:nil];
  NSString *infoPlistPath = nil;
  
  for (NSString *file in dirContents) {
    if ([[[file pathExtension] lowercaseString] isEqualToString:@"plist"]) {
      infoPlistPath = [self.workingPath stringByAppendingPathComponent:file];
      break;
    }
  }
  
  return [self changeBundleIDForFile:infoPlistPath bundleIDKey:kKeyBundleIDPlistiTunesArtwork newBundleID:newBundleID plistOutOptions:NSPropertyListXMLFormat_v1_0];
  
}

- (BOOL)doAppBundleIDChange:(NSString *)newBundleID {
  NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self.workingPath stringByAppendingPathComponent:kPayloadDirName] error:nil];
  NSString *infoPlistPath = nil;
  
  for (NSString *file in dirContents) {
    if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
      infoPlistPath = [[[self.workingPath stringByAppendingPathComponent:kPayloadDirName]
                        stringByAppendingPathComponent:file]
                       stringByAppendingPathComponent:kInfoPlistFilename];
      break;
    }
  }
  
  return [self changeBundleIDForFile:infoPlistPath bundleIDKey:kKeyBundleIDPlistApp newBundleID:newBundleID plistOutOptions:NSPropertyListBinaryFormat_v1_0];
}

- (BOOL)changeBundleIDForFile:(NSString *)filePath bundleIDKey:(NSString *)bundleIDKey newBundleID:(NSString *)newBundleID plistOutOptions:(NSPropertyListWriteOptions)options {
  
  NSMutableDictionary *plist = nil;
  
  if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    plist = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    [plist setObject:newBundleID forKey:bundleIDKey];
    
    NSData *xmlData = [NSPropertyListSerialization dataWithPropertyList:plist format:options options:kCFPropertyListImmutable error:nil];
    
    return [xmlData writeToFile:filePath atomically:YES];
    
  }
  
  return NO;
}


- (void)doProvisioning {
  NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self.workingPath stringByAppendingPathComponent:kPayloadDirName] error:nil];
  
  for (NSString *file in dirContents) {
    if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
      self.appPath = [[self.workingPath stringByAppendingPathComponent:kPayloadDirName] stringByAppendingPathComponent:file];
      if ([[NSFileManager defaultManager] fileExistsAtPath:[self.appPath stringByAppendingPathComponent:@"embedded.mobileprovision"]]) {
        NSLog(@"Found embedded.mobileprovision, deleting.");
        [[NSFileManager defaultManager] removeItemAtPath:[self.appPath stringByAppendingPathComponent:@"embedded.mobileprovision"] error:nil];
      }
      break;
    }
  }
  
  NSString *targetPath = [self.appPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
  
  __weak typeof(self) weakSelf = self;
  self.task = [[IRTask alloc] initWithLaunchPath:@"/bin/cp"
                                       arguments:@[self.provisioningPath, targetPath]];
  [self.task runAsync:^(IRTask *task, NSPipe *pipe) {
    [weakSelf checkProvisioning];
  }];
  
//  provisioningTask = [[NSTask alloc] init];
//  [provisioningTask setLaunchPath:@"/bin/cp"];
//  [provisioningTask setArguments:[NSArray arrayWithObjects:[provisioningPathField stringValue], targetPath, nil]];
//  
//  [provisioningTask launch];
//  
//  [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkProvisioning:) userInfo:nil repeats:TRUE];
}

- (void)checkProvisioning {
  
  NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self.workingPath stringByAppendingPathComponent:kPayloadDirName] error:nil];
  
  for (NSString *file in dirContents) {
    if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
      self.appPath = [[self.workingPath stringByAppendingPathComponent:kPayloadDirName] stringByAppendingPathComponent:file];
      if ([[NSFileManager defaultManager] fileExistsAtPath:[self.appPath stringByAppendingPathComponent:@"embedded.mobileprovision"]]) {
        
        BOOL identifierOK = FALSE;
        NSString *identifierInProvisioning = @"";
        
        NSString *embeddedProvisioning = [NSString stringWithContentsOfFile:[self.appPath stringByAppendingPathComponent:@"embedded.mobileprovision"] encoding:NSASCIIStringEncoding error:nil];
        NSArray* embeddedProvisioningLines = [embeddedProvisioning componentsSeparatedByCharactersInSet:
                                              [NSCharacterSet newlineCharacterSet]];
        
        for (int i = 0; i < [embeddedProvisioningLines count]; i++) {
          if ([[embeddedProvisioningLines objectAtIndex:i] rangeOfString:@"application-identifier"].location != NSNotFound) {
            
            NSInteger fromPosition = [[embeddedProvisioningLines objectAtIndex:i+1] rangeOfString:@"<string>"].location + 8;
            
            NSInteger toPosition = [[embeddedProvisioningLines objectAtIndex:i+1] rangeOfString:@"</string>"].location;
            
            NSRange range;
            range.location = fromPosition;
            range.length = toPosition-fromPosition;
            
            NSString *fullIdentifier = [[embeddedProvisioningLines objectAtIndex:i+1] substringWithRange:range];
            
            NSArray *identifierComponents = [fullIdentifier componentsSeparatedByString:@"."];
            
            if ([[identifierComponents lastObject] isEqualTo:@"*"]) {
              identifierOK = TRUE;
            }
            
            for (int i = 1; i < [identifierComponents count]; i++) {
              identifierInProvisioning = [identifierInProvisioning stringByAppendingString:[identifierComponents objectAtIndex:i]];
              if (i < [identifierComponents count]-1) {
                identifierInProvisioning = [identifierInProvisioning stringByAppendingString:@"."];
              }
            }
            break;
          }
        }
        
        NSLog(@"Mobileprovision identifier: %@",identifierInProvisioning);
        
        NSDictionary *infoplist = [NSDictionary dictionaryWithContentsOfFile:[self.appPath stringByAppendingPathComponent:@"Info.plist"]];
        if ([identifierInProvisioning isEqualTo:[infoplist objectForKey:kKeyBundleIDPlistApp]]) {
          NSLog(@"Identifiers match");
          identifierOK = TRUE;
        }
        
        if (identifierOK) {
          NSLog(@"Provisioning completed.");
          [self status:@"Provisioning completed"];
          [self doEntitlementsFixing];
        } else {
//          [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"Product identifiers don't match"];
//          [self enableControls];
          [self status:@"Ready"];
        }
      } else {
//        [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"Provisioning failed"];
//        [self enableControls];
        [self status:@"Ready"];
      }
      break;
    }
  }
}

- (void)doEntitlementsFixing
{
//  if (![entitlementField.stringValue isEqualToString:@""] || [provisioningPathField.stringValue isEqualToString:@""]) {
//  }
  if(!STR_EMPTY(self.entitlementPath) || STR_EMPTY(self.provisioningPath)) {
    [self doCodeSigning];
    return; // Using a pre-made entitlements file or we're not re-provisioning.
  }
  
  [self status:@"Generating entitlements"];
  
  if (self.appPath) {
    
    __weak typeof(self) weakSelf = self;
    self.task = [[IRTask alloc] initWithLaunchPath:@"/usr/bin/security"
                                         arguments:@[@"cms", @"-D", @"-i", self.provisioningPath]
                                        workingDir:self.workingPath];
    [self.task runAsync:^(IRTask *task, NSPipe *pipe) {
      NSFileHandle *handle = [pipe fileHandleForReading];
      NSString *entitlementsResult = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
      [weakSelf doEntitlementsEdit:entitlementsResult];
    }];

//    
//    generateEntitlementsTask = [[NSTask alloc] init];
//    [generateEntitlementsTask setLaunchPath:@"/usr/bin/security"];
//    [generateEntitlementsTask setArguments:@[@"cms", @"-D", @"-i", provisioningPathField.stringValue]];
//    [generateEntitlementsTask setCurrentDirectoryPath:workingPath];
//    
//    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkEntitlementsFix:) userInfo:nil repeats:TRUE];
//    
//    NSPipe *pipe=[NSPipe pipe];
//    [generateEntitlementsTask setStandardOutput:pipe];
//    [generateEntitlementsTask setStandardError:pipe];
//    NSFileHandle *handle = [pipe fileHandleForReading];
//    
//    [generateEntitlementsTask launch];
//    
//    [NSThread detachNewThreadSelector:@selector(watchEntitlements:)
//                             toTarget:self withObject:handle];
  }
}
//
//- (void)watchEntitlements:(NSFileHandle*)streamHandle {
//  @autoreleasepool {
//    entitlementsResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
//  }
//}
//
//- (void)checkEntitlementsFix:(NSTimer *)timer {
//  if ([generateEntitlementsTask isRunning] == 0) {
//    [timer invalidate];
//    generateEntitlementsTask = nil;
//    NSLog(@"Entitlements fixed done");
//    [self status:@"Entitlements generated"];
//    [self doEntitlementsEdit];
//  }
//}

- (void)doEntitlementsEdit:(NSString*) entitlementsResult
{
  self.entitlementsResult = entitlementsResult;
  NSDictionary* entitlements = entitlementsResult.propertyList;
  entitlements = entitlements[@"Entitlements"];
  NSString* filePath = [self.workingPath stringByAppendingPathComponent:@"entitlements.plist"];
  NSData *xmlData = [NSPropertyListSerialization dataWithPropertyList:entitlements format:NSPropertyListXMLFormat_v1_0 options:kCFPropertyListImmutable error:nil];
  if(![xmlData writeToFile:filePath atomically:YES]) {
    NSLog(@"Error writing entitlements file.");
//    [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"Failed entitlements generation"];
//    [self enableControls];
    [self status:@"Ready"];
  }
  else {
//    entitlementField.stringValue = filePath;
    [self doCodeSigning];
  }
}

- (void)doCodeSigning {
  self.appPath = nil;
  NSString *frameworksDirPath = nil;
  self.hasFrameworks = NO;
  self.frameworks = [[NSMutableArray alloc] init];
  
  NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self.workingPath stringByAppendingPathComponent:kPayloadDirName] error:nil];
  
  for (NSString *file in dirContents) {
    if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
      self.appPath = [[self.workingPath stringByAppendingPathComponent:kPayloadDirName] stringByAppendingPathComponent:file];
      frameworksDirPath = [self.appPath stringByAppendingPathComponent:kFrameworksDirName];
      NSLog(@"Found %@",self.appPath);
      self.appName = file;
      if ([[NSFileManager defaultManager] fileExistsAtPath:frameworksDirPath]) {
        NSLog(@"Found %@",frameworksDirPath);
        self.hasFrameworks = YES;
        NSArray *frameworksContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:frameworksDirPath error:nil];
        for (NSString *frameworkFile in frameworksContents) {
          NSString *extension = [[frameworkFile pathExtension] lowercaseString];
          if ([extension isEqualTo:@"framework"] || [extension isEqualTo:@"dylib"]) {
            NSString *frameworkPath = [frameworksDirPath stringByAppendingPathComponent:frameworkFile];
            NSLog(@"Found %@",frameworkPath);
            [self.frameworks addObject:frameworkPath];
          }
        }
      }
      [self status:[NSString stringWithFormat:@"Codesigning %@",file]];
      break;
    }
  }
  
  if (self.appPath) {
    if (self.hasFrameworks) {
      [self signFile:[self.frameworks lastObject]];
      [self.frameworks removeLastObject];
    } else {
      [self signFile:self.appPath];
    }
  }
}

- (void)signFile:(NSString*)filePath {
  NSLog(@"Codesigning %@", filePath);
  [self status:[NSString stringWithFormat:@"Codesigning %@",filePath]];
  
  NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"-fs", self.certName, nil];
  NSDictionary *systemVersionDictionary = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
  NSString * systemVersion = [systemVersionDictionary objectForKey:@"ProductVersion"];
  NSArray * version = [systemVersion componentsSeparatedByString:@"."];
  if ([version[0] intValue]<10 || ([version[0] intValue]==10 && ([version[1] intValue]<9 || ([version[1] intValue]==9 && [version[2] intValue]<5)))) {
    
    // Before OSX 10.9, code signing requires a version 1 signature.
    // The resource envelope is necessary.
    // To ensure it is added, append the resource flag to the arguments.
    
    NSString *resourceRulesPath = [[NSBundle mainBundle] pathForResource:@"ResourceRules" ofType:@"plist"];
    NSString *resourceRulesArgument = [NSString stringWithFormat:@"--resource-rules=%@",resourceRulesPath];
    [arguments addObject:resourceRulesArgument];
  } else {
    
    
    // For OSX 10.9 and later, code signing requires a version 2 signature.
    // The resource envelope is obsolete.
    // To ensure it is ignored, remove the resource key from the Info.plist file.
    
    
    NSString *infoPath = [NSString stringWithFormat:@"%@/Info.plist", filePath];
    NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:infoPath];
    [infoDict removeObjectForKey:@"CFBundleResourceSpecification"];
    [infoDict writeToFile:infoPath atomically:YES];
    [arguments addObject:@"--no-strict"]; // http://stackoverflow.com/a/26204757
  }
  
  if(!STR_EMPTY(self.entitlementPath)) {
//  if (![[entitlementField stringValue] isEqualToString:@""]) {
    [arguments addObject:[NSString stringWithFormat:@"--entitlements=%@", self.entitlementPath]];
  }
  
  [arguments addObjectsFromArray:[NSArray arrayWithObjects:filePath, nil]];
  
  __weak typeof(self) weakSelf = self;
  self.task = [[IRTask alloc] initWithLaunchPath:@"/usr/bin/codesign"
                                       arguments:arguments];
  [self.task runAsync:^(IRTask *task, NSPipe *pipe) {
    NSFileHandle *handle = [pipe fileHandleForReading];
    NSString *codesigningResult = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
    [weakSelf checkCodesigning:codesigningResult];
  }];
  
//  codesignTask = [[NSTask alloc] init];
//  [codesignTask setLaunchPath:@"/usr/bin/codesign"];
//  [codesignTask setArguments:arguments];
//  
//  [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCodesigning:) userInfo:nil repeats:TRUE];
//  
//  
//  NSPipe *pipe=[NSPipe pipe];
//  [codesignTask setStandardOutput:pipe];
//  [codesignTask setStandardError:pipe];
//  NSFileHandle *handle=[pipe fileHandleForReading];
//  
//  [codesignTask launch];
//  
//  [NSThread detachNewThreadSelector:@selector(watchCodesigning:)
//                           toTarget:self withObject:handle];
}

//- (void)watchCodesigning:(NSFileHandle*)streamHandle {
//  @autoreleasepool {
//    
//    codesigningResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
//    
//  }
//}

- (void)checkCodesigning:(NSString *)codesigningResult {
  self.codesigningResult = codesigningResult;
  
  if (self.frameworks.count > 0) {
    [self signFile:[self.frameworks lastObject]];
    [self.frameworks removeLastObject];
  } else if (self.hasFrameworks) {
    self.hasFrameworks = NO;
    [self signFile:self.appPath];
  } else {
    NSLog(@"Codesigning done");
    [self status:@"Codesigning completed"];
    [self doVerifySignature];
  }
}

- (void)doVerifySignature {
  if (self.appPath) {
    
    __weak typeof(self) weakSelf = self;
    self.task = [[IRTask alloc] initWithLaunchPath:@"/usr/bin/codesign"
                                         arguments:@[@"-v", self.appPath]];
    [self.task runAsync:^(IRTask *task, NSPipe *pipe) {
      NSFileHandle *handle = [pipe fileHandleForReading];
      NSString *verificationResult = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
      [weakSelf checkVerificationProcess:verificationResult];
    }];
    
//    verifyTask = [[NSTask alloc] init];
//    [verifyTask setLaunchPath:@"/usr/bin/codesign"];
//    [verifyTask setArguments:[NSArray arrayWithObjects:@"-v", appPath, nil]];
    
//    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkVerificationProcess:) userInfo:nil repeats:TRUE];
    
//    NSLog(@"Verifying %@",appPath);
//    [self status:[NSString stringWithFormat:@"Verifying %@",self.appName]];
    
//    NSPipe *pipe=[NSPipe pipe];
//    [verifyTask setStandardOutput:pipe];
//    [verifyTask setStandardError:pipe];
//    NSFileHandle *handle=[pipe fileHandleForReading];
//    
//    [verifyTask launch];
//    
//    [NSThread detachNewThreadSelector:@selector(watchVerificationProcess:)
//                             toTarget:self withObject:handle];
  }
}

//- (void)watchVerificationProcess:(NSFileHandle*)streamHandle {
//  @autoreleasepool {
//    
//    verificationResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
//    
//  }
//}

- (void)checkVerificationProcess:(NSString *)verificationResult {
  self.verificationResult = verificationResult;

  if ([verificationResult length] == 0) {
    NSLog(@"Verification done");
    [self status:@"Verification completed"];
    [self doZip];
  } else {
//    NSString *error = [[self.codesigningResult stringByAppendingString:@"\n\n"] stringByAppendingString:verificationResult];
//    [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Signing failed" AndMessage:error];
//    [self enableControls];
    [self status:@"Please try again"];
  }
}

- (void)doZip {
  if (self.appPath) {
    NSArray *destinationPathComponents = [self.sourcePath pathComponents];
    NSString *destinationPath = @"";
    
    for (int i = 0; i < ([destinationPathComponents count]-1); i++) {
      destinationPath = [destinationPath stringByAppendingPathComponent:[destinationPathComponents objectAtIndex:i]];
    }
    
    NSString *fileName = [self.sourcePath lastPathComponent];
    fileName = [fileName substringToIndex:([fileName length] - ([[self.sourcePath pathExtension] length] + 1))];
    fileName = [fileName stringByAppendingString:@"-resigned"];
    fileName = [fileName stringByAppendingPathExtension:@"ipa"];
    self.outputFile = fileName;
    
    destinationPath = [destinationPath stringByAppendingPathComponent:fileName];
    
    NSLog(@"Dest: %@",destinationPath);
    
    __weak typeof(self) weakSelf = self;
    self.task = [[IRTask alloc] initWithLaunchPath:@"/usr/bin/zip"
                                         arguments:@[@"-qry", destinationPath, @"."]
                                        workingDir:self.workingPath];
    [self.task runAsync:^(IRTask *task, NSPipe *pipe) {
      [weakSelf checkZip];
    }];

    
//    zipTask = [[NSTask alloc] init];
//    [zipTask setLaunchPath:@"/usr/bin/zip"];
//    [zipTask setCurrentDirectoryPath:workingPath];
//    [zipTask setArguments:[NSArray arrayWithObjects:@"-qry", destinationPath, @".", nil]];
    
//    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkZip:) userInfo:nil repeats:TRUE];
    
//    NSLog(@"Zipping %@", destinationPath);
    [self status:[NSString stringWithFormat:@"Saving %@",fileName]];
//
//    [zipTask launch];
  }
}

- (void)checkZip {
  NSLog(@"Zipping done");
  [self status:[NSString stringWithFormat:@"Saved %@",self.outputFile]];
  
//  [self enableControls];
  
  NSString *result = [[self.codesigningResult stringByAppendingString:@"\n\n"] stringByAppendingString:self.verificationResult];
  NSLog(@"Codesigning result: %@",result);
  
  [self cleanUp];
}

-(void) cleanUp {
  [[NSFileManager defaultManager] removeItemAtPath:self.workingPath error:nil];
  self.task = nil;
  self.delegate = nil;
}

#pragma mark print status
-(void) status:(NSString *)statusText {
  
  if(self.delegate) {
    if([self.delegate respondsToSelector:@selector(resignTask:didSetStatus:)]) {
      [self.delegate resignTask:self didSetStatus:statusText];
    }
  }
}

@end
