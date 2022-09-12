# Cinematic
A mod for [Minetest](https://www.minetest.net/).

Use chat commands to control your camera when recording in-game videos with aerial views, time lapse, movie-style scenes. The mod runs server-side and controls calling player position and look direction, so using client-side movement will obviously cause disruption.

All commands are placed under `/cc` command which stands for *cinematic camera*. Running the commands requires `fly` privilege (they don't make sense without it anyway).

# Camera motions

## 360
```
/cc 360 [r=<radius>] [dir=<l|left|r|right>] [v=<velocity>] [fov=<field of view>] [t=<seconds>] [n=<named motion>]
```
Move the camera around a center point while keeping the focus on the center.

Parameters:
* `r` or `radius` - distance to the center point in the look direction of the player.
* `dir` or `direction` - direction of the camera motion.
* `v` or `speed` - speed multiplier.
* `fov` - Field of View multiplier to create fish eye effect or  zoom on an object.
* `t` or `time` - the duration time to stop(seconds)
* `n` or `name` - named the motion

## Tilt
```
/cc tilt [v=<velocity>] [dir=<u|up|d|down>] [fov=<field of view>] [t=<seconds>] [n=<named motion>]
```
Rotate the camera vertically, like looking up or down.

Parameters:
* `dir` or `direction` - direction of the camera motion.
* `v` or `speed` - speed multiplier.
* `fov` - Field of View multiplier to create fish eye effect or  zoom on an object.
* `t` or `time` - the duration time to stop(seconds)
* `n` or `name` - named the motion

## Pan
```
/cc pan [v=<velocity>] [dir=<l|left|r|right>] [fov=<field of view>] [t=<seconds>] [n=<named motion>]
```
Rotate the camera horizontally, like looking to the left or right.

Parameters:
* `dir` or `direction` - direction of the camera motion.
* `v` or `speed` - speed multiplier.
* `fov` - Field of View multiplier to create fish eye effect or  zoom on an object.
* `t` or `time` - the duration time to stop(seconds)
* `n` or `name` - named the motion

## Truck
```
/cc truck [v=<velocity>] [dir=<l|left|r|right>] [fov=<field of view>] [t=<seconds>] [n=<named motion>]
```
Move the camera sideways without changing the angles, like it is on a truck

Parameters:
* `dir` or `direction` - direction of the camera motion.
* `v` or `speed` - speed multiplier.
* `fov` - Field of View multiplier to create fish eye effect or  zoom on an object.
* `t` or `time` - the duration time to stop(seconds)
* `n` or `name` - named the motion

## Dolly
```
/cc truck [v=<velocity>] [dir=<f|forward|in|b|back|backwards|out>] [fov=<field of view>] [t=<seconds>] [n=<named motion>]
```
Move the camera forward or backwards in the look direction. You can rotate the camera in motion to set the desired look angles.

Parameters:
* `dir` or `direction` - direction of the camera motion.
* `v` or `speed` - speed multiplier.
* `fov` - Field of View multiplier to create fish eye effect or  zoom on an object.
* `t` or `time` - the duration time to stop(seconds)
* `n` or `name` - named the motion

## Pedestal
```
/cc pedestal [v=<velocity>] [dir=<u|up|d|down>] [fov=<field of view>] [t=<seconds>] [n=<named motion>]
```
Move the camera vertically. You can rotate the camera in motion to set the desired look angles.

Parameters:
* `dir` or `direction` - direction of the camera motion.
* `v` or `speed` - speed multiplier.
* `fov` - Field of View multiplier to create fish eye effect or  zoom on an object.
* `t` or `time` - the duration time to stop(seconds)
* `n` or `name` - named the motion

## Zoom
```
/cc zoom [v=<velocity>] [dir=<in|out>] [fov=<field of view>] [t=<seconds>] [n=<named motion>]
```
Gradually zoom on an object or out into panorama view.

Parameters:
* `dir` or `direction` - direction of the camera motion.
* `v` or `speed` - speed multiplier.
* `fov` - Initial Field of View multiplier.
* `t` or `time` - the duration time to stop(seconds)
* `n` or `name` - named the motion

## To

```
/cc to pos=<named position> [v=<velocity>] [fov=<field of view>] [t=<seconds>] [n=<named motion>]
```

from the player current position to the `pos`(include the look direction)

Parameters:

* `p` or `pos` - the position name to go(use the `/cc pos save your_pos_name` to save the position)
* `v` or `speed` - speed multiplier.
* `fov` - Initial Field of View multiplier.
* `t` or `time` - the duration time to stop(seconds)
* `n` or `name` - named the motion

Note: `speed` or `time` only one need.

## Wait


```
/cc wait  [t=<seconds>] [n=<named motion>]
```

Just wait time, do nothing.

Parameters:

* `fov` - Initial Field of View multiplier.
* `t` or `time` - the duration time to stop(seconds)
* `n` or `name` - named the motion

# Camera control
```
/cc stop
```
Stop the camera motion
```
/cc revert
```
Stop and return to initial position.
# Position control
Manage the list of camera positions stored in the player's metadata. The list survives rejoining and server restarts.
```
/cc pos save [name]
```
Save the current position and look direction, with an optional name (will be saved in `default` slot if no name provided)
```
/cc pos restore [name]
```
Return to the saved position, either `default` or a named one.
```
/cc pos clear [name]
```
Remove a saved position. Clear all positions if no name provided
```
/cc pos list
```
Get a list of saved positions.

# Motion control

Manage the list named motion.

```
/cc motion clear [name]
```
Remove a saved motion. Clear all motions if no name provided.
```
/cc motion list
```
Get a list of saved motion.

# Batch Running


Run a series of named motions in sequence.

```
/cc run motion1 wait motion2 wait=3 motion3
```

`wait` is a shorcut for wait motion. The default wait is 1 seconds.


# Copyright
Copyright (c) 2021 Dmitry Kostenko.
Code License: GNU AGPL v3.0

