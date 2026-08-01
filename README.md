# MiniFramework

The shared config-UI framework behind the [Mini\* addons](https://github.com/Verubato). It provides
saved-variable handling, the Blizzard settings-panel plumbing, and a set of flat, crimson-accented
widgets — checkboxes, sliders, dropdowns, tabs, dialogs and a standalone window.

This is **not** a LibStub library. Every addon embeds its own private copy, because the framework
derives saved-variable names, slash commands and global frame names from the consuming addon's name.
There is no cross-addon version arbitration and there shouldn't be.

## Consuming it

Copy `src/MiniFramework` into your addon at `src/Libs/MiniFramework`, then add a single line to the
toc — before any file that uses it, and after your locale files if you have them:

```
Libs\MiniFramework\MiniFramework.xml
```

The XML pulls in every framework file in the correct order, so adding a widget to the framework
never means editing 20-odd tocs.

To re-sync every addon from this repo after making a change here:

```powershell
cd scripts
.\SyncFramework.ps1            # -WhatIf to preview, -Include/-Exclude to scope
```

It finds every sibling repo that already has `src\Libs\MiniFramework`, copies over any file whose
hash differs, and deletes files the framework no longer ships so a rename can't leave an orphan the
toc still loads. Use `-Include` to seed an addon for the first time.

## Using it

```lua
local _, addon = ...
local mini = addon.Framework

local db = mini:GetSavedVars(defaults)

local panel = CreateFrame("Frame")
panel.name = "MyAddon"

mini:Checkbox({
    Parent = panel,
    LabelText = "Enabled",
    GetValue = function() return db.Enabled end,
    SetValue = function(value) db.Enabled = value end,
})

local category = mini:AddCategory(panel)
mini:RegisterSlashCommand(category, panel, { "/myaddon" })
```

Widgets register themselves with their parent panel, so `panel:MiniRefresh()` re-reads every control
from its `GetValue`. Define `panel.OnMiniRefresh` for anything extra that needs to run afterwards.

## API

`addon.Framework` — the whole public surface.

### Framework

| Member | Purpose |
| --- | --- |
| `Version` | Version of the embedded snapshot |
| `VerticalSpacing`, `HorizontalSpacing`, `TextMaxWidth` | Layout constants; assignable |
| `ContentWidth` | Width layouts are measured against; set it when hosting your own window |
| `Notify(msg, ...)` | Prints a chat message prefixed with the addon name |
| `NotifyCombatLockdown()` | Prints the standard combat-lockdown message |
| `ClampInt(v, min, max, fallback)` / `ClampFloat(...)` | Numeric coercion and clamping |
| `CopyTable(src, dst)` | Deep merge-copy, filling only nil keys |
| `CopyValueOrTable(src)` | Deep clone for tables, passthrough otherwise |
| `Reverse(array)` / `Append(src, dst)` | In-place array helpers |
| `CleanTable(target, template, cleanValues, recurse)` | Strips keys the template doesn't have |
| `IsSecret(value)` / `HasSecrets()` | Secure "secret value" detection |
| `GetSavedVars(defaults)` / `GetCharacterSavedVars(defaults)` / `ResetSavedVars(defaults)` | Saved variables |
| `WaitForAddonLoad(callback)` | Runs once saved variables are available |
| `AddCategory(panel)` / `AddSubCategory(parent, panel)` | Interface > AddOns registration |
| `RegisterSlashCommand(category, panel, commands)` / `OpenSettings(category, panel)` | Slash commands |
| `SettingsSize()` / `ColumnWidth(columns, padding, spacingColumns)` | Layout measurement |
| `CanOpenOptionsDuringCombat()` | Whether the client still allows it |
| `SetCustomStyling(enabled)` | Opts into the accented restyle; call before building widgets |
| `SetPalette(colors)` | Rebrands the accent colors; call before building widgets |

### Widgets

| Member | Returns |
| --- | --- |
| `TextLine(options)` | FontString |
| `TextBlock(options)` | Frame of stacked lines |
| `TextBlockSegmented(options)` | Frame of lines mixing prefix/text/suffix fonts |
| `PanelHeader(options)` | `{ Title, Description, Anchor }` — title + version + blurb every panel opens with |
| `Divider(options)` | Labelled horizontal rule |
| `Button(options)` | Button |
| `EditBox(options)` | `{ EditBox, Label }` — supports `Numeric`, `MultiLine`, `Readonly` |
| `FlattenEditBox(box)` | Restyles an existing `InputBoxTemplate` box |
| `Dropdown(options)` | `control, isModern` — modern menu, LibUIDropDownMenu, or legacy fallback |
| `Slider(options)` | `{ Slider, EditBox, Label }` |
| `Checkbox(options)` | CheckButton |
| `ColorSwatch(options)` | Colour button opening the colour picker; `GetValue`/`SetValue` use r, g, b, a with alpha 1 = opaque |
| `List(options)` | `{ ScrollFrame, Content, Add, SetItems, GetItems }` |
| `CreateTabs(options)` | Tab controller with `Select`, `GetSelected`, `GetContent`, `GetTabButton` |
| `WireTabNavigation(controls)` | Tab/Shift+Tab focus cycling |
| `ShowDialog(options)` / `HideDialog()` | Shared notification dialog |
| `CreateStandaloneWindow(options)` | Draggable window with title bar, close button and content frame; `Resizable` adds edge and corner drag handles |

Every widget takes a single `options` table; see the `---@class` annotations at the bottom of each
file for the exact fields.

### Styling

Widgets draw stock Blizzard art by default, so an addon dropped into the Interface options panel
looks native. Opt into the accented restyle — crimson checkboxes, flat slider track, flattened edit
box fields, accent-outline buttons, gradient dividers — with a single call before building anything:

```lua
mini:SetCustomStyling(true)
```

Pass `CustomStyling` to an individual widget to override that either way. Chrome that has no
Blizzard equivalent — `CreateTabs`, `CreateStandaloneWindow`, `ShowDialog` — is always styled.

### Long dropdowns

Dropdowns spread themselves over multiple columns automatically rather than running off the bottom
of the screen — 2 columns above 10 items, 3 above 24, 4 above 36 — and scroll once even four columns
would exceed `MaxRows` (20) rows. Pass `Columns` to fix the count, or `Columns = 1` to opt out.

This needs the modern menu system (retail 11.0+, Cata/MoP Classic). The legacy `UIDropDownMenu` path
can only scroll, and an embedded LibUIDropDownMenu can do neither — long lists still overflow there.

## Localization

Framework strings are looked up through `addon.L` when the addon defines one, and fall back to the
English key otherwise. Resolution is deferred to access time, so load order doesn't matter. Nothing
has to be translated for the framework to work.

Where the client already has a localized global for a string the framework uses one (`CLOSE`,
`REMOVE`), so only these keys are worth adding to a locale table:

- `Can't do that during combat.`
- `Notification`
- `Information` — tooltip title fallback, only reached when a checkbox has a tooltip but no label

## Game flavors

Targets retail through Classic Era. Widgets are styled for retail and degrade on older clients:
`GUI/Compat.lua` shims `PixelUtil`, `BackdropTemplate`, `SetColorTexture`, `SetShown`,
`SetObeyStepOnDrag`, `SetPropagateKeyboardInput`, the checkbox label field, and gradients
(`SetGradient` with ColorMixins → `SetGradientAlpha` → a flat averaged fill).

Gradient support is detected by *calling* the modern form rather than probing for it, because 9.x
clients have both `CreateColor` and `SetGradient` while `SetGradient` still takes eight numbers there.

## Development

```powershell
cd build
.\install-luacheck.ps1     # once
.\lint.ps1
```
