#include "ui_home.h"

#define COL_BG      lv_color_hex(0x0B0E14)
#define COL_TILE    lv_color_hex(0x161B26)
#define COL_TILE_HL lv_color_hex(0x24304A)
#define COL_ACCENT  lv_color_hex(0x7AA2F7)
#define COL_TEXT    lv_color_hex(0xC0CAF5)
#define COL_DIM     lv_color_hex(0x565F89)

#define DIAM 412

typedef struct {
    const char *icon;
    const char *name;
    const char *detail;
} miniapp_desc_t;

static const miniapp_desc_t APPS[] = {
    { LV_SYMBOL_AUDIO,    "Voice",    "long-press to talk" },
    { LV_SYMBOL_IMAGE,    "Camera",   "capture -> vision"  },
    { LV_SYMBOL_REFRESH,  "Weather",  "18C  clear"         },
    { LV_SYMBOL_UPLOAD,   "Stocks",   "NVDA +1.4%"         },
    { LV_SYMBOL_SETTINGS, "Settings", "wifi, keys"         },
};
#define APP_COUNT (sizeof(APPS) / sizeof(APPS[0]))

static lv_group_t *s_group;
static lv_obj_t   *s_list;
static lv_obj_t   *s_tiles[APP_COUNT];
static lv_obj_t   *s_vol_layer;
static lv_obj_t   *s_vol_arc;
static lv_obj_t   *s_vol_label;

static void volume_close(void);

static void tile_event_cb(lv_event_t *e)
{
    lv_event_code_t code = lv_event_get_code(e);
    lv_obj_t *tile = lv_event_get_target(e);

    if (code == LV_EVENT_FOCUSED) {
        lv_obj_set_style_bg_color(tile, COL_TILE_HL, 0);
        lv_obj_set_style_border_width(tile, 2, 0);
        lv_obj_scroll_to_view(tile, LV_ANIM_ON);
    } else if (code == LV_EVENT_DEFOCUSED) {
        lv_obj_set_style_bg_color(tile, COL_TILE, 0);
        lv_obj_set_style_border_width(tile, 0, 0);
    } else if (code == LV_EVENT_LONG_PRESSED) {
        lv_obj_clear_flag(s_vol_layer, LV_OBJ_FLAG_HIDDEN);
        for (size_t i = 0; i < APP_COUNT; i++) lv_group_remove_obj(s_tiles[i]);
        lv_group_add_obj(s_group, s_vol_arc);
        lv_group_focus_obj(s_vol_arc);
        lv_group_set_editing(s_group, true);
    }
}

static void vol_event_cb(lv_event_t *e)
{
    lv_event_code_t code = lv_event_get_code(e);

    if (code == LV_EVENT_VALUE_CHANGED) {
        lv_label_set_text_fmt(s_vol_label, "%d", (int)lv_arc_get_value(s_vol_arc));
    } else if (code == LV_EVENT_LONG_PRESSED || code == LV_EVENT_CLICKED) {
        volume_close();
    }
}

static void volume_close(void)
{
    lv_obj_add_flag(s_vol_layer, LV_OBJ_FLAG_HIDDEN);
    lv_group_remove_obj(s_vol_arc);
    for (size_t i = 0; i < APP_COUNT; i++) lv_group_add_obj(s_group, s_tiles[i]);
    lv_group_focus_obj(s_tiles[0]);
    lv_group_set_editing(s_group, false);
}

static lv_obj_t *make_root(void)
{
    lv_obj_t *scr = lv_scr_act();
    lv_obj_set_style_bg_color(scr, lv_color_black(), 0);

    lv_obj_t *root = lv_obj_create(scr);
    lv_obj_set_size(root, DIAM, DIAM);
    lv_obj_center(root);
    lv_obj_set_style_radius(root, LV_RADIUS_CIRCLE, 0);
    lv_obj_set_style_clip_corner(root, true, 0);
    lv_obj_set_style_bg_color(root, COL_BG, 0);
    lv_obj_set_style_border_width(root, 0, 0);
    lv_obj_set_style_pad_all(root, 0, 0);
    lv_obj_clear_flag(root, LV_OBJ_FLAG_SCROLLABLE);
    return root;
}

static void make_header(lv_obj_t *root)
{
    lv_obj_t *time = lv_label_create(root);
    lv_label_set_text(time, "03:24");
    lv_obj_set_style_text_color(time, COL_TEXT, 0);
    lv_obj_set_style_text_font(time, &lv_font_montserrat_28, 0);
    lv_obj_align(time, LV_ALIGN_TOP_MID, 0, 46);

    lv_obj_t *sub = lv_label_create(root);
    lv_label_set_text(sub, LV_SYMBOL_WIFI "  " LV_SYMBOL_BATTERY_3 " 82%");
    lv_obj_set_style_text_color(sub, COL_DIM, 0);
    lv_obj_set_style_text_font(sub, &lv_font_montserrat_12, 0);
    lv_obj_align(sub, LV_ALIGN_TOP_MID, 0, 82);
}

