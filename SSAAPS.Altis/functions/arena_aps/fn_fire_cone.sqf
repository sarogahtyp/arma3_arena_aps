/*
 Author: Sarogahtyp
 Description: shoots a protection charge in a cone shape in the direction of the threatening object
*/

params ["_threat_pos", "_start_pos", "_charge_holder"];

private "_dummy";
private _bullet_num = 50;
private _scatter = 0.3;

// create charge container explosion and set the velocity impact to that container
private _speed_change = ( _threat_pos vectorFromTo _start_pos ) vectorMultiply random [40, 50, 60]; 
_charge_holder setVelocity ( (velocity _charge_holder) vectorAdd _speed_change);

private _charge_boom = createVehicle [ "SmallSecondary", _start_pos, [], 0, "CAN_COLLIDE" ];

// fire bullet cone
for "_i" from 1 to _bullet_num do 
{ 
 private _scattered_pos = _start_pos vectorAdd [random[-_scatter, 0, _scatter], random[-_scatter, 0, _scatter], random[-_scatter, 0, _scatter]];
 
 _dummy = [_scattered_pos, _threat_pos] call saro_fnc_fire_bullet; 
};