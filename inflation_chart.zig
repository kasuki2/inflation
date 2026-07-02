const std = @import("std");

// We enforce a strict memory layout so JavaScript's Float32Array can read it perfectly.
// Total size: 16 floats (64 bytes) per point.
pub const Point = extern struct {
    x: f32,
    y: f32,
    tx: f32, // Target X (Logarithmic weight)
    ty: f32, // Target Y (Inflation)
    r: f32, // Red color (0.0 - 1.0)
    g: f32, // Green color
    b: f32, // Blue color
    radius: f32, // Bubble radius
    id: f32, // Using f32 for ID so it aligns perfectly in a Float32Array
    weight: f32, // Raw weight value
    inflation: f32, // Raw inflation value
    visible: f32, // Current opacity (0.0 to 1.0)
    tvisible: f32, // Target opacity
    pad1: f32,
    pad2: f32,
    pad3: f32,
};

// Allocate memory for up to 500 product groups
var points: [500]Point = undefined;
var points_len: usize = 0;

export fn reset_points() void {
    points_len = 0;
}

export fn add_point(id: f32, r: f32, g: f32, b: f32) void {
    if (points_len >= points.len) return;

    points[points_len] = Point{
        .x = 0,
        .y = 0,
        .tx = 0,
        .ty = 0,
        .r = r,
        .g = g,
        .b = b,
        .radius = 5.0,
        .id = id,
        .weight = 0,
        .inflation = 0,
        .visible = 0.0,
        .tvisible = 0.0,
        .pad1 = 0,
        .pad2 = 0,
        .pad3 = 0,
    };
    points_len += 1;
}

export fn update_target(id: f32, tx: f32, ty: f32, weight: f32, inflation: f32, visible: f32) void {
    var i: usize = 0;
    while (i < points_len) : (i += 1) {
        var p = &points[i];
        if (p.id == id) {
            p.tx = tx;
            p.ty = ty;
            p.weight = weight;
            p.inflation = inflation;
            p.tvisible = visible;

            // If the point was fully invisible and is now appearing, snap it to the target
            // so it doesn't fly in from coordinates (0,0)
            if (p.visible < 0.01 and visible > 0.0) {
                p.x = tx;
                p.y = ty;
            }
            break;
        }
    }
}

// Called 60 times a second by requestAnimationFrame
export fn animate(dt: f32) void {
    // Animation speed constant for smooth interpolation
    const speed: f32 = 6.0 * dt;

    var i: usize = 0;
    while (i < points_len) : (i += 1) {
        var p = &points[i];
        p.x += (p.tx - p.x) * speed;
        p.y += (p.ty - p.y) * speed;
        p.visible += (p.tvisible - p.visible) * speed;
    }
}

// Return the memory pointer to JavaScript so JS can stream it directly to WebGL
export fn get_points_ptr() [*]Point {
    return &points;
}

export fn get_points_len() usize {
    return points_len;
}
