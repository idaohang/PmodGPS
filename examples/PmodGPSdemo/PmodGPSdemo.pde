/**************************************************/
/* PmodGPS Demo                                   */
/**************************************************/
/*    Author: Thomas Kappenman                    */
/*    Copyright 2014, Digilent Inc.               */
/*                                                */
/*   Made for use with chipKIT Pro MX7            */
/*   PmodGPS on connector JF 1-6                  */
/**************************************************/
/*  Module Description:                           */
/*                                                */
/*    This module implements a demo application   */
/*    of the PmodGPS.                             */
/*                                                */
/*  Functionality:                                */
/*                                                */  
/*    The module works automatically, first       */
/*    resetting the GPS and then detecting a      */
/*    GPS signal from several satellites before   */
/*    outputting data to the serial monitor.      */
/*    LD1 on the PmodGPS should blink while       */
/*    searching of satellites.                    */
/*                                                */
/**************************************************/
/*  Revision History:                             */
/*                                                */
/*      6/23/2014(TommyK): Created                */
/*                                                */
/**************************************************/
/*                                                */
/*  The data received from the PmodGPS is stored  */
/*  in several structs within the GPS class. This */
/*  data can be accessed by either calling the    */
/*  GPS.getXXX() function to access the struct,   */
/*  or by calling several other get functions.    */
/*                                                */
/*  Example: If I want to see how many satellites */
/*  the GPS is connected to I would access either */
/*  GPSdata.getGGA().NUMSAT to get the char*      */
/*  string, or myGPS.getNumSats() to get an       */
/*  integer value.                                */
/*                                                */
/**************************************************/

#include "PmodGPS.h"

//chipKIT Pro MX7
#define _3DFpin   40 //pin 40, JF-01
#define _1PPSpin  43 //pin43, JF-04
#define RSTpin    37 //pin 37, JE-08

typedef enum{
  RESTART,
  NOTFIXED,
  FIXED
}STATE;


GPS myGPS;
char* LAT;
char* LONG;
NMEA mode;

STATE state=RESTART;

void setup() { 
  Serial.begin(9600);
  myGPS.GPSinit(Serial1, 9600, _3DFpin, _1PPSpin);
}

void loop() {
  //State machine for GPS
  switch (state)
  {
    case(RESTART):
        state=NOTFIXED;
        break;
    case(NOTFIXED)://Look for satellites, display how many the GPS is connected to
      mode = myGPS.getData(Serial1);//Receive data from GPS
      if (mode == GGA){//If GGAdata was received
        Serial.print("Number of Satellites: ");Serial.println(myGPS.getNumSats());
        if (myGPS.isFixed()){//When it is fixed, continue
          state=FIXED;
        }
      }
        break;
    case(FIXED):
        if(myGPS.isFixed()){//Update data while there is a position fix
          mode = myGPS.getData(Serial1);
          if (mode == GGA)//If GGAdata was received
          {
              Serial.print("Latitude: ");Serial.println(myGPS.getLatitude());
              Serial.print("Longitude: ");Serial.println(myGPS.getLongitude());
              Serial.print("Altitude: ");Serial.println(myGPS.getAltitudeString());
              Serial.print("Number of Satellites: ");Serial.println(myGPS.getNumSats());
              Serial.print("\n");
          }
        }
        else {
          state=RESTART;//If PFI = 0, re-enter connecting state
        }
      break;
  }
}
