from __future__ import annotations

import pathlib
import re


FORBIDDEN_NAMES = (
    "codex", "python", "python3", "py", "bash", "sh", "zsh", "fish",
    "pwsh", "powershell", "cmd", "cmd.exe", "wscript", "cscript",
)
FORBIDDEN_COMMAND = re.compile(
    r"^(?:" + "|".join(re.escape(name) for name in FORBIDDEN_NAMES) + r")(?:\s|$)"
)
FORBIDDEN_SHELL_LINE = re.compile(
    r"^\s*(?:[$>#]\s*)?(?:" + "|".join(re.escape(name) for name in FORBIDDEN_NAMES) + r")(?:\s|$)"
)
FORBIDDEN_INSTALLER = re.compile(r"(?:apply-iron-box\.sh|iron_box\.py|--install-codex-roles)")
RESOLVED_RUNTIME_INSTALLER_MARKER = "resolved runtime installer sequence"


def check(path: pathlib.Path) -> None:
    in_fence = False
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        stripped = line.strip()
        if stripped.startswith("```"):
            in_fence = not in_fence
            continue
        if FORBIDDEN_SHELL_LINE.match(line):
            raise SystemExit(f"forbidden Desktop command invocation at {path}:{number}")
        if FORBIDDEN_INSTALLER.search(line) and RESOLVED_RUNTIME_INSTALLER_MARKER not in line.lower() and (
            in_fence or line.lstrip().startswith(("$", ">", "./", "scripts/"))
        ):
            raise SystemExit(f"forbidden Desktop command invocation at {path}:{number}")
        snippets = re.findall(r"`([^`]+)`", line)
        if in_fence:
            snippets.append(stripped)
        # The integrity gate states forbidden names as prose, not commands.
        if "must never execute" in line:
            snippets = [s for s in snippets if s not in set(FORBIDDEN_NAMES)]
        for snippet in snippets:
            command = snippet.strip().lstrip("$ ")
            if FORBIDDEN_COMMAND.match(command) or FORBIDDEN_INSTALLER.search(command):
                raise SystemExit(f"forbidden Desktop command invocation at {path}:{number}")


if __name__ == "__main__":
    root = pathlib.Path(__file__).resolve().parents[1]
    check(root / "skills" / "iron-box-onboarding" / "SKILL.md")
    print("Desktop user path contains no forbidden command invocation")
