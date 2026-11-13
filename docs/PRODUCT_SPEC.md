# TUPIC Product Specification

**Service:** TUPIC (튜픽)  
**Positioning:** YouTube content curation app — not a YouTube replacement.  
**Primary early audience:** Parents managing kids’ viewing; also usable by general users.

## Core concepts

| Term | Meaning |
| --- | --- |
| Channel | A content collection created by a TUPIC user |
| Youtuber | External YouTube creator / YouTube channel |
| Video | Individual YouTube video |
| Playlist | YouTube playlist |
| Content block | Managed unit (video / playlist / youtuber) inside a TUPIC channel |

Do not confuse **TUPIC channel** with **YouTube youtuber/channel**.

## Value proposition

Users pick YouTube videos, playlists, and creators to build their own curated channels and watch them conveniently via the official YouTube embedded player and allowed APIs.

## Design system

**Concept:** Premium Dark + Deep Violet + Playful Space Illustration

| Token | Value |
| --- | --- |
| Main Background | `#0B0910` |
| Secondary | `#17121F` |
| Card | `#241B31` |
| Selected | `#39264F` |
| Accent Violet | `#A78BFA` |
| Primary Text | `#F6F3FC` |
| Player Black | `#000000` |

Avoid navy/charcoal as the main background, excessive neon glow, copyrighted character art as fixed sample assets, and sparse empty-card-only layouts.

## Navigation

- Menu entry is always at the **top-right**.
- Menu opens as a **right-side drawer** (no fixed left sidebar).
- Drawer items: channel list (expandable, default open), create channel, import shared channel (placeholder until STEP 6B), settings, my account.
- Per-channel management hub is Channel Detail (add content, manage content, settings via AppBar).
- Premium messaging may appear as a secondary drawer note without covering primary items.

## Home screen structure

1. Hero with space illustration + greeting/logo + menu
2. My Channels (cards + create-channel card)
3. Recommended content (audience-aware; mock in STEP 1)
4. Explore my content (category chips + filtered rails)
5. Future ad slot (modeled separately later; not shown in STEP 1)

## Channel creation (future behavior, preserved)

- Name input
- Kids channel checkbox (default **checked** → `isKidsChannel = true`)
- Parental gate (4-digit birth year; age ≥ 18): only when switching from a **playing kids channel** to a **general channel**. Not used for management screens or starting playback from home/detail.
- Birth year is never persisted.

## Playback (future)

- Landscape default for watching
- Controls: back (top-left), menu (top-right), lock (bottom-left), queue (bottom-right)
- Queue shows only videos of the **current TUPIC channel**
- Screen lock limits TUPIC UI; does not claim to block official YouTube/OS controls

## Free / Premium targets

| Plan | Price | Key limits |
| --- | --- | --- |
| Free | 0 | 1 channel, 100 videos/channel |
| Premium monthly | ₩1,900 | Up to 30 channels, 1,000 videos/channel, sync features |
| Premium yearly | ₩15,900 | Same Premium entitlements |

Canceling Premium must not immediately delete existing channels/videos. Limits should be server-configurable later.

## Localization (required from STEP 1)

- System locale auto-detect: `ko` → Korean, `en` → English, others → English fallback
- Settings: System default / Korean / English
- Manual choice overrides system and persists locally; switching is immediate without app restart
- Brand name `TUPIC` is not translated
- User-entered channel names and YouTube titles stay as-is

## Channel persistence (STEP 2)

Until Firebase is connected, user channels are stored on-device:

- id, name, kids flag, createdAt, play order, last selected channel
- Free plan: max 1 channel (Premium upsell only; no billing yet)
- Kids channel management uses parental gate (birth year → age ≥ 18)

## Content registration (STEP 3A)

- Users can register YouTube video / playlist / creator URLs into a TUPIC channel
- Individual videos are stored locally by video ID (no live metadata fetch yet)
- Playlist/creator sources are stored as pending until YouTube API is connected
- Playback queue is deduped; excluded videos stay stored but out of queue
- Free: max 100 unique active videos per channel; auto-sync locked

## Playback (STEP 3B)

- Official YouTube IFrame Player only (no stream extraction / download)
- Channel detail Play + per-video entry open a landscape viewing screen
- Queue strip, TUPIC screen lock, sequential/shuffle, ended → next (no infinite loop by default)
- Minimum embed size 200×200; 16:9 when possible
- Kids parental gate for management / unlock; not per-video watch approval

## Out of scope (through STEP 3B)

YouTube Data API, Firebase auth/storage, Premium billing, scheduled auto-sync, ads, AI classification, share servers.
