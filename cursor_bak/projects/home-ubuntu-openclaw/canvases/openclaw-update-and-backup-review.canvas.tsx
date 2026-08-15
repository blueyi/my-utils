import {
  Callout,
  Card,
  CardBody,
  CardHeader,
  Code,
  Divider,
  Grid,
  H1,
  H2,
  H3,
  Pill,
  Row,
  Stack,
  Stat,
  Table,
  Text,
  TodoListCard,
  useCanvasState,
} from "cursor/canvas";

type Tab = "verify" | "backup" | "plan";

export default function OpenClawUpdateAndBackupReview() {
  const [tab, setTab] = useCanvasState<Tab>("tab", "verify");

  return (
    <Stack gap={20}>
      <Stack gap={6}>
        <H1>OpenClaw update + ucloud git backup</H1>
        <Text tone="secondary">
          VPS Ubuntu · branch ucloud · checked 2026-08-16 00:48 HKT. Stable
          channel is already current; remote git backup has been failing for 14
          days.
        </Text>
      </Stack>

      <Grid columns={4} gap={12}>
        <Stat value="2026.7.1-2" label="OpenClaw (stable = latest)" tone="success" />
        <Stat value="active" label="Gateway systemd user" tone="success" />
        <Stat value="4 / 4" label="Channels probed connected" tone="success" />
        <Stat value="14 days" label="Remote ucloud backup stale" tone="danger" />
      </Grid>

      <Row gap={8} wrap>
        <Pill active={tab === "verify"} onClick={() => setTab("verify")}>
          Update verification
        </Pill>
        <Pill active={tab === "backup"} onClick={() => setTab("backup")}>
          Backup review
        </Pill>
        <Pill active={tab === "plan"} onClick={() => setTab("plan")}>
          Modification plan
        </Pill>
      </Row>

      {tab === "verify" ? <VerifyTab /> : null}
      {tab === "backup" ? <BackupTab /> : null}
      {tab === "plan" ? <PlanTab /> : null}

      <Text size="small" tone="tertiary">
        Sources: openclaw update/status/doctor/health/channels/cron, npm
        dist-tags, crontab, auto-git-backup.log, .auto-backup-include,
        gitcode origin/ucloud. No secret values are shown.
      </Text>
    </Stack>
  );
}

