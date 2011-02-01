//
//  LocationManager.m
//  Remindly
//
//  Created by Nathan Stitt on 1/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LocationAlarmManager.h"
#import "NotesManager.h"
#import <MapKit/MapKit.h>

LocationAlarmManager *instance;

@interface LocationAlarmManager()
-(void)startMonitor;
@property (nonatomic,retain) CLLocationManager *manager;
@property (nonatomic,readonly) NSMutableDictionary *notes;
@property (nonatomic,retain ) CLLocation *lastLocation;
@end

@implementation LocationAlarmManager

@synthesize manager, notes, lastLocation;

+ (void)startup {
    // Create the location manager if this object does not
    // already have one.

    if ( ! instance ){
		instance = [[ LocationAlarmManager alloc ] init ];
		
	} else {
		instance.startMonitor;
	}
}

-(void)startMonitor {
	NSLog(@"Started Monitor");
	manager.delegate = self;
    [ manager startMonitoringSignificantLocationChanges];
	
}

-(id) init {
	self = [ super init ];
	if ( ! self ){
		return nil;
	}
	notes = [[ NSMutableDictionary alloc ] init ];
	for ( Note *note in [ NotesManager notesWithLocationAlarms ] ){
		[ notes setObject: note forKey: note.directory ];
	}
	self.manager = [[CLLocationManager alloc] init];
	manager.purpose = @"In order to use geographical alarms that alert you when leaving or entering an area";
    manager.delegate = self;
	[ manager startUpdatingLocation ];
	[ manager release ];

	return self;
}


-(void)fireNoteAlarm:(Note*)note {
	UILocalNotification *notification = [[UILocalNotification alloc] init];

	notification.fireDate =  [ NSDate date ];
	notification.timeZone =  [ NSTimeZone defaultTimeZone];
	notification.alertBody = [ NSString stringWithFormat:@"Location %@\n%@", 
							   note.onEnterRegion ? @"Reached" : @"Left",
							   note.alarmText ];
	notification.alertAction = @"View Note";
	notification.soundName = UILocalNotificationDefaultSoundName;
	notification.applicationIconBadgeNumber = 1;

	[ [UIApplication sharedApplication] presentLocalNotificationNow:notification ];
	[ notification release ];
	[ note unScedule ];
}



-(void)dealloc {
	[ [ NSNotificationCenter defaultCenter] removeObserver:self];
	[ notes   release ];
	[ manager release ];
	[ super dealloc ];
}


+(void)unregisterNote:(Note*)note{
	[ instance.notes removeObjectForKey: note.directory ];
}


+(CLLocation*)lastCoord {
	return instance.manager.location;
}


+ (void)registerNote:(Note*)note {
	[ instance.notes setObject:note forKey:note.directory ];
}


// returns a string if the number with one decimal place of precision
// sets the style (commas or periods) based on the locale
NSString * formatDecimal_1(NSNumber *num) {
	static NSNumberFormatter *numFormatter;
	if (!numFormatter) {
		numFormatter = [[[NSNumberFormatter alloc] init] retain];
		[numFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[numFormatter setLocale:[NSLocale currentLocale]];
		[numFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[numFormatter setMaximumFractionDigits:1];
		[numFormatter setMinimumFractionDigits:1];
	}
	return [numFormatter stringFromNumber: num ];
}

+ (NSString*)distanceStringFrom:(CLLocationCoordinate2D)coord{
	double distance = MKMetersBetweenMapPoints( MKMapPointForCoordinate( coord ),
												MKMapPointForCoordinate( [ LocationAlarmManager lastCoord ].coordinate ) );
	NSString * unitName;
	NSString *locale = [ [ NSLocale currentLocale ] localeIdentifier ];
	if ( [ locale isEqual:@"en_US" ]) {
		unitName = @"mi";
		distance = distance / 1609.344;
	} else {
		unitName = @"km";
		distance = distance / 1000;
	}
	return [NSString stringWithFormat:@"%@ %@", formatDecimal_1( [NSNumber numberWithDouble: distance] ), unitName ];
}

#pragma mark -
#pragma mark CLLocationManager delegate methods

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"Location Manager error: %@", [error description] );
	
}


- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	double meters = [ lastLocation distanceFromLocation: newLocation ];
	if ( ! lastLocation || meters > 10 ){
		for ( Note *note in [ notes allValues ] ){
			meters = MKMetersBetweenMapPoints(  MKMapPointForCoordinate( newLocation.coordinate ),
												MKMapPointForCoordinate( note.coordinate ) );

			if ( meters < ALARM_METER_RADIUS && note.onEnterRegion ){
				[ self fireNoteAlarm:note ];
			} else if ( meters > ( ALARM_METER_RADIUS + 200 ) && ! note.onEnterRegion ) {
				[ self fireNoteAlarm:note ];
			}
		}
		self.lastLocation = newLocation;
	}
}

// this sucks balls, terribly inaccurate, alarms only fire about 1/3 of the time

//- (void)locationManager:(CLLocationManager *)m didEnterRegion:(CLRegion *)region{
//	NSLog(@"-----------------------> Location Manager Entered: %@", region.identifier );
//	Note *note = [ [NotesManager instance] noteWithDirectory: region.identifier ];
//	if ( note ){ //&& note.onEnterRegion ){
//		[ self displayNoteAlarm:note ];
//	}
////	[ m stopMonitoringForRegion:region ];
//}
//
//- (void)locationManager:(CLLocationManager *)m didExitRegion:(CLRegion *)region{
//	NSLog(@"-----------------------> Location Manager Exited: %@", region.identifier );
//
//	Note *note = [ [NotesManager instance] noteWithDirectory: region.identifier ];
//	if ( note ){// && ! note.onEnterRegion ){
//		[ self displayNoteAlarm:note ];
//	}
////	[ m stopMonitoringForRegion:region ];
//}


@end
