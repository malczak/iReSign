//
//  main.m
//  iReSignCmd
//
//  Created by Mateusz Malczak on 06/04/16.
//  Copyright © 2016 nil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "argtable2/include/argtable2.h"
#import "IRCertFetcher.h"

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
    void* argtable[] = {
      ipa,
      prov,
      ent,
      cert,
      pass,
      list,
      help,
      end
    };
    
    
    /* verify the argtable[] entries were allocated sucessfully */
    if (arg_nullcheck(argtable) != 0)
    {
      return 0;
    }
    
    /* Parse the command line as defined by argtable[] */
    int nerrors = arg_parse(argc,argv,argtable);
    
    /* special case: '--help' takes precedence over everything */
    if (help->count > 0)
    {
      printf("Usage:");
      arg_print_syntax(stdout,argtable,"\n");
      printf("Resign IPA file. ]:-> \n\n");
      arg_print_glossary(stdout,argtable,"  %-10s %s\n");
      printf("\n");
      return 0;
    }

    
    /* special case: '--list' takes precedence over actions */
    if (list->count > 0)
    {
      NSLog(@"Getting Certificate IDs");
      
      IRCertFetcher *certFetcher = [[IRCertFetcher alloc] init];
      [certFetcher getCertsSyncWithCompletion:^(NSArray *certificates) {
        NSUInteger index = 0;
        for (NSString * cert in certificates) {
          NSLog(@"%u. %@", index, cert);
          index += 1;
        }
      }];
      
      return 0;
    }

  }

  return 0;
}
