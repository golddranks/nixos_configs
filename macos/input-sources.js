// Run by the input-sources login agent (configuration.nix) with `osascript -l JavaScript`.
// Makes the enabled keyboard layouts and input modes exactly the given list,
// and selects one of them.
// Usage: osascript -l JavaScript input-sources.js '{"enabled": [id, ...], "selected": id}'
ObjC.import("Carbon");

function prop(s, key) {
  const r = $.TISGetInputSourceProperty(s, key);
  return r ? ObjC.castRefToObject(r).js : null;
}

function list(includeAllInstalled) {
  const a = ObjC.castRefToObject($.TISCreateInputSourceList($(), includeAllInstalled));
  const out = [];
  for (let i = 0; i < a.count; i++) out.push(a.objectAtIndex(i));
  return out;
}

function check(what, status) {
  if (status !== 0) throw new Error(what + " failed: " + status);
}

// What the list manages. Input method parents (e.g. Kotoeri.RomajiTyping)
// follow their modes, and palettes (emoji viewer, press-and-hold) are left alone.
const managed = [
  "TISTypeKeyboardLayout",
  "TISTypeKeyboardInputMode",
  "TISTypeKeyboardInputMethodWithoutModes",
];

const id = s => prop(s, $.kTISPropertyInputSourceID);

function run(argv) {
  const want = JSON.parse(argv[0]);
  if (!want.enabled.includes(want.selected)) {
    throw new Error(want.selected + " is selected but not in enabled");
  }
  const installed = list(true);
  const find = wanted => {
    const s = installed.find(s => id(s) === wanted);
    if (!s) throw new Error(wanted + " is not installed");
    return s;
  };

  // All looked up first, so a missing source leaves things as they are.
  const enabled = want.enabled.map(find);
  const selected = find(want.selected);

  for (const s of enabled) {
    check("enable " + id(s), $.TISEnableInputSource(s));
  }
  check("select " + id(selected), $.TISSelectInputSource(selected));
  for (const s of list(false)) {
    if (!managed.includes(prop(s, $.kTISPropertyInputSourceType))) continue;
    if (want.enabled.includes(id(s))) continue;
    check("disable " + id(s), $.TISDisableInputSource(s));
  }
  return "done";
}
