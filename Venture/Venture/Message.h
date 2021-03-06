//
//  Message.h
//  Venture
//
//  Created by Amy Bearman on 5/30/14.
//  Copyright (c) 2014 Amy Bearman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Person;

@interface Message : NSManagedObject

@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) Person *sender;

@end
