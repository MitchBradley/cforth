#define DDA_SUBSTEPS  256
#define NMOTORS 6

// Values that don't change after configuration
typedef struct motorspec {
    int on_set_mask;
    int on_clear_mask;
    int off_set_mask;
    int off_clear_mask;
    int on_count;
    int8_t encoder_step_sign;
    int16_t encoder_steps_run;
    int32_t encoder_steps;
} motorspec_t;
motorspec_t motorspecs[NMOTORS];

// Values that change for every segment
typedef struct motorsteps {
    int substep_accumulator;
    int substep_increment;
    int substep_increment_increment;
    int on_steps;
} motorsteps_t;

typedef struct stepspec {
    struct stepspec *next;
    int dda_ticks_downcount;
    motorsteps_t motorsteps[NMOTORS];
} stepspec_t;

stepspec_t *runp;
int active_motors;  // Configuration
uint32_t off_set_mask;
uint32_t off_clear_mask;

void foo() {
    // dda_timer.getInterruptCause();  // clear interrupt condition

    if (!runp)
        return;

    uint32_t set_mask = off_set_mask;
    uint32_t clear_mask = off_clear_mask;

    motorsteps_t *motorsteps;
    motorspec_t *motorspec;

    // clear all steps from the previous interrupt
    motor_1.stepEnd();

    // process last DDA tick after end of segment
    if (runp->dda_ticks_downcount == 0) {
        // we used to turn off the stepper timer here, but we don't anymore
        return;
    }
    motorsteps = runp->motorsteps;
    for (uint8_t motor=0; motor<active_motors; motor++) {
        if ((motorsteps->substep_accumulator += motorsteps->substep_increment) > 0) {
            motorspec_t motorspec = &motorspecs[motor];
            clear_mask |= motorspec->on_clear_mask;
            set_mask |= motorspec->on_set_mask;
            motorsteps->substep_accumulator -= DDA_SUBSTEPS;
            motorsteps->encoder_steps_run += motorsteps->encoder_step_sign;
        }
        motorsteps->substep_increment += motorsteps->substep_increment_increment;
        motorsteps++;
    }

    gpio->w1tc = clear_mask;
    gpio->w1ts = set_mask;

    off_set_mask = clear_mask;
    off_clear_mask = set_mask;

    // Process end of segment.
    // One more interrupt will occur to turn of any pulses set in this pass.
    if (--runp->dda_ticks_downcount == 0) {
      runp = runp->next;
    }
}
