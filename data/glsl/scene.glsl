uniform vec2 resolution;
uniform float time;
uniform sampler2D map;

// =============//============//===============//=============//============
// Codigo base feito por Barradeau, a partir de https://github.com/nicoptere/raymarching-for-THREE
// =============//============//===============//=============//===========

// Frame quadrado para a base da posicao do objeto na tela

vec2 squareFrame(vec2 screenSize) {
  vec2 position = 2.0 * (gl_FragCoord.xy / screenSize.xy) - 1.0;
  position.x *= screenSize.x / screenSize.y;
  return position;
}
vec2 squareFrame(vec2 screenSize, vec2 coord) {
  vec2 position = 2.0 * (coord.xy / screenSize.xy) - 1.0;
  position.x *= screenSize.x / screenSize.y;
  return position;
}

// Como visto em https://github.com/stackgl/glsl-look-at/blob/gh-pages/index.glsl
//
// Criamos uma matriz de 3 dimensoes onde: 
// origem e a posicao da camera
// alvo e a posicao que queremos olhar
// roll e a rotacao de rolagem da camera
//

mat3 calcLookAtMatrix(vec3 origin, vec3 target, float roll) {
    vec3 rr = vec3(sin(roll), cos(roll), 0.0);
    vec3 ww = normalize(target - origin);
    vec3 uu = normalize(cross(ww, rr));
    vec3 vv = normalize(cross(uu, ww));
    return mat3(uu, vv, ww);
}

// Como visto em https://github.com/stackgl/glsl-camera-ray
//
// Geramos um raio semelhante a Camera de raycasting do site ShaderToy, aceitando uma camera origem
// ou uma matriz de tres dimensoes arbitraria, onde:
//
// origem e a posicao da camera
// alvo e a posicao que a camera esta apontando
// tela e a posicao do fragmento na tela, usualmente entre -1 e 1.
// lente e a largura da lente da camera. Funciona como o FOV (Campo de visao), onde 0.0 e muito aberto e 2.0 e o padrao
//
// Para conveniencia, podemos substituir as variaveis "ro" e "ta" por uma matriz de 3 dimensoes "matCam".
// Desta maneira, conseguimos usar os modulos de camera junto com o glsl-camera-ray

vec3 getRay(mat3 camMat, vec2 screenPos, float lensLength) {
  return normalize(camMat * vec3(screenPos, lensLength));
}
vec3 getRay(vec3 origin, vec3 target, vec2 screenPos, float lensLength) {
  mat3 camMat = calcLookAtMatrix(origin, target, 0.0);
  return getRay(camMat, screenPos, lensLength);
}

mat3 rotationMatrix3(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c          );
}

// =============//============//===============//=============//============
// Tracando as primitivas do SDF
// =============//============//===============//=============//============

// Esfera
vec2 sphere( vec3 p, float radius, vec3 pos , vec4 quat)
{
    mat3 transform = rotationMatrix3( quat.xyz, quat.w );
    float d = length( ( p * transform )-pos ) - radius;
    return vec2(d,1);
}

// Caixa de pontas redondas
vec2 roundBox(vec3 p, vec3 size, float corner, vec3 pos, vec4 quat )
{
    mat3 transform = rotationMatrix3( quat.xyz, quat.w );
    return vec2( length( max( abs( ( p-pos ) * transform )-size, 0.0 ) )-corner,1.);
}

// Torus (Conhecido popularmente como "rosca" ou "Donut")
vec2 torus( vec3 p, vec2 radii, vec3 pos, vec4 quat )
{
    mat3 transform = rotationMatrix3( quat.xyz, quat.w );
    vec3 pp = ( p - pos ) * transform;
    float d = length( vec2( length( pp.xz ) - radii.x, pp.y ) ) - radii.y;
    return vec2(d,1.);
}

// Cilindro, como visto em http://www.pouet.net/topic.php?post=365312
vec2 cylinder( vec3 p, float h, float r, vec3 pos, vec4 quat ) {
    mat3 transform = rotationMatrix3( quat.xyz, quat.w );
    vec3 pp = (p - pos ) * transform;
    return vec2( max(length(pp.xz)-r, abs(pp.y)-h),1. );
}

// =============//============//===============//=============//============
// Operacoes Basicas
// =============//============//===============//=============//============


// Uniao
vec2 unionAB(vec2 a, vec2 b){
    return vec2(min(a.x, b.x),1.);
}

