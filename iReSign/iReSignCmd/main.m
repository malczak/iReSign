//
//  main.m
//  iReSignCmd
//
//  Created by Mateusz Malczak on 06/04/16.
//  Copyright © 2016 nil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "argtable2/include/argtable2.h"
#import "IRResignTask.h"
#import "IRCertFetcher.h"

const char * const progname = "iresign";
const char * const progress = "-\\|/";

@interface Resign : NSObject <IRResignTaskDelegate>

@property (nonatomic, readonly) BOOL running;

@property (nonatomic, readonly) IRResignTask *resignTask;

@property (nonatomic, strong) NSString *currentStatus;

-(void) run;

@end

@implementation Resign

-(instancetype) init {
  self = [super init];
  if(self) {
    _running = NO;
    _resignTask = [self createResignTask];
  }
  return self;
}

-(void) run {
  if(self.running) {
    return;
  }
  [self.resignTask resign];
  
  uint8 i = 0;
  uint8 c = strlen(progress);
  while(self.running) {
    
    printf("\r%s %c", [self.currentStatus UTF8String], progress[i]);
    fflush(stdout);
    i = (i + 1) % c;
    usleep(500);
  }
  
}

-(IRResignTask*) createResignTask {
  IRResignTask* task = [[IRResignTask alloc] init];
  task.delegate = self;
  return task;
}

-(void)resignTaskDidStart:(IRResignTask *) task
{
  _running = YES;
}

-(void)resignTaskDidComplete:(IRResignTask *)task
{
  _running = NO;
}

-(void)resignTaskDidComplete:(IRResignTask *)task withError:(NSError *)error
{
  // @todo
}

-(void) resignTask:(IRResignTask *)task didSetStatus:(NSString *)string
{
  NSString *oldStatus = self.currentStatus;
  if(oldStatus) {
    printf("\r%s   \n", [self.currentStatus UTF8String]);
  }
  self.currentStatus = string;
}

@end

void** argtable;

void show_help()
{
  printf("Usage:");
  arg_print_syntax(stdout,argtable,"\n");
  printf("Resign IPA file. ]:-> \n\n");
  arg_print_glossary(stdout,argtable,"  %-10s %s\n");
  printf("\n");
}

void list_certificates()
{
  IRCertFetcher *certFetcher = [[IRCertFetcher alloc] init];
  [certFetcher getCertsSyncWithCompletion:^(NSArray *certificates) {
    NSUInteger index = 0;
    for (NSString * cert in certificates) {
      printf("\t%lu. %s\n", (unsigned long)index, [cert UTF8String]);
      index += 1;
    }
  }];
}

int main(int argc, char **argv) {
  @autoreleasepool {
    
    /* Define the allowable command line options, collecting them in argtable[] */
    struct arg_file *ipa  = arg_file1("i", "ipa", "ipa", "ipa to be resigned installed certificates");
    struct arg_file *prov = arg_file0("m", "mobileprov", "mobileprov", "mobile provisioning to be used in resigning");
    struct arg_file *ent  = arg_file0("e", "entitlements", "entitlements", "entitlements file to be used");
    struct arg_str *cert  = arg_str1("c", "certificate", "cert", "certificate to be used for resigning");
    struct arg_str *pass  = arg_str0("p", "password", "pass", "certificate password");
    struct arg_str *bund  = arg_str0("b", "bundle", "bundleId", "new bundle id to be used");
    struct arg_lit *list  = arg_lit0(NULL, "list-certs", "list installed certificates");
    struct arg_lit *help  = arg_lit0(NULL, "help", "print this help and exit");
    struct arg_end *end   = arg_end(20);
    void* table[] = {
      ipa,
      prov,
      ent,
      cert,
      pass,
      bund,
      list,
      help,
      end
    };
    argtable = table;
    
    
    /* verify the argtable[] entries were allocated sucessfully */
    if (arg_nullcheck(argtable) != 0)
    {
      return 0;
    }
    
    int done = 0;
    
    /* Parse the command line as defined by argtable[] */
    int nerrors = arg_parse(argc,argv,argtable);

    /* special case: '--help' takes precedence over everything */
    if (!done && help->count > 0)
    {
      show_help();
      done = 1;
    }
    
    /* special case: '--list' takes precedence over actions */
    if (!done && list->count > 0)
    {
      printf("Getting available certificates list\n");
      list_certificates();
      done = 1;
    }
    
    /* If the parser returned any errors then display them and exit */
    if (!done && ((argc == 1) || nerrors > 0))
    {
      /* Display the error details contained in the arg_end struct.*/
      arg_print_errors(stdout,end,progname);
      printf("Try '%s --help' for more information.\n",progname);
      done = 1;
    }
    
    if(!done) {
      NSString *sourcePath, *certName;
      
      if(ipa->count > 0)
      {
        sourcePath = [NSString stringWithUTF8String:ipa->filename[0]];
        NSLog(@"Using source file '%@'\n", sourcePath);
      }
      
      if(cert->count > 0)
      {
        certName = [NSString stringWithUTF8String:cert->sval[0]];
        if([certName hasPrefix:@"@"]) {
          __block NSString *certNameAtIndex = nil;

          NSInteger certIdx = [[certName substringFromIndex:1] integerValue];
          IRCertFetcher *certFetcher = [[IRCertFetcher alloc] init];
          [certFetcher getCertsSyncWithCompletion:^(NSArray *certificates) {
            certNameAtIndex = (certIdx < [certificates count]) ? [certificates objectAtIndex:certIdx] : nil;
          }];
          
          certName = certNameAtIndex;
        }
        
        if(!certName) {
          NSLog(@"Unknown certificate. Available certificates\n");
          list_certificates();
          done = 1;
        } else {
          NSLog(@"Using certificate '%@'\n", certName);
        }
      }
      
      if(!done) {
        
        Resign *resign = [[Resign alloc] init];

        IRResignTask *task = resign.resignTask;
        task.sourcePath = sourcePath;
        task.certName = certName;
        
        if(prov->count > 0) {
          task.provisioningPath = [NSString stringWithUTF8String:prov->filename[0]];
          NSLog(@"Using provisioning file '%@'\n", task.provisioningPath);
        }
        
        if(ent->count > 0) {
          task.entitlementPath = [NSString stringWithUTF8String:ent->filename[0]];
          NSLog(@"Using entitlement file '%@'\n", task.entitlementPath);
        }
        
        if(bund->count > 0) {
          NSString *bundleId = [[NSString stringWithUTF8String:bund->sval[0]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
          if([bundleId isEqualToString:@""]){
            task.changeBundleID = YES;
            task.bundleID = bundleId;
          }
        }
        
        [resign run];
      }

    }
    
     arg_freetable(argtable,sizeof(argtable)/sizeof(argtable[0]));
  }

  return 0;
}
