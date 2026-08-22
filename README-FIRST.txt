Gesture Presentation — developer entry point
============================================

1. Read AGENTS.md and APP_SPEC.md.
2. Edit src/index.template.html, app.config.json, or dependencies.json; never edit generated dist HTML manually.
3. Run build-standalone.bat on Windows.
4. Review dist/build-size-report.json and dist/dependency-manifest.json.
5. Test dist/index.html and dist/index.self-extract.html with the network disabled.
6. For camera testing, GitHub Pages/HTTPS is recommended. start-local.bat provides a localhost server for local development.
