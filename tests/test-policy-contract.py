"""Guard the text-level governance contract against accidental weakening."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
POLICY_FILES = (
    ROOT / "skills/iron-box-orchestration/SKILL.md",
    ROOT / "assets/codex/agents/terra-manager.toml",
    ROOT / "assets/codex/agents/luna-verifier.toml",
    ROOT / "assets/codex/agents/sol-advisor.toml",
    ROOT / "templates/AGENTS.global.recommended.md",
    ROOT / "docs/durable-task-state.md",
    ROOT / "README.md",
)


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8").lower()


def require_all(text: str, clauses: tuple[str, ...], owner: str) -> None:
    missing = [clause for clause in clauses if clause.lower() not in text]
    assert not missing, f"{owner} is missing policy clauses: {missing}"


def test_completion_gate_and_context_discipline_are_explicit() -> None:
    text = "\n".join(path.read_text(encoding="utf-8") for path in POLICY_FILES)
    required = (
        "Every claimed completion",
        "fresh",
        "read-only independent",
        "including trivial work",
        "goal/protected constraints",
        "declared scope",
        "actual diff",
        "exact commands",
        "deviations",
        "capability claims",
        "out-of-scope",
        "unapproved",
        "unsupported",
        "Deterministic evidence",
        "never bypass",
        "Before interrupting",
        "active status",
        "Never",
        "disjoint",
        "justified cost/time benefit",
        "causally distinct",
    )
    missing = [phrase for phrase in required if phrase.lower() not in text.lower()]
    assert not missing, f"missing policy clauses: {missing}"


def test_default_verifier_does_not_make_sol_mandatory() -> None:
    text = (ROOT / "skills/iron-box-orchestration/SKILL.md").read_text(
        encoding="utf-8"
    )
    assert "default is a Luna verifier" in text
    assert "Sol is used\n   only when proportional high-judgment review is warranted" in text


def test_responsibilities_are_enforced_per_policy_owner() -> None:
    require_all(
        read("assets/codex/agents/terra-manager.toml"),
        (
            "before interrupting, respawning, or fanning out",
            "active status",
            "never replace an active worker",
            "every claimed completion",
            "fresh read-only independent",
            "completion review",
            "goal/protected constraints",
            "declared scope",
            "actual diff/artifacts",
            "exact commands/results",
            "deviations/workarounds",
            "capability claims",
            "pass requires all four plus evidence",
        ),
        "Terra manager",
    )
    require_all(
        read("assets/codex/agents/luna-verifier.toml"),
        (
            "completion review",
            "goal/protected constraints",
            "declared scope",
            "exact commands/results",
            "criterion coverage",
            "out-of-scope",
            "unapproved",
            "unsupported or unobserved",
            "fresh review is required",
        ),
        "Luna verifier",
    )
    require_all(
        read("skills/iron-box-orchestration/SKILL.md"),
        (
            "every claimed completion, including trivial work",
            "never a bypass",
            "default is a luna verifier",
            "sol is used",
            "only when proportional high-judgment review is warranted",
            "trivial low-risk work may use a compact packet",
        ),
        "orchestration skill",
    )
    require_all(
        read("docs/durable-task-state.md"),
        (
            "before interrupting, respawning, or fanning out",
            "record a concise rationale",
            "before canonical completion",
            "fresh read-only independent",
            "completion",
            "a claim is never a verified",
            "do not advance a requirement record",
            "deterministic evidence is",
            "never a bypass",
        ),
        "durable task state",
    )


if __name__ == "__main__":
    test_completion_gate_and_context_discipline_are_explicit()
    test_default_verifier_does_not_make_sol_mandatory()
    test_responsibilities_are_enforced_per_policy_owner()
    print("policy contract tests passed")
