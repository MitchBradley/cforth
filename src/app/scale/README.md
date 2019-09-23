# WiFi Bathroom Scale

This is a project to convert an ordinary digital bathroom
scale into one that sends the reading to a Google Sheets
spreadsheet via WiFi.  It replaces the scale's electronics
board and LCD with an HX711 load cell amplifier module
($1), a Wemos D1 Mini ESP8266 board ($3), a Wemos OLED
display shield ($3), and a few other inexpensive components
(FET, resistors, capacitor, switch).  The enclosure,
an ordinary FSE PVC electrical box, costs about the same
as the electronics.

## User Interaction

- Push the button to awaken the ESP8266 from deep sleep
- The CPU displays 888 on the OLED indicating that it
is calibrating, then takes a few reading to tare the
scale.  This takes a couple of seconds
- The CPU displays 0 to show that it is ready.
- The user steps on the scale and the weight is displayed
- If the user wants to send the reading to the spreadsheet
in the cloud, they press the button again.  The data
is transmitted to the spreadsheet, which computes a
moving average of the last few readings and sends that
back.
- The average is displayed on the OLED for a few seconds,
then the CPU turns off the display and goes to sleep
- If the user steps off the scale without pressing the
button to send the data, the CPU sleeps after a few
seconds of 0 reading.

## Spreadsheet code

The spreadsheet is a Google Sheets spreadsheet with this schema

<table>
<tr>
<th>Date</th> <th>Weight</th> <th>Average</th> <th>Filter Length</th>
</tr>
<tr>
<td>09/20/2019</td> <td>161</td> <td>=$B$2</td> <td>4</td>
</tr>
<tr>
<td>09/21/2019</td> <td>160</td> <td>=((C2*($D$2-1)+B3)/$D$2)</td> <td>4</td>
</tr>
</table>

The formula in column C is a first order recursive filter that averages
over (more or less) the number of days in D1.

The spreadsheet has this associated script, which receives URLs like

``https://script.google.com/macros/s/<ID>/exec?Weight=159``
adds a new row to the bottom of the sheet with that weight and the
current date, and returns the new value of the moving average.

```
// Format a string into text for the HTML response
function out( s ) {
  return ContentService.createTextOutput(s).setMimeType(ContentService.MimeType.TEXT);
}

function doPost(e) { 
  var ssID = ScriptProperties.getProperty('targetSpreadsheetID');
  if (ssID == null ) {
    return( out( "Property targetSpreadsheetID not found. Be sure to run Setup script."));
  }
  var ss = SpreadsheetApp.openById( ssID );  
  if (ss == null ) {     
    return( out( "Could not find spreadsheet ID ["+ssID+"]. Aborting."));    
  }
  var sheetName = ScriptProperties.getProperty('targetSheetName');
  if (sheetName == null ) {
    return( out( "Property targetSheetName not found. Be sure to run Setup script."));
  }  
  var sheet = ss.getSheetByName(sheetName);
  if (sheet == null ) {
    return( out( "Could not find sheet named  ["+sheetName+"]. Aborting."));
  }
  var parameters = e.parameter;   // Grab the parameters from the request
  var headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];  //read headers from top row of spreadsheet    
  var lastRow = sheet.getLastRow();
  var newRow = [];     // Hold new row to be Added to bottom           
  newRow[0] = Utilities.formatDate(new Date(), "HST", "MM/dd/yyyy");
  newRow[1] = parameters['Weight'];
  newRow[2] = 0;
  
  sheet.appendRow(newRow);   // Append new row to end of spreadsheet  
  var averageCell = sheet.getRange(lastRow+1,3);
  sheet.getRange(lastRow,3).copyTo(averageCell);
  return( out(averageCell.getDisplayValue()) );
}

function doGet(e) {
  return(doPost(e));
}

function setupLoggingToCurrentSheet() {
  ScriptProperties.setProperty('targetSpreadsheetID', SpreadsheetApp.getActiveSpreadsheet().getId());
  ScriptProperties.setProperty('targetSheetName', SpreadsheetApp.getActiveSpreadsheet().getActiveSheet().getSheetName());      
}

function onOpen() {
  SpreadsheetApp.getActive()
  .addMenu("Setup Logging",
           [{name: "Setup Script", 
             functionName: "setupLoggingToCurrentSheet"}]);
}

```

## HTTP to HTTPS tunneling

ESP8266's have a hard time with SSL security due to the high RAM
requirements of a full TLS certificate check, so instead of speaking
https directly, this program speaks http to a proxy on the local
network, which converts to https to speak securely over the web.

I use the stunnel proxy program with the following entry in
the /etc/stunnel/stunnel.conf configuration file:

```
[http]
client = yes
accept = 6000
connect = script.googleusercontent.com:443
verify = 0
```

script.googleusercontent.com is a secure redirect for
script.google.com

You can run such a proxy on any machine on your local
network that is always on (or is on when you want to send
data from the scale).  I run it on my WiFi router, which
runs the open source "OpenWrt" routing code and can
host other programs like stunnel.

## Acknowledgment

I got the basic recipe for how to log to a Google spreadsheet from

https://wp.josh.com/2014/06/04/using-google-spreadsheets-for-logging-sensor-data/

His script is very flexible and will automatically create columns
based on the URL parameters.  I simplified it to do only what I
need, adding the date stamp automatically, propagating the
averaging column formula and returning its value.

That page tells you how to set things up and get the ID
that goes into spreadsheet-url-prefix in app.fth .
