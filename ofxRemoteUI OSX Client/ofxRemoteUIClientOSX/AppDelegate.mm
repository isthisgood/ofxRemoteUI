//
//  AppDelegate.h.m
//  ofxRemoteUIClientOSX
//
//  Created by Oriol Ferrer Mesia on 8/28/11.
//  Copyright 2011 uri.cat. All rights reserved.
//

#import "Item.h"
#import "AppDelegate.h"


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)note {

	client = new ofxRemoteUIClient();
	
	// setup recent connections ///////////////

	//[[addressField cell] setSearchButtonCell:nil];
	[[addressField cell] setCancelButtonCell:nil];
	[[addressField cell] setSendsSearchStringImmediately:NO];
	[[addressField cell] setSendsActionOnEndEditing:NO];
	[addressField setRecentsAutosaveName:@"recentHosts"];

	NSMenu *cellMenu = [[NSMenu alloc] initWithTitle:@"Search Menu"];
	[cellMenu setAutoenablesItems:YES];
    NSMenuItem *item;

    item = [[NSMenuItem alloc] initWithTitle:@"Clear" action:nil keyEquivalent:@""];
    [item setTag:NSSearchFieldClearRecentsMenuItemTag];
	[item setTarget:self];
    [cellMenu insertItem:item atIndex:0];
	[item release];

    item = [NSMenuItem separatorItem];
    [item setTag:NSSearchFieldRecentsTitleMenuItemTag];
	[item setTarget:nil];
    [cellMenu insertItem:item atIndex:1];


    item = [[NSMenuItem alloc] initWithTitle:@"Recent Searches" action:NULL keyEquivalent:@""];
    [item setTag:NSSearchFieldRecentsTitleMenuItemTag];
	[item setTarget:nil];
    [cellMenu insertItem:item atIndex:2];
	[item release];


    item = [[NSMenuItem alloc] initWithTitle:@"Recents" action:NULL keyEquivalent:@""];
    [item setTag:NSSearchFieldRecentsMenuItemTag];
	[item setTarget:nil];
    [cellMenu insertItem:item atIndex:3];
	[item release];

    id searchCell = [addressField cell];
    [searchCell setSearchMenuTemplate:cellMenu];

	///////////////////////////////////////////////

	[self setup];
	timer = [NSTimer scheduledTimerWithTimeInterval:REFRESH_RATE target:self selector:@selector(update) userInfo:nil repeats:YES];
	statusTimer = [NSTimer scheduledTimerWithTimeInterval:STATUS_REFRESH_RATE target:self selector:@selector(statusUpdate) userInfo:nil repeats:YES];
	updateContinuosly = false;

	//connect to last used server by default
	NSUserDefaults * df = [NSUserDefaults standardUserDefaults];
	//NSLog(@"%@", [df stringForKey:@"lastAddress"]);
	if([df stringForKey:@"lastAddress"]) [addressField setStringValue:[df stringForKey:@"lastAddress"]];
	if([df stringForKey:@"lastPort"]) [portField setStringValue:[df stringForKey:@"lastPort"]];
	lagField.stringValue = @"";
	[self performSelector:@selector(connect) withObject:nil afterDelay:0.0];

	//get notified when window is resized
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowResized:) name:NSWindowDidResizeNotification
											   object: window];

	//debug
//	CALayer *viewLayer = [CALayer layer];
//	[viewLayer setBackgroundColor:CGColorCreateGenericRGB(0,0,0,0.1)];
//	[listContainer setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
//	[listContainer setLayer:viewLayer];

}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
    return YES;
}


- (void)windowResized:(NSNotification *)notification;{


	//NSPoint p = [self calcNumRowsCols];
	//NSLog( @"%f %f  -  %f %f", p.x, p.y, lastLayout.x, lastLayout.y );

	//if ( p.x != lastLayout.x || p.y != lastLayout.y ){
		[self layOutParams];
	//}
	for( map<string,Item*>::iterator ii = widgets.begin(); ii != widgets.end(); ++ii ){
		string key = (*ii).first;
		Item* t = widgets[key];
		[t remapSlider];
	}
}



