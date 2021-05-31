/*
 Author: Sarogahtyp
 Description: -registers clients which run arena on server
			  -adds EH on server to handle a disconnected player 
*/

private _dummy = params ["_uid", "_vec", "_reload_time", "_range", "_fire_max_range", "_fire_min_range", "_charge_height"];

private _vec_params = [_vec, _reload_time, _range, _fire_max_range, _fire_min_range, _charge_height];

if (isNil "saro_clients_running_arena") then
{
 if ( missionNamespace getVariable "debugOn" ) then { diag_log "SASPS CR-Server: No array found. Registering first vehicle/player."; };

 saro_clients_running_arena = [];

 saro_meh_plyr_disc_index = addMissionEventHandler ["PlayerDisconnected",
 {
  if ( missionNamespace getVariable "debugOn" ) then { diag_log "SASPS CR-Server: Player disconnected, EH unregisters players vehicles"; };
  
  _this spawn
  {
   params ["", "_uid"];

   private _plyr_vecs = [];

   private _index = saro_clients_running_arena findIf { (_x#0) isEqualTo _uid}; // return index of players entry
 
   // player not register
   if (_index isEqualTo -1) exitWith {};
 
   _plyr_vecs = saro_clients_running_arena deleteAt _index; 
  
   //this was the last player in array. Nil the array and remove mission EH
   if (saro_clients_running_arena isEqualTo []) then
   {
    saro_clients_running_arena = nil;
    removeMissionEventHandler ["PlayerDisconnected", saro_meh_plyr_disc_index];
   };

   private _dummy = _plyr_vecs deleteAt 0; // delete uid

   private "_vec_params";

   _dummy =
   {
    _vec_params = [ (_x#0), (_x#1), (_x#2), (_x#3), (_x#4), (_x#5) ];

    (_x#0) setOwner 2; //transfer vehicle to server
    (_x#0) setVariable ["saro_arena_active", false, true];
    
    // give network time to broadcast variable
    sleep 0.5;
   
    if ( !local (_x#0) ) then
    {
     if ( missionNamespace getVariable "debugOn" ) then { diag_log "SASPS CR-Server: Player disconnected, vehicle not local, starting AS on client"; };
  
     //send to machine where the vehicle is local
     _dummy = _vec_params remoteExec [ "saro_fnc_arena_start", (owner (_x#0)) ];
    } else
    {
     if ( missionNamespace getVariable "debugOn" ) then { diag_log "SASPS CR-Server: Player disconnected, vehicle local, starting AS on server"; };
   
     _dummy = _vec_params spawn saro_fnc_arena_start;
    };
   } count _plyr_vecs;
  };
 }];
};

private _index = saro_clients_running_arena findIf {(_x#0) isEqualTo _uid};

if (_index isEqualTo -1) exitWith
{
 _dummy = saro_clients_running_arena pushback [_uid, _vec_params];
};

_dummy = (saro_clients_running_arena select _index) pushback _vec_params;