function VerifyTab() {
  return (
    <Stack gap={16}>
      <Callout tone="success" title="Already on latest stable">
        Channel is stable. npm latest and local install are both 2026.7.1-2
        (0790d9f). Ran openclaw update --yes --no-restart: before = after,
        11 npm plugins unchanged, 2 skipped. Beta 2026.8.1-beta.2 exists but
        was not applied. Node v22.23.1 is within the required range.
      </Callout>

      <H2>Functional verification</H2>
      <Table
        headers={["Check", "Result", "Detail"]}
        rowTone={["success", "success", "success", "success", "success", "success", "warning", "warning", "warning", "info"]}
        rows={[
          ["CLI version", "Pass", "2026.7.1-2 /data/npm-global"],
          ["Gateway process", "Pass", "systemd user enabled, pid 482068, ws://127.0.0.1:28789 probe ok"],
          ["CLI vs gateway version", "Pass", "Both 2026.7.1-2 after update"],
          ["Feishu", "Pass", "enabled, running, connected, works"],
          ["WeChat (openclaw-weixin)", "Pass", "enabled, running; last session 24m before check"],
          ["QQ Bot", "Pass", "enabled, running, connected"],
          ["Telegram", "Pass", "polling @myuclawBot works; still in pairing/first-time group mode"],
          ["Agents (5)", "Pass", "main, qq-agent, kora-health, feishu-agent, weixin-agent"],
          ["Cron enabled jobs", "Partial", "5 enabled; morning stock brief error 2x (mellow-trail)"],
          ["Skills / plugins", "Pass", "56 eligible skills, 0 missing reqs; 10/80 plugins loaded, 0 errors"],
        ]}
        striped
      />

      <H2>Enabled cron jobs</H2>
      <Table
        headers={["Job", "Schedule (HKT)", "Last", "Status"]}
        rowTone={["success", "success", "danger", "success", "warning"]}
        rows={[
          ["disk-cleanup-weekly", "Sun 03:00", "7d ago", "ok"],
          ["每日英文话题推送", "08:30", "16h ago", "ok, delivered"],
          ["股票自选股早报", "10:00", "15h ago", "error 2x: process mellow-trail failed"],
          ["ai-infra-learning-daily", "11:30 (Shanghai)", "13h ago", "ok, delivered to Feishu"],
          ["股票自选股晚报", "22:00", "3h ago", "ok, delivered; lb_client.py warn"],
        ]}
        striped
      />
      <Text size="small" tone="secondary">
        7 more jobs exist but are disabled (Kora audit/health/cleanup, AI Infra
        WeChat digest, one-shot reports). Daily Auto-Update cron from the
        auto-updater skill is not present, so OpenClaw does not self-update on
        this host.
      </Text>

      <H2>Doctor findings (pre-existing)</H2>
      <Grid columns={2} gap={12}>
        <Card>
          <CardHeader trailing={<Pill size="sm">warning</Pill>}>
            Config / security
          </CardHeader>
          <CardBody>
            <Stack gap={8}>
              <Text size="small">
                plugins.allow is an exclusive allowlist while tools.allow is *.
                Plugin tools outside the allowlist stay unavailable.
              </Text>
              <Text size="small">
                openclaw.json has plaintext secret-bearing fields (memorySearch
                apiKey, gateway tokens, provider apiKeys). Doctor recommends
                SecretRefs. Repo myclaw is private, but git still stores those
                values.
              </Text>
              <Text size="small">
                Telegram groups remain blocked until allowlists or groupPolicy
                are set.
              </Text>
            </Stack>
          </CardBody>
        </Card>
        <Card>
          <CardHeader trailing={<Pill size="sm">info</Pill>}>
            State / cron
          </CardHeader>
          <CardBody>
            <Stack gap={8}>
              <Text size="small">
                2453 orphan transcript files under agents/main/sessions.
                Doctor can archive them with --fix; not applied.
              </Text>
              <Text size="small">
                One cron job pins api-proxy-claude/claude-sonnet-4-6 instead of
                inheriting deepseek/deepseek-v4-pro.
              </Text>
              <Text size="small">
                Five isolated jobs drive shell via agent prompt (supported,
                informational). Live cron store is gateway/sqlite;
                ~/.openclaw/cron/jobs.json is missing on disk.
              </Text>
            </Stack>
          </CardBody>
        </Card>
      </Grid>

      <Callout tone="info" title="Update policy kept on stable">
        npm beta is 2026.8.1-beta.2 (SQLite snapshot CLI, secret egress binding,
        GPT-5.6 Ultra). Not installed. Stay on stable unless you explicitly
        want the beta channel.
      </Callout>
    </Stack>
  );
}

