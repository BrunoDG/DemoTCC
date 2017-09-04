var renderer, scene, camera;

function init() {
    scene = new THREE.Scene();

    renderer = new THREE.WebGLRenderer();
    renderer.setClearColor(0x000000, 1.0);
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.shadowMapEnabled = true;

    camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);
    camera.position.x = 15;
    camera.position.y = 16;
    camera.position.z = 13;
    camera.lookAt(scene.position);

    var loader = new THREE.JSONLoader();

    var createMesh = function(geometry, materials) {
        var zmesh = new THREE.Mesh(geometry, new THREE.MeshFaceMaterial(materials) );
        zmesh.position.set(0,0,0);
        zmesh.scale.set(3,3,3);
        zmesh.overdraw = true;
        scene.add(zmesh);
    };

    loader.load("data/obj/Ship/Windscale-V2.js", createMesh);

    document.body.appendChild(renderer.domElement);
    render();
}

function render() {
    renderer.render(scene, camera);
    requestAnimationFrame(render);

}

window.onload = init;