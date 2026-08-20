# Changelog

## Unreleased

### Added

- `M:Dropdown` takes an optional `Tooltip` string, and a `TooltipTitle` for a caller that draws
  its own label, shown on hover the way `M:Checkbox` and `M:Slider` do. Modern menus only; the
  legacy frames never see the hover.
- `M:Dropdown` takes an optional `DecorateItem(button, value)` hook, run as the open menu builds
  each row, for per-row looks the menu system cannot express such as a font list previewing
  itself. Modern menus only.
- Horizontal tab strips read as controls rather than bare labels: a faint plate under every
  tab, an accent wash rising from the underline on the selected one, and a stronger baseline.
- `M:Slider` takes an optional `Tooltip` string and shows it on hover, matching `M:Checkbox`:
  the label as a gold title, the tooltip text wrapped below it. The scripts are hooked rather
  than set, so the styled thumb keeps its own hover colouring.
- `M:NotifyWithPrefix(msg, ...)` prints with the addon name coloured via the new
  `M.NotifyColor` (RRGGBB, default gold `ffd100`); an addon can override the colour before
  its first notify. BREAKING: `M:Notify` no longer prefixes at all - it is now a plain print for
  messages that carry their own context, so call sites that want the classic prefixed form
  must move to `NotifyWithPrefix` (`M:NotifyCombatLockdown` already has).
- The fixed page header draws its tab icon at 26px instead of 20px, so the title art reads
  at a glance.
- `CreateTabs` honours a `TabIconSize` option for the vertical nav icons (default 20). The
  option existed in call sites but was never read; the icon size was hardcoded.
- A panel's `MiniRefresh` cascades into registered panels nested below it (sub-tab contents,
  section frames), recursing through plain wrapper frames. Without this, a profile reset only
  refreshed a tabbed page's directly-registered controls and left the sub-tab controls showing
  stale values.

- The styled slider and dropdown now share the toggle's chrome. The slider's thumb is the same
  circle knob with the same hover brightening, its value box is a pill chip, and disabling it
  dims and greys the fill like a disabled toggle. The retail dropdown's closed face becomes a
  soft-cornered dark field with a 1px border, white text, a chevron arrow and the shared hover
  tint; the open menu and the classic-era dropdown paths stay stock. Built on new shared
  helpers in `Common.lua` (`GUI.PillField`/`RoundedField` three-slice chrome,
  `GUI.CropIcon`/`CropPill`, the `GUI.Field*`/`Knob*`/`Line*` chrome colors) and new
  `Chevron.tga`/`RoundedField.tga`/`RoundedBorder.tga` textures.
- `M:Checkbox` renders a pill-shaped sliding toggle switch under the accented restyle: rounded
  track, crimson fill when on, animated circular knob, hover brightening, click sounds and a
  click-through label. Disabling one dims it and swaps the fill to grey, so an on-but-locked
  switch reads as locked. Unstyled addons keep the stock Blizzard checkbox, and the widget
  still answers `SetChecked`/`GetChecked` either way, so call sites and layout code carry over
  untouched. The shapes ship as two white TGAs in `Media/` (regenerate with
  `scripts/GenerateToggleTextures.py`), tinted via the new `GUI.TintGradientH`, which colors a
  texture's existing image where `SetGradientH` would flood it solid.
- `M:MakeMovable(frame, position, options)` plus `ApplyPosition` / `SavePosition` /
  `SetPositionLocked`, consolidating the drag-and-persist code nine addons each had their own
  copy of. Fixes a bug in several of them: the frame object was written into saved variables
  instead of its name, then read back with `_G[frame]`, so a custom anchor never survived a
  reload. Also applies `SetDontSavePosition` consistently.
- `M:RunWhenCombatEnds(callback, key)` — deferring protected work beats the usual notify-and-
  give-up, which leaves it permanently undone.
- `M:ColorSwatch(options)` with a `ColorPickerFrame` wrapper covering both the modern and
  pre-Dragonflight APIs. `GetValue`/`SetValue` deal in alpha where 1 is opaque; the picker's
  own inconsistency about that is handled inside the widget.
- `M:PanelHeader(options)` and `M:AddonVersion()` for the title-plus-blurb every config panel
  opens with. Supports left- or centre-aligned headers.

- `CreateStandaloneWindow` gained an opt-in `Resizable` mode: a right edge handle for width, a
  bottom edge handle for height, and a bottom-right corner grip for both. Bounds come from
  `MinWidth`/`MinHeight` (defaulting to the starting size) and `MaxWidth`/`MaxHeight` (defaulting
  to the screen), with `OnResize` and `OnResizeStop` callbacks.

### Changed

- `M:IsSecret` binds its implementation once at load rather than testing for `issecretvalue` on
  every call. It sits on hot paths in several addons.

## 1.0.0

Initial extraction from MiniCC, consolidating the 22 drifted copies of `MiniFramework.lua`.

### Added

- `MiniFramework.xml` single-entry load file, so adding a framework file doesn't mean editing 23 tocs.
- `GUI/Compat.lua` cross-flavor shims: `PixelUtil`, `BackdropTemplate`, `SetColorTexture`,
  `SetShown`, `SetObeyStepOnDrag`, `SetPropagateKeyboardInput`, the checkbox label field, and a
  three-tier gradient fallback.
- Widgets draw stock Blizzard art by default. The crimson-and-flat restyle is opt-in via
  `M:SetCustomStyling(true)` — only MiniCC calls it, because it runs its own window rather than
  living in the Blizzard options panel. A `CustomStyling` option on `Button`, `Checkbox`, `Slider`,
  `EditBox`, `Divider` and `List` overrides that per widget, in either direction. Chrome with no
  Blizzard equivalent — `CreateTabs`, `CreateStandaloneWindow`, `ShowDialog` — is always styled.
- `M:SetPalette(colors)` for rebranding the accent colors.
- Dropdowns lay long item lists out in multiple columns instead of running off the bottom of the
  screen, and scroll once even four columns would be too tall — `Columns` and `MaxRows` options.
  Needs the modern menu system; the legacy path falls back to scrolling only.
- `EditBox` gained `MultiLine`, `Readonly` and `TextInsets` (from MiniCompactRunes / MiniNameplatePower).
- `Dropdown` gained `LabelText` and `Width` (from MiniResourceDisplay), and exposes the label as
  `control.Label`.
- `TextLine`, `TextBlock` and `TextBlockSegmented` gained an explicit `Width`.
- `IsSecret` / `HasSecrets` promoted from the addons that had them.

### Fixed

- Dropdown's legacy `UIDropDownMenu` path called three undefined globals (`name`, `setSelected`,
  `getValue`) and created an unnamed frame the template can't drive. This is the branch that runs on
  Classic, so the fallback was dead on arrival everywhere it was needed.
- Dropdown frame names are addon-scoped, fixing colliding `MiniArenaDebuffsDropdown<n>` globals when
  two Mini addons were loaded together.
- Dropdown `Width` is applied with the setter each flavor actually responds to; `Frame:SetWidth`
  does not resize `UIDropDownMenuTemplate` or LibUIDropDownMenu.
- `ClampInt` / `ClampFloat` now clamp in every addon (MiniCombatNotifier shipped no-op stubs).
- `OpenSettings` no longer calls an undefined global `mini` on combat lockdown (MiniQueueTimer,
  MiniRoleIcons, MiniTrinketGlow).
- Framework strings no longer index a nil `addon.L` in addons without locale files (MiniMarkers).
- `List`'s "Remove" and `Checkbox`'s tooltip fallback title are localizable.