function BackupTab() {
  return (
    <Stack gap={16}>
      <Callout tone="danger" title="Design is sound; production backup is broken">
        Per-machine branch + whitelist + dual GitHub/GitCode remotes is a
        reasonable scheme for this layout. It has not pushed origin/ucloud
        since 2026-08-02 03:09 HKT. Local HEAD is 12 commits ahead; cron still
        runs hourly and only fails the .openclaw entry.
      </Callout>

      <Grid columns={3} gap={12}>
        <Stat value="12" label="Local commits not on origin/ucloud" tone="danger" />
        <Stat value="missing" label="cron/jobs.json export file" tone="danger" />
        <Stat value="private" label="github.com/blueyi/myclaw" tone="success" />
      </Grid>

      <H2>What still works</H2>
      <Table
        headers={["Piece", "Assessment"]}
        rowTone={["success", "success", "success", "success", "success"]}
        rows={[
          ["Branch pin ~/.openclaw:ucloud", "Correct for this VPS; script never switches branches"],
          [".gitignore defense-in-depth", "Keeps sessions, sqlite, caches, bak copies out of git"],
          [".auto-backup-include whitelist", "Right idea: only config, creds, workspaces, models.json"],
          ["Dual remote (GitCode fetch, GitHub+GitCode push)", "Matches my-utils dual-remote lib; GitCode is the working fallback"],
          ["Git dir on /data/openclaw-git", "Keeps the 38G root disk from holding pack files"],
        ]}
      />

      <H2>Failure chain since 2026-08-02 04:00</H2>
      <Text>
        Interactive run at 03:08 succeeded because the shell had MY_UTILS_ROOT
        and loaded git-dual-remote.env, so pull was{" "}
        <Code>git pull --rebase origin ucloud</Code>. Hourly cron does not set
        that env. Dual-remote setup then fails, the script falls back to{" "}
        <Code>git pull --rebase</Code> with no upstream on ucloud, pull errors,
        and push is skipped even when a local backup commit already exists.
      </Text>
      <Table
        headers={["Step", "Cron behavior", "Effect"]}
        rowTone={["danger", "danger", "danger", "warning"]}
        rows={[
          [
            "refresh-backup-exports.sh",
            "PATH has no ~/.npm-global/bin; openclaw not found",
            "jobs.json is never regenerated (deleted from git on Aug 2 14:00)",
          ],
          [
            "ucloud upstream",
            "branch.ucloud.remote is unset",
            "Bare git pull --rebase refuses to run",
          ],
          [
            "git_dual_ensure_remotes",
            "MY_UTILS_ROOT unset in crontab; GitHub user env empty",
            "Falls back to untracked pull; blocks push",
          ],
          [
            "BACKUP_DIRS_LINUX",
            "Same path listed as both :ucloud and :wsl",
            "wsl entry is skipped every hour (noise, not the outage)",
          ],
        ]}
        striped
      />

      <H2>Include-list coverage</H2>
      <Table
        headers={["Path", "In whitelist", "On disk", "Restore impact"]}
        rowTone={["success", "danger", "danger", "warning", "info", "info"]}
        rows={[
          ["openclaw.json, credentials, identity, devices", "yes", "yes", "Core restore OK if remotes catch up"],
          ["cron/jobs.json", "yes", "no", "Cron jobs live in sqlite; git copy is stale/absent"],
          ["agents/*/agent/auth-profiles.json", "no", "feishu only", "Feishu OAuth profile not backed up"],
          ["workspace*/ + skills + models.json", "yes", "yes", "Covered, but heartbeat-state.json is noisy"],
          ["plugins/, extensions/", "no", "yes", "Rebuildable; omit is OK"],
          ["sessions + sqlite", "ignored", "yes", "Correct omit; use openclaw backup create for full state"],
        ]}
        striped
      />

      <H2>Other design smells</H2>
      <Grid columns={2} gap={12}>
        <Card>
          <CardHeader>Commit quality</CardHeader>
          <CardBody>
            <Text size="small">
              After Aug 2, almost every local commit is
              workspace-feishu/memory/heartbeat-state.json or disk-cleanup.log.
              Hourly snapshots of heartbeat JSON burn history and hide real
              config diffs. Pull-failure also means those 12 commits never left
              the machine.
            </Text>
          </CardBody>
        </Card>
        <Card>
          <CardHeader>Stash around pull</CardHeader>
          <CardBody>
            <Text size="small">
              Script does git stash push -u before pull because the worktree is
              intentionally dirty outside the whitelist. A failed stash pop
              (already warned in logs on other repos) can lose untracked files.
              Safer: pull with --autostash only for tracked paths, or skip pull
              when ahead-only.
            </Text>
          </CardBody>
        </Card>
      </Grid>

      <Callout tone="warning" title="Official OpenClaw backup is unused">
        openclaw backup create can snapshot the whole ~/.openclaw tree
        (config, credentials, sessions, workspaces) to a verified tar.gz. Git
        is a good incremental config sync; it is a poor full-restore image.
        Use both.
      </Callout>
    </Stack>
  );
}

