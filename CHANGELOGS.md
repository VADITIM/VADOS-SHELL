# Changelogs

Newest version first. The version and its number are set by the user on each push.

## Unreleased

- Activity pill in the middle of the taskbar: hidden, idle, active and expanded states, stepped with `CTRL + LEFT` / `CTRL + RIGHT` (IPC `activity next` / `previous` / `mode` / `rotate`), clicks and scroll. Music (MPRIS) and Discord voice calls (PipeWire) each have their own expanded shape.
- The activity pill merges into the dashboard and search burst without turning 90°: a taskbar part tips towards the seed only as far as it travels along its own length.
- Back from expanded to active, the pill's icons and satellite droplets each pop in on their own spot, one after another, instead of growing out of one point together.
- `Reshape` ability: a body grows to a new size with its own overshooting enter and a faster, separate collapse.
- Glyphs: music, headset, headphones, deafened, mic, mic-off, play, pause, next, previous.
- Preview: `Ctrl+Left/Right` step the pill, `Ctrl+Up` rotates the lead, `C` and `M` toggle the mock call and music.

## 0.1.1

- Search: the large circle shows the user's profile picture and mutates into the found app's icon while searching.
- Config: `profile.name` and `profile.picture` (`Config.setProfile`).
