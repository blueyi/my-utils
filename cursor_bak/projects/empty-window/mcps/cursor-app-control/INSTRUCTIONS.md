The cursor-app-control MCP allows you to control the Cursor application itself. Use it to:
- Move the current agent to a new root workspace directory (move_agent_to_root) — use this after creating a worktree or whenever the conversation should continue from a different workspace root
- Move the current agent to a verbatim clone of the current workspace (move_agent_to_cloned_root) — use this ONLY when the target is a sibling clone already on the agent's branch (for example from cursorfs-clone); skips the migration git fetch / ff-merge that the generic move performs
- Create a new project at a given path (create_project) — creates the directory if missing and initializes a git repository. Use this to bootstrap a new project before moving to it with move_agent_to_root
- Open a resource by URI in Glass (open_resource) — opens files in the right-hand editor panel (workspace paths or anything under ~/.cursor), focuses terminals, opens output channels, opens web links according to the Glass browser setting, or delegates other schemes to the default workbench opener
- Open the Automations UI in Glass (open_automation) — opens the new automation form, with optional templateId and structured prefillWorkflowData sent only to the active Glass view
- Run Cursor-specific actions (cursor_dialog) — currently supports item="rule" and scope="user" with action="list", "add", "update", or "remove" for user rules after asking what the user wants Cursor to remember
- Rename the current chat conversation (rename_chat) — sets the current chat title to the provided value

Use move_agent_to_root when you want the current conversation to adopt a different root workspace directory. This updates the visible work surface and the default cwd for new terminals.
Use move_agent_to_cloned_root when the target is a freshly-made sibling clone of the current workspace.
Use create_project when you need to create a brand new project directory with an initialized git repository.
Use open_resource when you need to reveal a file, terminal, output channel, or URL for the current agent.
Use open_automation when you need to show or prefill the Glass Automations UI; never put raw automation prefill payloads in cursor:// URLs.
Use rename_chat when you need to set a specific title for the current chat conversation.
Use cursor_dialog for onboarding and preference-learning workflows. Always list rules first to avoid duplicate memories, and only write rules the user has agreed should be remembered.