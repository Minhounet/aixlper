#!/usr/bin/env python3
"""
Validate every skill under skills/ against this repo's portability rules
(see CLAUDE.md): a well-formed SKILL.md, and frontmatter limited to the
subset that both Claude Code and Gemini CLI read.

Usage:
    python3 scripts/validate_skills.py [skills-dir]
"""

import sys
from pathlib import Path

import yaml

# Frontmatter keys understood by both Claude Code and Gemini CLI.
PORTABLE_KEYS = {"name", "description"}

# Known Claude Code-only frontmatter keys. Allowed, but only for a skill
# whose description says up front that it's Claude-only.
CLAUDE_ONLY_KEYS = {"allowed-tools", "model"}


def parse_frontmatter(text, skill_md):
    if not text.startswith("---"):
        raise ValueError(f"{skill_md}: missing YAML frontmatter (must start with '---')")
    parts = text.split("---", 2)
    if len(parts) < 3:
        raise ValueError(f"{skill_md}: frontmatter is not closed with a second '---'")
    try:
        data = yaml.safe_load(parts[1]) or {}
    except yaml.YAMLError as e:
        raise ValueError(f"{skill_md}: invalid YAML frontmatter: {e}")
    if not isinstance(data, dict):
        raise ValueError(f"{skill_md}: frontmatter must be a YAML mapping")
    return data


EXCLUDED_DIR_PARTS = {"__pycache__", "node_modules"}
ROOT_EXCLUDED_DIR_PARTS = {"evals"}


def _counts_as_skill_md(rel_path):
    """True if a SKILL.md at rel_path (relative to the skill dir) is part of the skill."""
    dir_parts = rel_path.parts[:-1]
    if any(part in EXCLUDED_DIR_PARTS for part in dir_parts):
        return False
    if dir_parts and dir_parts[0] in ROOT_EXCLUDED_DIR_PARTS:
        return False
    return True


def validate_skill(skill_dir):
    """Returns (errors, warnings) for one skills/<name>/ directory."""
    errors, warnings = [], []

    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        errors.append(f"{skill_dir.name}: no SKILL.md found at {skill_dir.name}/SKILL.md")
        return errors, warnings

    skill_md_files = [
        p for p in skill_dir.rglob("SKILL.md")
        if _counts_as_skill_md(p.relative_to(skill_dir))
    ]
    extras = [p for p in skill_md_files if p.resolve() != skill_md.resolve()]
    if extras:
        errors.append(
            f"{skill_dir.name}: extra SKILL.md file(s) found: "
            f"{', '.join(str(p.relative_to(skill_dir)) for p in extras)} "
            "(a skill must contain exactly one, at <name>/SKILL.md)"
        )

    text = skill_md.read_text(encoding="utf-8")
    try:
        frontmatter = parse_frontmatter(text, f"{skill_dir.name}/SKILL.md")
    except ValueError as e:
        errors.append(str(e))
        return errors, warnings

    for key in ("name", "description"):
        value = frontmatter.get(key)
        if not (isinstance(value, str) and value.strip()):
            errors.append(f"{skill_dir.name}/SKILL.md: frontmatter is missing required '{key}'")

    name = frontmatter.get("name")
    if isinstance(name, str) and name != skill_dir.name:
        errors.append(
            f"{skill_dir.name}/SKILL.md: frontmatter name '{name}' does not match "
            f"directory name '{skill_dir.name}'"
        )

    unknown_keys = set(frontmatter.keys()) - PORTABLE_KEYS - CLAUDE_ONLY_KEYS
    if unknown_keys:
        warnings.append(
            f"{skill_dir.name}/SKILL.md: unrecognized frontmatter key(s) "
            f"{sorted(unknown_keys)} - confirm these are portable or remove them"
        )

    claude_only_used = set(frontmatter.keys()) & CLAUDE_ONLY_KEYS
    if claude_only_used:
        description = frontmatter.get("description", "")
        if "claude" not in description.lower() and "claude-only" not in description.lower():
            warnings.append(
                f"{skill_dir.name}/SKILL.md: uses Claude-only key(s) {sorted(claude_only_used)} "
                "but description doesn't flag the skill as Claude-only"
            )

    return errors, warnings


def main():
    skills_dir = Path(sys.argv[1] if len(sys.argv) > 1 else "skills")
    if not skills_dir.is_dir():
        print(f"No such directory: {skills_dir}")
        return 1

    skill_dirs = sorted(p for p in skills_dir.iterdir() if p.is_dir())
    if not skill_dirs:
        print(f"No skills found under {skills_dir}/ (nothing to validate)")
        return 0

    all_errors, all_warnings = [], []
    for skill_dir in skill_dirs:
        errors, warnings = validate_skill(skill_dir)
        all_errors.extend(errors)
        all_warnings.extend(warnings)

    for w in all_warnings:
        print(f"WARNING: {w}")
    for e in all_errors:
        print(f"ERROR: {e}")

    print(f"\nChecked {len(skill_dirs)} skill(s): {len(all_errors)} error(s), {len(all_warnings)} warning(s)")
    return 1 if all_errors else 0


if __name__ == "__main__":
    sys.exit(main())
