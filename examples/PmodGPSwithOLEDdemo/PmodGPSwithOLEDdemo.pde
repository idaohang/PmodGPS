/**************************************************/
/* PmodGPS Demo with OLED                         */
/**************************************************/
/*    Author: Thomas Kappenman                    */
/*    Copyright 2014, Digilent Inc.               */
/*                                                */
/*   Made for use with chipKIT Pro MX7            */
/*   PmodGPS on connector JF 1-6, pmodOLED on JD  */
/**************************************************/
/*  Module Description:                           */
/*                                                */
/*    This module implements a demo application   */
/*    of the PmodGPS along with the PmodOLED.     */
/*                                                */
/*  Functionality:                                */
/*                                                */  
/*    The module works automatically, first       */
/*    resetting the GPS and then detecting a      */
/*    GPS signal from several satellites before   */
/*    outputting data to the OLED screen.         */
/*    btn1 and btn2 switch between available data */
/*    once fixed.                                 */
/*    LD1 on the PmodGPS should blink while       */
/*    searching for satellites.                   */
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
#include <OLED.h>
#include <DSPI.h>

OledClass OLED;


//chipKIT Pro MX7
#define _3DFpin   40 //pin 40, JF-01
#define _1PPSpin  43 //pin43, JF-04
#define RSTpin    37 //pin 37, JE-08
#define btn1      48 //Btn1 on MX7cK
#define btn2      49 //Btn2 on MX7cK


//Because the PmodOLED doesn't include the degree character, a custom character can be used
#define degree 0x01 //Custom character code for degree
uint8_t degreeDef[8]={0x00,0x00,0x07, 0x05, 0x07, 0x00, 0x00, 0x00};//Degree symbol


typedef enum{
  RESTART,
  NOTFIXED,
  ENTERFIXED1,
  ENTERFIXED2,
  FIXED1,
  FIXED2
}STATE;


GPS myGPS;

STATE state=RESTART;
char* LAT;
char* LONG;
NMEA mode;
int dot=0;


void setup() {
  OLED.begin();
  myGPS.GPSinit(Serial1, 9600, _3DFpin, _1PPSpin);
  pinMode(btn1, INPUT);
  pinMode(btn2, INPUT);
  OLED.setCharUpdate(1);//Automatically update OLED when strings are written
  OLED.defineUserChar(degree, degreeDef);//Custom degree character defined
}

