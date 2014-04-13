//
//  HomeModel.m
//  Venture
//
//  Created by Amy Bearman on 4/12/14.
//  Copyright (c) 2014 Amy Bearman. All rights reserved.
//

//post request with lat/lng

#import "HomeModel.h"
#import "VentureActivity.h"
#import <AFHTTPRequestOperationManager.h>

@interface HomeModel() {
    NSMutableData *_downloadedData;
}
@end

@implementation HomeModel

-(void)downloadActivity:(int)indexOfTransport atFeeling:(int)indexOfFeeling withCallback:(void (^)(VentureActivity *))callback {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSString *modeOfTransport;
    if (indexOfTransport == 0) {
        modeOfTransport = @"walking";
    } else if (indexOfTransport == 1) {
        modeOfTransport = @"bicycling";
    } else if (indexOfTransport == 2) {
        modeOfTransport = @"driving";
    } else if (indexOfTransport == 3) {
        modeOfTransport = @"transit";
    }
    
    NSString *feeling;
    if (indexOfFeeling == 0) {
        feeling = @"hungry";
    } else if (indexOfFeeling == 1) {
        feeling = @"adventurous";
    } else if (indexOfFeeling == 2) {
        feeling = @"bored";
    }
    
    NSDictionary *parameters = @{@"lat": @"37.43777", @"lng": @"-122.1374", @"uid": @"3", @"transport": modeOfTransport, @"feeling": feeling};
    
    //transport, feeling
    //walking bicycling transit driving
    //hungry adventurous bored
    
    VentureActivity *activity = [[VentureActivity alloc] init];
    
    [manager POST:@"http://grapevine.stanford.edu:8080/VentureBrain/Brain" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        
        if([responseObject isKindOfClass:[NSDictionary class]]) NSLog(@"Yes");
        
        NSDictionary *dict = (NSDictionary *)(responseObject);
        NSDictionary *suggestion = [dict objectForKey:@"suggestion"];
        NSString *justification = [dict objectForKey:@"reason"];
        
        NSString *title = [suggestion objectForKey:@"title"];
        NSString *address = [suggestion objectForKey:@"address"];
        NSString *lat = [suggestion objectForKey:@"lat"];
        NSString *lng = [suggestion objectForKey:@"lng"];
        
        activity.title = title;
        activity.address = address;
        activity.justification = justification;
        activity.lat = lat;
        activity.lng = lng;
        
        callback(activity);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];

};

@end



