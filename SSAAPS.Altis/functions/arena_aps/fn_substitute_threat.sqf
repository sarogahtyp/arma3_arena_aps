params [ ["_vec", objNull, [objNull]], ["_threat", objNull, [objNull]], "_threat_pos", "_maxHeight", "_class", "_charge_speed","_start_pos"];

if (isNull _threat || isNull _vec) exitWith{};
if !(alive _threat && alive _vec) exitWith{};

_threat_speed_vector = velocity _threat;

_threat_speed = vectorMagnitude _threat_speed_vector;

_threat_norm_vector = vectorDir _threat;

_charge_norm_vector = _start_pos vectorFromTo _threat_pos;

_charge_speed_vector = _charge_norm_vector vectorMultiply (_charge_speed * _threat_speed);

_result_speed_vector = _threat_speed_vector vectorAdd _charge_speed_vector;

_result_norm_vector = vectorNormalized _result_speed_vector;

_dir_vectors = [ ( vectorDir _threat), ( vectorUp _threat) ];

deleteVehicle _threat;

_threat = createVehicle [_class, _threat_pos,[],0,"NONE"];

_threat setVectorDirAndUp _dir_vectors;

_threat setVelocity _result_speed_vector;

_threat setVectorDir _result_norm_vector;