// Replace [VALUE] with the corresponding value!
// For example
// string  sBaseURL        = "[DOMAIN_NAME OF YOU AZURACAST]";
// string  sBaseURL        = "radio.domain.fm";
// or 
// integer iStationID      = [STATIONNUMBER];
// integer iStationID      = 1;
// ----------------------------------------------------------------------------------------------------------------------------

string  sAPIKey         = "[API KEY FROM AZURACAST]";
string  sBaseURL        = "[DOMAIN_NAME OF YOU AZURACAST]";
integer iStationID      = [STATIONNUMBER];

integer iPWLength       = 8;
list    lPWCharSet      = [
                            "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "v", "w", "x", "y", "z", "ä", "ö", "ü",
                            "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "V", "W", "X", "Y", "Z", "Ä", "Ö", "Ü",
                            "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
                          ];

key     kUserID         = NULL_KEY;
key     kHTTPReqID      = NULL_KEY;
integer iProcessID      = 0;
string  sSavedPW        = "";
string  sUserName       = "";

string whPWGen(list CharSet, integer iLength)
{
    integer i = 0;
    string tmpPass = "";
    for (;i<iLength;i++)
    {
        tmpPass += llList2String(CharSet, (integer)llFrand(llGetListLength(CharSet)-1));
    }
    return tmpPass;
}

key whAzuraReq(string sRequest, string method, string json_body) {
    return llHTTPRequest(sBaseURL + "/api"+ sRequest, [
                                                                HTTP_METHOD, method,
                                                                HTTP_MIMETYPE, "application/json",
                                                                HTTP_BODY_MAXLENGTH, 16384,
                                                                HTTP_CUSTOM_HEADER, "X-API-Key", sAPIKey,
                                                                HTTP_USER_AGENT, "Alphas-ScriptAPI/1.1",
                                                                HTTP_ACCEPT, "application/json"
                                                            ], json_body);
}

default
{
    state_entry()
    {

    }
    
    timer()
    {
        llSetText("", <0,0,0>, 0);
        iProcessID  = 0;
        kHTTPReqID  = NULL_KEY;
        kUserID     = NULL_KEY;
        sSavedPW    = "";
    }

    touch_start(integer total)
    {
        integer i = 0;
        for (;i<total;i++) {
            if (kUserID != NULL_KEY) {
                if (llDetectedKey(i) == kUserID) {
                    llInstantMessage(llDetectedKey(i), "you dont need click more ...");
                } else {
                    llInstantMessage(llDetectedKey(i), "Please wait, system is currently in use by "+llKey2Name(kUserID));
                }
            } else {
                kUserID = llDetectedKey(i);
                llSetText("check for exiting Account ...", <1,1,0>, 1);
                kHTTPReqID = whAzuraReq("/station/" + (string)iStationID + "/streamers", "GET", "");
            }
        }
    }
    


    
    http_response(key request_id, integer status, list metadata, string body)
    {
        if (kHTTPReqID != request_id) return;
        if (iProcessID == 0) {
            if (status == 200) {
                
                list lStreamers = llJson2List(body);
                integer i = 0;
                for (;i<llGetListLength(lStreamers);i++) {
//                    if ((key)llJsonGetValue(llList2String(lStreamers, i), ["display_name"]) == kUserID) {
                    if ((key)llJsonGetValue(llList2String(lStreamers, i), ["comments"]) == kUserID) {
                        iProcessID = 2;
                        llSetText("Account found, generate new PW and Update ...", <0.5,1,0>, 1);
                        sSavedPW = whPWGen(lPWCharSet, iPWLength);
                        sUserName = llJsonGetValue(llList2String(lStreamers, i), ["streamer_username"]);
                        kHTTPReqID = whAzuraReq("/station/" + (string)iStationID + "/streamer/"+llJsonGetValue(llList2String(lStreamers, i), ["id"]), "PUT", llJsonSetValue("", ["streamer_password"], sSavedPW));
                    }
                }
                if (iProcessID != 2) {
                    iProcessID = 1;
                    llSetText("No Account found, register new DJ ...", <0.5,1,0>, 1);
                    string reg = "";
                    sUserName = llGetUsername(kUserID);
                    reg = llJsonSetValue(reg, ["streamer_username"],sUserName);
                    sSavedPW = whPWGen(lPWCharSet, iPWLength);
                    reg = llJsonSetValue(reg, ["streamer_password"], sSavedPW);
                    reg = llJsonSetValue(reg, ["display_name"], llGetDisplayName(kUserID));
//                    reg = llJsonSetValue(reg, ["display_name"], (string)kUserID);
                    reg = llJsonSetValue(reg, ["comments"], (string)kUserID);
//                    reg = llJsonSetValue(reg, ["comments"], "Account created via API: "+llGetTimestamp());
                    reg = llJsonSetValue(reg, ["is_active"], JSON_TRUE);
                    reg = llJsonSetValue(reg, ["enforce_schedule"], JSON_FALSE);
                    kHTTPReqID = whAzuraReq("/station/" + (string)iStationID + "/streamers", "POST", reg);
                }
            } else {
                llSetText("Something are wrong, please try again later ...", <1,0,0>, 1);
                llSetTimerEvent(10);
            }
        } else if (iProcessID > 0) {
            if (status == 200) {
                llSetText("Successful, send Data, please Wait ...", <0,1,0>, 1);


                llInstantMessage(kUserID, "Server: [DOMAIN_NAME OF YOU AZURACAST]");

                llInstantMessage(kUserID, "Evtl. muss die Verbindung direkt via IP-Adresse hergestellt werden.");

                llInstantMessage(kUserID, "Server-IP: [SERVER-IP");

                llInstantMessage(kUserID, "Port: [PORT1] ([PORT2] für einige Clients)");

                llInstantMessage(kUserID, "Mount (falls benötigt): /");

                llInstantMessage(kUserID, "Benutzername: "+sUserName);

                llInstantMessage(kUserID, "Passwort: "+sSavedPW);

                llInstantMessage(kUserID, "(bei Shoutcast v1): "+sUserName+":"+sSavedPW);

                llSetTimerEvent(10);
            } else {
                llSetText("Something are wrong, please try again later ...", <1,0,0>, 1);
                llSetTimerEvent(10);
            }
        }
    }
}
