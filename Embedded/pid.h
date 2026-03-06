#ifndef PID_H
#define PID_H

/*
 * pid.h - PID Controller Interface
 * 
 * Proportional-Integral-Derivative control algorithm
 */

typedef struct {
    float kp;           // Proportional gain
    float ki;           // Integral gain
    float kd;           // Derivative gain
    float setpoint;     // Target value
    float integral;     // Accumulated error
    float prev_error;   // Previous error value
} PIDController;

// Initialize PID controller
void pid_init(PIDController *pid, float setpoint, float kp, float ki, float kd);

// Compute PID output
float pid_compute(PIDController *pid, float current_value, float dt);

// Reset PID state
void pid_reset(PIDController *pid);

#endif