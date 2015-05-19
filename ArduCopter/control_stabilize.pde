/// -*- tab-width: 4; Mode: C++; c-basic-offset: 4; indent-tabs-mode: nil -*-

/*
 * control_stabilize.pde - init and run calls for stabilize flight mode
 */

// stabilize_init - initialise stabilize controller
static bool stabilize_init(bool ignore_checks)
{
    // set target altitude to zero for reporting
    // To-Do: make pos controller aware when it's active/inactive so it can always report the altitude error?
    pos_control.set_alt_target(0);

    // stabilize should never be made to fail
    return true;
}

// stabilize_run - runs the main stabilize controller
// should be called at 100hz or more
static void stabilize_run()
{
    int16_t target_roll, target_pitch;
    float target_yaw_rate;
    int16_t pilot_throttle_scaled;

    // if not armed or throttle at zero, set throttle to zero and exit immediately
    if(!motors.armed() || g.rc_3.control_in <= 0) {
        attitude_control.relax_bf_rate_controller();
        attitude_control.set_yaw_target_to_current_heading();
        attitude_control.set_throttle_out(0, false);
        return;
    }

    // apply SIMPLE mode transform to pilot inputs
    update_simple_mode();

    // convert pilot input to lean angles
    // To-Do: convert get_pilot_desired_lean_angles to return angles as floats
    get_pilot_desired_lean_angles(g.rc_1.control_in, g.rc_2.control_in, target_roll, target_pitch);

    // get pilot's desired yaw rate
    target_yaw_rate = get_pilot_desired_yaw_rate(g.rc_4.control_in);

    // get pilot's desired throttle
    pilot_throttle_scaled = get_pilot_desired_throttle(g.rc_3.control_in);

    // call attitude controller
    attitude_control.angle_ef_roll_pitch_rate_ef_yaw_smooth(target_roll, target_pitch, target_yaw_rate, get_smoothing_gain());

    // body-frame rate controller is run directly from 100hz loop

    // output pilot's throttle
    attitude_control.set_throttle_out(pilot_throttle_scaled, true);

    Vector3f land_data(0.0f, 0.0f, 0.0f);
    int32_t ir_alt = 100;
    if (irlock_blob_detected == true)
    {
        if (irlock.num_blocks() == 2)
        {
            int16_t xone = IRLOCK_FRAME[0].center_x;
            int16_t xtwo = IRLOCK_FRAME[1].center_x;
            int16_t yone = IRLOCK_FRAME[0].center_y;
            int16_t ytwo = IRLOCK_FRAME[1].center_y;
            int16_t height_one = IRLOCK_FRAME[0].height;
            int16_t height_two = IRLOCK_FRAME[1].height;
            int16_t width_one = IRLOCK_FRAME[0].width;
            int16_t width_two = IRLOCK_FRAME[1].width;
            land_data = irlock.irlock_two_target_control(xone,yone,height_one,width_one,xtwo,ytwo,height_two,width_two,ir_alt);
            cliSerial->printf_P(PSTR(" x: %i  y: %i  angle: %i \n"),(int16_t)land_data[0],(int16_t)land_data[1],(int16_t)land_data[2]);
        }
        else
        {
        }

    }
}
