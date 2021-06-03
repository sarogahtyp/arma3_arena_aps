/*
 Author: Sarogahtyp
 Description: Searches for near AT objects and tries to destroy those
			  Full Multiplayer compatible.
			  Main loop runs on machine where vehicle is local.
			  If locality of vehicle changes then the script will change locality as well
			  If a threat is found then it will be tracked and 
			  destroyed by a script on the machine where that threat is local.

Params:
		_vec - object - vehicle to which the Arena system is to be attached
		_reload_time - number - optional - time to reload the charge after it was fired (default 2 seconds)
										 - if lower 0.5 seconds than it is changed to 0.5 seconds
        _range - number - optional - detection range (default 200 meters)
        _fire_max_range - number - optional - maximum interception distance (default 70 meters)
        _fire_min_range - number - optional - minimum interception distance (default 15 meters)
		_charge_height - number - optional - charge explodes on this height above vehicle (default 10 meters)
*/

private _dummy = params [ ["_vec", objNull, [objNull]], ["_skill", 90, [0]], ["_reload_time", 0, [0]], ["_range", 200, [0]], ["_fire_max_range", 40, [0]], ["_fire_min_range", 15, [0]], ["_charge_height", 10, [0]] ];


_skill = if (_skill > 100) then {100} else {_skill};
_skill = if (_skill <= 0) then {0.001} else {_skill};

_skill = if (_skill < 68) then { 0.074 * _skill } else
{
 if (_skill < 87) then { 0.263 * _skill - 12.895 } else
 {
  if (_skill < 91) then { 2.5 * _skill - 207.5 } else { 4.444 * _skill - 384.444 };

 };
};

//set debug mode for whole arena system here
_debug = false;

missionNamespace setVariable ["saro_arena_debug", _debug, true];

//script entered, logging it.
if (isServer) then
{
 if ( saro_arena_debug ) then { diag_log "SASPS AS-Server: Script started, nothing checked."; };
}
else
{
 if ( saro_arena_debug ) then { diag_log "SASPS AS-Client: Script started, nothing checked."; };
};

//no object given, leave.
if (isNull _vec || {!alive _vec || !(_vec in vehicles) }) exitWith 
{
 if ( saro_arena_debug ) then { diag_log "SASPS AS: Object is not an alive vehicle. Exit."; };
};

//arena active allready?
if ( !isNil {_vec getVariable "saro_arena_active"} ) then
{
 if (_vec getVariable "saro_arena_active") exitWith 
 {
  if ( saro_arena_debug ) then { diag_log "SASPS AS: EXIT, arena active allready"; };
 };
};

//ensure that arena runs on the machine where the vehicle is local
if (!local _vec) exitWith
{
 if (isServer) then
 {
  if ( saro_arena_debug ) then { diag_log "SASPS AS-Server: Vehicle not local, starting AS on client"; };
  
  //send to machine where the vehicle is local
  _dummy = _this remoteExec [ "saro_fnc_arena_start", (owner _vec) ];
 }
 else
 {
  if ( saro_arena_debug ) then { diag_log "SASPS AS-Client: Vehicle not local starting AS on server"; };
  
  //as we are not on server we have to send it to server which will transfer it to the correct client
  _dummy = _this remoteExec [ "saro_fnc_arena_start", 2 ];
 };
};

//register running script instance on server to be able to handle locality changes
if (!isServer) then
{
 _dummy = [(getPlayerUID player), _vec, _reload_time, _range, _fire_max_range, _fire_min_range, _charge_height] remoteExec [ "saro_fnc_client_register", 2 ];
};

// mark arena active
_vec setVariable ["saro_arena_active", true, true];

private _bbr = boundingBoxReal _vec;
private _p1 = _bbr select 0;
private _p2 = _bbr select 1;

_maxHeight = abs ((_p2 select 2) - (_p1 select 2)) + _charge_height;
_maxWidth = 0.5 * (abs ((_p2 select 0) - (_p1 select 0)) max abs ((_p2 select 1) - (_p1 select 1))) ;

private "_fire_range";

_range = if (_range <= _fire_max_range) then {_fire_max_range + 1} else {_range};

//_sleep_time for main loop. missiles should not get closer than 120% of _fire_max_range in one sleep cycle
//assuming 2000 m/s as max speed for armas AT threats
private _sleep_time = 0.4 * (_range - _fire_max_range) / 2000;

// mark loaded charge as not fired
_vec setVariable ["saro_charge_fired", false, true];

// mark tracking as inactive
_vec setVariable ["saro_tracking", false, true];

// give network time to broadcast variables
sleep 0.5;

