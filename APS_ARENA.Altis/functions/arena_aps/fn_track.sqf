/*
 Author: Sarogahtyp
 Description: tracks a threatening object and calls the function to shoot a protection charge if it is near
*/

params [["_vec", objNull, [objNull]], ["_threat", objNull, [objNull]], "_max_distSqr", "_maxHeight"];

if ( saro_arena_debug ) then { diag_log "SASPS TR: Script started, nothing checked."; };

if !(isNull _vec) then
{
 if (!alive _vec) exitWith 
 {
  if ( saro_arena_debug ) then { diag_log "SASPS TR: Vehicle dead, Setting saro_tracking false."; };
  _vec setVariable ["saro_tracking", false, true];
 };
} else 
{ 
 if (true) exitWith 
 {
  if ( saro_arena_debug ) then { diag_log "SASPS TR: Vehicle null, exiting only."; };
 }; 
};

if (isNull _threat || { !alive _threat } ) exitWith
{
  if ( saro_arena_debug ) then { diag_log "SASPS TR: Threat null or dead, exiting and setting saro_tracking false."; };
  _vec setVariable ["saro_tracking", false, true];
};

//if threat is not local at this point then we are on server machine!
//Therefore we just execute this script on the proper client and leave.
if (!local _threat) exitWith
{
 if ( saro_arena_debug ) then { diag_log "SASPS TR-Server: Threat not local, exiting and restarting on client."; };
  //send to machine where the threat is local
  _dummy = [ _vec, _threat, _max_distSqr, _maxHeight ] remoteExec [ "saro_fnc_track", (owner _threat) ];
};  
 
private _dummy = 0;
private "_last_dist";
private _dist = _vec distanceSqr _threat;

waitUntil 
{
 isNil 
 {
  _last_dist = _dist;
 
  //check if something bad happend with vec or threat
  if ( isNil "_vec" || isNil "_threat" || { isNull _vec || isNull _threat || { !alive _vec || !alive _threat } } ) exitWith 
  {
   if ( saro_arena_debug ) then { diag_log "SASPS TR: Vehicle or threat gone, exiting isNil with nil to return true and therefore exiting waitUntil."; };
  };

  _dist = _vec distanceSqr _threat;
 
  if ((_dist < _max_distSqr) && (_last_dist > _dist)) then
  {
   if ( saro_arena_debug ) then { diag_log "SASPS TR: Threat in range, defending and setting saro_charge_fired true."; };

   _dummy = [_vec, (position _threat), _maxHeight] spawn saro_fnc_fire_cone;

   [_threat] call saro_fnc_substitute_threat;
  
   _vec setVariable ["saro_charge_fired", true, true];
  };
  // if charge is fired or threat is moving away then end isNil with nil to get waitUntil finished.
  if ((_vec getVariable "saro_charge_fired") or (_last_dist < _dist)) then {} else {false};
 };
};

//check if something bad happend with vec
if ( isNil "_vec" || { isNull _vec || { !alive _vec } } ) exitWith 
{
 if ( saro_arena_debug ) then { diag_log "SASPS TR: Vehicle gone. Exiting script only."; };
};

if ( saro_arena_debug ) then { diag_log "SASPS TR: Normal script exit. Setting saro_tracking false"; };

_vec setVariable ["saro_tracking", false, true];