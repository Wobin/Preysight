# Preysight

Night vision for characters with augmetic lenses. In a dark mission, if you qualify, the world
turns monochrome, brightens, and takes on a coloured cast, with an edge vignette and an optional
forward-facing light. It arms itself automatically and fades in, no manual toggle needed unless
you want to turn it off.


## Who qualifies

Checked in this order, first match wins:

1. Every Skitarii (archetype `cryptic`) qualifies unconditionally.
2. Anyone with a lens-coloured eye item equipped.
3. Anyone whose head cosmetic contains lens-like geometry. This is detected by walking the item's
   own attachment tree and looking for names like goggles, a visor, a rebreather, an optic or a
   monocle.
4. Anyone whose head item you have explicitly taught the mod, using the settings action described
   below.


## Colour

The tint's hue is resolved in this order, most specific first:

1. The character's own lens colour item, if equipped. This is real measured colour data read
   straight off the item.
2. Otherwise, a colour read off the worn head item, if it carries a recognised coloured emissive
   detail. The game stores these overrides as raw numeric colour values, but those numbers are not
   usable: measured across every such item in the game, more than half have RGB components outside
   the normal 0-1 range entirely, and even the ones that are in range do not match their own item
   names (the item named "yellow" is stored as white, the one named "orange" is stored as yellow).
   Using the numbers as-is would tint a red-lensed helmet blue. Instead the mod reads the colour
   word baked into the override item's own name (`emissive_red_01`, `emissive_blue_02`, and so on)
   and maps that word to a hand-picked hue. If a head item carries more than one recognised
   emissive override, the first one found wins, checking the head item itself before its
   attachments.
3. Otherwise, a fixed colour you set in the mod options.

Choosing "Fixed colour" as the hue source in the mod options skips straight to step 3.


## Turning it off

A keybind toggles the effect off and back on mid-mission (unbound by default, set it in the mod
options). There is also an "Always on" setting that bypasses the darkness check entirely, so the
effect runs in every mission regardless of lighting.


## Head-cosmetic detection is partial, not complete

Automatic detection for point 3 above works by pattern-matching the internal names inside a head
item's attachment tree. Measured against the full item list, this catches roughly one in five head
items. It is not a complete list of every lensed cosmetic in the game, and playing
more will not extend it; the coverage is fixed by what the underlying item names actually
describe.

Anything missed can be taught by hand: equip the head item, then open the mod options. The
Headgear section shows a checkbox labelled with the name of whatever head item you currently have
equipped; tick it to mark that item as lensed, untick it to remove it. The label updates to match
whatever you have on, and if nothing is equipped (or no character is loaded) it says so instead of
showing a stale name. "Forget taught headgear" clears everything you have taught, across every
head item, not just the one you are currently wearing.

Skitarii headgear specifically is missed by this detection entirely, since their item names carry
no descriptive token the pattern matcher can key on. This does not cost them the effect in
practice, because every Skitarii already qualifies unconditionally by archetype (point 1 above).


## Scanlines and grain

Two of the four overlay passes, scanlines and grain, ship on by default alongside the hue wash and
vignette. Both have been checked on screen in a real dark mission and tuned from there. Adjust
either in the mod options if you want more or less of them.

Both need SimpleAssets to draw at all. If SimpleAssets is not installed or is disabled, those two
passes simply never render, no error, nothing else affected. The hue wash, vignette, and the rest
of the effect work the same either way.


## Where the brightening actually comes from

Almost all of it comes from an exposure lift applied to the world itself, not from the coloured
wash on top. That matters because exposure is a plain multiply: it scales near and far surfaces by
the same amount, so it makes the scene brighter without making you able to see any further into
the dark. That is what the forward light is for.

The wash is an ordinary alpha-blended overlay rather than an additive one, so it cannot brighten
the picture either. It only tints what is already there.


## The forward light sits behind and above you, on purpose

If the forward light is enabled, it is mounted about 1.5 metres behind your head and 1.5 metres
above it, not in front of you. You never look directly into the light source, so it does not ruin 
your own dark adaptation, while it still spills forward into the scene ahead of you.


## Outlines and the HUD keep their own colours

The greyscale and tint only reach the world itself. Enemy outlines and every HUD element render in
their normal colours on top, untouched. If you rely on outline colour to tell enemy types apart,
that coding is not lost while Preysight is active.


## Compatibility

If Machine God's Beacon is installed and enabled, Preysight's own darkness detection switches
itself off (logged once on load) so the two mods are not fighting over what counts as dark. Turn
on "Always on" in Preysight's own settings if you still want it active.


## Credits

Wobin