while { !isNil {"_vec"} && { !isNull _vec && { (_vec getVariable "saro_arena_active") && (local _vec) && (alive _vec) } } } do
{
 _incoming =[];

 waitUntil 
 {
  sleep _sleep_time;

  //check if something bad happend with vec
  if (isNil "_vec" || { isNull _vec || { !alive _vec } } ) exitWith 
  {
   if ( saro_arena_debug ) then { diag_log "SASPS AS: Vehicle null, nil or dead. Exiting waitUntil"; };
   true
  };

  if (_vec getVariable "saro_charge_fired") then
  {
   _vec setVariable ["saro_charge_fired", false, true];
   sleep (_reload_time max 0.5);
  };
  
  !(_vec getVariable "saro_tracking")
 };

 //check if something bad happend with vec
 if (isNil "_vec" || { isNull _vec || { !alive _vec } } ) exitWith 
 {
  if ( saro_arena_debug ) then { diag_log "SASPS AS: Vehicle null, nil or dead. Exiting while"; };
 };

 _incoming = (_vec nearObjects["RocketBase",_range]) select { (vectorMagnitude velocity _x) > 25 };

 if (_incoming isEqualTo []) then
 {
  _incoming append (_vec nearObjects["MissileBase",_range]) select { (vectorMagnitude velocity _x) > 25 };
 
  if (_incoming isEqualTo []) then
  {
   _incoming append (_vec nearObjects["ShellBase",_range]) select { (vectorMagnitude velocity _x) > 25 };
  };
 };
 
 if !(_incoming isEqualTo []) then
 {
  _vec setVariable ["saro_tracking", true, true];

  private _threat = (_incoming#0);
  
  private _speed = vectorMagnitude velocity _threat;

  _fire_range = ( _fire_max_range - _fire_min_range ) * _speed / 2000 + _fire_min_range;

  _max_distSqr = (_maxWidth + _fire_range)^2;

  if (!local _threat) then
  {
   if (isServer) then
   {
    //send to machine where the threat is local
    _dummy = [ _vec, _threat, _skill, _max_distSqr, _maxHeight] remoteExec [ "saro_fnc_track", (owner _threat) ];
   }
   else
   {
    //as we are not on server we have to send it to server which will transfer it to the correct client
    _dummy = [ _vec, _threat, _skill, _max_distSqr, _maxHeight] remoteExec [ "saro_fnc_track", 2 ];
   };
  } else
  {
   //track locally
   _dummy = [ _vec, _threat, _skill, _max_distSqr, _maxHeight ] spawn saro_fnc_track;
  };
 };
};

//check if something bad happend with vec
if !(isNil "_vec" || { isNull _vec } ) then
{
 if ( !alive _vec ) exitWith
 {
  // vehicle is destroyed. Mark arena inactive
  _vec setVariable ["saro_arena_active", false, true];

  if (isServer) then
  {
   if ( saro_arena_debug ) then { diag_log "SASPS AS-Server: Vehicle is dead. Exiting script.";};
  } else
  {
   if ( saro_arena_debug ) then { diag_log "SASPS AS-Client: Vehicle is dead. Exiting script and unregistering";};

   _dummy = [(getPlayerUID player), "_vec"] remoteExec [ "saro_fnc_client_unregister", 2 ]; 
  };
 };
} else
{
 if (true) exitWith 
 {
  if ( saro_arena_debug ) then { diag_log "SASPS AS: Vehicle is nil or null. Exiting script"; };
 };
};

//loop ended but arena is active. Means vehicle is not local anymore and we start the whole script again.
if (_vec getVariable "saro_arena_active") exitWith
{
 // mark arena inactive
 _vec setVariable ["saro_arena_active", false, true];

 // give network time to broadcast variable
 sleep 0.5;

 if (isServer) then
 {
  if ( saro_arena_debug ) then { diag_log "SASPS AS-Server: Vehicle not local anymore. Restarting script on client."; };
  _dummy = _this remoteExec [ "saro_fnc_arena_start", (owner _vec) ];
 } else
 {
  if ( saro_arena_debug ) then { diag_log "SASPS AS-Client: Vehicle not local anymore. Unregistering. Restarting script on server."; };

  _dummy = [(getPlayerUID player), "_vec"] remoteExec [ "saro_fnc_client_unregister", 2 ];
  _dummy = _this remoteExec [ "saro_fnc_arena_start", 2 ];
 };
};

//script was disabled, leave normal
if (isServer) then
{
 if ( saro_arena_debug ) then { diag_log "SASPS AS-Server: Normal script exit. Exiting script.";};
} else
{
 if ( saro_arena_debug ) then { diag_log "SASPS AS-Client: Normal script exit. Exiting script and unregistering";};

 _dummy = [(getPlayerUID player), "_vec"] remoteExec [ "saro_fnc_client_unregister", 2 ]; 
};