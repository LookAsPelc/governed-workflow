# Jax Codex Pet Design

## Purpose

Create a Codex V2 pet named **Jax** for the Iron Box plugin. The pet extends the
existing app icon's story: the icon shows the black iron box holding the moon,
while Jax is the mischievous thief responsible for it.

## Character

Jax is a compact young humanoid with dark, slightly unruly hair and an elegant,
quick, falsely innocent expression. He must remain an original depiction of
Jax's moon-thief motif rather than a literal copy of Bast. Do not give him
animal features, pointed ears, horns, or cloven hooves.

The black iron box is his permanent signature prop and remains physically
attached to his silhouette. Its dark metal, pale moonlight, rounded forms, and
charcoal-and-ivory palette are grounded in `assets/app-icon.png`. A folded,
crooked house pack and a stone flute may appear when the animation state makes
them readable, but they must not compete with the box.

## Style

Use a polished compact 3D-toy mascot style derived from the existing app icon:
near-black iron, warm ivory moonlight, restrained cool gray-blue accents, clean
edges, and no generic purple magic. The whole body and expression must remain
legible within a 192x208 sprite cell.

## Animation Story

- `idle`: calm breathing and blinking while guarding the closed iron box.
- `running-right` / `running-left`: escaping with the box and folded house pack.
- `waving`: an overly innocent greeting while keeping hold of the box.
- `jumping`: a compact triumphant leap with the box secured to the body.
- `failed`: the lid shifts and Jax reacts as the captive moon threatens to escape.
- `waiting`: an expectant approval-seeking pose with the box held close.
- `running`: active work expressed by carefully unfolding the crooked house.
- `review`: focused inspection or listening at the iron box.
- look directions: eyes lead, then head and upper torso follow; the box stays
  anchored against the body throughout the continuous clockwise gaze loop.

## Delivery Contract

Package an 8x11 WebP atlas at 1536x2288 with all nine standard animation rows,
sixteen clockwise look directions, transparent backgrounds, and a `pet.json`
manifest using `spriteVersionNumber: 2`. Deterministic validation, motion
previews, direction semantics, blind direction review, and final visual QA must
pass before installation.
