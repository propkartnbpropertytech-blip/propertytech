import fs from "fs";

const path = "c:/NB/propkart/.dart_tool/package_config.json";

function run() {
    if (!fs.existsSync(path)) {
        console.error("package_config.json does not exist!");
        return;
    }

    const config = JSON.parse(fs.readFileSync(path, "utf8"));
    const pkg = config.packages.find(p => p.name === "propkart");
    if (pkg) {
        console.log("Found propkart in package_config.json:", pkg);
    } else {
        console.log("propkart is NOT in package_config.json!");
        console.log("First 5 packages:", config.packages.slice(0, 5).map(p => p.name));
    }
}

run();
