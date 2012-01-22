// Shed Security Alarm

local button = 0;
local door = 0;
local sensor = 0;
local adcValue = 0;

local lights = hardware.pin1;
local sounder = hardware.pin5;
local beacon = hardware.pin7;
local buzzer = hardware.pin8;
local adcSensors = hardware.pin9;
local temp = hardware.pin2;

beacon.configure(DIGITAL_OUT);
sounder.configure(DIGITAL_OUT);
lights.configure(DIGITAL_OUT);
buzzer.configure(DIGITAL_OUT);
temp.configure(ANALOG_IN);
adcSensors.configure(ANALOG_IN);

beacon.write(0);
sounder.write(0);
lights.write(0);
buzzer.write(0);

//if the door opens, count up before sounding the alarm
local alarmCounter = 0;

//variable so we can pulse the buzzer
local buzzerState = 0;

//has the system been muted
local alarmMute = 0;

//can we check to reset the system?
local resetCheck = 0;

//time for the system to wait before re-arming
local systemWaitFor = 20;
local systemWait = 0;

//can we start the reset process?
local startReset = 0;

//is the alarm sounding?
local alarmSounding = 0;

//time to allow the sounder to sound
local alarmSoundingLimit = 300;
local alarmSoundingCounter = 0;

//should the buzzer be on constantly
local buzzerConstant = 0;
 
// you can read the imp's input voltage at any time with:
local voltage = hardware.voltage();
server.log(format("Running at %f", voltage));
 
server.log("Hardware Configured");
 
function checkSensors() {
    adcValue = adcSensors.read();
    
    local tempValue = temp.read();
    
    if (adcValue < 100){
        button = 1;
        sensor = 0;
        door = 0;
    } else if (adcValue < 31000){
        button = 0;
        sensor = 1;
        door = 0;
    } else if (adcValue < 38000){
        button = 0;
        sensor = 0;
        door = 0;
    } else {
        button = 0;
        sensor = 0;
        door = 1;  
    }
    
    
    //if the door is opened, start the counter
    if (door == 1){
        if ((alarmCounter == 0) && (alarmMute == 0)){
            alarmCounter = 1;    
            beacon.write(1);
            server.log("door");
        }
    } 
    
    //if the door has been opened, start counting up
    if (alarmCounter > 0){
        alarmCounter++;
        //pulse the buzzer
        if (buzzerConstant){
            buzzer.write(1);
        } else {
            if (buzzerState){
                buzzer.write(0);
                buzzerState = 0;
            } else {
                buzzer.write(1);
                buzzerState = 1;
            }
        }
    }
    
    //if the reset button has ben pressed, then acknowledge this (but only if we are in alarm)
    if((button) && (alarmCounter)){
        alarmMute = 1;
        startReset = 1;
        //mute the stuff
        sounder.write(0);
        lights.write(0);
        buzzer.write(0);
        beacon.write(0);
        alarmCounter = 0;
        alarmSounding = 0;
        alarmSoundingCounter = 0;
        buzzerConstant = 0;
        server.log("mute everything");
        buzzer.write(0);
        imp.sleep(0.1);
        buzzer.write(1);
        imp.sleep(0.1);
        buzzer.write(0);
        imp.sleep(0.1);
        buzzer.write(1);
        imp.sleep(0.1);;
        buzzer.write(0);
        imp.sleep(0.1);
        buzzer.write(1);
        imp.sleep(0.1);
        buzzer.write(0);
        imp.sleep(0.1);
    }
    
    if (startReset){
        //if wait for counter has elapsed, we can reset
        if (systemWait > systemWaitFor){
            startReset = 0;
            systemWait = 0;
        } else {
           systemWait++; 
        }
    
    }
    
    //if the mute button has bee is closed after a reset, then reset the whole alarm
    if ((alarmMute) && (button == 0) && (door == 0) && (startReset == 0)){
        alarmMute = 0;
        server.log("reset system");
        //chirp the buzzer, indicating a reset.
        buzzer.write(1);
        imp.sleep(0.1);
        buzzer.write(0);
        imp.sleep(0.1);
        buzzer.write(1);
        imp.sleep(0.1);;
        buzzer.write(0);
        imp.sleep(0.1);
        buzzer.write(1);
        imp.sleep(0.1);
        buzzer.write(0);
        imp.sleep(0.1);
    }
    
    if (alarmCounter > 30){
        sounder.write(1); 
        lights.write(1); 
        if (alarmSounding == 0){
            //if the sounders are just about to be switched on, alert the server
            server.log("sounders!");
        }
        alarmSounding = 1;
        buzzerConstant = 1; 
    }
    
    if (alarmSounding){
        alarmSoundingCounter++;
        if (alarmSoundingCounter > alarmSoundingLimit){
            //the sounder has reahced its sounder limit
            sounder.write(0); 
            alarmSounding = 0;
            server.log("mute sounder");
        }
    }
    
    //server.log(format("Temp at %.2f V", tempValue));
    //server.log(format("ADC at %.2f", adcValue));
    
    imp.wakeup(1, checkSensors);
}
 
server.log("Shed Alarm");
imp.configure("Shed Alarm", [], []);
checkSensors();
 
//EOF