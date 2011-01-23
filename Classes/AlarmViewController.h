//
//  AlarmView.h
//  Created by Nathan Stitt on 11/14/10.
//  Copyright 2011.
//  Distributed under the terms of the GNU General Public License version 3.

// The AlarmViewController handles setting an alarm.
// it has a button which will toggle sliding the view up & down
// calls AlarmViewDelegate to set alarm after save button is pressed


#import <UIKit/UIKit.h>
#import "Note.h"
#import "AlarmQuickTimes.h"
#import "AlarmAbsoluteTimes.h"

@class AlarmViewController;

@protocol AlarmViewDelegate
@required
-(void)alarmSet:(AlarmViewController*)av;
-(void)alarmShowingChanged:(AlarmViewController*)av;
@end


@interface AlarmViewController : UIView {
	BOOL wasSet;
	id<AlarmViewDelegate> delegate;
	NSArray *panels;
	NSArray *quickChoices;
	NSDictionary *choicesTimes;
	AlarmQuickTimes *quickTimes;
	AlarmAbsoluteTimes *absTimes;
	UISegmentedControl *typeCtrl;
	UITabBar *tabBar;
}

-(void)showWithNote:(Note*)note;

-(void)saveToNote:(Note*)note;

-(void)quickSelectionMade;

@property (nonatomic, assign) id<AlarmViewDelegate> delegate;
@property (nonatomic,readonly ) BOOL wasSet;
@property (nonatomic) BOOL isShowing;

@end