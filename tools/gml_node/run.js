#!/usr/bin/env node
/*
 * Runs our pure-logic GML tests in Node.js in a few seconds, without GameMaker.
 *
 * Why this works: the GML we use for game rules and tests (functions, structs,
 * arrays, if/for/switch, try/catch) is written the same way in JavaScript.
 * This script:
 *   1. collects only these scripts (everything else needs the real engine):
 *        scr_test_framework, scr_tests_framework_selftest,
 *        scr_rules_*  (game rules)      scr_tests_rules_*  (their tests)
 *   2. refuses GML that would mean something different in JavaScript,
 *   3. turns each "#macro NAME value" line into a JavaScript constant,
 *   4. supplies stand-ins for the GameMaker built-ins those scripts call,
 *   5. starts the scripts as if the game was launched with --run-tests, so the
 *      framework writes test_results.json exactly as it does in the game.
 *
 * Pass or fail is then decided by tools/ci/check_test_results.py, the same
 * check the Windows job uses. This is a fast first check: the Windows job still
 * builds the real game and runs the same tests inside GameMaker.
 *
 * Usage:
 *   node tools/gml_node/run.js                     # finds <project>/scripts
 *   node tools/gml_node/run.js --scripts DIR --out test-output-node
 */
"use strict";

const fs = require("fs");
const path = require("path");
const vm = require("vm");

const SCRIPT_PATTERN = /^(scr_test_framework|scr_tests_framework_selftest|scr_rules_\w+|scr_tests_rules_\w+)$/;

// ---------------------------------------------------------------------------
// Command line
// ---------------------------------------------------------------------------

function parseArgs(argv) {
    const args = { scripts: null, out: "test-output-node" };
    for (let i = 0; i < argv.length; i++) {
        if (argv[i] === "--scripts") args.scripts = argv[++i];
        else if (argv[i] === "--out") args.out = argv[++i];
        else throw new Error(`Unknown argument: ${argv[i]}`);
    }
    return args;
}

function findScriptsDir(start) {
    const skip = new Set([".git", ".github", "tools", "node_modules", "extensions", "prefabs"]);
    const found = [];
    (function walk(dir) {
        for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
            if (entry.isDirectory()) {
                if (!skip.has(entry.name)) walk(path.join(dir, entry.name));
            } else if (entry.name.endsWith(".yyp")) {
                found.push(path.join(dir, "scripts"));
            }
        }
    })(start);
    if (found.length !== 1) throw new Error(`Expected one .yyp file, found ${found.length}. Pass --scripts.`);
    return found[0];
}

/** Every .gml file whose script name matches SCRIPT_PATTERN, framework first. */
function collectScripts(dir) {
    const files = [];
    (function walk(d) {
        for (const entry of fs.readdirSync(d, { withFileTypes: true })) {
            const full = path.join(d, entry.name);
            if (entry.isDirectory()) walk(full);
            else if (entry.name.endsWith(".gml") && SCRIPT_PATTERN.test(path.basename(entry.name, ".gml"))) files.push(full);
        }
    })(dir);
    const rank = (f) => (path.basename(f).startsWith("scr_test_framework") ? 0 : 1);
    return files.sort((a, b) => rank(a) - rank(b) || a.localeCompare(b));
}

// ---------------------------------------------------------------------------
// Checking and converting GML
// ---------------------------------------------------------------------------

/** Blank out comments and strings so the checks below only see code. */
function codeOnly(text) {
    let out = "";
    for (let i = 0; i < text.length; i++) {
        const c = text[i], n = text[i + 1];
        if (c === "/" && n === "/") { while (i < text.length && text[i] !== "\n") { out += " "; i++; } out += "\n"; }
        else if (c === "/" && n === "*") { i += 2; out += "  "; while (i < text.length && !(text[i] === "*" && text[i + 1] === "/")) { out += text[i] === "\n" ? "\n" : " "; i++; } i++; out += "  "; }
        else if (c === '"') { out += " "; i++; while (i < text.length && text[i] !== '"') { if (text[i] === "\\") { out += " "; i++; } out += " "; i++; } out += " "; }
        else out += c;
    }
    return out;
}

