"""Grafik çekirdeği: anime toon shader, post-process (çizgi + bloom + renk), gökyüzü, su."""
import math
from ursina import Shader, Entity, camera, scene, Vec3, window, color, Color
from panda3d.core import TransparencyAttrib, ColorBlendAttrib, CullFaceAttrib, DepthWriteAttrib

# ------------------------------------------------------------------ dünya / karakter shader'ı
TOON_VERT = '''
#version 140
uniform mat4 p3d_ModelViewProjectionMatrix;
uniform mat4 p3d_ModelMatrix;
uniform mat4 p3d_ModelViewMatrix;
uniform float time;
uniform float sway;
in vec4 p3d_Vertex;
in vec3 p3d_Normal;
in vec4 p3d_Color;
in vec2 p3d_MultiTexCoord0;
out vec3 wnorm;
out vec4 vcol;
out vec3 wpos;
out float vdist;
out vec2 uv;
void main() {
    vec4 wp = p3d_ModelMatrix * p3d_Vertex;
    vec4 lp = p3d_Vertex;
    if (sway > 0.0) {
        float h = max(wp.y - 2.0, 0.0);
        float s = sin(time * 1.7 + wp.x * 0.11 + wp.z * 0.07) * sway * h * 0.012;
        lp.x += s; lp.z += s * 0.6;
        wp = p3d_ModelMatrix * lp;
    }
    gl_Position = p3d_ModelViewProjectionMatrix * lp;
    wpos = wp.xyz;
    wnorm = mat3(p3d_ModelMatrix) * p3d_Normal;
    vcol = p3d_Color;
    vdist = length((p3d_ModelViewMatrix * lp).xyz);
    uv = p3d_MultiTexCoord0;
}
'''

TOON_FRAG = '''
#version 140
uniform sampler2D p3d_Texture0;
uniform vec4 p3d_ColorScale;
uniform vec3 sun_dir;
uniform vec3 sun_col;
uniform vec3 sky_amb;
uniform vec3 ground_amb;
uniform vec3 fog_col;
uniform float fog_density;
uniform vec3 cam_pos;
uniform float rim;
uniform float variation;
uniform float emissive;
in vec3 wnorm;
in vec4 vcol;
in vec3 wpos;
in float vdist;
in vec2 uv;
out vec4 fragColor;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void main() {
    vec4 base = vcol * p3d_ColorScale * texture(p3d_Texture0, uv);
    if (base.a < 0.02) discard;
    vec3 n = normalize(wnorm);
    if (!gl_FrontFacing) n = -n;
    float ndl = dot(n, sun_dir);
    float toon = smoothstep(-0.02, 0.06, ndl) * 0.55 + smoothstep(0.42, 0.5, ndl) * 0.45;
    vec3 amb = mix(ground_amb, sky_amb, n.y * 0.5 + 0.5);
    vec3 col = base.rgb;
    if (variation > 0.0) {
        float v = vnoise(wpos.xz * 0.18) * 0.6 + vnoise(wpos.xz * 1.3) * 0.4;
        col *= 1.0 + (v - 0.5) * 0.28 * variation;
    }
    vec3 lit = col * (amb + sun_col * toon);
    vec3 vdir = normalize(cam_pos - wpos);
    float r = pow(1.0 - max(dot(n, vdir), 0.0), 3.0) * rim;
    lit += r * (sun_col * 0.5 + sky_amb * 0.6);
    lit = mix(lit, col * 1.4, emissive);
    float f = 1.0 - exp(-pow(vdist * fog_density, 1.5));
    float hf = clamp((wpos.y - 40.0) / 300.0, 0.0, 1.0);
    lit = mix(lit, fog_col, clamp(f * (1.0 - hf * 0.6), 0.0, 1.0));
    fragColor = vec4(lit, base.a);
}
'''

toon_shader = Shader(name='toon', language=Shader.GLSL, vertex=TOON_VERT, fragment=TOON_FRAG,
                     default_input=dict(rim=0.0, variation=0.0, emissive=0.0, sway=0.0))

