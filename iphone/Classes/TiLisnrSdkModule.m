/**
 * LisnrSdk
 *
 * Created by Your Name
 * Copyright (c) 2017 Your Company. All rights reserved.
 */


#import "TiLisnrSdkModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiApp.h"
#import <AVFoundation/AVAudioSession.h>

@implementation TiLisnrSdkModule

#pragma mark Internal

bool initialized = false;
bool listening = false;

// this is generated for your module, please do not change it
-(id)moduleGUID
{
    return @"9898bf6f-89f5-4825-9a5f-42231238c034";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
    return @"ti.lisnr.sdk";
}

#pragma mark Lifecycle

-(void)startup
{
    // this method is called when the module is first loaded
    // you *must* call the superclass
    [super startup];
    
    NSLog(@"[INFO] %@ loaded",self);

}

-(void)shutdown:(id)sender
{
    // this method is called when the module is being unloaded
    // typically this is during shutdown. make sure you don't do too
    // much processing here or the app will be quit forceably
    
    // you *must* call the superclass
    [super shutdown:sender];
}

#pragma mark Cleanup

-(void)dealloc
{
    // release any resources that have been retained by the module
    [super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
    // optionally release any resources that can be dynamically
    // reloaded once memory is available - such as caches
    [super didReceiveMemoryWarning:notification];
}

#pragma mark Listener Notifications

-(void)_listenerAdded:(NSString *)type count:(int)count
{
    if (count == 1 && [type isEqualToString:@"my_event"])
    {
        // the first (of potentially many) listener is being added
        // for event named 'my_event'
    }
}

-(void)_listenerRemoved:(NSString *)type count:(int)count
{
    if (count == 0 && [type isEqualToString:@"my_event"])
    {
        // the last listener called for event named 'my_event' has
        // been removed, we can optionally clean up any resources
        // since no body is listening at this point for that event
    }
}

#pragma Public APIs

-(id)example:(id)args
{
    // example method
    return @"hello world";
}

-(id)exampleProp
{
    // example property getter
    return @"hello world";
}

-(void)initialize:(id)value
{
    ENSURE_UI_THREAD(initialize, value);
    TiThreadPerformOnMainThread(^{
        
        NSDictionary *tiAppProperties = [TiApp tiAppProperties];
        
        [[LISNRService sharedService] configureWithApiKey:[tiAppProperties valueForKey:@"lisnr-service-api-key"] completion:^(NSError *error) {
            
            [[LISNRService sharedService] addObserver:self];
            if (!error) {
                initialized = true;
                [[LISNRContentManager sharedContentManager] configureWithLISNRService: [LISNRService sharedService]];
                [[LISNRContentManager sharedContentManager] setDelegate: self];
                [[LISNRContentManager sharedContentManager] setShouldFetchContent: YES];
                [LISNRService sharedService].enableBackgroundListening = YES;
                NSLog(@"[INFO] configureWithApiKey successfully");
            } else {
                initialized = false;
                NSLog(@"[INFO] configureWithApiKey error");
            }
        }];
        
    }, YES);
}

-(id)playTextTone:(id)args
{
    ENSURE_UI_THREAD(playTextTone, args);
    
    id params = [args objectAtIndex:0];
    ENSURE_SINGLE_ARG(params, NSDictionary);
    NSString *text = [params objectForKey:@"text"];
    
    NSLog(@"[INFO] Text to play %@ is convertable : %@", text,  [text canBeConvertedToEncoding:NSASCIIStringEncoding] ? @"Yes" : @"No");
    
    
    //[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
    
    
    //}];
    //dispatch_async(dispatch_get_main_queue(), ^{
    TiThreadPerformOnMainThread(^{
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //Do background work
    //    dispatch_async(dispatch_get_main_queue(), ^{
            //Update UI
    
            @try {
                NSError *err=nil;
                
                LISNRTextTone *textTone = [LISNRTextTone toneWithText:text iterations:1 sampleRate:LISNRToneSampleRateDefault error:&err];
                
                if (!err) {
                    [[LISNRService sharedService] broadcastTone: textTone fromDeviceSpeakersOnly:NO onBroadcastStart:^(NSError * _Nullable error, NSTimeInterval duration) {
                        // Broadcast Started
                        NSLog(@"[INFO] Broadcast Started");
                    }];
                } else {
                    NSLog(@"[INFO] Tone Creation Error",[err localizedDescription]);
                    // Handle Tone Creation Error
                }
            }
            @catch (NSException * e) {
                NSLog(@"[INFO] Exception: %@", e);
            }
            @finally {
                NSLog(@"[INFO] finally");
            }
            
     //   });
    //});
       
    }, YES);
    
    return @"";
    
}

-(void)startListening:(id)args{
    
    if(initialized && listening==false){
        [[LISNRService sharedService] startListeningWithCompletion:^(NSError *e) {
            if (!e) {
                listening=true;
                NSLog(@"[INFO] startListeningWithCompletion started");
                // Update your interface
            } else {
                NSLog(@"[INFO] startListeningWithCompletion error");
                // Unable to begin listening
            }
        }];
    }
    
}

-(void)stopListening:(id)args{
    
    if(initialized && listening==true){
        [[LISNRService sharedService] stopListening];
    }
    
}

- (void) IDToneDidAppearWithId:(NSUInteger)toneId atIteration:(NSUInteger)iterationIndex atTimestamp:(NSTimeInterval)timestamp {
    NSLog(@"[INFO] I am listening to tone %lu", toneId);
}

-(void)IDToneDidDisappearWithId:(NSUInteger) toneId duration:(NSTimeInterval) duration {
    NSLog(@"[INFO] Tone %lu ended after %f seconds", toneId, duration);
}

-(void)lisnrStatusChanged:(LisnrStatus)status oldStatus:(LisnrStatus)oldStatus{
    if ([self _hasListeners:@"statusChanged"]) {
        NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                     @"from": [self lisnrStatusToString:oldStatus],
                                                                                     @"to": [self lisnrStatusToString:status]}
                                      ];
        [self fireEvent:@"statusChanged" withObject:event];
    }
    NSLog(@"[INFO] lisnrStatusChanged from %@ to  %@", [self lisnrStatusToString:oldStatus], [self lisnrStatusToString:status]);
    
}

