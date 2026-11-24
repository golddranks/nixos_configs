# Learnings

## macOS input sources

- A keyboard layout bundle can set a custom input source ID
  (a `TISInputSourceID` key in the `KLInfo_…` dict of its `Info.plist`).
  macOS reports that ID only while the layout is enabled;
  while disabled, it reports `<CFBundleIdentifier>.keylayout.<layout name without spaces>`.
  Without the key, the derived ID is used in both states, so lookups by ID always work.
- 英数 goes to the last-selected keyboard layout in script group 0 (Roman).
  A layout in group 126 (Unicode, the default in layout editors)
  loses to any enabled Apple layout, even when it was selected more recently.
  The group is the `group` attribute of `<keyboard>` in the `.keylayout`.
- A newly installed layout bundle can't be enabled until the next login;
  `TISEnableInputSource` returns success but changes nothing.
- The Japanese IME's settings only offer Apple's layouts for romaji typing.
  A custom one can still be set with the
  `com.apple.inputmethod.Kotoeri` `JIMPrefRomajiKeyboardLayoutKey` default.
