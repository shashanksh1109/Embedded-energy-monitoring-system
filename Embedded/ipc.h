#ifndef IPC_H
#define IPC_H

/*
 * ipc.h - Inter-Process Communication Interface
 *
 * Defines the shared memory structure used between:
 *   - hvac_controller (WRITER) — updates state every second
 *   - power_meter     (READER) — reads state to calculate real power
 *
 * Mechanism: POSIX shared memory + POSIX named semaphore
 *
 * Shared memory key: /energy_hvac_state
 * Semaphore name:    /energy_hvac_sem
 *
 * Memory layout:
 *   HVACSharedState struct mapped at the start of the shared region.
 *   Size = sizeof(HVACSharedState) bytes.
 */

#include <stdint.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <semaphore.h>
#include <unistd.h>

/* ============================================================
 * SHARED MEMORY CONFIGURATION
 * ============================================================ */
#define SHM_NAME      "/energy_hvac_state"   // POSIX shared memory object name
#define SEM_NAME      "/energy_hvac_sem"     // POSIX named semaphore name
#define SHM_SIZE      sizeof(HVACSharedState)

/* ============================================================
 * SHARED DATA STRUCTURE
 * Written by hvac_controller, read by power_meter.
 * Protected by semaphore to prevent race conditions.
 * ============================================================ */
typedef struct {
    float    heater_pct;     // Current heater output (0-100%)
    float    cooler_pct;     // Current cooler output (0-100%)
    float    current_temp;   // Current measured temperature (°C)
    float    setpoint;       // Target temperature (°C)
    uint32_t timestamp;      // Unix epoch of last update
    int      is_valid;       // 1 = data is valid, 0 = not yet written
} HVACSharedState;

/* ============================================================
 * IPC FUNCTIONS
 * ============================================================ */

/**
 * ipc_create_shm()
 * Create and initialize shared memory (called by hvac_controller).
 * Returns pointer to mapped HVACSharedState, or NULL on failure.
 */
HVACSharedState* ipc_create_shm(void);

/**
 * ipc_open_shm()
 * Open existing shared memory for reading (called by power_meter).
 * Returns pointer to mapped HVACSharedState, or NULL on failure.
 */
HVACSharedState* ipc_open_shm(void);

/**
 * ipc_close_shm()
 * Unmap shared memory (called by both processes on exit).
 */
void ipc_close_shm(HVACSharedState *state);

/**
 * ipc_destroy_shm()
 * Unlink shared memory and semaphore (called by hvac_controller on exit).
 * Should only be called by the creator process.
 */
void ipc_destroy_shm(void);

/**
 * ipc_create_sem()
 * Create named semaphore (called by hvac_controller).
 * Returns semaphore pointer or SEM_FAILED on failure.
 */
sem_t* ipc_create_sem(void);

/**
 * ipc_open_sem()
 * Open existing named semaphore (called by power_meter).
 * Returns semaphore pointer or SEM_FAILED on failure.
 */
sem_t* ipc_open_sem(void);

/**
 * ipc_close_sem()
 * Close semaphore handle (called by both processes on exit).
 */
void ipc_close_sem(sem_t *sem);

#endif