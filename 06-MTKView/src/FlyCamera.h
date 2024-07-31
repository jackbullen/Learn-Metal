////////////////////////////////////////////////////////////////////////////////////////////////////
// SOURCE  :: https://github.com/nlguillemot/flythrough_camera/blob/master/flythrough_camera.h /////
////////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef FLYTHROUGH_CAMERA_H
#define FLYTHROUGH_CAMERA_H

#define FLYTHROUGH_CAMERA_LEFT_HANDED_BIT 1

void flythrough_camera_update(
    float eye[3],                               // eye position
    float look[3],                              // look direction
    const float up[3],                          // up direction

    float view[16],                             // 4x4 view matrix to update

    float delta_time_seconds,                   // time since last camera update
    float eye_speed,                            // eye speed in world units / second
    float degrees_per_cursor_move,              // degrees camera
    float max_pitch_rotation_degrees,           // prevent vertical pitch issues
    float delta_cursor_x, float delta_cursor_y, // cursor dxdy between frames

    // indicators for whether or not strafing 
    int forward_held, int left_held, int backward_held, int right_held,
    int jump_held, int crouch_held, 

    unsigned int flags);           

// Utility for producing a look-to matrix without having to update a camera.
void flythrough_camera_look_to(
    const float eye[3],
    const float look[3],
    const float up[3],
    float view[16],
    unsigned int flags);

#endif // FLYTHROUGH_CAMERA_H