#include <string.h>

#include "lvgl.h"
#include "watcher_engine.h"
#include "ui_home.h"

#define PANEL WSIM_PANEL_PX

static lv_disp_draw_buf_t s_draw_buf;
static lv_color_t         s_lv_buf[PANEL * 60];
static lv_disp_drv_t      s_disp_drv;
static lv_indev_drv_t     s_knob_drv;
static lv_indev_drv_t     s_touch_drv;

static uint8_t s_fb[PANEL * PANEL * 4];

static int32_t s_knob_pending;
static bool    s_knob_pressed;
static int32_t s_touch_x, s_touch_y;
static bool    s_touch_down;
static bool    s_ready;

static void flush_cb(lv_disp_drv_t *drv, const lv_area_t *area, lv_color_t *px)
{
    for (int32_t y = area->y1; y <= area->y2; y++) {
        for (int32_t x = area->x1; x <= area->x2; x++) {
            lv_color_t c = *px++;
            if (x < 0 || y < 0 || x >= PANEL || y >= PANEL) continue;
            uint8_t *dst = &s_fb[(y * PANEL + x) * 4];
            /* RGB565 -> BGRA8888, replicating high bits so white stays white */
            uint8_t r = (uint8_t)(c.ch.red   << 3), g = (uint8_t)(c.ch.green << 2),
                    b = (uint8_t)(c.ch.blue  << 3);
            dst[0] = (uint8_t)(b | (b >> 5));
            dst[1] = (uint8_t)(g | (g >> 6));
            dst[2] = (uint8_t)(r | (r >> 5));
            dst[3] = 0xFF;
        }
    }
    lv_disp_flush_ready(drv);
}

static void knob_read_cb(lv_indev_drv_t *drv, lv_indev_data_t *data)
{
    (void)drv;
    data->enc_diff = (int16_t)s_knob_pending;
    s_knob_pending = 0;
    data->state = s_knob_pressed ? LV_INDEV_STATE_PRESSED : LV_INDEV_STATE_RELEASED;
}

static void touch_read_cb(lv_indev_drv_t *drv, lv_indev_data_t *data)
{
    (void)drv;
    data->point.x = (lv_coord_t)s_touch_x;
    data->point.y = (lv_coord_t)s_touch_y;
    data->state = s_touch_down ? LV_INDEV_STATE_PRESSED : LV_INDEV_STATE_RELEASED;
}

void wsim_init(void)
{
    if (s_ready) return;

    lv_init();

    lv_disp_draw_buf_init(&s_draw_buf, s_lv_buf, NULL, PANEL * 60);
    lv_disp_drv_init(&s_disp_drv);
    s_disp_drv.draw_buf = &s_draw_buf;
    s_disp_drv.flush_cb = flush_cb;
    s_disp_drv.hor_res  = PANEL;
    s_disp_drv.ver_res  = PANEL;
    lv_disp_drv_register(&s_disp_drv);

    lv_indev_drv_init(&s_touch_drv);
    s_touch_drv.type    = LV_INDEV_TYPE_POINTER;
    s_touch_drv.read_cb = touch_read_cb;
    lv_indev_drv_register(&s_touch_drv);

    lv_indev_drv_init(&s_knob_drv);
    s_knob_drv.type    = LV_INDEV_TYPE_ENCODER;
    s_knob_drv.read_cb = knob_read_cb;
    lv_indev_t *knob = lv_indev_drv_register(&s_knob_drv);

    lv_group_t *group = lv_group_create();
    lv_group_set_default(group);
    lv_indev_set_group(knob, group);

    ui_home_init(group);
    s_ready = true;
}

void wsim_tick(uint32_t elapsed_ms)
{
    if (!s_ready) return;
    lv_tick_inc(elapsed_ms);
    lv_timer_handler();
}

const uint8_t *wsim_framebuffer(void) { return s_fb; }
int wsim_panel_size(void) { return PANEL; }

void wsim_knob_rotate(int32_t detents) { s_knob_pending += detents; }
void wsim_knob_set_pressed(bool pressed) { s_knob_pressed = pressed; }

void wsim_touch(int32_t x, int32_t y, bool down)
{
    s_touch_x = x;
    s_touch_y = y;
    s_touch_down = down;
}
