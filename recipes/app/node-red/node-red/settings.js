const fs = require("fs");

const readPrivateValue = (name) =>
    fs.readFileSync(`/data/${name}`, "utf8").trim();

module.exports = {
    // DropLive reaches the service through the container address. Node-RED's
    // loopback default is not externally reachable from the launch probe.
    uiHost: "0.0.0.0",
    uiPort: 1880,
    flowFile: "flows.json",
    flowFilePretty: true,
    credentialSecret: readPrivateValue(".droplive-credential-secret"),
    adminAuth: {
        type: "credentials",
        sessionExpiryTime: 86400,
        users: [{
            username: "admin",
            password: readPrivateValue(".droplive-admin-password-hash"),
            permissions: "*"
        }]
    },
    // Keep readiness independent of mutable user flows. This route is served
    // only after Node-RED has loaded its settings and started the HTTP server.
    httpAdminMiddleware: (request, response, next) => {
        if (request.path === "/healthz") {
            response.status(200).json({
                status: "ok",
                app: "node-red",
                runtime: "ready"
            });
            return;
        }
        next();
    },
    editorTheme: {
        projects: { enabled: false }
    },
    logging: {
        console: {
            level: "info",
            metrics: false,
            audit: false
        }
    }
};
