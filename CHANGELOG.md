# Changelog

All notable changes to **Thespian** are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [1.0.1] - 2026-10-25

### Changed
- Updated for Retail patch 12.1.5 and TBC Classic Anniversary 2.5.6, so the addon is no longer flagged as out of date.

### Fixed
- Long emotes with accented or non-Latin letters (à, é, ö, Cyrillic...) could be cut in the middle of a character and fail to send. They are now shortened cleanly.
- The minimap option now describes the icon correctly (a theatre mask, not a book).

## [1.0.0] - 2026-10-24

First public release. Press play on your character.

### Added
- **Emote soundboard** with six tabs (Greetings, Gestures, Emotions, Actions, Speech, Custom) and more than 70 ready-made buttons, 15 per page.
- **Custom emote builder**: choose a label, a type (Emote `/me`, Say, Yell, Party, Standard emote), a tab and the text, with a live chat preview.
- **Edit and delete** your own emotes with a right-click; deleting asks for confirmation.
- **`%t` placeholder** replaced with your target's name (or "someone" when you have no target).
- **Quick emote** box that sends any text as a `/me` emote.
- **Tooltips** showing the type and a preview of the chat line for every button.
- **Options panel** integrated into the game's settings (*AddOns → Thespian*) with: minimap button toggle, close-after-use, tooltips toggle, lock window, window scale, window opacity, reset window position and reset options.
- **Minimap button** with a golden theatre-mask icon: left-click to open, right-click for options, drag to move. Supports square minimaps.
- **Retail addon compartment** entry (right-click opens the options).
- **Slash commands**: `/thespian` (aliases `/rpe`, `/rpemotes`), `options`, `new`, `scale`, `reset`, `minimap`.
- Draggable, screen-clamped main window that remembers its position; closes with Esc.
- Custom artwork: addon icon and minimap icon.
- Single download for **Retail, Forever, Classic Era (Hardcore / Seasonal), TBC Classic Anniversary and Mists of Pandaria Classic**.
