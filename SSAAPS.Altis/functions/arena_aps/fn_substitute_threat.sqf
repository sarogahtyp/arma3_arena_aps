params [ 
		[ "_threat", objNull, [objNull] ],
		"_threat_pos",
		"_class",
		"_charge_speed",
		"_start_pos",
		"_skill"
	   ];

private _threat_norm_vector = vectorDir _threat;

private _threat_speed_vector = velocity _threat;

private _threat_speed = vectorMagnitude _threat_speed_vector;

// spawn chest to destroy threat mid-air
if ( (random 100) < _skill && _threat_speed < 1000 ) exitWith
{
 private _charge_distance_vector = _threat_norm_vector vectorMultiply (0.01 * _threat_speed);

 private _spawn_pos = AGLToASL ( _threat_pos vectoradd _charge_distance_vector );
  
 private _chest = createSimpleObject [ "Land_Target_Concrete_01_v1_F", (_spawn_pos vectorAdd [ 0, 0, -1 ]) ];

 //hide that helper chest everywhere but on this machine
 if(isServer) then
 {
  _chest remoteExecCall ["hideObject", -2];
 } else
 {
  _chest remoteExecCall ["hideObject", -clientOwner];
 };
 _chest setVectorDirAndUp [ (vectorDir _threat), (vectorUp _threat) ];
 
 // wait for dead threat to delete helper chest
 [ _threat, _chest ]spawn
 { 
  while { alive (_this select 0) } do {};
 
  deleteVehicle (_this select 1);
 };
};

// calculate vectors for speed and direction after shrapnels impacted threat
// substitute threat and set new vectors
private _result_speed_vector = _threat_speed_vector vectorAdd ( ( _start_pos vectorFromTo _threat_pos ) vectorMultiply ( _charge_speed * _threat_speed ) );

private _dir_vectors = [ _threat_norm_vector, ( vectorUp _threat) ];

deleteVehicle _threat;

_threat = createVehicle [_class, _threat_pos,[],0,"CAN_COLLIDE"];

_threat setVectorDirAndUp _dir_vectors;

_threat setVelocity _result_speed_vector;

_threat setVectorDir (vectorNormalized _result_speed_vector);