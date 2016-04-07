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

@interface Resign : NSObject

@end

@implementation Resign

-(void) resign {
  IRResignTask *task = [[IRResignTask alloc] init];
//  task.delegate = self;
//  task.sourcePath = [pathField stringValue];
//  task.provisioningPath = [provisioningPathField stringValue];
//  task.entitlementPath = [entitlementField stringValue];
//  task.certName = [certComboBox stringValue];
  
//  if (changeBundleIDCheckbox.state == NSOnState) {
//    task.changeBundleID = YES;
//    task.bundleID = bundleIDField.stringValue;
//  }
  
  
  [task resign];
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
      NSLog(@"%u. %@", index, cert);
      index += 1;
    }
  }];
}

int main(int argc, char **argv) {
  @autoreleasepool {
    
    /* Define the allowable command line options, collecting them in argtable[] */
    struct arg_file *ipa  = arg_file0("i", "ipa", "ipa", "ipa to be resigned installed certificates");
    struct arg_file *prov = arg_file0("m", "mobileprov", "mobileprov", "mobile provisioning to be used in resigning");
    struct arg_file *ent  = arg_file0("e", "entitlements", "entitlements", "entitlements file to be used");
    struct arg_str *cert  = arg_str0("c", "certificate", "cert", "certificate to be used for resigning");
    struct arg_str *pass  = arg_str0("p", "password", "pass", "certificate password");
    struct arg_lit *list  = arg_lit0(NULL, "list-certs", "list installed certificates");
    struct arg_lit *help  = arg_lit0(NULL, "help", "print this help and exit");
    struct arg_end *end   = arg_end(20);
    void* table[] = {
      ipa,
      prov,
      ent,
      cert,
      pass,
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
    
    /* If the parser returned any errors then display them and exit */
    if ((argc == 1) || nerrors > 0)
    {
      /* Display the error details contained in the arg_end struct.*/
      arg_print_errors(stdout,end,progname);
      printf("Try '%s --help' for more information.\n",progname);
      done = 1;
    }

    /* special case: '--help' takes precedence over everything */
    if (!done && help->count > 0)
    {
      show_help();
      done = 1;
    }

    
    /* special case: '--list' takes precedence over actions */
    if (!done && list->count > 0)
    {
      NSLog(@"Getting Certificate IDs");
      list_certificates();
      done = 1;
    }
    
     arg_freetable(argtable,sizeof(argtable)/sizeof(argtable[0]));
  }

  return 0;
}