// Interseccao
vec2 intersectionAB(vec2 a, vec2 b){
    return vec2(max(a.x, b.x),1.);
}

// Diferenciacao / Subtracao
vec2 subtract(vec2 a, vec2 b){ 
    return vec2(max(-a.x, b.x),1.); 
}

// Mistura (Blend)
vec2 blendAB( vec2 a, vec2 b, float t ){ 
    return vec2(mix(a.x, b.x, t ),1.);
}

// =============//============//===============//=============//============
// A funcao do minimo suavizado definido por expressao polinomial,
// com k sendo a variavel definindo o campo de interpolacao,
// como demonstrado por Inigo Quilez em http://iquilezles.org/www/articles/smin/smin.htm
// =============//============//===============//=============//============

vec2 smin( vec2 a, vec2 b, float k ) { 
    float h = clamp( 0.5+0.5*(b.x-a.x)/k, 0.0, 1.0 ); 
    return vec2( mix( b.x, a.x, h ) - k*h*(1.0-h), 1. ); 
}

// =============//============//===============//=============//============
// Outras funcoes uteis
// =============//============//===============//=============//============

// funcao de ruido definida por Ken Perlin, descrita no topico do Pouet
// http://www.pouet.net/topic.php?post=367360

const vec3 pa = vec3(1., 57., 21.);
const vec4 pb = vec4(0., 57., 21., 78.);
float perlin(vec3 p) {
    vec3 i = floor(p);
    vec4 a = dot( i, pa ) + pb;
    vec3 f = cos((p-i)*acos(-1.))*(-.5)+.5;
    a = mix(sin(cos(a)*a),sin(cos(1.+a)*(1.+a)), f.x);
    a.xy = mix(a.xz, a.yw, f.y);
    return mix(a.x, a.y, f.z);
}

// =============//============//===============//=============//============
// Funcao da Superficie de Distancia
// =============//============//===============//=============//============

const int steps = 30;
const int shadowSteps = 4;
const int ambienOcclusionSteps = 3;
const float PI = 3.14159;
vec2 field( vec3 position )
{
    // posicao
    vec3 zero = vec3(0.);

    // rotacao
    vec4 quat = vec4( 1., sin( time ) *.1 , 0., time * .2 );

    // ruido (noise)
    vec3 noise = position * .25;
    //noise += time * .1;
    float pnoise = 1. + perlin( noise );

    // caixa / cubo
    vec2 rb = roundBox( position, vec3(2.0,2.0,2.0),  0.5, zero, quat + vec4( 1., 1., 1., PI / 4. ) );
    vec2 cubo = roundBox(position, vec3(2.0,2.0,2.0),  0.5, zero, vec4( 1., 0.25, 1., PI/3. ) ); 
    // rosca
    vec2 to0 = torus( position, vec2( 5.0,.15), zero, vec4( 1., 0., 0., 0. + time * .2 ) );
    vec2 to1 = torus( position, vec2( 5.0,.15), zero, vec4( 0., 0., 1., PI *.5 + time * .2 ) );
    vec2 to2 = torus( position, vec2( 5.0,.15), zero, vec4( 1., 1., 0., PI *.5 + time * .2) );

    // esferas
    vec2 sre = sphere( position, 3.25, zero, quat );
    vec2 sce = sphere( position, 2., zero, quat ) + perlin( position + time ) * .25;

    // cilindro
    vec2 cy1 = cylinder(position, 4., 2., zero, vec4(1, 0, 0, PI * .75));
    vec2 cy2 = cylinder(position, 4., 2., zero, vec4(0, 0, 1., PI * 1.25 ));
    vec2 cy3 = cylinder(position, 4., 2., zero, vec4(0, 0, 1, PI * .75));

    // a CSG composta para criar o objeto em tela
    //return intersectionAB(cubo, sre);
    //return unionAB(cy1, unionAB(cy2, cy3));
    //return subtract(unionAB(cy1, unionAB(cy2, cy3)), intersectionAB(cubo, sre));
    return smin( sce, smin( to0, smin( to1, smin( to2, subtract(sre, rb), pnoise), pnoise ), pnoise ), pnoise);
}

// =============//============//===============//=============//============
// A partir daqui, todas as funcoes fazem uso da funcao da superficie de distancia acima
// =============//============//===============//=============//============

// =============//============//===============//=============//============
// O metodo de Raymarching
// descrito em https://github.com/stackgl/glsl-raytrace/blob/master/index.glsl
// e explicado por Inigo Quilez
// =============//============//===============//=============//============

