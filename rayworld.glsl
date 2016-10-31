precision lowp float;
uniform float iGlobalTime;
uniform vec2 iResolution;

const float vFov = 60.0;
const float sHgt = 1.0;

const float minD = 0.0;
const float maxD = 60.0;
const float stepD = 0.15;

const vec3 camO = vec3(0, 2, -2);
const float sunAngle = 35.0;

const vec4 snowColor = vec4(0.8, 0.8, 0.85, 1.0);
const vec4 rockColor = vec4(0.4, 0.4, 0.38, 1.0);
const vec4 dirtColor = vec4(0.55, 0.45, 0.4, 1.0);
const vec4 grassColor = vec4(0.35, 0.45, 0.35, 1.0);

const vec4 hrzDColor = vec4(0.9, 0.95, 1.0, 1.0);
const vec4 hrzEColor = vec4(0.9, 0.75, 0.6, 1.0);
const vec4 hrzNColor = vec4(0.2, 0.24, 0.4, 1.0);

const vec4 zenDColor = vec4(0.7, 0.75, 1.0, 1.0);
const vec4 zenEColor = vec4(0.7, 0.6, 0.65, 1.0);
const vec4 zenNColor = vec4(0.3, 0.35, 0.5, 1.0);

const vec4 sunDColor = vec4(1.0, 0.97, 0.9, 1.0);
const vec4 sunEColor = vec4(0.8, 0.6, 0.5, 1.0);

const vec4 ambDColor = vec4(0.4, 0.42, 0.50, 1.0);
const vec4 ambEColor = vec4(0.4, 0.35, 0.32, 1.0);
const vec4 ambNColor = vec4(0.1, 0.12, 0.2, 1.0);

struct ray {
    vec3 o;
    vec3 d;
};

ray rayFromScreenCoords(in vec2 coord, in vec3 camO) {
    vec2 xy = vec2(coord.x - iResolution.x/2.0,
                   coord.y - iResolution.y/2.0)
    / iResolution.y;

    vec3 ori = vec3(camO.x + sHgt*xy.x,
                    camO.y + sHgt*xy.y,
                    camO.z);

    vec2 ang = radians(vFov) * xy;
    vec3 dir = vec3(sin(ang.x) * cos(ang.y),
                    sin(ang.y) * cos(ang.x),
                    -cos(ang.x) * cos(ang.y));

    return ray(ori, dir);
}

// ===== github.com/ashima/webgl-noise =====
vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289(((x*34.0)+1.0)*x);
}

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                        0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                        -0.577350269189626,  // -1.0 + 2.0 * C.x
                        0.024390243902439); // 1.0 / 41.0
    // First corner
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);

    // Other corners
    vec2 i1;
    //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
    //i1.y = 1.0 - i1.x;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    // x0 = x0 - 0.0 + 0.0 * C.xx ;
    // x1 = x0 - i1 + 1.0 * C.xx ;
    // x2 = x0 - 1.0 + 2.0 * C.xx ;
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    // Permutations
    i = mod289(i); // Avoid truncation effects in permutation
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
                     + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;

    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt( a0*a0 + h*h );
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

    // Compute final noise value at P
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}
// =========================================

float terrainBase(in float x, in float z) {
    return snoise(vec2(x, z) * 0.1);
}

float terrainH(in float x, in float z) {
    float base = terrainBase(x, z);

    if (base >= -0.25) {
        base += snoise(vec2(x, z) * 0.8) * 0.2 * (base+0.25);
    }
    return base;
}

vec4 grassC(vec3 pt) {
    return mix(grassColor, vec4(0,0,0,1.0),
               terrainBase(150.0*pt.z, 150.0*pt.x)*0.03);
}

vec4 rockC(vec3 pt) {
    return mix(rockColor, vec4(0,0,0,1.0),
               terrainBase(40.0*pt.z, 40.0*pt.x)*0.02);
}

vec4 snowC(vec3 pt) {
    return mix(snowColor, vec4(0,0,0,1.0),
               terrainBase(60.0*pt.z, 60.0*pt.x)*0.015);
}

vec4 terrainD(vec3 pt) {
    float dirtLevel = 0.1 * cos(25.2*pt.x)
    * sin(24.3*pt.z)
    - 0.25;
    float rockLevel = 0.1 * cos(14.1*pt.x)
    * sin(12.5*pt.z);

    float snowLevel = 0.02 * cos(36.3*pt.x)
    * sin(31.2*pt.z)
    + 0.65
    + sin(1.3*pt.x)
    * cos(1.4*pt.z)
    * 0.2;

    if (pt.y < dirtLevel) {
        return mix(grassC(pt), dirtColor,
                   max(0.0, (pt.y - dirtLevel+0.2)/0.2));
    } else if (pt.y < rockLevel) {
        return mix(dirtColor, rockC(pt),
                   (pt.y - dirtLevel)/(rockLevel-dirtLevel));
    } else if (pt.y < snowLevel){
        return rockC(pt);
    } else {
        return mix(rockC(pt), snowC(pt),
                   min(0.05, pt.y - snowLevel)/0.05);
    }
}