function PlanTab() {
  return (
    <Stack gap={16}>
      <Callout tone="info" title="Do not rewrite the model">
        Keep per-OS branches, whitelist, no branch switching, and dual remotes.
        Fix the cron environment and make pull/push independent so a tracking
        miss cannot silently stop offsite backups.
      </Callout>

      <H2>P0 — restore offsite backup this week</H2>
      <TodoListCard
        defaultExpanded
        todos={[
          {
            id: "p0-path",
            content:
              "Fix crontab PATH + env: export PATH with ~/.npm-global/bin, MY_UTILS_ROOT, and source git-dual-remote.env before refresh-backup-exports.sh",
            status: "pending",
          },
          {
            id: "p0-upstream",
            content:
              "git -C ~/.openclaw branch --set-upstream-to=origin/ucloud ucloud  (local only; needed so fallback pull works)",
            status: "pending",
          },
          {
            id: "p0-pull-args",
            content:
              "Change auto-git-commit.sh to always git_dual_pull --rebase origin <branch> and never bare git pull --rebase; do not skip push if pull fails but local is ahead",
            status: "pending",
          },
          {
            id: "p0-export",
            content:
              "Re-run refresh-backup-exports.sh with a working PATH so cron/jobs.json exists, then confirm it is staged by the include list",
            status: "pending",
          },
          {
            id: "p0-push",
            content:
              "Once pull works: push the 12 local ucloud commits to GitCode + GitHub. Inspect the Aug 2 jobs.json deletion before force-syncing remotes.",
            status: "pending",
          },
        ]}
      />

      <H3>Proposed crontab (ucloud host only)</H3>
      <Card>
        <CardBody>
          <Text size="small" as="span">
            <Code>
              SHELL=/bin/bash{"\n"}
              PATH=/home/ubuntu/.npm-global/bin:/home/ubuntu/.local/bin:/usr/bin:/bin{"\n"}
              MY_UTILS_ROOT=/home/ubuntu/workspace/my-utils{"\n"}
              0 * * * * . "$MY_UTILS_ROOT/config/git-dual-remote.env"; /bin/bash
              /home/ubuntu/.openclaw/scripts/refresh-backup-exports.sh &gt;&gt;
              /home/ubuntu/workspace/auto-git-backup.log 2&gt;&amp;1; AUTO_GIT_SILENT=1
              /bin/bash $MY_UTILS_ROOT/common/auto-git-commit.sh &gt;&gt;
              /home/ubuntu/workspace/my-utils/common/auto-git-backup.log 2&gt;&amp;1
            </Code>
          </Text>
        </CardBody>
      </Card>

      <H2>P1 — make the scheme actually restoreable</H2>
      <TodoListCard
        defaultExpanded
        todos={[
          {
            id: "p1-linux-list",
            content:
              "Split BACKUP_DIRS_LINUX: this VPS should only list ~/.openclaw:ucloud. Move ~/.openclaw:wsl to a WSL-only list or detect WSL vs native Linux.",
            status: "pending",
          },
          {
            id: "p1-include",
            content:
              "Add agents/*/agent/auth-profiles.json. Exclude **/heartbeat-state.json and workspace/memory/disk-cleanup.log (or rotate logs outside git).",
            status: "pending",
          },
          {
            id: "p1-stash",
            content:
              "Replace stash -u with: commit include paths first, then git pull --rebase --autostash origin <branch>. Never stash untracked runtime files.",
            status: "pending",
          },
          {
            id: "p1-alert",
            content:
              "If .openclaw push fails twice, write a flag and notify (Telegram 8231952046 or Feishu). Silent hourly FAIL is how 14 days slipped.",
            status: "pending",
          },
          {
            id: "p1-official",
            content:
              "Weekly: openclaw backup create --verify --output /data/openclaw-backups and keep N copies. This captures sqlite/sessions that git correctly ignores.",
            status: "pending",
          },
          {
            id: "p1-dead",
            content:
              "Drop $HOME/repos/my-utils (path does not exist). Decide whether ~/.hermes on this host should be on a real branch or removed from the list.",
            status: "pending",
          },
        ]}
      />

      <H2>P2 — secrets and restore drill</H2>
      <Table
        headers={["Change", "Why"]}
        rows={[
          [
            "Migrate plaintext keys in openclaw.json to SecretRefs / env",
            "Private git still copies gateway tokens and provider keys to GitHub+GitCode",
          ],
          [
            "Keep env.rc.enc via sync-config; never commit ~/.env.rc",
            "Already the stated policy; verify SYNC_ENV_KEY exists on this host",
          ],
          [
            "Quarterly restore drill: clone myclaw ucloud into a temp dir and start a gateway",
            "Whitelist backup is unproven until a restore has been timed",
          ],
          [
            "Optional Daily Auto-Update isolated cron",
            "This host has no OpenClaw self-update job; stable lag is currently zero",
          ],
        ]}
        striped
      />

      <H2>Target architecture</H2>
      <Table
        headers={["Layer", "What it covers", "Cadence"]}
        rows={[
          [
            "Git ucloud branch (whitelist)",
            "openclaw.json, creds, identity, devices, workspaces, skills, models, exported jobs.json",
            "Hourly, only on substantive include-list diffs",
          ],
          [
            "openclaw backup create tar.gz on /data",
            "Full ~/.openclaw including sqlite + sessions for disaster restore",
            "Weekly + before any channel/version upgrade",
          ],
          [
            "Kora DB backup (already in crontab)",
            "Application database, unrelated to OpenClaw git",
            "Daily 03:00 (existing)",
          ],
        ]}
      />

      <Callout tone="warning" title="Not applied in this session">
        Backup script, crontab, upstream, and the 12 unpushed commits were left
        untouched. Say if you want P0 applied on this VPS (crontab + upstream +
        script pull/push fix + jobs.json export + push).
      </Callout>
    </Stack>
  );
}
