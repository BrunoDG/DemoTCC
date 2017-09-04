var rm;
function init() {
    var w = window.innerWidth;
    var h = window.innerHeight;

    rm = new RayMarcher().setSize(w,h).loadFragmentShader("data/glsl/scene.glsl", animate);
    document.body.appendChild(rm.domElement);
}

function animate() {
    requestAnimationFrame(animate);

    rm.distance = 50;
    rm.precision = 0.01;
    rm.update();

    rm.render();
}

function handleResize() {
    rm.camera.aspect = window.innerWidth / window.innerHeight;
    rm.camera.updateProjectionMatrix();
    rm.setSize(window.innerWidth, window.innerHeight);
}

window.addEventListener('resize', handleResize, false);

init();