-(void)syncLocalParamsToClientParams{

	[self cleanUpParams];

	vector<string> paramList = client->getAllParamNamesList();
	vector<string> updatedParamsList = client->getChangedParamsList();

	//NSLog(@"Client holds %d params so far", (int) paramList.size());
	//NSLog(@"Client reports %d params changed since last check", (int)updatedParamsList.size());

	int c = 0;

	for(int i = 0; i < paramList.size(); i++){

		string paramName = paramList[i];
		RemoteUIParam p = client->getParamForName(paramName);

		map<string,Item*>::iterator it = widgets.find(paramName);
		if ( it == widgets.end() ){	//not found, this is a new param... lets make an UI item for it
			Item * row = [[Item alloc] initWithParam: p paramName: paramName ID: c];
			c++;
			orderedKeys.push_back(paramName);
			widgets[paramName] = row;
		}
	}
	[self layOutParams];
}


-(void)adjustScrollView{

	int totalH = ROW_HEIGHT * (orderedKeys.size() );
	[listContainer setFrameSize: CGSizeMake( listContainer.frame.size.width, totalH)];
}


-(void)layOutParams{

	//remove all views, start over
	NSArray * subviews = [listContainer subviews];
	for( int i = [subviews count]-1 ; i >= 0 ; i-- ){
		[[subviews objectAtIndex:i] removeFromSuperview];
		//[[subviews objectAtIndex:i] release];
	}
	[self adjustScrollView];

	float scrollW = listContainer.frame.size.width;
	float scrollH = scroll.frame.size.height;
	int numParams = orderedKeys.size();
	int numCol = ceil(scrollW / ROW_WIDTH);
	int howManyPerCol = floor( scrollH / ROW_HEIGHT );
	int howManyThisCol = 0;
	int colIndex = 0;
	int numUsedColumns = ceil(numParams / (float)howManyPerCol);
	float rowW = scrollW / numUsedColumns;
	bool forceOneCol = false;

	if (rowW < ROW_WIDTH){
		rowW = ROW_WIDTH;
		forceOneCol = true;
		numUsedColumns = 1;
		rowW = scrollW / numUsedColumns;
	}

	int h = 0;
	for(int i = 0; i < numParams; i++){
		string key = orderedKeys[i];
		Item * item = widgets[key];
		NSRect r = item->ui.frame;

		item->ui.frame = NSMakeRect( colIndex * rowW, (numParams - 1) * ROW_HEIGHT - h , rowW, r.size.height);
		[listContainer addSubview: item->ui];
		h += r.size.height;
		howManyThisCol++;
		if (forceOneCol == false && howManyThisCol >= howManyPerCol ){
			colIndex++;
			howManyThisCol = 0;
			h = 0;
		}
		[item updateUI];
		[item remapSlider];
	}

//	NSLog(@"\n");
//	NSLog(@"numParams: %d ", numParams);
//	NSLog(@"howManyPerCol: %d ", howManyPerCol);
//	NSLog(@"numCol: %d ", numCol);
//	NSLog(@"numUsedColumns: %d ", numUsedColumns);
//	NSLog(@"rowW: %f ", rowW);
//	NSLog(@"forceOneCol: %d ", forceOneCol);
//	NSLog(@"colIndex: %d ", colIndex);

	lastLayout.x = colIndex;
	lastLayout.y = howManyPerCol;
	//[self adjustScrollView];
	int off = ((int)[scroll.contentView frame].size.height ) % ((int)(ROW_HEIGHT));

//	NSLog(@"h: %d  off %d", h, off);

	if(forceOneCol){
		[listContainer setFrameSize: CGSizeMake( listContainer.frame.size.width, numParams * ROW_HEIGHT + off)];
		lastLayout.y = numParams;
	}else{
		[listContainer setFrameSize: CGSizeMake( listContainer.frame.size.width, howManyPerCol * ROW_HEIGHT + off)];
	}

}


-(void)disableAllWidgets{
	for( map<string,Item*>::iterator ii = widgets.begin(); ii != widgets.end(); ++ii ){
		string key = (*ii).first;
		Item* t = widgets[key];
		[t disableChanges];
	}
}


-(void)enableAllWidgets{
	for( map<string,Item*>::iterator ii = widgets.begin(); ii != widgets.end(); ++ii ){
		string key = (*ii).first;
		Item* t = widgets[key];
		[t enableChanges];
	}
}


