//
//  main.cpp
//  noOF_Example
//
//  Created by Oriol Ferrer Mesià on 29/06/13.
//  Copyright (c) 2013 Oriol Ferrer Mesià. All rights reserved.
//

#include <iostream>
#include "ofxRemoteUIServer.h"
#include "unistd.h"

/////////////////////////////////////////////////////////////////////////////////////
// my app's paramaters defined here
/////////////////////////////////////////////////////////////////////////////////////

int myParam = 0;
bool quitButton = false;
string myString = "Test String";
ofColor color;	//RGBA as uchars
				//access to components: color.r, color.g, color.b, color.a [0..255]
				//also access by color[0] (red), color[1] (green), etc


/////////////////////////////////////////////////////////////////////////////////////
//define a callback method to get notifications of client actions
/////////////////////////////////////////////////////////////////////////////////////

void serverCallback(RemoteUIServerCallBackArg arg){

	switch (arg.action) {

		case CLIENT_CONNECTED:
			cout << "CLIENT_CONNECTED" << endl;
			break;

		case CLIENT_DISCONNECTED:
			cout << "CLIENT_DISCONNECTED" << endl;
			break;

		case CLIENT_UPDATED_PARAM:
			cout << "CLIENT_UPDATED_PARAM "<< arg.paramName << ": ";
			arg.param.print();
			break;

		/*see RemoteUICallServerAction enum for more event callbacks */

		default:
			break;
	}
}


int main(int argc, const char * argv[]){

	std::cout << "Hello, World!\n";

	//setup our client callback, to get notified when client changes things
	OFX_REMOTEUI_SERVER_SET_CALLBACK(serverCallback);

	//start the server
	OFX_REMOTEUI_SERVER_SETUP();

	//chose a new random color for all the upcoming variables
	OFX_REMOTEUI_SERVER_SET_NEW_COLOR();
	// share my float param, give a valid range [0..100]
	OFX_REMOTEUI_SERVER_SHARE_PARAM(myParam, 0, 100);


	OFX_REMOTEUI_SERVER_SET_NEW_COLOR();
	OFX_REMOTEUI_SERVER_SHARE_COLOR_PARAM(color); //share color param

	OFX_REMOTEUI_SERVER_SET_NEW_COLOR();
	OFX_REMOTEUI_SERVER_SHARE_PARAM(myString); //share string param

	OFX_REMOTEUI_SERVER_SET_NEW_COLOR();
	OFX_REMOTEUI_SERVER_SHARE_PARAM(quitButton); //finally share bool param, used as a "quit now" flag


	OFX_REMOTEUI_SERVER_LOAD_FROM_XML();	//load param states from XML

	//stay here until user presses quit button
	while (quitButton == false) {
		OFX_REMOTEUI_SERVER_UPDATE(0.01666);
		usleep(100000 / 6.);
	}

	quitButton = false;

	//save current state of params to XML
	OFX_REMOTEUI_SERVER_SAVE_TO_XML();

	//close server, notify client about the closure
	OFX_REMOTEUI_SERVER_CLOSE();

	//end program
    return 0;
}
