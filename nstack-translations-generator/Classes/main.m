//
//  main.m
//  nstack-translations-generator
//
//  Created by Dominik Hádl on 07/02/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

#import <Foundation/Foundation.h>
@import TranslationsGenerator;

SInt32 resultCode = 0;

int main(int argc, const char * argv[]) {
    @autoreleasepool {

        // Create empty typed array
        NSMutableArray <NSString *> *arguments = [NSMutableArray new];

        // Parse arguments we get into a string array
        for (int i = 0; i < argc; i++) {
            [arguments addObject:[NSString stringWithUTF8String:argv[i]]];
        }

        // Pass it onto the translations generator
        NSError *error;
        [TranslationsGenerator generate:arguments error:&error];

        if (error) {
            // Handle errors
            NSLog(@"%@", error.localizedDescription);
        }

        while (1)
        {
            @autoreleasepool
            {
                resultCode = CFRunLoopRunInMode(kCFRunLoopDefaultMode, DBL_MAX, false);
            }

            if (kCFRunLoopRunStopped == resultCode || kCFRunLoopRunFinished == resultCode)
                break;
        }

        return 0;
    }
}