-(IBAction)pressedSync:(id)sender;{

	client->requestCompleteUpdate();
	//delay a bit the screen update so that we have gathered the values
	[self performSelector:@selector(handleUpdate:) withObject:nil afterDelay: REFRESH_RATE * 5];
}


-(void) handleUpdate:(id)timer{

	[self syncLocalParamsToClientParams];
	[self layOutParams];
}


-(IBAction)pressedContinuously:(NSButton *)sender;{

	if(connectButton.state == 1){
		if ([sender state]) {
			[self disableAllWidgets];
			updateContinuosly = true;
			[updateFromServerButton setEnabled: false];
		}else{
			updateContinuosly = false;
			[updateFromServerButton setEnabled: true];
			[self enableAllWidgets];
		}
	}
}


-(IBAction)pressedConnect:(id)sender{
	//NSLog(@"pressedConnect");
	[self connect];
}


-(void) connect{
	
	//NSLog(@"connect!");
	NSUserDefaults * df = [NSUserDefaults standardUserDefaults];
	[df setObject: addressField.stringValue forKey:@"lastAddress"];
	[df setObject: portField.stringValue forKey:@"lastPort"];

	if ([[connectButton title] isEqualToString:@"Connect"]){ //we are not connected, let's connect
		[addressField setEnabled:false];
		[portField setEnabled:false];
		connectButton.title = @"Disconnect";
		connectButton.state = 1;
		NSLog(@"ofxRemoteUIClientOSX Connecting to %@", addressField.stringValue);
		int port = [portField.stringValue intValue];
		if (port < OFXREMOTEUI_PORT - 1) {
			port = OFXREMOTEUI_PORT - 1;
			portField.stringValue = [NSString stringWithFormat:@"%d", OFXREMOTEUI_PORT - 1];
		}
		client->setup([addressField.stringValue UTF8String], port);
		[updateFromServerButton setEnabled: true];
		[updateContinuouslyCheckbox setEnabled: true];
		[statusImage setImage:nil];
		//first load of vars
		[self pressedSync:nil];
		[progress startAnimation:self];
		lagField.stringValue = @"";

	}else{ // let's disconnect

		[addressField setEnabled:true];
		[portField setEnabled:true];
		connectButton.state = 0;
		connectButton.title = @"Connect";
		[updateFromServerButton setEnabled: false];
		[updateContinuouslyCheckbox setEnabled:false];
		[statusImage setImage:[NSImage imageNamed:@"offline.png"]];
		[progress stopAnimation:self];
		lagField.stringValue = @"";
		[self cleanUpParams];
	}
}

-(void)cleanUpParams{
	for( map<string,Item*>::iterator ii = widgets.begin(); ii != widgets.end(); ++ii ){
		string key = (*ii).first;
		Item* t = widgets[key];
		//NSLog(@"release %s", key.c_str());
		[t release];
	}
	widgets.clear();
	orderedKeys.clear();
}



-(void)setup{
	//client->setup("127.0.0.1", 0.1);
}


-(void)statusUpdate{

	if (connectButton.state == 1){
		float lag = client->connectionLag();
		//printf("lag: %f\n", lag);
		if (lag > CONNECTION_TIMEOUT || lag < 0.0f){
			[self connect]; //force disconnect if lag is too large
			[progress stopAnimation:self];
			[statusImage setImage:[NSImage imageNamed:@"offline"]];
		}else{
			if (lag > 0.0f){
				lagField.stringValue = [NSString stringWithFormat:@"%.1fms", lag];
				[progress stopAnimation:self];
				[statusImage setImage:[NSImage imageNamed:@"connected.png"]];
			}
		}
	}
}


-(void)update{

	if ( connectButton.state == 1 ){ // if connected

		client->update(REFRESH_RATE);

		if(updateContinuosly){
			client->requestCompleteUpdate();
			[self syncLocalParamsToClientParams];
		}

		if(!client->isReadyToSend()){	//if the other side disconnected, or error
			[self connect]; //this disconnects if we were connectd
		}
	}
}


//UI callback, we will get notified with this when user changes something in UI
-(void)userChangedParam:(RemoteUIParam)p paramName:(string)name{
	//NSLog(@"usr changed param! %s", name.c_str());
	if( connectButton.state == 1 ){
		//printf("client sending: "); p.print();
		client->sendParamUpdate(p, name);
	}
}


@end
