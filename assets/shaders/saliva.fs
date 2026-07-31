#if defined(VERTEX) || __VERSION__ > 100 || defined(GL_FRAGMENT_PRECISION_HIGH)
	#define MY_HIGHP_OR_MEDIUMP highp
#else
	#define MY_HIGHP_OR_MEDIUMP mediump
#endif

// Steamodded sends the card's motion state under the shader's own key:
// saliva.x = VT.r*3 + time/28 + juice + tilt  (bumps with rotation/inclination)
// saliva.y = real time
extern MY_HIGHP_OR_MEDIUMP vec2 saliva;
extern MY_HIGHP_OR_MEDIUMP number dissolve;
extern MY_HIGHP_OR_MEDIUMP number time;
extern MY_HIGHP_OR_MEDIUMP vec4 texture_details;
extern MY_HIGHP_OR_MEDIUMP vec2 image_details;
extern bool shadow;
extern MY_HIGHP_OR_MEDIUMP vec4 burn_colour_1;
extern MY_HIGHP_OR_MEDIUMP vec4 burn_colour_2;

// ------------------------- tuning -------------------------
#define CELL_SCALE 5.5        // approx. number of cells across the card
#define EDGE_BAND 0.45        // width (in cell units) of the blurry rim of each cell
#define MAX_BLUR_PX 3.5       // blur radius in sprite pixels at cell edges/interstices
#define BLUR_DIRECTIONS 12.0  // Cryptid-style disc blur: directions
#define BLUR_QUALITY 4.0      //                          radial steps
#define WOBBLE 0.32           // how far cell nuclei wander (keep < 0.5)
#define BUBBLE_ZOOM 1.1        // per-cell magnifier strength; multiplied by each cell's own size
#define BUBBLE_LIGHT 0.85      // overall intensity of the fake-3D sphere shading
// -----------------------------------------------------------

// sprite-local uv (0-1) -> atlas texture coords, clamped to this sprite's
// rect so the blur never bleeds pixels from neighbouring atlas entries
vec2 uv_to_tc(vec2 uv)
{
    vec2 clamped = clamp(uv, vec2(0.001), vec2(0.999));
    return ((clamped + texture_details.xy) * texture_details.ba) / image_details;
}

vec4 dissolve_mask(vec4 tex, vec2 texture_coords, vec2 uv)
{
    if (dissolve < 0.001) {
        return vec4(shadow ? vec3(0.,0.,0.) : tex.xyz, shadow ? tex.a*0.3: tex.a);
    }

    float adjusted_dissolve = (dissolve*dissolve*(3.-2.*dissolve))*1.02 - 0.01; //Adjusting 0.0-1.0 to fall to -0.1 - 1.1 scale so the mask does not pause at extreme values

	float t = time * 10.0 + 2003.;
	vec2 floored_uv = (floor((uv*texture_details.ba)))/max(texture_details.b, texture_details.a);
    vec2 uv_scaled_centered = (floored_uv - 0.5) * 2.3 * max(texture_details.b, texture_details.a);

	vec2 field_part1 = uv_scaled_centered + 50.*vec2(sin(-t / 143.6340), cos(-t / 99.4324));
	vec2 field_part2 = uv_scaled_centered + 50.*vec2(cos( t / 53.1532),  cos( t / 61.4532));
	vec2 field_part3 = uv_scaled_centered + 50.*vec2(sin(-t / 87.53218), sin(-t / 49.0000));

    float field = (1.+ (
        cos(length(field_part1) / 19.483) + sin(length(field_part2) / 33.155) * cos(field_part2.y / 15.73) +
        cos(length(field_part3) / 27.193) * sin(field_part3.x / 21.92) ))/2.;
    vec2 borders = vec2(0.2, 0.8);

    float res = (.5 + .5* cos( (adjusted_dissolve) / 82.612 + ( field + -.5 ) *3.14))
    - (floored_uv.x > borders.y ? (floored_uv.x - borders.y)*(5. + 5.*dissolve) : 0.)*(dissolve)
    - (floored_uv.y > borders.y ? (floored_uv.y - borders.y)*(5. + 5.*dissolve) : 0.)*(dissolve)
    - (floored_uv.x < borders.x ? (borders.x - floored_uv.x)*(5. + 5.*dissolve) : 0.)*(dissolve)
    - (floored_uv.y < borders.x ? (borders.x - floored_uv.y)*(5. + 5.*dissolve) : 0.)*(dissolve);

    if (tex.a > 0.01 && burn_colour_1.a > 0.01 && !shadow && res < adjusted_dissolve + 0.8*(0.5-abs(adjusted_dissolve-0.5)) && res > adjusted_dissolve) {
        if (!shadow && res < adjusted_dissolve + 0.5*(0.5-abs(adjusted_dissolve-0.5)) && res > adjusted_dissolve) {
            tex.rgba = burn_colour_1.rgba;
        } else if (burn_colour_2.a > 0.01) {
            tex.rgba = burn_colour_2.rgba;
        }
    }

    return vec4(shadow ? vec3(0.,0.,0.) : tex.xyz, res > adjusted_dissolve ? (shadow ? tex.a*0.3: tex.a) : .0);
}