# ------------------------------------------------------------------ su
WATER_FRAG = '''
#version 140
uniform vec3 sun_dir;
uniform vec3 sun_col;
uniform vec3 sky_amb;
uniform vec3 fog_col;
uniform float fog_density;
uniform vec3 cam_pos;
uniform float time;
uniform vec4 p3d_ColorScale;
in vec3 wpos;
in float vdist;
out vec4 fragColor;
void main() {
    vec2 p = wpos.xz;
    float t = time;
    vec3 n = normalize(vec3(
        sin(p.x * 0.35 + t * 1.3) * 0.08 + sin(p.x * 1.1 - p.y * 0.7 + t * 2.1) * 0.05 + sin((p.x + p.y) * 2.3 + t * 3.0) * 0.02,
        1.0,
        cos(p.y * 0.31 + t * 1.1) * 0.08 + sin(p.y * 1.3 + p.x * 0.5 - t * 1.7) * 0.05 + cos((p.x - p.y) * 2.1 - t * 2.6) * 0.02));
    vec3 v = normalize(cam_pos - wpos);
    float fres = pow(1.0 - max(dot(n, v), 0.0), 4.0);
    vec3 deep = p3d_ColorScale.rgb * 0.55;
    vec3 shallow = p3d_ColorScale.rgb * 1.1;
    vec3 col = mix(deep, shallow, 0.5 + 0.5 * n.x * 4.0);
    col = col * (sky_amb + sun_col * 0.45) + fres * (fog_col * 0.9);
    vec3 h = normalize(sun_dir + v);
    float spec = pow(max(dot(n, h), 0.0), 220.0) * 2.5;
    col += sun_col * spec;
    float foam = smoothstep(0.86, 1.0, sin(p.x * 0.8 + t) * sin(p.y * 0.7 - t * 0.8));
    col += foam * 0.06;
    float f = 1.0 - exp(-pow(vdist * fog_density, 1.5));
    col = mix(col, fog_col, clamp(f, 0.0, 1.0));
    fragColor = vec4(col, mix(0.72, 0.95, fres));
}
'''
water_shader = Shader(name='water', language=Shader.GLSL, vertex=TOON_VERT, fragment=WATER_FRAG)

# ------------------------------------------------------------------ gökyüzü
SKY_VERT = '''
#version 140
uniform mat4 p3d_ModelViewProjectionMatrix;
uniform mat4 p3d_ModelMatrix;
in vec4 p3d_Vertex;
out vec3 dir;
void main() {
    gl_Position = p3d_ModelViewProjectionMatrix * p3d_Vertex;
    dir = normalize(mat3(p3d_ModelMatrix) * p3d_Vertex.xyz);
}
'''
SKY_FRAG = '''
#version 140
uniform vec3 sun_dir;
uniform vec3 sun_col;
uniform vec3 zenith;
uniform vec3 horizon;
uniform float night;
uniform float clouds;
uniform float time;
in vec3 dir;
out vec4 fragColor;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) { float s = 0.0, a = 0.5; for (int i = 0; i < 5; i++) { s += vnoise(p) * a; p *= 2.03; a *= 0.5; } return s; }
void main() {
    vec3 d = normalize(dir);
    float y = max(d.y, -0.05);
    vec3 col = mix(horizon, zenith, pow(clamp(y, 0.0, 1.0), 0.55));
    float sd = max(dot(d, sun_dir), 0.0);
    col += sun_col * (pow(sd, 900.0) * 6.0 + pow(sd, 12.0) * 0.25);
    vec3 md = -sun_dir;
    float m = max(dot(d, md), 0.0);
    col += vec3(0.85, 0.9, 1.0) * pow(m, 1500.0) * 4.0 * night + vec3(0.2, 0.25, 0.4) * pow(m, 20.0) * 0.3 * night;
    if (night > 0.0 && d.y > 0.0) {
        vec2 sp = d.xz / (d.y + 0.2) * 220.0;
        float st = step(0.997, hash(floor(sp)));
        col += st * night * (0.6 + 0.4 * sin(time * 3.0 + hash(floor(sp)) * 20.0));
    }
    if (d.y > 0.0 && clouds > 0.0) {
        vec2 cp = d.xz / (d.y + 0.08) * 1.4 + vec2(time * 0.012, time * 0.004);
        float c = fbm(cp);
        c = smoothstep(0.55 - clouds * 0.25, 0.9, c);
        vec3 ccol = mix(horizon * 1.1, vec3(1.0), 0.6) * (0.55 + 0.45 * (1.0 - night)) + sun_col * 0.15;
        col = mix(col, ccol, c * smoothstep(0.0, 0.15, d.y) * 0.9);
    }
    fragColor = vec4(col, 1.0);
}
'''
sky_shader = Shader(name='sky', language=Shader.GLSL, vertex=SKY_VERT, fragment=SKY_FRAG)

# ------------------------------------------------------------------ post-process
POST_FRAG = '''
#version 140
uniform sampler2D tex;
uniform sampler2D dtex;
uniform vec2 res;
uniform float near;
uniform float far;
uniform float outline;
uniform float bloom;
uniform vec4 tint;
uniform float vignette;
uniform float saturation;
uniform float flash;
in vec2 uv;
out vec4 o_color;

float lin(vec2 p) {
    float z = texture(dtex, p).r;
    return near * far / (far - z * (far - near));
}
void main() {
    vec2 px = 1.0 / res;
    vec3 c = texture(tex, uv).rgb;
    // mürekkep çizgileri (derinlik farkı)
    float d0 = lin(uv);
    float w = 1.2;
    float dl = lin(uv - vec2(px.x * w, 0.0));
    float dr = lin(uv + vec2(px.x * w, 0.0));
    float du = lin(uv + vec2(0.0, px.y * w));
    float dd = lin(uv - vec2(0.0, px.y * w));
    float e = (abs(dl - d0) + abs(dr - d0) + abs(du - d0) + abs(dd - d0)) / max(d0, 0.5);
    float edge = smoothstep(0.12, 0.35, e) * (1.0 - smoothstep(120.0, 600.0, d0));
    c = mix(c, c * 0.18, edge * outline);
    // bloom (parlak alanların hafif yayılması)
    vec3 b = vec3(0.0);
    for (int i = 0; i < 12; i++) {
        float a = float(i) * 0.5236;
        vec2 o = vec2(cos(a), sin(a));
        vec3 s1 = texture(tex, uv + o * px * 7.0).rgb;
        vec3 s2 = texture(tex, uv + o * px * 18.0).rgb;
        b += max(s1 - 0.72, 0.0) + max(s2 - 0.72, 0.0) * 0.6;
    }
    c += b / 12.0 * bloom;
    // renk
    float l = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(vec3(l), c, saturation);
    c = c * c * (3.0 - 2.0 * c) * 0.35 + c * 0.65;
    c = mix(c, tint.rgb * l * 1.4, tint.a);
    vec2 q = uv - 0.5;
    c *= 1.0 - dot(q, q) * vignette;
    c += flash;
    o_color = vec4(c, 1.0);
}
'''
post_shader = Shader(name='post', language=Shader.GLSL, fragment=POST_FRAG)


