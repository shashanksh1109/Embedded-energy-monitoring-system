#define _POSIX_C_SOURCE 200809L

#include "ipc.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <time.h>
#include <unistd.h>

HVACSharedState* ipc_create_shm(void) {
    int fd = shm_open(SHM_NAME, O_CREAT | O_RDWR, 0666);
    if (fd < 0) {
        printf("[IPC ERROR] shm_open(create) failed: %s\n", strerror(errno));
        return NULL;
    }
    if (ftruncate(fd, SHM_SIZE) < 0) {
        printf("[IPC ERROR] ftruncate failed: %s\n", strerror(errno));
        close(fd);
        return NULL;
    }
    HVACSharedState *state = mmap(NULL, SHM_SIZE,
                                   PROT_READ | PROT_WRITE,
                                   MAP_SHARED, fd, 0);
    close(fd);
    if (state == MAP_FAILED) {
        printf("[IPC ERROR] mmap(create) failed: %s\n", strerror(errno));
        return NULL;
    }
    memset(state, 0, SHM_SIZE);
    state->is_valid     = 0;
    state->heater_pct   = 0.0f;
    state->cooler_pct   = 0.0f;
    state->current_temp = 0.0f;
    state->setpoint     = 0.0f;
    state->timestamp    = (uint32_t)time(NULL);
    printf("[IPC] Shared memory created: %s (%zu bytes)\n", SHM_NAME, SHM_SIZE);
    return state;
}

HVACSharedState* ipc_open_shm(void) {
    int fd = -1;
    int retries = 5;
    while (retries-- > 0) {
        fd = shm_open(SHM_NAME, O_RDWR, 0666);
        if (fd >= 0) break;
        printf("[IPC] Waiting for shared memory (retries left: %d)...\n", retries);
        sleep(1);
    }
    if (fd < 0) {
        printf("[IPC ERROR] shm_open(open) failed after retries: %s\n", strerror(errno));
        printf("[IPC]       Is hvac_controller running?\n");
        return NULL;
    }
    HVACSharedState *state = mmap(NULL, SHM_SIZE,
                                   PROT_READ | PROT_WRITE,
                                   MAP_SHARED, fd, 0);
    close(fd);
    if (state == MAP_FAILED) {
        printf("[IPC ERROR] mmap(open) failed: %s\n", strerror(errno));
        return NULL;
    }
    printf("[IPC] Shared memory opened: %s\n", SHM_NAME);
    return state;
}

void ipc_close_shm(HVACSharedState *state) {
    if (state && state != MAP_FAILED) {
        munmap(state, SHM_SIZE);
        printf("[IPC] Shared memory unmapped\n");
    }
}

void ipc_destroy_shm(void) {
    shm_unlink(SHM_NAME);
    sem_unlink(SEM_NAME);
    printf("[IPC] Shared memory and semaphore unlinked\n");
}

sem_t* ipc_create_sem(void) {
    sem_t *sem = sem_open(SEM_NAME, O_CREAT, 0666, 1);
    if (sem == SEM_FAILED) {
        printf("[IPC ERROR] sem_open(create) failed: %s\n", strerror(errno));
        return SEM_FAILED;
    }
    printf("[IPC] Semaphore created: %s\n", SEM_NAME);
    return sem;
}

sem_t* ipc_open_sem(void) {
    sem_t *sem = sem_open(SEM_NAME, 0);
    if (sem == SEM_FAILED) {
        printf("[IPC ERROR] sem_open(open) failed: %s\n", strerror(errno));
        printf("[IPC]       Is hvac_controller running?\n");
        return SEM_FAILED;
    }
    printf("[IPC] Semaphore opened: %s\n", SEM_NAME);
    return sem;
}

void ipc_close_sem(sem_t *sem) {
    if (sem && sem != SEM_FAILED) {
        sem_close(sem);
        printf("[IPC] Semaphore closed\n");
    }
}
