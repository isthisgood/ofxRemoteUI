//
//  ExternalDevices.h
//  ofxRemoteUIClientOSX
//
//  Created by Oriol Ferrer Mesià on 19/04/14.
//
//

#import <Foundation/Foundation.h>
#import <VVMIDI/VVMIDI.h>
#import "JoystickNotificationDelegate.h"
#include "ofxRemoteUIClient.h"
#import "ParamUI.h"


@interface ExternalDevices : NSObject <VVMIDIDelegateProtocol, JoystickNotificationDelegate>{

	IBOutlet NSTableView			*midiBindingsTable;
	IBOutlet NSButton *				externalButtonsBehaveAsToggleCheckbox;

	//MIDI
	VVMIDIManager					*midiManager;
	ParamUI							*upcomingDeviceParam;
	map<string, string>				bindingsMap; //table of bindings for midi and joystick

	map<string, ParamUI*> *			widgets;
	ofxRemoteUIClient *				client;
	BOOL							externalButtonsBehaveAsToggle;	//if true, one press on midi or joystick toggles a bool;
}


-(void)initWithWidgets:(map<string, ParamUI*>*) widgets andClient:(ofxRemoteUIClient*) client;
-(void)savePrefs:(id)sender;
-(IBAction)applyPrefs:(id)sender;
-(void)loadPrefs;

-(BOOL)parseDeviceBindingsFromFile:(NSURL*) file;
-(void)saveDeviceBindingsToFile:(NSURL*) path;
-(IBAction)saveDeviceBindings:(id)who;

-(void)updateParamUIOnMainThread:(ParamUI*)item;

//midi
-(void)userClickedOnParamForDeviceBinding:(ParamUI*)param;

//midi delegate
- (void) setupChanged;
- (void) receivedMIDI:(NSArray *)a fromNode:(VVMIDINode *)n;

//joystick delegates
- (void)joystickAdded:(Joystick *)joystick ;
- (void)joystickAxisChanged:(Joystick *)joystick atAxisIndex:(int)axis;
- (void)joystickButton:(int)buttonIndex state:(BOOL)pressed onJoystick:(Joystick*)joystick;

@end
