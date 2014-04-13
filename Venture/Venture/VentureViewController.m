// Gizz442@
// VentureViewController.m
//  Venture
//
//  Created by Amy Bearman on 4/11/14.
//  Copyright (c) 2014 Amy Bearman. All rights reserved.
//

#import "VentureViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreLocation/CoreLocation.h>
#import <AFHTTPRequestOperationManager.h>
#import <GoogleMaps/GoogleMaps.h>
#import <pthread.h>

@interface VentureViewController()

@property (weak, nonatomic) IBOutlet UITextField *searchBar;
@property (weak, nonatomic) IBOutlet UISegmentedControl *modeOfTransportation;
@property (weak, nonatomic) IBOutlet UISegmentedControl *activityType;

@property (weak, nonatomic) IBOutlet UILabel *activityName1;
@property (weak, nonatomic) IBOutlet UILabel *activityAddress1;
@property (weak, nonatomic) IBOutlet UILabel *activityJustification1;
@property (weak, nonatomic) IBOutlet UILabel *activityDistanceAway1;
@property (weak, nonatomic) IBOutlet UIImageView *activityImage1;
@property (weak, nonatomic) IBOutlet UIImageView *activityYelpRating1;
@property (weak, nonatomic) IBOutlet UILabel *iChose1;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (weak, nonatomic) IBOutlet UIButton *searchButton;

@property (strong, nonatomic) HomeModel *model;
@property (strong, nonatomic) NSMutableArray *activities; // of VentureActivity

@property (weak, nonatomic) IBOutlet UIView *activityView;

@end

@implementation VentureViewController {
    
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    CLGeocoder *geocoder;
    
    NSString *activityLat;
    NSString *activityLng;
    int indexActivitiesArray;
}

// Lazily intantiate the model
- (HomeModel *)model {
    if (!_model) _model = [[HomeModel alloc] init];
    return _model;
}

// Lazily instantiate the NSArray of VentureActivity's
- (NSMutableArray *)activities {
    if (!_activities) _activities = [[NSMutableArray alloc] init];
    return _activities;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    indexActivitiesArray = 0;
    
    [self.spinner setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.spinner setColor:[UIColor colorWithWhite: 0.70 alpha:1]];
    
    locationManager = [[CLLocationManager alloc] init];
    geocoder = [[CLGeocoder alloc] init];
    self.searchBar.delegate = self;
    
    //Starts up location tracking
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
    
    self.spinner.hidesWhenStopped = YES;
    [self.spinner startAnimating];
    
    //Loads first suggestion
    int indexOfTransport = self.modeOfTransportation.selectedSegmentIndex;
    int indexOfFeeling = self.activityType.selectedSegmentIndex;
    [self getNewActivity:indexOfTransport atFeeling:indexOfFeeling];

    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(respondToSwipeRight)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionLeft;
    
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(respondToSwipeUp)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(respondToSwipeLeft)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionRight;
    
    [self.activityView addGestureRecognizer:swipeRight];
    [self.activityView addGestureRecognizer:swipeUp];
    [self.activityView addGestureRecognizer:swipeLeft];
}

-(void)getActivityAtIndex {
    //Retrieve existing element
    VentureActivity *activity = [self.activities objectAtIndex:indexActivitiesArray];
    self.activityName1.text = activity.title;
    self.activityAddress1.text = activity.address;
    self.activityJustification1.text = activity.justification;
    
    activityLat = activity.lat;
    activityLng = activity.lng;
    
    CLLocation *loc1 = currentLocation;
    CLLocation *loc2 = [[CLLocation alloc] initWithLatitude:[activityLat doubleValue] longitude:[activityLng doubleValue]];
    
    double distance = [loc1 distanceFromLocation:loc2];
    distance /= 1000.0;
    self.activityDistanceAway1.text = [NSString stringWithFormat:@"%f km", distance];
    
    NSString *ImageURL = activity.imageURL;
    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:ImageURL]];
    self.activityImage1.image = [UIImage imageWithData:imageData];
    
    NSString *yelpURL = activity.yelpRatingImageURL;
    NSData *imageDataYelp = [NSData dataWithContentsOfURL:[NSURL URLWithString:yelpURL]];
    self.activityYelpRating1.image = [UIImage imageWithData:imageDataYelp];
    
    self.iChose1.text = @"I chose this because ... ";
}

-(void)respondToSwipeLeft {
    if (indexActivitiesArray > 0) {
        NSLog(@"Swiped left");
        indexActivitiesArray--;
        NSLog(@"Index: %d", indexActivitiesArray);
        
        NSLog(@"Index: %d", indexActivitiesArray);
        [self getActivityAtIndex];
    }
}

-(void)respondToSwipeRight {
    NSLog(@"Swiped right");
    indexActivitiesArray++;
    NSLog(@"Index: %d", indexActivitiesArray);
    
    if (indexActivitiesArray <= [self.activities count] - 1) {
        [self getActivityAtIndex];
    } else {
        int indexOfTransport = self.modeOfTransportation.selectedSegmentIndex;
        int indexOfFeeling = self.activityType.selectedSegmentIndex;
        [self getNewActivity:indexOfTransport atFeeling:indexOfFeeling];
    }
}