float sunTime() {
    return iGlobalTime * 0.05 + radians(30.0);
}

vec3 sunDir() {
    float t = sunTime();
    float angleR = radians(sunAngle);

    return vec3(
                sin(t)*sin(angleR),
                cos(t),
                sin(t)*cos(angleR));
}

bool isSunlit(vec3 pt) {
    vec3 sunD = sunDir();

    if (sunD.y > 0.0) {
        float t = stepD;
        for (int i=0;i<500;i++) {
            vec3 p = pt + t*sunD;

            if (p.y > 2.0) {
                return true;
            } else if (p.y < terrainH(p.x, p.z)) {
                return false;
            }
            t+=stepD;
        }
    } else {
        return false;
    }
}

vec4 sunCycle(vec4 day, vec4 eve, vec4 nig) {
    float sunHeight = cos(sunTime());

    if (sunHeight > 0.0) {
        return mix(eve, day, sunHeight);
    } else {
        return mix(eve, nig, abs(sunHeight));
    }
}

bool marchRay(in ray r, out float d, out vec4 diff) {
    float lt = minD;
    float lh = 0.0;
    float ly = 0.0;
    float dt = 0.0;
    for (float t=minD; t<maxD; t+=stepD) {
        vec3 p = r.o + t*r.d;

        if (p.y > 1.25 && r.d.y >= 0.0) {
            // We are above the terrain and not heading down. We won't collide.
            return false;
        }

        float h = terrainH(p.x, p.z);

        if (p.y < h) {
            d = t - dt + dt*(lh-ly)/(p.y-ly-h+lh);

            vec3 chosenP = r.o + d*r.d;

            diff = terrainD(chosenP);

            vec4 light = sunCycle(ambDColor, ambEColor, ambNColor);

            if (isSunlit(chosenP)) {
                light = clamp(sunCycle(sunDColor, sunEColor, vec4(0,0,0,1.0))+light, 0.0, 1.0);
            }
            diff = min(diff, light);

            return true;
        }
        lt = t;
        lh = h;
        ly = p.y;
        dt = stepD;
    }
    return false;
}

vec4 skyColor(ray r) {
    float amt = clamp(r.d.y, 0.0, 1.0);
    return mix(sunCycle(hrzDColor, hrzEColor, hrzNColor),
               sunCycle(zenDColor, zenEColor, zenNColor),
               amt);
}

float sunD(ray r) {
    vec3 sd = sunDir();
    float d = length(cross(r.d, sd));

    if (sd.z > 0.0) {
        d = radians(180.0)-d;
    }
    return d;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float camX = 6.0 * sin(iGlobalTime*0.5) * cos(iGlobalTime*0.01 + 0.5);
    float camZ = -4.0 * iGlobalTime;
    float camY = mix(terrainBase(camX, camZ)*1.5 + 1.12, 2.5 + sin(iGlobalTime),
                     min(1.0, max(0.0, 0.5 - 2.0 * cos(iGlobalTime*0.069))));

    vec3 camLoc = vec3(camX, camY, camZ);
    ray r = rayFromScreenCoords(fragCoord, camLoc);
    float sd = sunD(r);

    float d;
    vec4 gc;
    if (marchRay(r, d, gc)) {
        float fogAmount = (min(max(d, minD), maxD) / (maxD-minD));
        fogAmount *= fogAmount*fogAmount;

        fragColor = gc * (1.0-fogAmount)
        + skyColor(r) * fogAmount;
    } else if (sunD(r) < radians(2.0)) {
        fragColor = vec4(1.0, 1.0, 1.0, 1.0);
    } else {
        fragColor = skyColor(r)
            + mix(vec4(1.0, 1.0, 1.0, 1.0), vec4(0, 0, 0, 1.0),
                  min(1.0, (sunD(r) - radians(2.0))/radians(2.0)))
            + mix(vec4(0.2, 0.2, 0.2, 1.0), vec4(0, 0, 0, 1.0),
                  min(1.0, sunD(r)/radians(40.0)));
    }
}

void main() {
  vec2 pos = gl_FragCoord.xy;
  mainImage(gl_FragColor, pos);
}

