Phoenix CTMS
=====

This repository is a supplemental part of the Phoenix CTMS platform, see [https://github.com/phoenixctms/ctsms](https://github.com/phoenixctms/ctsms).

## Private site config

`install.sh` / `upgrade.sh` (via `/ctsms/update`) accept:

```text
TAG  [CONFIG_REPO]  [TOKEN]
```

| Args | Config source |
|------|----------------|
| *(none / no CONFIG_REPO)* | Public `phoenixctms/config-default` |
| `CONFIG_REPO` + `TOKEN` | Private repo via GitHub PAT (`wget` + `Authorization: token …`) |
| `CONFIG_REPO` only | Private repo via read-only SSH **deploy key** |

Passing a `TOKEN` always uses PAT mode.

### Deploy key setup

`/ctsms/update` is normally run as a regular user (it sudo’s `upgrade.sh`). After install/upgrade, `/ctsms/setup-config-deploy-key.sh` is present and can be run the same way — it re-execs with `sudo` for key/`known_hosts` setup under `/root/.ssh`.

On an existing host, one PAT update ships the script:

```bash
/ctsms/update master OWNER/config-repo ghp_...
/ctsms/setup-config-deploy-key.sh
```

Add the printed public key as a **read-only** deploy key on the private config repo, then omit `TOKEN` on later runs:

```bash
/ctsms/update master OWNER/config-repo
```

Default key path: `/root/.ssh/ctsms_config_deploy` (override with `CTSMS_CONFIG_SSH_KEY`). The key lives as root because `upgrade.sh` runs as root. Host keys are pinned into `/root/.ssh/known_hosts` (GitHub’s published SSH fingerprints).