static void make_list(lv_obj_t *root)
{
    s_list = lv_obj_create(root);
    lv_obj_set_size(s_list, 300, 250);
    lv_obj_align(s_list, LV_ALIGN_TOP_MID, 0, 110);
    lv_obj_set_style_bg_opa(s_list, LV_OPA_TRANSP, 0);
    lv_obj_set_style_border_width(s_list, 0, 0);
    lv_obj_set_style_pad_all(s_list, 0, 0);
    lv_obj_set_style_pad_row(s_list, 10, 0);
    lv_obj_set_flex_flow(s_list, LV_FLEX_FLOW_COLUMN);
    lv_obj_set_scroll_snap_y(s_list, LV_SCROLL_SNAP_CENTER);
    lv_obj_set_scrollbar_mode(s_list, LV_SCROLLBAR_MODE_OFF);

    for (size_t i = 0; i < APP_COUNT; i++) {
        lv_obj_t *tile = lv_obj_create(s_list);
        lv_obj_set_size(tile, 280, 72);
        lv_obj_set_style_bg_color(tile, COL_TILE, 0);
        lv_obj_set_style_border_color(tile, COL_ACCENT, 0);
        lv_obj_set_style_border_width(tile, 0, 0);
        lv_obj_set_style_radius(tile, 18, 0);
        lv_obj_set_style_pad_all(tile, 14, 0);
        lv_obj_clear_flag(tile, LV_OBJ_FLAG_SCROLLABLE);

        lv_obj_t *icon = lv_label_create(tile);
        lv_label_set_text(icon, APPS[i].icon);
        lv_obj_set_style_text_color(icon, COL_ACCENT, 0);
        lv_obj_set_style_text_font(icon, &lv_font_montserrat_20, 0);
        lv_obj_align(icon, LV_ALIGN_LEFT_MID, 4, 0);

        lv_obj_t *name = lv_label_create(tile);
        lv_label_set_text(name, APPS[i].name);
        lv_obj_set_style_text_color(name, COL_TEXT, 0);
        lv_obj_set_style_text_font(name, &lv_font_montserrat_20, 0);
        lv_obj_align(name, LV_ALIGN_TOP_LEFT, 44, 2);

        lv_obj_t *detail = lv_label_create(tile);
        lv_label_set_text(detail, APPS[i].detail);
        lv_obj_set_style_text_color(detail, COL_DIM, 0);
        lv_obj_set_style_text_font(detail, &lv_font_montserrat_12, 0);
        lv_obj_align(detail, LV_ALIGN_BOTTOM_LEFT, 44, -2);

        lv_obj_add_event_cb(tile, tile_event_cb, LV_EVENT_ALL, NULL);
        lv_group_add_obj(s_group, tile);
        s_tiles[i] = tile;
    }
}

static void make_volume_layer(lv_obj_t *root)
{
    s_vol_layer = lv_obj_create(root);
    lv_obj_set_size(s_vol_layer, DIAM, DIAM);
    lv_obj_center(s_vol_layer);
    lv_obj_set_style_radius(s_vol_layer, LV_RADIUS_CIRCLE, 0);
    lv_obj_set_style_bg_color(s_vol_layer, COL_BG, 0);
    lv_obj_set_style_bg_opa(s_vol_layer, LV_OPA_90, 0);
    lv_obj_set_style_border_width(s_vol_layer, 0, 0);
    lv_obj_clear_flag(s_vol_layer, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_add_flag(s_vol_layer, LV_OBJ_FLAG_HIDDEN);

    s_vol_arc = lv_arc_create(s_vol_layer);
    lv_obj_set_size(s_vol_arc, 300, 300);
    lv_obj_center(s_vol_arc);
    lv_arc_set_rotation(s_vol_arc, 135);
    lv_arc_set_bg_angles(s_vol_arc, 0, 270);
    lv_arc_set_range(s_vol_arc, 0, 100);
    lv_arc_set_value(s_vol_arc, 45);
    lv_obj_set_style_arc_color(s_vol_arc, COL_TILE, LV_PART_MAIN);
    lv_obj_set_style_arc_color(s_vol_arc, COL_ACCENT, LV_PART_INDICATOR);
    lv_obj_set_style_arc_width(s_vol_arc, 16, LV_PART_MAIN);
    lv_obj_set_style_arc_width(s_vol_arc, 16, LV_PART_INDICATOR);
    lv_obj_add_event_cb(s_vol_arc, vol_event_cb, LV_EVENT_ALL, NULL);

    s_vol_label = lv_label_create(s_vol_layer);
    lv_label_set_text(s_vol_label, "45");
    lv_obj_set_style_text_color(s_vol_label, COL_TEXT, 0);
    lv_obj_set_style_text_font(s_vol_label, &lv_font_montserrat_48, 0);
    lv_obj_center(s_vol_label);

    lv_obj_t *cap = lv_label_create(s_vol_layer);
    lv_label_set_text(cap, "VOLUME");
    lv_obj_set_style_text_color(cap, COL_DIM, 0);
    lv_obj_set_style_text_font(cap, &lv_font_montserrat_12, 0);
    lv_obj_align(cap, LV_ALIGN_CENTER, 0, 40);
}

void ui_home_init(lv_group_t *group)
{
    s_group = group;
    lv_obj_t *root = make_root();
    make_header(root);
    make_list(root);
    make_volume_layer(root);
    lv_group_focus_obj(s_tiles[0]);
}
