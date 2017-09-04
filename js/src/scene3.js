var scene, renderer, camera, control, stats;

//Definindo largura e altura da cena
var w = window.innerWidth;
var h = window.innerHeight;

function init() {

    //criando a cena
    scene = new THREE.Scene();

    //Criando o renderer
    renderer = new THREE.WebGLRenderer();
    renderer.setClearColor(0x000000, 1.0);
    renderer.setSize(w,h);

    //Habilitando mapeamento de sombra
    renderer.shadowMap.enabled = true;
    //Definindo tipo de mapeamento de sombra
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;

    //Criando a câmera da cena
    camera = new THREE.PerspectiveCamera( 45, w/h, 0.1, 1000 );

    camera.position.x = 15;
    camera.position.y = 16;
    camera.position.z = 13;
    camera.lookAt(scene.position);

    //Criando o cubo
    var cubeGeometry = new THREE.CubeGeometry(6, 4, 6);
    var cubeMaterial = new THREE.MeshLambertMaterial({
        color: 'red'
    });
    var cube = new THREE.Mesh(cubeGeometry /* Geometria */, cubeMaterial /* Material */);
    cube.castShadow = true;
    cube.name = 'cube';
    cube.material.transparent = true;

    //Adicionando o cubo à cena
    scene.add(cube);

    //Criando o plano geométrico
    var planeGeometry = new THREE.PlaneGeometry(20, 20);
    var planeMaterial = new THREE.MeshLambertMaterial({
        color: 0xcccccc
    });
    var plane = new THREE.Mesh(planeGeometry, planeMaterial);
    plane.receiveShadow = true;

    plane.rotation.x = -0.5 * Math.PI;

    plane.position.x = 0;
    plane.position.y = -2;
    plane.position.z = 0;

    //Adicionando o plano à cena
    scene.add(plane);

    //Criando a Luz da cena
    var spotLight = new THREE.SpotLight(0xffffff);
    spotLight.position.set(10, 20, 20);
    spotLight.shadow.camera.near = 20;
    spotLight.shadow.camera.far = 50;
    spotLight.castShadow = true;
    //Adicionando a luz à cena
    scene.add(spotLight);

    //Criando a GUI para os controles da cena
    control = new function() {
        this.rotationSpeed = 0.005;
        this.opacity = 0.6;
        this.color = cubeMaterial.color.getHex();
    };
    addControlGui(control);

    //Aplicando ao corpo do HTML
    document.body.appendChild(renderer.domElement);
    addStatsObject();
    render();

}

//Status de benchmark do JS
function addStatsObject() {
    stats = new Stats();
    stats.setMode(0);
    stats.domElement.style.position = 'absolute';
    stats.domElement.style.left = '0px';
    stats.domElement.style.top = '0px';
    document.body.appendChild(stats.domElement);
}


//Aqui é onde acontece a chamada para o renderizador
function render() {
    scene.getObjectByName('cube').material.opacity = control.opacity;
    scene.getObjectByName('cube').material.color = new THREE.Color(control.color);

    requestAnimationFrame(render);
    renderer.render(scene, camera);
    stats.update();
}

//Redimensionar a tela
function handleResize() {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
}


//Adicionando os controles da cena, propriamente dizendo
function addControlGui(controlObject) {
    var gui = new dat.GUI();
    gui.add(controlObject, 'rotationSpeed', -0.01, 0.01);
    gui.add(controlObject, 'opacity', 0.1, 1);
    gui.addColor(controlObject, 'color');
}


//Chamando a função para iniciar a cena
window.onload = init;
//Chama o redimensionador para a janela
window.addEventListener('resize', handleResize, false);