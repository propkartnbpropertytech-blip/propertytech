import fs from "fs";

const filePath = "lib/core/storage/isar_collections.g.dart";

function run() {
    if (!fs.existsSync(filePath)) {
        console.warn("⚠️ Could not find isar_collections.g.dart. Run build_runner first.");
        return;
    }

    console.log("🔧 Mapping JS integer literals to variables in isar_collections.g.dart...");
    let content = fs.readFileSync(filePath, "utf8");

    const replacements = [
        ["1318305215323522509", "hash_1318305215323522509"],
        ["1318305215323522560", "hash_1318305215323522509"],
        ["3268401673993471357", "hash_3268401673993471357"],
        ["3268401673993471488", "hash_3268401673993471357"],
        ["8271700807818507403", "hash_8271700807818507403"],
        ["8271700807818507264", "hash_8271700807818507403"],
        ["7980756281068083239", "hash_7980756281068083239"],
        ["7980756281068083200", "hash_7980756281068083239"],
        ["4721984852078906678", "hash_4721984852078906678"],
        ["4721984852078906368", "hash_4721984852078906678"],
        ["435823299237027808", "hash_435823299237027808"],
        ["435823299237027840", "hash_435823299237027808"],
        ["886259216879823833", "hash_886259216879823833"],
        ["886259216879823872", "hash_886259216879823833"],
        ["4502856345066684593", "hash_4502856345066684593"],
        ["4502856345066684416", "hash_4502856345066684593"],
        ["8922081633273292290", "hash_8922081633273292290"],
        ["8922081633273292800", "hash_8922081633273292290"],
        ["7985840613772203549", "hash_7985840613772203549"],
        ["7985840613772204032", "hash_7985840613772203549"],
        ["5416242803166401319", "hash_5416242803166401319"],
        ["5416242803166401536", "hash_5416242803166401319"]
    ];

    for (const [target, replacement] of replacements) {
        // Use negative lookbehind to ensure we don't match if already prefixed with 'hash_'
        const regex = new RegExp(`(?<!hash_)${target}`, "g");
        content = content.replace(regex, replacement);
    }

    fs.writeFileSync(filePath, content, "utf8");
    console.log("✅ Successfully mapped JS/Mobile platform constant hashes (idempotent)!");
}

run();
