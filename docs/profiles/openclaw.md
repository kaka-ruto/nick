# OpenClaw Setup Playbook (Reusable)

This document defines the kinds of work to complete when setting up OpenClaw for a project.  
It is intentionally environment-agnostic and should be used across teams/projects.

## 1) Infrastructure Baseline

- [ ] Provision a dedicated host for OpenClaw gateway/control plane.
- [ ] Apply OS updates and install core ops packages (`git`, `curl`, `jq`, `tmux`, `ufw`, `fail2ban`).
- [ ] Enforce SSH key-only access and disable password/root login.
- [ ] Restrict SSH ingress to private/admin paths only (for example private network + IAP/jump-host).
- [ ] Enable and verify firewall + brute-force protection.

## 2) OpenClaw Installation Baseline

- [ ] Install OpenClaw CLI/gateway and verify command availability in login shells.
- [ ] Configure gateway mode/bind for private access by default.
- [ ] Set gateway auth token and secure it.
- [ ] Start gateway under a managed process (`systemd` or `tmux`) and verify listener health.
- [ ] Confirm `openclaw status` and `openclaw security audit --deep` are clean (no critical/warn).

## 3) Identity and Access Model

- [ ] Use dedicated bot/service identities for source control and channel integrations.
- [ ] Enable MFA and recovery controls for bot accounts.
- [ ] Grant least-privilege permissions only (repo/channel scoped; no broad admin by default).
- [ ] Keep secrets in secret stores/session auth; never in plaintext docs or repo files.

## 4) Agent Topology

- [ ] Define at least:
  - `main` coordinator agent
  - one specialist implementation agent (for example `<project>-dev`)
- [ ] Keep each agent isolated with its own workspace and agent directory.
- [ ] Assign explicit role boundaries:
  - coordinator: routing/planning/status
  - specialist: implementation/test/fix/PR workflow
- [ ] Set model defaults globally, then override per-agent only when needed.

## 5) Prompt and Policy Contracts

- [ ] Add workspace policy files (`AGENTS.md`, `IDENTITY.md`, `USER.md`) per agent.
- [ ] Include non-negotiables:
  - operate only on explicit request (unless automation is intentionally enabled)
  - no direct pushes to default branch
  - branch naming convention required
  - mandatory test-before-commit and PR evidence
  - no destructive git/history operations without explicit approval
- [ ] Require explicit approval before creating/linking external accounts.
- [ ] Prohibit storing plaintext credentials/tokens in memory files, docs, or commits.

## 6) Channel Integration (Slack/WhatsApp/etc.)

- [ ] Configure channel auth and verify connection status.
- [ ] Enable mention/trigger gating so bots do not reply to every message.
- [ ] Apply allowlists:
  - channel allowlists for group platforms (for example Slack channels)
  - sender allowlists for direct-message channels (for example WhatsApp)
- [ ] Verify routing bindings map each channel/account to the intended specialist agent.
- [ ] Run channel smoke tests and confirm inbound + outbound behavior.

## 7) Security Hardening in OpenClaw

- [ ] Keep gateway non-public by default.
- [ ] Configure trusted proxy settings when reverse proxies are used.
- [ ] Disable elevated tools unless explicitly required.
- [ ] Restrict tool/network/file permissions by agent role.
- [ ] Re-run deep security audit after every auth/network/policy change.

## 8) CI/CD and Git Workflow Integration

- [ ] Ensure specialist agent can:
  - sync branch
  - run install/lint/tests
  - create fix branch
  - commit by guideline
  - push and open PR
- [ ] Require PR template fields:
  - root cause
  - change summary
  - test evidence
  - risk/rollback notes
- [ ] Keep merges human-approved unless explicitly automating merge policy.

## 9) Ephemeral Test Environment Pattern

- [ ] Keep gateway host stable; run heavy install/test loops on disposable test hosts.
- [ ] Provide guarded scripts/wrappers for create/list/ssh/delete operations.
- [ ] Enforce naming prefixes, labels, and region/shape constraints.
- [ ] Add cleanup policy (TTL or periodic cleanup job).

## 10) Observability and Recovery

- [ ] Standardize diagnostic commands:
  - `openclaw status --deep`
  - `openclaw channels status --probe`
  - `openclaw logs --follow`
  - `openclaw channels logs --channel <name>`
- [ ] Document fallback admin access path (for example private tunnel or IAP).
- [ ] Keep an incident runbook for channel failures, auth failures, and gateway restart loops.

## 11) Capacity and SSH Resilience (Heavy Task Stability)