-(void)didReceiveContent:(id<LISNRBaseContentProtocol>)content forIDToneWithId:(NSUInteger)toneId {
    if([content conformsToProtocol:@protocol(LISNRImageContentProtocol)]){
        [self handleImageContent:content];
    }
    
    if([content conformsToProtocol:@protocol(LISNRVideoContentProtocol)]){
        [self handleVideoContent:content];
    }
    
    
    if([content conformsToProtocol:@protocol(LISNRWebContentProtocol)]){
        [self handleWebContent:content];
    }
    
    
    if([content conformsToProtocol:@protocol(LISNRNotificationContentProtocol)]){
        [self handleNotificationContent:content];
    }
    
    
    NSLog(@"[INFO] content received %lu", toneId);
}

-(void)handleImageContent:(id<LISNRImageContentProtocol>)content
{
    NSLog(@"[INFO] handleImageContent : %@", [[content contentImageUrl] absoluteString]);
    
    if ([self _hasListeners:@"contentReceived"]) {
        NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                     @"contentType" : @"image",
                                                                                     @"contentImageUrl": [[content contentImageUrl] absoluteString],
                                                                                     @"contentThumbnailUrl": [[content contentThumbnailUrl] absoluteString],
                                                                                     @"contentTitle": [content contentTitle],
                                                                                     @"contentNotificationText": [content contentNotificationText],
                                                                                     }
                                      ];
        [self fireEvent:@"contentReceived" withObject:event];
        
    }
    
}

-(void)handleVideoContent:(id<LISNRVideoContentProtocol>)content
{
    
    if ([self _hasListeners:@"contentReceived"]) {
        NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                     @"contentType" : @"video",
                                                                                     @"contentVideoUrl": [[content contentVideoUrl] absoluteString],
                                                                                     @"contentTitle": [content contentTitle],
                                                                                     @"contentNotificationText": [content contentNotificationText],
                                                                                     }
                                      ];
        [self fireEvent:@"contentReceived" withObject:event];
        
    }
    
}

-(void)handleWebContent:(id<LISNRWebContentProtocol>)content
{
    
    if ([self _hasListeners:@"contentReceived"]) {
        NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                     @"contentType" : @"web",
                                                                                     @"contentUrl": [[content contentUrl] absoluteString],
                                                                                     @"contentTitle": [content contentTitle],
                                                                                     @"contentNotificationText": [content contentNotificationText],
                                                                                     }
                                      ];
        [self fireEvent:@"contentReceived" withObject:event];
        
    }
    
}

-(void)handleNotificationContent:(id<LISNRNotificationContentProtocol>)content
{
    
    if ([self _hasListeners:@"contentReceived"]) {
        NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                     @"contentType" : @"notification",
                                                                                     @"contentTitle": [content contentTitle],
                                                                                     @"contentNotificationText": [content contentNotificationText],
                                                                                     }
                                      ];
        [self fireEvent:@"contentReceived" withObject:event];
        
    }
    
}


-(void)didHearTextToneWithPayload:(NSString *)text {
    
    NSLog(@"[INFO] didHearTextToneWithPayload %@:", text);
    
    if ([self _hasListeners:@"textToneReceived"]) {
        NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                     @"text": text,
                                                                                     @"success": @"true"}
                                      ];
        [self fireEvent:@"textToneReceived" withObject:event];
    }
}

- (NSString*)lisnrStatusToString:(LisnrStatus)lisnrStatus{
    NSString *result = nil;
    switch(lisnrStatus) {
        case LisnrStatusInactive:
            listening=false;
            result = @"inactive";
            break;
        case LisnrStatusListening:
            listening=true;
            result = @"listening";
            break;
        case LisnrStatusInterrupted:
            listening=false;
            result = @"interrupted";
            break;
        case LisnrStatusBroadcasting:
            listening=false;
            result = @"broadcasting";
            break;
        case LisnrStatusUnconfigured:
            listening=false;
            result = @"configured";
            break;
        default:
            [NSException raise:NSGenericException format:@"Unexpected FormatType."];
    }
    
    return result;
}

@end
