params [ ["_threat", objNull, [objNull]] ];

if (isNull _threat || !alive _threat) exitWith { diag_log "TO SLOW"; };

_perc = random 30;

_class = typeOf _threat;

_speed_vector = velocity _threat;

_ro_speed = vectorMagnitude _speed_vector;

_perc_inv = 1 / (_perc + 0.00001);

_norm_speed = vectorNormalized _speed_vector;
 
_speed_change = _norm_speed vectorMultiply (_perc * 0.01);

_speed_change set [ 2, (_speed_change#2 - _perc_inv) ];

_speed_change = (vectorNormalized _speed_change) vectorMultiply _ro_speed;

_dir_vectors = [ (vectorDir _threat), (vectorUp _threat) ];
  
_posi = position _threat;
  
deleteVehicle _threat;
  
_threat = createVehicle [_class, _posi,[],0,"NONE"];

_threat setVelocity _speed_change;

_threat setVectorDirAndUp _dir_vectors;