- [ ] Add swap on small VPS shapes (recommended: `4G` minimum) and persist in `/etc/fstab`.
- [ ] Apply kernel memory/IO guardrails:
  - `vm.swappiness=10`
  - `vm.vfs_cache_pressure=50`
  - `vm.dirty_background_ratio=5`
  - `vm.dirty_ratio=20`
- [ ] Enable SSH keepalive hardening:
  - `ClientAliveInterval 30`
  - `ClientAliveCountMax 5`
  - `TCPKeepAlive yes`
- [ ] Cap OpenClaw pressure on small hosts:
  - lower `agents.defaults.maxConcurrent`
  - set conservative process scheduling for gateway service (`Nice`, `IOScheduling*`, optional `CPUQuota`)
- [ ] Prefer non-interactive admin paths (`IAP` and/or `Tailscale`) and keep one fallback path available.
- [ ] Treat Tailscale health warnings as first-class signals when remote shell drops are observed.

## 12) Stability Validation (Post-Hardening)

- [ ] Baseline check:
  - `free -h`
  - `swapon --show`
  - `uptime`
- [ ] Run repeated remote probes before and during a heavy OpenClaw operation.
- [ ] Pass criteria:
  - no SSH probe failures/timeouts during the stress window
  - gateway remains reachable
  - no critical findings in `openclaw security audit`
- [ ] If probes fail:
  - reduce concurrency further
  - move to larger machine size
  - split heavy workloads onto disposable test hosts

## 13) Incident Pattern to Watch

- [ ] Symptom cluster indicating resource/network instability:
  - SSH banner timeouts or dropped tunnels under load
  - very high load averages on low-core hosts
  - high IO wait and delayed service responses
  - intermittent relay/control-plane health warnings
- [ ] Response sequence:
  1. reduce runtime pressure immediately
  2. confirm swap + sysctl + SSH keepalives
  3. restart gateway cleanly
  4. rerun probe-based stress test

## 14) Worker Offloading Pattern (Recommended)

- [ ] Keep OpenClaw gateway/channels on a control-plane host only.
- [ ] Run heavy QA/build/test/fix loops on separate worker VMs.
- [ ] Prefer disposable workers per job or per short batch.
- [ ] Keep worker scripts guarded and reproducible.

### Suggested command flow

1. Create worker:
   - `caf-openclaw-worker-create <name> [zone] [machine-type]`
   - default machine type: `e2-small`
2. Run one remote command:
   - `caf-openclaw-worker-run <name> <zone> "<command...>"`
3. Run full ephemeral offload job:
   - `caf-openclaw-offload <name> <zone> <machine-type> <repo-url> "<job-cmd>"`
   - recommended starter: `e2-small`
4. Destroy worker:
   - `caf-openclaw-worker-destroy <name> [zone]`

### Worker baseline contents

- [ ] Base ops tools (`git`, `curl`, `jq`, `tmux`, `ufw`, `fail2ban`)
- [ ] Swap enabled (minimum `4G`)
- [ ] sysctl tuning for memory/IO behavior
- [ ] project checkout under `~/work/<repo>`
- [ ] no channel credentials unless explicitly needed

### Worker readiness gate

- [ ] Offload runner should wait for:
  - startup marker file: `/var/tmp/cafaye-worker-ready`
  - swap active: `swapon --show` contains `/swapfile`
- [ ] Fail fast if readiness conditions are not met before job start.

## 15) QA Continuity Memory (No Repeated QA)

- [ ] Maintain per-project QA state file:
  - `/home/kaka/.openclaw/workspace/projects/<project-key>-qa-state.md`
- [ ] Required sections:
  - `Tested (completed)`
  - `Reported (issues filed)`
  - `Not Worked (queued)`
  - `Retest Required`
- [ ] QA run policy:
  - always read state file first
  - prioritize `Not Worked` then `Retest Required`
  - skip `Tested` unless user requests full rerun or code changed in area
  - update state file at end of every QA run with timestamps and links

## 16) Operational Defaults

- [ ] Keep heartbeat disabled for request/response-only deployments.
- [ ] Enable heartbeat only when proactive checks/reminders are required.
- [ ] Keep automation off until smoke tests and policy controls are verified.

## 17) Definition of Done

- [ ] Gateway is private, authenticated, and reachable via approved admin path.
- [ ] Channels are connected and correctly routed to target agents.
- [ ] Specialist agent can complete one full test->fix->PR cycle successfully.
- [ ] Security audit reports no critical/warn findings.
- [ ] Recovery path and operational runbook are documented.
