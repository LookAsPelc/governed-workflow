"""Exercise the real Codex local marketplace flow against this checkout.

The fixture is committed because Git-backed marketplace implementations may
resolve only committed content.  No model, network marketplace, or auth flow
is involved: Codex is given an isolated CODEX_HOME and a local source.
"""

from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
CODEX = os.environ.get("CODEX_BIN", "codex")
SKILLS = (
    "skills/iron-box-onboarding/SKILL.md",
    "skills/iron-box-orchestration/SKILL.md",
)
ROLES = (
    "assets/codex/agents/luna-worker.toml",
    "assets/codex/agents/terra-worker.toml",
    "assets/codex/agents/sol-advisor.toml",
)
MAX_SKILL_BYTES = 6_000


def run(*args: str, env: dict[str, str], cwd: Path | None = None) -> str:
    result = subprocess.run(args, cwd=cwd, env=env, text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(f"command failed ({result.returncode}): {' '.join(args)}\\n{result.stderr}")
    return result.stdout


def codex(*args: str, home: Path) -> str:
    env = os.environ.copy()
    env["CODEX_HOME"] = str(home)
    return run(CODEX, *args, env=env)


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="iron-box-marketplace-") as temporary:
        temporary_root = Path(temporary)
        fixture = temporary_root / "fixture"
        cache_home = temporary_root / "codex-home"
        cache_home.mkdir()
        shutil.copytree(
            ROOT,
            fixture,
            ignore=shutil.ignore_patterns(".git", "__pycache__", "*.pyc"),
        )
        git_env = os.environ.copy()
        git_env.update(
            {
                "GIT_CONFIG_NOSYSTEM": "1",
                "GIT_CONFIG_GLOBAL": os.devnull,
                "GIT_AUTHOR_NAME": "Iron Box CI",
                "GIT_AUTHOR_EMAIL": "iron-box-ci@example.invalid",
                "GIT_COMMITTER_NAME": "Iron Box CI",
                "GIT_COMMITTER_EMAIL": "iron-box-ci@example.invalid",
            }
        )
        run("git", "init", "--quiet", env=git_env, cwd=fixture)
        run("git", "add", ".", env=git_env, cwd=fixture)
        run("git", "commit", "--quiet", "-m", "fixture", env=git_env, cwd=fixture)

        added = json.loads(codex("plugin", "marketplace", "add", str(fixture), "--json", home=cache_home))
        assert added["marketplaceName"] == "iron-box"
        listed = json.loads(codex("plugin", "list", "--marketplace", "iron-box", "--available", "--json", home=cache_home))
        assert len(listed["available"]) == 1
        assert listed["available"][0]["pluginId"] == "iron-box@iron-box"
        assert listed["available"][0]["installed"] is False
        installed = json.loads(codex("plugin", "add", "iron-box@iron-box", "--json", home=cache_home))
        cached_root = Path(installed["installedPath"])
        assert cached_root.is_dir() and cached_root != fixture
        final = json.loads(codex("plugin", "list", "--json", home=cache_home))
        assert final["installed"][0]["enabled"] is True
        source = final["installed"][0]["source"]
        assert source.get("source") == "local"
        assert Path(source["path"]).resolve() == fixture.resolve()

        for relative in (*SKILLS, *ROLES):
            target = cached_root / relative
            assert target.is_file(), f"missing cached runtime payload: {relative}"
        onboarding = cached_root / "skills/iron-box-onboarding/SKILL.md"
        assert onboarding.stat().st_size <= MAX_SKILL_BYTES, (
            f"cached onboarding SKILL.md exceeds {MAX_SKILL_BYTES} bytes: "
            f"{onboarding.stat().st_size}"
        )
        assert (cached_root / "iron-box-package.json").is_file(), (
            "cached runtime payload is missing iron-box-package.json"
        )
        run(sys.executable, "scripts/iron_box.py", "validate-package", env=os.environ.copy(), cwd=cached_root)
    print("marketplace E2E passed: local add, plugin add, active cache, skills, and role assets")


if __name__ == "__main__":
    main()