-(void)respondToSwipeUp {
    NSString *destAddr;
    destAddr = [self.activityAddress1.text stringByReplacingOccurrencesOfString:@" " withString:@"+"];

    NSString *modeOfTransport;
    int index = [self.modeOfTransportation selectedSegmentIndex];
    if (index == 0) {
        modeOfTransport = @"walking";
    } else if (index == 1) {
        modeOfTransport = @"biking";
    } else if (index == 2) {
        modeOfTransport = @"driving";
    } else if (index == 3) {
        modeOfTransport = @"transit";
    }
    
    NSString *url = [NSString stringWithFormat:@"comgooglemaps://?origin=%f,%f&daddr=%@&center=%@,%@&directionsmode=%@&zoom=10", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude, destAddr, activityLat, activityLng, modeOfTransport];
    
    if ([[UIApplication sharedApplication] canOpenURL:
         [NSURL URLWithString:@"comgooglemaps://"]]) {
        [[UIApplication sharedApplication] openURL:
         [NSURL URLWithString:url]];
    } else {
        NSLog(@"Can't use comgooglemaps://");
    }
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error" message:@"Failed to Get Your Location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"didUpdateToLocation: %@", newLocation);
    currentLocation = newLocation;
    
    /*if (currentLocation != nil) {
        NSString *lng = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        NSString *lat = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
    }*/
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)searchButtonClicked:(id)sender {
    NSString *specifiedLoc = self.searchBar.text;
    [self textFieldShouldReturn:self.searchBar];
    
    [geocoder geocodeAddressString:specifiedLoc
                 completionHandler:^(NSArray *placemarks, NSError *error) {
                     if (!error) {
                         CLPlacemark *placemark = [placemarks firstObject];
                         currentLocation = placemark.location;
                     } else {
                         NSLog(@"There was a forward geocoding error\n%@",
                               [error localizedDescription]);
                     }
                 }
    ];
    
    int indexOfTransport = self.modeOfTransportation.selectedSegmentIndex;
    int indexOfFeeling = self.activityType.selectedSegmentIndex;
    [self getNewActivity:indexOfTransport atFeeling:indexOfFeeling];
}

-(void)getNewActivity:(int)indexOfTransport atFeeling:(int)indexOfFeeling {
    [self.spinner startAnimating];
    
    self.activityName1.text = @"";
    self.activityAddress1.text = @"";
    self.activityJustification1.text = @"";
    self.activityDistanceAway1.text = @"";
    self.activityImage1.image = nil;
    self.activityYelpRating1.image = nil;
    self.iChose1.text = @"";
    
    [self.model downloadActivity:indexOfTransport atFeeling:indexOfFeeling withCallback:^(VentureActivity* activity) {
       
        [self.activities addObject:activity];
        
        self.activityName1.alpha = 0;
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn
                         animations:^{ self.activityName1.alpha = 1;}
                         completion:nil];
        self.activityName1.text = activity.title;
        
        self.activityAddress1.alpha = 0;
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn
                         animations:^{ self.activityAddress1.alpha = 1;}
                         completion:nil];
        self.activityAddress1.text = activity.address;
        
        self.activityJustification1.alpha = 0;
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn
                         animations:^{ self.activityJustification1.alpha = 1;}
                         completion:nil];
        self.activityJustification1.text = activity.justification;
        
        self.activityImage1.alpha = 0;
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn
                         animations:^{ self.activityImage1.alpha = 1;}
                         completion:nil];
        NSString *ImageURL = activity.imageURL;
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:ImageURL]];
        self.activityImage1.image = [UIImage imageWithData:imageData];
        
        self.activityYelpRating1.alpha = 0;
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn
                         animations:^{ self.activityYelpRating1.alpha = 1;}
                         completion:nil];
        NSString *yelpURL = activity.yelpRatingImageURL;
        NSData *imageDataYelp = [NSData dataWithContentsOfURL:[NSURL URLWithString:yelpURL]];
        self.activityYelpRating1.image = [UIImage imageWithData:imageDataYelp];
        
        //Do google maps stuff to get time of travel and distance away
        activityLat = activity.lat;
        activityLng = activity.lng;
        
        CLLocation *loc1 = currentLocation;
        CLLocation *loc2 = [[CLLocation alloc] initWithLatitude:[activityLat doubleValue] longitude:[activityLng doubleValue]];
        
        double distance = [loc1 distanceFromLocation:loc2];
        distance /= 1000.0;
        
        self.activityDistanceAway1.alpha = 0;
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn
                         animations:^{ self.activityDistanceAway1.alpha = 1;}
                         completion:nil];
        self.activityDistanceAway1.text = [NSString stringWithFormat:@"%f km", distance];
        
         NSLog(@"Activity View 1 loaded");
        
        self.iChose1.alpha = 0;
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn
                         animations:^{ self.iChose1.alpha = 1;}
                         completion:nil];
        self.iChose1.text = @"I chose this because ... ";
        
        //stop spinner
        [self.spinner stopAnimating];
    }];
}

@end