vec2 raymarching( vec3 rayOrigin, vec3 rayDir, float maxd, float precis ) {

    float latest = precis * 2.0;
    float dist   = 0.0;
    float type   = -1.0;
    vec2  res    = vec2(-1.0, -1.0);
    for (int i = 0; i < steps; i++) {

        if (latest < precis || dist > maxd) break;

        vec2 result = field( rayOrigin + rayDir * dist );
        latest = result.x;
        type   = result.y;
        dist  += latest;
    }

    if (dist < maxd) { res = vec2(dist, type); }
    return res;
}

// =============//============//===============//=============//============
// Calculo da normal, como explicado em https://github.com/stackgl/glsl-sdf-normal
// =============//============//===============//=============//============

vec3 calcNormal(vec3 pos, float eps) {
  const vec3 v1 = vec3( 1.0,-1.0,-1.0);
  const vec3 v2 = vec3(-1.0,-1.0, 1.0);
  const vec3 v3 = vec3(-1.0, 1.0,-1.0);
  const vec3 v4 = vec3( 1.0, 1.0, 1.0);

  return normalize( v1 * field( pos + v1*eps ).x +
                    v2 * field( pos + v2*eps ).x +
                    v3 * field( pos + v3*eps ).x +
                    v4 * field( pos + v4*eps ).x );
}

vec3 calcNormal(vec3 pos) {
  return calcNormal(pos, 0.002);
}

// =============//============//===============//=============//============
// Sombras e Oclusao de Ambiente, vistas em https://www.shadertoy.com/view/Xds3zN
// =============//============//===============//=============//============

float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax, in float K )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<shadowSteps; i++ )
    {
        float h = field( ro + rd*t ).x;
        res = min( res, K * h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<ambienOcclusionSteps; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/float( ambienOcclusionSteps );
        vec3 aopos =  nor * hr + pos;
        float dd = field( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );
}


vec3 rimlight( vec3 pos, vec3 nor )
{
    vec3 v = normalize(-pos);
    float vdn = 1.0 - max(dot(v, nor), 0.0);
    return vec3(smoothstep(0., 1.0, vdn));
}

// =============//============//===============//=============//============
// E agora, vamos renderizar tudo!
// =============//============//===============//=============//============

void main() {
    vec3 color0 = vec3(0.9, 0.9, 0.0);    // amarelo
    vec3 color1 = vec3(0.0, 0.2, 0.9);    // azul

    // cor padrao (cor de fundo)
    vec2 xy = gl_FragCoord.xy / resolution;
    gl_FragColor = vec4( mix( color0, color1, sin( xy.y + 0.5 ) ) * 2., 1. );

    float cameraAngle   = 0.; // 0.8 * time;
    float cameraRadius  = 20.;

    vec2  screenPos    = squareFrame( resolution );
    float lensLength   = 2.5;
    vec3  rayOrigin    = vec3( cameraRadius * sin(cameraAngle), 0., cameraRadius * cos(cameraAngle));
    vec3  rayTarget    = vec3(0, 0, 0);
    vec3  rayDirection = getRay(rayOrigin, rayTarget, screenPos, lensLength);


    float maxDist = 50.;
    vec2 collision = raymarching( rayOrigin, rayDirection, maxDist, .01 );

    if ( collision.x > -0.5)
    {

        // "posicao do mundo"
        vec3 pos = rayOrigin + rayDirection * collision.x;

        // cor de difusao
        vec3 col = vec3( .8,.8,.8 );

        // vetor normal
        vec3 nor = calcNormal( pos );

        //  reflexao (Spherical Environment Mapping)
        vec2 uv = nor.xy / 2. + .5;
        vec3 tex = texture2D( map, uv ).rgb;
        col += tex * .1;

        vec3 lig0 = normalize( vec3(-0.5, 0.75, -0.5) );
        vec3 light0 =  max( 0.0, dot( lig0, nor) ) * color0;

        vec3 lig1 = normalize( vec3( 0.5, -0.75, 0.5) );
        vec3 light1 = max( 0.0, dot( lig1, nor) ) * color1;

        //  Oclusao de Ambiente : normalmente muito forte
        float occ = calcAO( pos, nor );

        float dep = ( ( collision.x + .5 ) / ( maxDist * .5 ) );
        gl_FragColor = vec4( ( col + light0 + light1 ) * occ * dep, 1. );
    }
}