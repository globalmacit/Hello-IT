//
//  HITPTestHTTP.m
//  TestHTTP
//
//  Created by Yoann Gini on 12/07/2015.
//  Copyright (c) 2015 Yoann Gini (Open Source Project). All rights reserved.
//

#import "HITPTestHTTP.h"

#define kHITPTestHTTPTitle @"title"
#define kHITPTestHTTPURL @"URL"
#define kHITPTestHTTPStringToCompare @"originalString"
#define kHITPTestHTTPMode @"mode"
#define kHITPTestHTTPRepeate @"repeate"
#define kHITPTestHTTPTimeout @"timeout"

@interface HITPTestHTTP ()
@property NSString *title;
@property NSURL *testPage;
@property NSString *mode;
@property NSString *originalString;
@property NSNumber *repeate;
@property HITPluginTestState state;
@property NSTimer *cron;
@property NSMenuItem *menuItem;
@property NSInteger timeout;
@end


@implementation HITPTestHTTP

+ (id<HITPluginProtocol>)newPlugInInstanceWithSettings:(NSDictionary*)settings {
    id instance = [[self alloc] initWithSettings:settings];
    return instance;
}

- (instancetype)initWithSettings:(NSDictionary*)settings
{
    self = [super init];
    if (self) {
        _title = [settings objectForKey:kHITPTestHTTPTitle];
        _testPage = [NSURL URLWithString:[settings objectForKey:kHITPTestHTTPURL]];
        _mode = [settings objectForKey:kHITPTestHTTPMode];
        _originalString = [settings objectForKey:kHITPTestHTTPStringToCompare];
        _repeate = [settings objectForKey:kHITPTestHTTPRepeate];
        
        _menuItem = [[NSMenuItem alloc] initWithTitle:self.title
                                               action:NULL
                                        keyEquivalent:@""];
        
        [_menuItem setState:NSMixedState];
        
        NSNumber *timeout = [settings objectForKey:kHITPTestHTTPTimeout];
        if (timeout) {
            _timeout = [timeout integerValue];
        } else {
            _timeout = 30;
        }
        
        
        if ([_repeate intValue] > 0) {
            _cron = [NSTimer scheduledTimerWithTimeInterval:[_repeate integerValue]
                                                     target:self
                                                   selector:@selector(runTheTest:)
                                                   userInfo:nil
                                                    repeats:YES];
            
            [_cron fire];
        } else {
            [self runTheTest];
        }
    }
    return self;
}

- (void)updateMenuItemState {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (self.state) {
            case HITPluginTestStateRed:
                self.menuItem.state = NSOffState;
                break;
            case HITPluginTestStateGreen:
                self.menuItem.state = NSOnState;
                break;
            case HITPluginTestStateOrange:
            default:
                self.menuItem.state = NSMixedState;
                break;
        }
    });
}

- (void)runTheTest:(NSTimer*)timer {
    [self runTheTest];
}

- (void)runTheTest {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:self.testPage
                                                                  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                              timeoutInterval:self.timeout]
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   if (connectionError) {
                                       self.state = HITPluginTestStateRed;
                                   } else {
                                       NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                       
                                       if ([self.mode isEqualToString:@"compare"]) {
                                           if ([content isEqualToString:self.originalString]) {
                                               self.state = HITPluginTestStateGreen;
                                           } else {
                                               self.state = HITPluginTestStateOrange;
                                           }
                                       } else if ([self.mode isEqualToString:@"contain"]) {
                                           if ([content containsString:self.originalString]) {
                                               self.state = HITPluginTestStateGreen;
                                           } else {
                                               self.state = HITPluginTestStateOrange;
                                           }
                                       }
                                   }
                                   
                                   [self updateMenuItemState];
                               }];
        
    });
}

@end