/*
 * pid.c - PID Controller Implementation
 * 
 * Proportional-Integral-Derivative control algorithm
 */

#include "pid.h"
#include <stdio.h>

void pid_init(PIDController *pid, float setpoint, float kp, float ki, float kd) {
    pid->kp = kp;
    pid->ki = ki;
    pid->kd = kd;
    pid->setpoint = setpoint;
    pid->integral = 0.0;
    pid->prev_error = 0.0;
}

float pid_compute(PIDController *pid, float current_value, float dt) {
    // Calculate error
    float error = pid->setpoint - current_value;
    
    // Proportional term
    float p_term = pid->kp * error;
    
    // Integral term (with anti-windup)
    pid->integral += error * dt;
    
    // Anti-windup: Clamp integral to prevent overflow
    if (pid->integral > 100.0) pid->integral = 100.0;
    if (pid->integral < -100.0) pid->integral = -100.0;
    
    float i_term = pid->ki * pid->integral;
    
    // Derivative term
    float derivative = (error - pid->prev_error) / dt;
    float d_term = pid->kd * derivative;
    
    // Store error for next iteration
    pid->prev_error = error;
    
    // Calculate output
    float output = p_term + i_term + d_term;
    
    // Clamp output to 0-100%
    if (output > 100.0) output = 100.0;
    if (output < 0.0) output = 0.0;
    
    return output;
}

void pid_reset(PIDController *pid) {
    pid->integral = 0.0;
    pid->prev_error = 0.0;
}