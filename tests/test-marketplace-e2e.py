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
sys.path.insert(0, str(ROOT))
from scripts.iron_box import validate_package

CODEX = os.environ.get("CODEX_BIN", "codex")
SKILLS = (
    "skills/iron-box-onboarding/SKILL.md",
    "skills/iron-box-orchestration/SKILL.md",
    "skills/iron-box-durable-state/SKILL.md",
    "skills/iron-box-durable-state/agents/openai.yaml",
)
ROLES = (
    "assets/codex/agents/luna-worker.toml",
    "assets/codex/agents/luna-verifier.toml",
    "assets/codex/agents/sol-peer.toml",
)
JAX_ASSETS = (
    "assets/pets/jax/pet.json",
    "assets/pets/jax/spritesheet.webp",
)
BOOTSTRAP_TARGETS = {
    **{relative: relative.removeprefix("assets/codex/") for relative in ROLES},
    "assets/pets/jax/pet.json": "pets/jax/pet.json",
    "assets/pets/jax/spritesheet.webp": "pets/jax/spritesheet.webp",
}
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

        for relative in (*SKILLS, *ROLES, *JAX_ASSETS):
            target = cached_root / relative
            assert target.is_file(), f"missing cached runtime payload: {relative}"
        activation_home = temporary_root / "activated-codex-home"
        activation_home.mkdir()
        bootstrap_script = cached_root / "scripts/iron_box.py"
        bootstrap_env = os.environ.copy()
        bootstrap_env["CODEX_HOME"] = str(activation_home)
        bootstrap_output = run(
            sys.executable,
            str(bootstrap_script),
            "activate-package",
            str(activation_home),
            str(cached_root),
            env=bootstrap_env,
        )
        assert "bootstrap: activated 5 package files" in bootstrap_output
        for source_relative, target_relative in BOOTSTRAP_TARGETS.items():
            source = cached_root / source_relative
            target = activation_home / target_relative
            assert target.is_file(), f"bootstrap omitted cached payload: {target_relative}"
            assert target.read_bytes() == source.read_bytes(), (
                f"bootstrap payload differs from cache: {target_relative}"
            )
        onboarding = cached_root / "skills/iron-box-onboarding/SKILL.md"
        assert onboarding.stat().st_size <= MAX_SKILL_BYTES, (
            f"cached onboarding SKILL.md exceeds {MAX_SKILL_BYTES} bytes: "
            f"{onboarding.stat().st_size}"
        )
        assert (cached_root / "iron-box-package.json").is_file(), (
            "cached runtime payload is missing iron-box-package.json"
        )
        portable = json.loads((cached_root / "plugin.json").read_text(encoding="utf-8"))
        assert portable["$schema"] == (
            "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"
        )
        assert portable["name"] == "iron-box"
        assert portable["version"] == "0.3.0"
        assert not {"agents", "skills", "category"}.intersection(portable)
        # Validate the cached runtime package through the contributor checker
        # loaded from this checkout.  The installed plugin does not need to
        # ship CI tooling or expose a runtime Python entry point.
        validate_package(cached_root)
    print(
        "marketplace E2E passed: local add, plugin add, cached bootstrap, "
        "skills, roles, and Jax assets"
    )


if __name__ == "__main__":
    main()