// per-cell pseudo-random values
vec2 hash22(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

vec4 effect( vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords )
{
    vec2 uv = (((texture_coords)*(image_details)) - texture_details.xy*texture_details.ba)/texture_details.ba;

    float t = saliva.y;
    float rot = saliva.x; // accumulates with rotation, tilt, juice
    float aspect = texture_details.b / texture_details.a;

    // --- cell-space coordinates: aspect corrected, slowly swirled by
    // --- the card's rotation/tilt channel so the pattern reacts to motion
    vec2 st = uv - vec2(0.5);
    st.x = st.x * aspect;
    float swirl = 0.18 * sin(rot * 0.9) + 0.05 * rot;
    float cs = cos(swirl); float sn = sin(swirl);
    st = mat2(cs, -sn, sn, cs) * st;
    vec2 p = st * CELL_SCALE;

    // --- multiplicatively-weighted Voronoi: nuclei drift and their
    // --- weights (cell radii) breathe over time, each with its own phase.
    // --- A Voronoi partition covers the whole plane, so no gaps, ever;
    // --- the multiplicative weights are what round the cells out and
    // --- make them different sizes. We also remember the winning cell's
    // --- offset-from-nucleus (in p-space) and its weight -- every cell
    // --- gets its own little bubble lens driven by these two numbers.
    vec2 g = floor(p);
    vec2 f = p - g;

    float F1 = 8.0;
    float F2 = 8.0;
    vec2 F1_diff = vec2(0.0);
    float F1_w = 1.0;
    for (float y = -2.0; y <= 2.0; y += 1.0) {
        for (float x = -2.0; x <= 2.0; x += 1.0) {
            vec2 cell = vec2(x, y);
            vec2 h = hash22(g + cell);
            vec2 h2 = hash22(g + cell + vec2(41.7, 289.3));
            // nucleus wanders inside its lattice cell; phase offset by the
            // rotation channel so tilting the card sloshes the cells
            vec2 nucleus = cell + vec2(0.5)
                + WOBBLE * vec2(sin(t * (0.35 + 0.4*h.x) + h.y * 6.2831 + 0.35*rot),
                                cos(t * (0.30 + 0.4*h.y) + h.x * 6.2831 - 0.28*rot));
            // per-cell radius weight, slowly breathing
            float w = 0.75 + 0.45 * h2.x + 0.20 * sin(t * (0.4 + 0.5*h2.y) + h2.x * 6.2831);
            vec2 diff = f - nucleus;
            float d = length(diff) / w;
            if (d < F1) { F2 = F1; F1 = d; F1_diff = diff; F1_w = w; }
            else if (d < F2) { F2 = d; }
        }
    }

    // edge metric: 0 exactly on a cell border (and in the interstices
    // where several borders meet), grows toward each cell's center
    float edge = F2 - F1;
    float blur_amt = 1.0 - smoothstep(0.0, EDGE_BAND, edge);
    blur_amt = blur_amt * blur_amt; // keep cell hearts crisp, rims soft

    // --- per-cell bubble lens: each Voronoi cell magnifies its own
    // --- centre, the way surface tension domes up a droplet. F1 is
    // --- already the distance to this cell's nucleus normalised by the
    // --- cell's own radius (0 at the nucleus, ~1 at its border), so it
    // --- doubles as the bubble's radial coordinate. Bigger cells (a
    // --- larger F1_w) get a stronger zoom, per the brief; the pull
    // --- fades back to zero at r=1 so neighbouring cells stay seamless.
    float r = clamp(F1, 0.0, 1.0);
    float dome = sqrt(max(0.0, 1.0 - r * r)); // hemisphere height: 1 at centre -> 0 at rim
    float cell_zoom = BUBBLE_ZOOM * F1_w;
    float shrink = cell_zoom * dome / (1.0 + cell_zoom * dome); // in [0,1)

    // undo (CELL_SCALE, swirl rotation, aspect) to turn the p-space
    // nucleus offset back into a uv-space offset, so the lens can warp
    // the actual sample coordinates
    vec2 uv_diff = mat2(cs, sn, -sn, cs) * (F1_diff / CELL_SCALE);
    uv_diff.x /= aspect;

    vec2 bubble_uv = uv - uv_diff * shrink;
    vec4 original_pixel = Texel(texture, uv_to_tc(bubble_uv));

    // --- Cryptid-style disc blur (blur.fs), radius scaled per-pixel by
    // --- proximity to the cell edge, sampling clamped to this sprite
    float two_pi = 6.28318530718;
    vec2 radius = (MAX_BLUR_PX * blur_amt) / texture_details.ba;

    vec4 blurred_pixel = original_pixel;
    float d_step = two_pi / BLUR_DIRECTIONS;
    float i_step = 1.0 / BLUR_QUALITY;
    for (float d = 0.0; d < two_pi; d += d_step) {
        for (float i = i_step; i < 1.001; i += i_step) {
            blurred_pixel += Texel(texture, uv_to_tc(bubble_uv + vec2(cos(d), sin(d)) * radius * i));
        }
    }
    blurred_pixel /= BLUR_QUALITY * BLUR_DIRECTIONS + 1.0;

    vec4 tex = vec4(blurred_pixel.rgb, original_pixel.a);

    // --- wet film: a faint milky sheen on the blurry rims, and a subtle
    // --- specular glint that sweeps with the card's rotation channel
    float film = blur_amt * 0.16;
    float glint = 0.10 * blur_amt * max(0.0, sin(rot * 1.7 + (F1 - F2) * 3.0 + st.y * 4.0));
    tex.rgb = mix(tex.rgb, vec3(0.94, 0.97, 1.0), (film + glint) * tex.a);

    // --- per-cell 3D shading: build a hemisphere normal from the same
    // --- (direction, radius) pair driving the lens above, so every
    // --- bubble reads as its own little lit sphere -- soft diffuse
    // --- falloff, a tight specular hotspot, and a fresnel-style rim
    // --- brightening near each cell's edge.
    vec2 dir = length(uv_diff) > 1e-5 ? normalize(uv_diff) : vec2(0.0);
    vec3 N = normalize(vec3(dir * r, dome));
    vec3 L = normalize(vec3(-0.35, 0.55, 0.75));
    vec3 V = vec3(0.0, 0.0, 1.0);
    vec3 H = normalize(L + V);
    float ndotl = max(dot(N, L), 0.0);
    float ndotv = max(dot(N, V), 0.0);
    float spec = pow(max(dot(N, H), 0.0), 22.0);
    float fresnel = pow(1.0 - ndotv, 3.0);

    tex.rgb += ndotl * 0.16 * BUBBLE_LIGHT;
    tex.rgb += spec * 0.6 * BUBBLE_LIGHT;
    tex.rgb = mix(tex.rgb, vec3(0.95, 0.98, 1.0), fresnel * 0.30 * BUBBLE_LIGHT * tex.a);
    tex.rgb -= (1.0 - ndotl) * 0.06 * BUBBLE_LIGHT;

    return dissolve_mask(tex * colour, texture_coords, bubble_uv);
}

extern MY_HIGHP_OR_MEDIUMP vec2 mouse_screen_pos;
extern MY_HIGHP_OR_MEDIUMP float hovering;
extern MY_HIGHP_OR_MEDIUMP float screen_scale;

#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    if (hovering <= 0.){
        return transform_projection * vertex_position;
    }
    float mid_dist = length(vertex_position.xy - 0.5*love_ScreenSize.xy)/length(love_ScreenSize.xy);
    vec2 mouse_offset = (vertex_position.xy - mouse_screen_pos.xy)/screen_scale;
    float scale = 0.2*(-0.03 - 0.3*max(0., 0.3-mid_dist))
                *hovering*(length(mouse_offset)*length(mouse_offset))/(2. -mid_dist);

    return transform_projection * vertex_position + vec4(0,0,0,scale);
}
#endif
