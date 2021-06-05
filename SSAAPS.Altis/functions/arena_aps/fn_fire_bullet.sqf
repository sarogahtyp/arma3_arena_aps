private "_dummy";

_dummy = params ["_start_pos", "_threat_pos"];

private _speed = random [1600, 1800, 2000];
private _cone_limit = 2;

private _vector = _start_pos vectorFromTo ( _threat_pos vectorAdd [random[-_cone_limit, 0, _cone_limit], random[-_cone_limit, 0, _cone_limit], random[-_cone_limit, 0, _cone_limit]]);
private _bullet = createVehicle [ "B_127x108_APDS", _start_pos, [], 0, "CAN_COLLIDE" ];
_bullet setVelocity (_vector vectorMultiply _speed);