// Code that is valid in both languages but means something different, or
// JavaScript-only code that GameMaker would reject. Either way, refuse it.
const FORBIDDEN = [
    [/=>/, "arrow functions are JavaScript-only"],
    [/===|!==/, "=== and !== are JavaScript-only"],
    [/\b(let|const|class|new|of|instanceof|await|async|yield|this|delete|in)\b/, "JavaScript keyword"],
    [/\.(length|push|pop|map|filter|forEach|indexOf|includes|slice|splice|join|split|keys|toString)\b/, "JavaScript method or property; use the GML function instead"],
    [/`/, "template strings are not GML"],
    [/\b(with|repeat|exit|self|other)\b/, "engine-dependent GML that this harness cannot run"],
];

function checkGml(file, text) {
    const problems = [];
    codeOnly(text).split("\n").forEach((line, i) => {
        for (const [pattern, reason] of FORBIDDEN) {
            const m = line.match(pattern);
            if (m) problems.push(`${file}:${i + 1}: "${m[0]}" ${reason}`);
        }
    });
    return problems;
}

/** Macros become constants; #region lines are dropped. Line numbers are kept. */
function convert(text, macros) {
    return text.split("\n").map((line) => {
        const m = line.match(/^\s*#macro\s+(\w+)\s+(.*)$/);
        if (m) { macros.push(`const ${m[1]} = ${m[2].trim()};`); return ""; }
        if (/^\s*#(end)?region\b/.test(line)) return "";
        return line;
    }).join("\n");
}

// ---------------------------------------------------------------------------
// Stand-ins for GameMaker built-in functions
// ---------------------------------------------------------------------------

function makeBuiltins(outDir, state) {
    const own = (o, k) => o !== null && typeof o === "object" && Object.prototype.hasOwnProperty.call(o, k);
    // GameMaker stops with an error when a built-in gets the wrong type, where
    // JavaScript would quietly return NaN or undefined. These wrappers do the
    // same, so a test that would crash in the game also crashes here.
    const isStruct = (v) => v !== null && typeof v === "object" && !Array.isArray(v);
    const needStruct = (name, v) => { if (!isStruct(v)) throw new TypeError(`${name}: struct expected, got ${str(v)}`); };
    const needArray = (name, v) => { if (!Array.isArray(v)) throw new TypeError(`${name}: array expected, got ${str(v)}`); };
    const numeric = (name, fn) => (...a) => {
        for (const v of a) if (typeof v !== "number" && typeof v !== "boolean") throw new TypeError(`${name}: number expected, got ${str(v)}`);
        return fn(...a.map(Number));
    };
    let seed = 1;
    const rand = () => { // mulberry32: small, seeded, repeatable
        seed |= 0; seed = (seed + 0x6d2b79f5) | 0;
        let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
        t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
    const str = (v) => {
        if (typeof v === "string") return v;
        if (typeof v === "number") {
            if (Number.isNaN(v)) return "NaN";
            if (!Number.isFinite(v)) return v > 0 ? "inf" : "-inf";
            return Number.isInteger(v) ? String(v) : v.toFixed(2);
        }
        if (typeof v === "boolean") return v ? "true" : "false";
        if (v === undefined) return "undefined";
        if (Array.isArray(v)) return "[ " + v.map(str).join(",") + " ]";
        if (typeof v === "function") return "function";
        try { return JSON.stringify(v); } catch (e) { return "{ struct }"; }
    };
    return {
        infinity: Infinity, pi: Math.PI,
        // types
        is_numeric: (v) => typeof v === "number" || typeof v === "boolean",
        is_bool: (v) => typeof v === "boolean",
        is_string: (v) => typeof v === "string",
        is_undefined: (v) => v === undefined,
        is_array: (v) => Array.isArray(v),
        is_struct: (v) => v !== null && typeof v === "object" && !Array.isArray(v),
        is_method: (v) => typeof v === "function",
        is_callable: (v) => typeof v === "function",
        is_nan: (v) => typeof v === "number" && Number.isNaN(v),
        is_infinity: (v) => typeof v === "number" && !Number.isFinite(v) && !Number.isNaN(v),
        // maths
        abs: numeric("abs", Math.abs), sqrt: numeric("sqrt", Math.sqrt), floor: numeric("floor", Math.floor),
        ceil: numeric("ceil", Math.ceil), sign: numeric("sign", Math.sign), power: numeric("power", Math.pow),
        min: numeric("min", Math.min), max: numeric("max", Math.max),
        clamp: numeric("clamp", (v, lo, hi) => Math.min(Math.max(v, lo), hi)),
        point_distance: numeric("point_distance", (x1, y1, x2, y2) => Math.hypot(x2 - x1, y2 - y1)),
        // randomness
        random_set_seed: (s) => { seed = s | 0; },
        random: (n) => rand() * n,
        irandom: (n) => Math.floor(rand() * (Math.floor(n) + 1)),
        irandom_range: (a, b) => { const lo = Math.ceil(Math.min(a, b)), hi = Math.floor(Math.max(a, b)); return lo + Math.floor(rand() * (hi - lo + 1)); },
        // arrays and structs
        array_length: (a) => { needArray("array_length", a); return a.length; },
        array_push: (a, ...v) => { needArray("array_push", a); a.push(...v); },
        array_create: (n, v = 0) => new Array(n).fill(v),
        variable_struct_exists: (s, k) => { needStruct("variable_struct_exists", s); return own(s, k); },
        variable_struct_get: (s, k) => { needStruct("variable_struct_get", s); return own(s, k) ? s[k] : undefined; },
        variable_struct_set: (s, k, v) => { needStruct("variable_struct_set", s); s[k] = v; },
        variable_global_exists: (k) => own(state.context, k),
        // strings
        string: str,
        string_length: (s) => s.length,
        string_upper: (s) => s.toUpperCase(),
        string_lower: (s) => s.toLowerCase(),
        string_char_at: (s, i) => (i >= 1 && i <= s.length ? s[i - 1] : ""),
        string_delete: (s, i, n) => s.slice(0, Math.max(0, i - 1)) + s.slice(Math.max(0, i - 1) + n),
        string_insert: (sub, s, i) => s.slice(0, Math.max(0, i - 1)) + sub + s.slice(Math.max(0, i - 1)),
        json_parse: (s) => JSON.parse(s),
        json_stringify: (v) => JSON.stringify(v),
        // game and files
        show_debug_message: (m) => console.log(str(m)),
        parameter_count: () => 1,
        parameter_string: (i) => (i === 1 ? "--run-tests" : ""),
        game_save_id: outDir + path.sep,
        game_end: () => { state.ended = true; },
        file_exists: () => false,
        file_text_open_write: (name) => ({ file: path.join(outDir, name), text: "" }),
        file_text_write_string: (h, s) => { h.text += s; },
        file_text_close: (h) => { fs.writeFileSync(h.file, h.text); },
        exception_unhandled_handler: (fn) => { state.handler = fn; },
        time_source_global: "global", time_source_units_frames: "frames", time_source_units_seconds: "seconds",
        time_source_create: (parent, period, units, cb) => { state.sources.push({ cb, started: false }); return state.sources.length - 1; },
        time_source_start: (id) => { state.sources[id].started = true; },
    };
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

/** A script's text with any BOM removed and Windows (CRLF) line endings made LF. */
function readGml(file) {
    return fs.readFileSync(file, "utf8").replace(/^﻿/, "").replace(/\r\n?/g, "\n");
}

function main() {
    const args = parseArgs(process.argv.slice(2));
    const scriptsDir = args.scripts || findScriptsDir(process.cwd());
    const files = collectScripts(scriptsDir);
    if (!files.some((f) => path.basename(f) === "scr_test_framework.gml")) {
        console.error(`scr_test_framework.gml not found under ${scriptsDir}`);
        return 2;
    }

    const problems = files.flatMap((f) => checkGml(f, readGml(f)));
    if (problems.length) {
        console.error("This GML cannot run in the Node harness:\n" + problems.join("\n"));
        return 2;
    }

    fs.mkdirSync(args.out, { recursive: true });
    const outDir = path.resolve(args.out);
    fs.rmSync(path.join(outDir, "test_results.json"), { force: true });

    const state = { sources: [], handler: null, ended: false, context: null };
    const context = vm.createContext(makeBuiltins(outDir, state));
    context.global = context;
    state.context = context;

    const macros = [];
    const bodies = files.map((f) => ({ f, code: convert(readGml(f), macros) }));
    console.log(`Loading ${files.length} scripts: ${files.map((f) => path.basename(f, ".gml")).join(", ")}`);
    try {
        vm.runInContext(macros.join("\n"), context, { filename: "macros" });
        // Function declarations become globals, as script functions do in GameMaker.
        for (const { f, code } of bodies) vm.runInContext(code, context, { filename: f });
    } catch (e) {
        console.error(`Could not load the scripts: ${e.stack || e}`);
        return 2;
    }

    for (const source of state.sources.filter((s) => s.started)) {
        try {
            source.cb();
        } catch (e) {
            if (!state.handler) throw e;
            state.handler({ message: String(e && e.message || e), longMessage: String(e && e.stack || e) });
            state.ended = true;
        }
    }
    if (!state.ended) {
        console.error("The test runner never ended the game; was --run-tests handled?");
        return 1;
    }
    console.log(`Results written to ${path.join(outDir, "test_results.json")}`);
    return 0;
}

process.exitCode = main();
