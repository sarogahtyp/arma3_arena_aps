/*
 Author: Sarogahtyp
 Description: shoots a protection charge in a cone shape in the direction of the threatening object
*/

params ["_vec", "_threat_pos", "_maxHeight"];

private _bullet_num = 25;
private _scatter = 0.3;
private "_dummy";
private _start_pos = position _vec;

_start_pos set [2, _maxHeight];

for "_i" from 1 to _bullet_num do 
{ 
  private _scattered_pos = _start_pos vectorAdd [random[-_scatter, 0, _scatter], random[-_scatter, 0, _scatter], random[-_scatter, 0, _scatter]];
 
 _dummy = [_scattered_pos, _threat_pos] spawn saro_fnc_fire_bullet; 
};