#define MAX_CELLS 512
extern number perm[MAX_CELLS];
extern number cols;
extern number rows;
extern number cell_size;

// Square-shuffle for the Puzzle boss blind. One real GPU shader pass (like
// record_spin.fs) instead of one love.graphics.draw() call per grid cell --
// dozens of small draw calls every single frame left very little headroom,
// which is exactly what let a momentary CPU/GPU spike (e.g. constructing a
// new UI element, like the deck-hover preview) tip a frame over its vsync
// deadline into a torn frame.
vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    float dc = floor(screen_coords.x / cell_size);
    float dr = floor(screen_coords.y / cell_size);
    if (dc < 0.0 || dc >= cols || dr < 0.0 || dr >= rows) {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }

    int screen_i = int(dr * cols + dc);
    float source_i = perm[screen_i];
    float sc = mod(source_i, cols);
    float sr = floor(source_i / cols);

    vec2 offset = screen_coords - vec2(dc, dr) * cell_size;
    vec2 source_coords = vec2(sc, sr) * cell_size + offset;

    if (source_coords.x >= love_ScreenSize.x || source_coords.y >= love_ScreenSize.y) {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }

    vec2 uv = source_coords / love_ScreenSize.xy;
    return Texel(texture, uv) * colour;
}
