#ifndef WATCHER_ENGINE_H
#define WATCHER_ENGINE_H

#include <stdbool.h>
#include <stdint.h>

#define WSIM_PANEL_PX 412

#ifdef __cplusplus
extern "C" {
#endif

void wsim_init(void);
void wsim_tick(uint32_t elapsed_ms);

/** BGRA8888, WSIM_PANEL_PX square, valid until the next wsim_tick. */
const uint8_t *wsim_framebuffer(void);
int wsim_panel_size(void);

/** Detents; positive = clockwise. */
void wsim_knob_rotate(int32_t detents);
void wsim_knob_set_pressed(bool pressed);

/** Panel-space coordinates, origin top-left. */
void wsim_touch(int32_t x, int32_t y, bool down);

#ifdef __cplusplus
}
#endif

#endif
