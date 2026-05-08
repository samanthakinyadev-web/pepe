{{flutter_js}}
{{flutter_build_config}}

const loading = document.createElement('div');
loading.setAttribute('aria-live', 'polite');
loading.style.cssText = `
  position: fixed;
  inset: 0;
  display: grid;
  place-items: center;
  background:
    radial-gradient(circle at top, rgba(111, 188, 138, 0.18), transparent 42%),
    linear-gradient(180deg, #ffffff 0%, #f4f8f5 100%);
  color: #14331f;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  z-index: 9999;
`;
loading.innerHTML = `
  <div style="
    width: min(420px, calc(100vw - 48px));
    padding: 28px;
    border-radius: 28px;
    background: rgba(255, 255, 255, 0.96);
    border: 1px solid rgba(47, 133, 90, 0.12);
    box-shadow: 0 24px 60px rgba(20, 51, 31, 0.12);
    text-align: center;
  ">
    <div style="
      width: 68px;
      height: 68px;
      margin: 0 auto 18px;
      border-radius: 22px;
      background: linear-gradient(180deg, #6fbc8a, #2f855a);
      box-shadow: 0 18px 28px rgba(47, 133, 90, 0.24);
    "></div>
    <div style="font-size: 30px; font-weight: 800; margin-bottom: 10px;">Elimu Pepe</div>
    <div style="font-size: 16px; line-height: 1.6; color: #5a6b5f;">Loading your learning shell and cached sections...</div>
  </div>
`;
document.body.appendChild(loading);

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    loading.remove();
  }
});
