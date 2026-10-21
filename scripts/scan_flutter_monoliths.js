import fs from "fs";
import path from "path";

const libDir = path.resolve(process.cwd(), "lib");

function scanDirectory(dir) {
    let files = [];
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            if (entry.name !== ".dart_tool" && entry.name !== "build") {
                files = files.concat(scanDirectory(fullPath));
            }
        } else if (entry.name.endsWith(".dart") && !entry.name.endsWith(".g.dart")) {
            files.push(fullPath);
        }
    }
    return files;
}

const dartFiles = scanDirectory(libDir);

const fileStats = [];
let totalLines = 0;

for (const file of dartFiles) {
    const content = fs.readFileSync(file, "utf-8");
    const lines = content.split("\n");
    const lineCount = lines.length;
    totalLines += lineCount;

    const relPath = path.relative(process.cwd(), file).replace(/\\/g, "/");

    const isWidget = /class\s+\w+\s+extends\s+(StatelessWidget|StatefulWidget|State<\w+>)/.test(content);
    const isBloc = /class\s+\w+\s+extends\s+(Bloc<\w+,\s*\w+>|Cubit<\w+>)/.test(content);
    const isRepository = /class\s+\w*Repository\w*/.test(content);
    const isService = /class\s+\w*Service\w*/.test(content);
    const isModel = /class\s+\w*(Model|Entity|Dto|Response)\w*/.test(content);

    // Direct database access checks
    const hasIsar = /\bisar\./.test(content) || /import\s+['"].*isar.*['"]/.test(content);
    const hasSupabase = /\bsupabase\./i.test(content) || /Supabase\.instance/.test(content) || /import\s+['"].*supabase.*['"]/.test(content);
    // Direct network / Dio checks
    const hasDio = /\bdio\./i.test(content) || /import\s+['"].*dio.*['"]/.test(content);

    fileStats.push({
        path: relPath,
        lineCount,
        isWidget,
        isBloc,
        isRepository,
        isService,
        isModel,
        hasIsar,
        hasSupabase,
        hasDio,
    });
}

fileStats.sort((a, b) => b.lineCount - a.lineCount);

const tier10k = fileStats.filter(f => f.lineCount >= 10000);
const tier5k = fileStats.filter(f => f.lineCount >= 5000 && f.lineCount < 10000);
const tier2k = fileStats.filter(f => f.lineCount >= 2000 && f.lineCount < 5000);
const tier1k = fileStats.filter(f => f.lineCount >= 1000 && f.lineCount < 2000);
const tier500 = fileStats.filter(f => f.lineCount >= 500 && f.lineCount < 1000);
const tierUnder500 = fileStats.filter(f => f.lineCount < 500);

const results = {
    totalFiles: fileStats.length,
    totalLines,
    tiers: {
        tier10k: { count: tier10k.length, files: tier10k },
        tier5k: { count: tier5k.length, files: tier5k },
        tier2k: { count: tier2k.length, files: tier2k },
        tier1k: { count: tier1k.length, files: tier1k },
        tier500: { count: tier500.length, files: tier500 },
        tierUnder500: { count: tierUnder500.length }
    },
    topMonoliths: fileStats.slice(0, 30),
    directDbWidgets: fileStats.filter(f => f.isWidget && (f.hasIsar || f.hasSupabase)),
    directApiWidgets: fileStats.filter(f => f.isWidget && f.hasDio),
};

fs.writeFileSync("scripts/flutter_scan_results.json", JSON.stringify(results, null, 2));
console.log(`Scanned ${dartFiles.length} files (${totalLines} total lines).`);
console.log(`>= 10,000 lines: ${tier10k.length}`);
console.log(`5,000 - 9,999 lines: ${tier5k.length}`);
console.log(`2,000 - 4,999 lines: ${tier2k.length}`);
console.log(`1,000 - 1,999 lines: ${tier1k.length}`);
console.log(`500 - 999 lines: ${tier500.length}`);
console.log(`< 500 lines: ${tierUnder500.length}`);
console.log(`Widgets with direct DB (Isar/Supabase): ${results.directDbWidgets.length}`);
console.log(`Widgets with direct Dio: ${results.directApiWidgets.length}`);
console.log("\nTop 10 Monoliths:");
fileStats.slice(0, 10).forEach((f, i) => {
    console.log(`${i + 1}. [${f.lineCount} lines] ${f.path}`);
});