void loop() {
  //State machine for GPS
  switch (state)
  {
    case(RESTART)://Set non changing text
        OLED.clearBuffer();
        OLED.updateDisplay();
        OLED.setCursor(0, 0);
        OLED.putString("Connecting...");
        OLED.setCursor(0, 1);
        OLED.putString("# Sats:");
        state=NOTFIXED;
        break;
        
    case(NOTFIXED)://Look for satellites, display how many the GPS is connected to
      mode = myGPS.getData(Serial1);//Receive data from GPS
      
      if (mode == GGA){//If GGAdata was updated, since NUMSAT and PFI are stored here, happens once per second
        OLED.setCursor(10,0);//Dot sequence
        switch(dot){
          case(0):OLED.putString(".   "); dot=1; break;
          case(1):OLED.putString("..  "); dot=2; break;
          case(2):OLED.putString("... "); dot=3; break;
          case(3):OLED.putString("...."); dot=0; break;
        }
        OLED.setCursor(8,1);
        OLED.putString(myGPS.getGGA().NUMSAT);//Print number of sats on OLED
        if (myGPS.isFixed()){//When it is fixed, continue
          dot=0;
          state=ENTERFIXED1;
        }
      }
        break;
        
    case (ENTERFIXED1)://Set non changing text
          OLED.clearBuffer();
          OLED.updateDisplay();
          
          OLED.setCursor(0, 2);
          OLED.putString("Alt:");
                                          
          OLED.setCursor(0, 3);
          OLED.putString("# Sats:");

          state=FIXED1;
          
      break;
      
    case(FIXED1):
    
        while (myGPS.isFixed())//Continually update data on OLED while position is fixed
        {
          if (digitalRead(btn2))
          {
            state=ENTERFIXED2;
            break;
          }
          mode = myGPS.getData(Serial1);//Receive data from GPS
          if (mode = GGA)//If GGAdata was just updated
          {//Update this info on the screen
            OLED.setCursor(0, 0);
              LAT=myGPS.getLatitude();
              LAT[2]=0x01;//Custom degrees character for OLED
              OLED.putString(LAT);
            OLED.setCursor(0, 1);
              LONG=myGPS.getLongitude();
              LONG[3]=0x01;//Custom degrees character for OLED
              OLED.putString(LONG);
            OLED.setCursor(4, 2);
              OLED.putString(myGPS.getAltitudeString());
            OLED.setCursor(8, 3);
              OLED.putString(myGPS.getGGA().NUMSAT);//Gets NUMSATs as a string
          }
        }
            
         if (!myGPS.isFixed())state=RESTART;//If not fixed, re-enter connecting state
      break;
      
    case (ENTERFIXED2)://Set non changing text
          OLED.clearBuffer();
          OLED.updateDisplay();
          
          OLED.setCursor(0, 0);
          OLED.putString("Date:");//Cursor at (5,0)
                                          
          OLED.setCursor(0, 1);
          OLED.putString("Spd:");//Cursor at (4,1) for KM and then (4,2) for knots
          
          OLED.setCursor(0, 3);
          OLED.putString("Head:");//Heading (cursor at (5,3)

          state=FIXED2;
          
      break;
    case(FIXED2):
        while (myGPS.isFixed()){//Continually update data on OLED while position is fixed
            if (digitalRead(btn1))
            {
              state=ENTERFIXED1;
              break;
            }
            mode = myGPS.getData(Serial1);//Receive data from GPS
            if (mode == RMC)//If RMCdata was updated
            {
              OLED.setCursor(5, 0);
                OLED.putString(myGPS.getDate());
            }
            else if (mode == VTG)//If VTGdata was updated
           { 
              //NOTE: Speed data is not accurate at low speeds, so output 0's at low speeds
              OLED.setCursor(4, 1);
                if (myGPS.getSpeedKM()>3){//If faster than 3 KM/H
                  OLED.putString(myGPS.getVTG().SPD_KM);
                }
                else{//If slower than 3 KM/H
                  OLED.putString("0");
                }
                OLED.putChar(' ');
                OLED.putChar(myGPS.getVTG().UNIT_KM);//Unit
                OLED.putString("   ");//Erase old chars on OLED
                
              OLED.setCursor(4, 2);
                if (myGPS.getSpeedKM()>3){
                  OLED.putString(myGPS.getVTG().SPD_N);
                }
                else{OLED.putString("0");} 
                OLED.putChar(' ');
                OLED.putChar(myGPS.getVTG().UNIT_N);
                OLED.putString("   ");
                
              OLED.setCursor(5, 3);
                if (myGPS.getSpeedKM()>3){
                  OLED.putString(myGPS.getVTG().COURSE_T);
                }
                else{OLED.putString("0");}
                OLED.putChar(0x01);//Custom degrees char
                OLED.putString("  ");
           }
          
        }
         if (!myGPS.isFixed())state=RESTART;//If PFI = 0, re-enter connecting state
      break;
  }
}

/*Bonus tip
  //For Satellite info
      SATELLITE* satInfo;    //Make a SATELLITE struct pointer
      satInfo= myGPS.getSatelliteInfo();     //Grab the array of satellites
    //Now all of the info is in this satInfo array.
      for(i=0; i<=13; i++)
      {
        Serial.println(satInfo[i].ID);
        Serial.println(satInfo[i].ELV);
        Serial.println(satInfo[i].AZM);
        Serial.println(satInfo[i].SNR);
      }
*/

