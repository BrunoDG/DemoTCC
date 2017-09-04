var scene, renderer, camera;

function init() {
    var w, h;

    w = window.innerWidth;
    h = window.innerHeight;

    scene = new THREE.Scene();

    renderer = new THREE.WebGLRenderer();
    renderer.setClearColor(0x000000, 1.0);
    renderer.setSize(w,h);

    camera = new THREE.PerspectiveCamera( 45, w/h, 0.1, 1000 );
    camera.position.x = 15;
    camera.position.y = 16;
    camera.position.z = 13;
    camera.lookAt(scene.position);

    document.body.appendChild(renderer.domElement);
    render();

}

function render() {
    renderer.render(scene, camera);
    requestAnimationFrame(render);
}

init();