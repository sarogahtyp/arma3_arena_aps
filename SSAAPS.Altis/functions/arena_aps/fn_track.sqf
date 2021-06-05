/*
 Author: Sarogahtyp
 Description: tracks a threatening object and calls the function to shoot a protection charge if it is near
*/

params [["_vec", objNull, [objNull]], ["_threat", objNull, [objNull]], "_skill", "_lift_start_height", "_lift_speed", "_fire_max_range", "_fire_min_range", "_lift_time", "_maxWidth" ];

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

// if threat is not local at this point then we are on server machine!
// Therefore we just execute this script on the proper client and leave.
if (!local _threat) exitWith
{
 if ( saro_arena_debug ) then { diag_log "SASPS TR-Server: Threat not local, exiting and restarting on client."; };
  //send to machine where the threat is local
  _dummy = [ _vec, _threat, _skill, _lift_start_height, _lift_speed, _fire_max_range, _fire_min_range, _lift_time, _maxWidth ] remoteExec [ "saro_fnc_track", (owner _threat) ];
};

//weight handicap for 1000 m/s
private _weight_handicap = 0.5556;

//randomize within skill limit
_skill = 100 - random (100 - _skill);

//get class name of threat
private _class = typeOf _threat;

//randomize charge speed for substitution and apply skill on it
_charge_speed = random [0.016, 0.018, 0.02] * _skill *_weight_handicap;

//manipulate skill for use on substitute script
_skill = _skill * 0.5;

private _dummy = 0;
private "_last_dist";
private _dist = _vec distanceSqr _threat;

private _charge_holder = objNull;
private _break_while = false;

while { !_break_while } do
{
 _break_while = isNil 
 {
  _last_dist = _dist;
 
  //check if something bad happend with vec or threat
  if ( isNil "_vec" || isNil "_threat" || { isNull _vec || isNull _threat || { !alive _vec || !alive _threat } } ) exitWith 
  {
   if ( saro_arena_debug ) then { diag_log "SASPS TR: Vehicle or threat gone, exiting isNil with nil to return true and therefore exiting waitUntil."; };
  };
  
  private _threat_speed = vectorMagnitude velocity _threat;
  
  _fire_range = ( _fire_max_range - _fire_min_range ) * _threat_speed / 2000 + _fire_min_range;
  
  _lift_range = (_fire_range + _threat_speed * _lift_time)^2;

  _max_distSqr = (_maxWidth + _fire_range)^2;

  _dist = _vec distanceSqr _threat;

  //spawn charge container and start lifting it.
  if ( ( _dist < _lift_range ) && ( _last_dist > _dist ) && isNull _charge_holder ) then
  {
   private _start_pos = position _vec;
   
   _start_pos set [ 2, _lift_start_height ];
   
   _charge_holder = createVehicle [ "Box_I_E_UAV_06_F", _start_pos, [], 0, "CAN_COLLIDE" ];
	
   _charge_holder setVelocity ( (velocity _vec) vectorAdd ((vectorUp _vec) vectorMultiply _lift_speed) );
  };
 
  //fire shrapnel cone
  if ((_dist < _max_distSqr) && (_last_dist > _dist)) then
  {
   if ( saro_arena_debug ) then { diag_log "SASPS TR: Threat in range, defending and setting saro_charge_fired true."; };
   
   private _threat_pos = position _threat;
   private _start_pos = position _charge_holder;

   _dummy = [_threat_pos, _start_pos, _charge_holder] call saro_fnc_fire_cone;

   [_threat, _threat_pos, _class, _charge_speed, _start_pos, _skill ] call saro_fnc_substitute_threat;
  
   _vec setVariable ["saro_charge_fired", true, true];
  };
  // if charge is fired or threat is moving away then end isNil with nil to get waitUntil finished.
  if ((_vec getVariable "saro_charge_fired") or (_last_dist < _dist)) then { nil } else { false };
 };
};

//check if something bad happend with vec
if ( isNil "_vec" || { isNull _vec || { !alive _vec } } ) exitWith 
{
 if ( saro_arena_debug ) then { diag_log "SASPS TR: Vehicle gone. Exiting script only."; };
};

if ( saro_arena_debug ) then { diag_log "SASPS TR: Normal script exit. Setting saro_tracking false"; };

_vec setVariable ["saro_tracking", false, true];