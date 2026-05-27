#!/usr/bin/env python3
"""
Terraform Generator - Simple wrapper for Claude Code session

This script formats prompts for generating Harness Terraform configs.
It works with your active Claude Code session - no API key needed.

Usage:
    python tf-gen.py "Create org Platform Team with admin group"
    python tf-gen.py --apply "Add AWS connector to org DevOps"
"""

import sys
import argparse
from pathlib import Path

CONFIGS_ROOT = Path(__file__).parent / "platform-configs"

def format_prompt(user_request: str, apply: bool = False) -> str:
    """Format a prompt for Claude Code to generate Terraform configs."""

    # Check for existing context
    existing_orgs = []
    if CONFIGS_ROOT.exists():
        orgs_dir = CONFIGS_ROOT / "organizations"
        if orgs_dir.exists():
            existing_orgs = [d.name for d in orgs_dir.iterdir() if d.is_dir()]

    context = ""
    if existing_orgs:
        context = f"\n**Existing organizations:** {', '.join(existing_orgs[:5])}"
        if len(existing_orgs) > 5:
            context += f" (and {len(existing_orgs) - 5} more)"

    apply_instruction = ""
    if apply:
        apply_instruction = "\n\n**ACTION:** Write the files to disk (not just preview)."

    prompt = f"""Generate Harness Terraform configuration for:

**Request:** {user_request}
{context}

**Output format:**
1. **Analysis** - Brief summary of what will be created and scope level
2. **Files** - Complete file paths and YAML content for each file
3. **Commands** - Exact Terraform/OpenTofu commands to run
4. **Notes** - Any validation steps or manual actions needed

Follow patterns from CLAUDE.md. Use proper identifier derivation (lowercase, spaces→underscores).{apply_instruction}"""

    return prompt


def main():
    parser = argparse.ArgumentParser(
        description="Terraform Generator - Simple wrapper for Claude Code",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python tf-gen.py "Create org Platform Team with admin group"
  python tf-gen.py "Add AWS connector with IRSA auth to org DevOps"
  python tf-gen.py --apply "Add production environment to project backend"

This tool formats your request and outputs it for Claude Code to process.
No API key needed - it uses your active Claude Code session.
        """
    )
    parser.add_argument(
        "prompt",
        help="Natural language description of infrastructure to create"
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Request files be written to disk (not just preview)"
    )
    parser.add_argument(
        "--copy",
        action="store_true",
        help="Copy formatted prompt to clipboard (requires pyperclip)"
    )

    args = parser.parse_args()

    # Format the prompt
    formatted = format_prompt(args.prompt, args.apply)

    # Output
    print("="*80)
    print("TERRAFORM GENERATOR")
    print("="*80)
    print(f"\nOriginal request: {args.prompt}")
    print(f"Apply mode: {'Yes - will write files' if args.apply else 'No - preview only'}")
    print("\n" + "="*80)
    print("FORMATTED PROMPT FOR CLAUDE CODE")
    print("="*80)
    print(f"\n{formatted}\n")
    print("="*80)

    # Copy to clipboard if requested
    if args.copy:
        try:
            import pyperclip
            pyperclip.copy(formatted)
            print("✓ Copied to clipboard!")
        except ImportError:
            print("Note: Install pyperclip for clipboard support (pip install pyperclip)")
    else:
        print("Tip: Copy the formatted prompt above and paste it into Claude Code")
        print("     Or use --copy flag to copy automatically")

    print("="*80)


if __name__ == "__main__":
    main()
