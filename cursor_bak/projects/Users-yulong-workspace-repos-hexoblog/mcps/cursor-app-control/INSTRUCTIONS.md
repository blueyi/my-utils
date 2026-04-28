The cursor-app-control MCP allows you to control the Cursor application itself. Use it to:
- Move the current agent to a new root workspace directory (move_agent_to_root) — use this after creating a worktree or whenever the conversation should continue from a different workspace root
- Create a new project at a given path (create_project) — creates the directory if missing and initializes a git repository. Use this to bootstrap a new project before moving to it with move_agent_to_root
- Open a resource by URI in Glass (open_resource) — opens files in the right-hand editor panel, focuses terminals, opens output channels, opens web links according to the Glass browser setting, or delegates other schemes to the default workbench opener

Use move_agent_to_root when you want the current conversation to adopt a different root workspace directory. This updates the visible work surface and the default cwd for new terminals.
Use create_project when you need to create a brand new project directory with an initialized git repository.
Use open_resource when you need to reveal a file, terminal, output channel, or URL for the current agent.