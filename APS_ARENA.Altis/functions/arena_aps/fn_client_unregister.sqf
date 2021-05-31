/*
 Author: Sarogahtyp
 Description: -unregisters clients/vehicles which did run arena
			  -removes player disconnect EH on server if no client runs arena anymore
*/

private _dummy = params ["_uid", "_vec"];

//something went wrong, leave
if (isNil "saro_clients_running_arena") exitWith 
{
 if ( missionNamespace getVariable "debugOn" ) then { diag_log "SASPS CUR-Server: No array. Player is not registered."; };
};

//something went wrong, leave
if (saro_clients_running_arena isEqualTo [] ) exitWith 
{
 if ( missionNamespace getVariable "debugOn" ) then { diag_log "SASPS CUR-Server: Array empty. Player is not registered."; };
};

//find players UID in array
private _index = saro_clients_running_arena findIf { (_x#0) isEqualTo _uid}; // return index of players entry

//no entry of that player, leave
if ( _index isEqualTo -1) exitWith 
{
if ( missionNamespace getVariable "debugOn" ) then { diag_log "SASPS CUR-Server: Player not found in array, is not registered."; };
};

_plyr_vecs = saro_clients_running_arena select _index;

//last vehicle. delete player entry and exit
if ( (count _plyr_vecs) < 3) exitWith
{
  if ( missionNamespace getVariable "debugOn" ) then { diag_log "SASPS CUR-Server: Players last vehicle. Player entry deleted."; };
  _dummy = saro_clients_running_arena deleteAt _index;

 //this was the last player in array. Nil the array and remove mission EH
 if (saro_clients_running_arena isEqualTo []) then
 {
  if ( missionNamespace getVariable "debugOn" ) then { diag_log "SASPS CUR-Server: Last registered player. Array niled, EH deleted."; };

  saro_clients_running_arena = nil;

  removeMissionEventHandler ["PlayerDisconnected", saro_meh_plyr_disc_index];
 };
};

_vec_index = _plyr_vecs findIf {_x isEqualTo _vec};

// vehicle was not registered, leave
if( _vec_index isEqualTo -1) exitWith 
{
if ( missionNamespace getVariable "debugOn" ) then { diag_log "SASPS CUR-Server: Player found but vehicle is not registered."; };
};

if ( missionNamespace getVariable "debugOn" ) then { diag_log "SASPS CUR-Server: Vehicle found and deleted in player entry."; };
_dummy = _plyr_vecs deleteAt _vec_index;

