The cursor-ide-browser is an MCP server that allows you to navigate the web and interact with the page. Use this for frontend/webapp development and testing code changes.

CORE WORKFLOW:
1. Start by understanding the user's goal and what success looks like on the page.
2. Use browser_tabs with action "list" to inspect open tabs and URLs before acting.
3. Use browser_snapshot before any interaction to inspect the current page structure and obtain refs.
4. Use browser_take_screenshot for standalone visual verification or screenshot-based coordinate clicks. For browser_mouse_click_xy, capture a fresh viewport screenshot for the same tab and then issue the click immediately using coordinates from that screenshot. Do not reuse older screenshot coordinates. If any other browser tool runs first, capture a new viewport screenshot before calling browser_mouse_click_xy.
5. After any action that could change the page structure or URL (click, type, fill, fill_form, select, hover, press key, drag, browser_navigate, browser_navigate_back, wait, dialog response, or lazy-loaded scroll), take a fresh browser_snapshot before the next structural action unless you are certain the page did not change.

AGENTIC PAGE NAVIGATION:
1. When you know the destination, use browser_navigate directly to that URL.
2. Use browser_navigate_back for browser history. Keep track of the current URL from tool output or snapshot metadata so you can navigate directly when needed.
3. Work top-down: identify the relevant page region, dialog, form, or menu in the snapshot first, then target a specific ref inside it.
4. Prefer one deliberate action followed by verification over exploratory thrashing.
5. Use browser_search to locate text before blindly scrolling through large pages.
6. Use browser_hover to reveal tooltips, dropdown menus, or hidden content before interacting with revealed elements.
7. Use browser_scroll with scrollIntoView: true before clicking elements that may be offscreen or obscured.
8. Use browser_fill to replace existing content (works on both input fields and contenteditable elements) and browser_type to append text or trigger typing-related handlers.
9. If multiple elements share the same role and name, choose the exact ref from the snapshot instead of guessing. Use [nth=N] only as a hint to tell duplicate elements apart.

AVOID RABBIT HOLES:
1. Do not repeat the same failing action more than once without new evidence such as a fresh snapshot, a different ref, a changed page state, or a clear new hypothesis.
2. IMPORTANT: If four attempts fail or progress stalls, stop acting and report what you observed, what blocked progress, and the most likely next step.
3. Prefer gathering evidence over brute force. If the page is confusing, use browser_snapshot, browser_console_messages, browser_network_requests, or a screenshot to understand it before trying more actions.
4. If you encounter a blocker such as login, passkey/manual user interaction, permissions, captchas, destructive confirmations, missing data, or an unexpected state, stop and report it instead of improvising repeated actions.
5. Do not get stuck in wait-action-wait loops. Every retry should be justified by something newly observed.

CRITICAL - Lock/unlock workflow:
1. browser_lock requires an existing browser tab - you CANNOT call browser_lock with action: "lock" before browser_navigate
2. Correct order: browser_navigate -> browser_lock({ action: "lock" }) -> (interactions) -> browser_lock({ action: "unlock" })
3. If a browser tab already exists (check with browser_tabs list), call browser_lock with action: "lock" FIRST before any interactions
4. Only call browser_lock with action: "unlock" when completely done with ALL browser operations for this turn

IMPORTANT - Waiting strategy:
When waiting for page changes (navigation, content loading, animations, etc.), prefer short incremental waits (1-3 seconds) with browser_snapshot checks in between rather than a single long wait. For example, instead of waiting 10 seconds, do: wait 2s -> snapshot -> check if ready -> if not, wait 2s more -> snapshot again. This allows you to proceed as soon as the page is ready rather than always waiting the maximum time.

PERFORMANCE PROFILING:
- browser_profile_start/stop: CPU profiling with call stacks and timing data. Use to identify slow JavaScript functions.
- Profile data is written to ~/.cursor/browser-logs/. Files: cpu-profile-{timestamp}.json (raw profile in Chrome DevTools format) and cpu-profile-{timestamp}-summary.md (human-readable summary).
- IMPORTANT: When investigating performance issues, read the raw cpu-profile-*.json file to verify summary data. Key fields: profile.samples.length (total samples), profile.nodes[].hitCount (per-node hits), profile.nodes[].callFrame.functionName (function names). Cross-reference with the summary to confirm findings before making optimization recommendations.

VISION:
- Snapshot and interaction tools can optionally attach a page screenshot by setting take_screenshot_afterwards: true. The screenshot provides visual context (layout, colors, state); the aria snapshot provides element refs required for targeting actions. Use both together: the screenshot shows what the page looks like, the snapshot tells you how to interact with it. Prefer refs from the snapshot for interactions; the one screenshot-based exception is browser_mouse_click_xy, which must use coordinates from a fresh viewport screenshot captured immediately before the click for that tab. Any other browser tool call invalidates that screenshot cache.

NOTES:
- browser_snapshot returns snapshot YAML and is the main source of truth for page structure.
- Refs are opaque handles tied to the latest browser_snapshot for that tab. If a ref stops working, take a fresh snapshot instead of guessing.
- Native dialogs (alert/confirm/prompt) never block automation. By default, confirm() returns true and prompt() returns the default value. To test different responses, call browser_handle_dialog BEFORE the triggering action: use accept: false for "Cancel", or promptText: "value" for custom prompt input.
- Iframe content is not accessible - only elements outside iframes can be interacted with.
- For nested scroll containers, use browser_scroll with scrollIntoView: true before clicking elements that may be obscured.
- When you stop to report a blocker, include the current page, the target you were trying to reach, the blocker you observed, and the best next action. If the blocker requires manual user interaction, ask the user to take over at that point rather than assuming it in advance.