class Graphics:
    """Gün döngüsü, ışık uniform'ları ve post-process ayarlarını tek yerden yönetir."""

    def __init__(self, settings):
        self.settings = settings
        self.time = 0.0
        self.root = scene
        self.post_enabled = False
        self.tint = [0, 0, 0, 0]
        self.flash = 0.0
        self.fog_density = .0016
        self.sky = Entity(model='sphere', scale=3000, double_sided=True, shader=sky_shader)
        self.sky.setBin('background', 0)
        self.sky.setDepthWrite(False)
        self.sky.setLightOff(1)
        self.set_globals(Vec3(.5, .7, .3), Color(1, .95, .85, 1), Color(.55, .65, .8, 1), Color(.35, .3, .25, 1),
                         Color(.7, .82, .95, 1), Color(.3, .55, .95, 1), 0.0, .5)
        self.enable_post(True)

    def set_globals(self, sun_dir, sun_col, sky_amb, ground_amb, horizon, zenith, night, clouds):
        r = scene
        sd = Vec3(sun_dir).normalized()
        r.set_shader_input('sun_dir', sd)
        r.set_shader_input('sun_col', Vec3(sun_col[0], sun_col[1], sun_col[2]))
        r.set_shader_input('sky_amb', Vec3(sky_amb[0], sky_amb[1], sky_amb[2]))
        r.set_shader_input('ground_amb', Vec3(ground_amb[0], ground_amb[1], ground_amb[2]))
        r.set_shader_input('fog_col', Vec3(horizon[0], horizon[1], horizon[2]))
        r.set_shader_input('fog_density', self.fog_density / max(.3, self.settings.get('view', 1.0)))
        self.sky.set_shader_input('zenith', Vec3(zenith[0], zenith[1], zenith[2]))
        self.sky.set_shader_input('horizon', Vec3(horizon[0], horizon[1], horizon[2]))
        self.sky.set_shader_input('night', night)
        self.sky.set_shader_input('clouds', clouds)

    def enable_post(self, on):
        if on and not self.post_enabled:
            camera.shader = post_shader
            self.post_enabled = True
        elif not on and self.post_enabled:
            camera.shader = None
            self.post_enabled = False

    def update(self, dt):
        self.time += dt
        scene.set_shader_input('time', self.time)
        scene.set_shader_input('cam_pos', camera.world_position)
        self.sky.set_shader_input('time', self.time)
        self.sky.position = camera.world_position
        self.flash = max(0, self.flash - dt * 3)
        if self.post_enabled:
            camera.set_shader_input('res', Vec3(*window.size, 0).xy if hasattr(Vec3(1, 1, 1), 'xy') else window.size)
            camera.set_shader_input('near', float(camera.clip_plane_near))
            camera.set_shader_input('far', float(camera.clip_plane_far))
            camera.set_shader_input('outline', 1.0)
            camera.set_shader_input('bloom', .9)
            camera.set_shader_input('tint', tuple(self.tint))
            camera.set_shader_input('vignette', 1.1)
            camera.set_shader_input('saturation', 1.15)
            camera.set_shader_input('flash', self.flash)


def make_additive(np_):
    """Parlayan efektler: toplamalı karışım, derinlik yazma yok, ışık/shader yok."""
    np_.setShaderOff(50)
    np_.setLightOff(50)
    np_.setAttrib(ColorBlendAttrib.make(ColorBlendAttrib.MAdd, ColorBlendAttrib.OIncomingAlpha, ColorBlendAttrib.OOne))
    np_.setDepthWrite(False)
    np_.setBin('fixed', 10)
    np_.setTransparency(TransparencyAttrib.MNone)


def make_alpha_fx(np_):
    """Duman gibi yarı saydam efektler."""
    np_.setShaderOff(50)
    np_.setLightOff(50)
    np_.setTransparency(TransparencyAttrib.MAlpha)
    np_.setDepthWrite(False)
    np_.setBin('fixed', 5)
