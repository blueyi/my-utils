The cursor-ide-browser is an MCP server that allows you to navigate the web and interact with the page. Use this for frontend/webapp development and testing code changes.

CRITICAL - Lock/unlock workflow:
1. browser_lock requires an existing browser tab - you CANNOT lock before browser_navigate
2. Correct order: browser_navigate -> browser_lock -> (interactions) -> browser_unlock
3. If a browser tab already exists (check with browser_tabs list), call browser_lock FIRST before any interactions
4. Only call browser_unlock when completely done with ALL browser operations for this turn

IMPORTANT - Before interacting with any page:
1. Use browser_tabs with action "list" to see open tabs and their URLs
2. Use browser_snapshot to get the page structure and element refs before any interaction (click, type, hover, etc.)

IMPORTANT - Waiting strategy:
When waiting for page changes (navigation, content loading, animations, etc.), prefer short incremental waits (1-3 seconds) with browser_snapshot checks in between rather than a single long wait. For example, instead of waiting 10 seconds, do: wait 2s -> snapshot -> check if ready -> if not, wait 2s more -> snapshot again. This allows you to proceed as soon as the page is ready rather than always waiting the maximum time.

Notes:
- Native dialogs (alert/confirm/prompt) never block automation. By default, confirm() returns true and prompt() returns the default value. To test different responses, call browser_handle_dialog BEFORE the triggering action: use accept: false for "Cancel", or promptText: "value" for custom prompt input.
- Iframe content is not accessible - only elements outside iframes can be interacted with.
- Use browser_type to append text, browser_fill to clear and replace. browser_fill also works on contenteditable elements.
- For nested scroll containers, use browser_scroll with scrollIntoView: true before clicking elements that may be obscured.