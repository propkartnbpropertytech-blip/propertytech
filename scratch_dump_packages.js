import fs from "fs";

const path = "c:/NB/propkart/.dart_tool/package_config.json";

function run() {
    const config = JSON.parse(fs.readFileSync(path, "utf8"));
    const localPkgs = config.packages.filter(p => p.rootUri.includes("..") || p.rootUri === "../" || p.rootUri === "");
    console.log("Local packages in config:", localPkgs);
}

run();
