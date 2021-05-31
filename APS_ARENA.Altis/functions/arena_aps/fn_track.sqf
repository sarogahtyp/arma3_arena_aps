/*
 Author: Sarogahtyp
 Description: tracks a threatening object and calls the function to shoot a protection charge if it is near
*/

params [["_vec", objNull, [objNull]], ["_threat", objNull, [objNull]], "_max_distSqr", "_maxHeight"];

if (isNull _vec || !alive _vec) exitWith {};

if (isNull _threat || !alive _threat) exitWith 
{ 
 _vec setVariable ["saro_tracking", false, true];

 // give network time to broadcast variables
 sleep 0.5;
};

//if threat is not local at this point then we are on server machine!
//Therefore we just execute this script on the proper client and leave.
if (!local _threat) exitWith
{
  //send to machine where the threat is local
  _dummy = [ _vec, _threat, _max_distSqr, _maxHeight ] remoteExec [ "saro_fnc_track", (owner _threat) ];
};  
 
private _dummy = 0;
private _last_dist = _vec distanceSqr _threat;;
private _dist = _last_dist;

waitUntil 
{
 _dummy = isNil 
 {
  _last_dist = _dist;
 
  //check if something bad happend with vec or threat
  if (isNil "_vec" || isNil "_threat" || { isNull _vec || isNull _threat || { !alive _vec || !alive _threat } }  ) exitWith {true};

  _dist = _vec distanceSqr _threat;
 
  if ((_dist < _max_distSqr) && (_last_dist > _dist)) then
  {
   _dummy = [_vec, (position _threat), _maxHeight] spawn saro_fnc_fire_cone;

   [_threat] call saro_fnc_substitute_threat;
  
   _vec setVariable ["saro_charge_fired", true, true];
  };
 };
 
 (_vec getVariable "saro_charge_fired") or (_last_dist < _dist)
};

//check if something bad happend with vec
if ( isNil "_vec" || { isNull _vec || { !alive _vec } } ) exitWith {};

_vec setVariable ["saro_tracking", false, true];

// give network time to broadcast variables
sleep 0.5;