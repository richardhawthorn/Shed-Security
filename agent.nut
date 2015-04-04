#require "Twilio.class.nut:1.0.0"
twilio <- Twilio("xxxx", "xxxx", "xxxx");
numberToSendTo <- "xxxx";

//send a text!
function sendText(text)
{
    message <- "Shed: "+text;

    twilio.send(numberToSendTo, message, function(response) {
        server.log(response.statuscode + " - " + response.body)
    })
}
 
//receive incoming messages from the device
device.on("message", sendText); 