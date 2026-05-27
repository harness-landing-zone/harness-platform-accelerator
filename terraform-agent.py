#!/usr/bin/env python3
"""
Terraform Agent for Harness Platform Accelerator

This agent generates Terraform/OpenTofu configuration files based on natural language prompts,
following the patterns and architecture defined in CLAUDE.md.

Usage:
    python terraform-agent.py "Create a new organization called DevOps Team with admin and viewer groups"
    python terraform-agent.py "Add a GCP connector for project cloud-infra with OIDC auth"
"""

import os
import sys
import yaml
import anthropic
from pathlib import Path
import argparse
import json

# Configuration
CLAUDE_MODEL = "claude-sonnet-4-6"
CONFIGS_ROOT = Path(__file__).parent / "platform-configs"
TEMPLATES_ROOT = Path(__file__).parent / "templates"

# Load CLAUDE.md for context
CLAUDE_MD_PATH = Path(__file__).parent / "CLAUDE.md"

class TerraformAgent:
    def __init__(self, api_key: str = None):
        self.client = anthropic.Anthropic(api_key=api_key or os.environ.get("ANTHROPIC_API_KEY"))
        self.system_prompt = self._load_system_prompt()

    def _load_system_prompt(self) -> str:
        """Load CLAUDE.md and build system prompt."""
        claude_md = ""
        if CLAUDE_MD_PATH.exists():
            claude_md = CLAUDE_MD_PATH.read_text()

        return f"""You are a Terraform/OpenTofu code generator for the Harness Platform Accelerator.

{claude_md}

Your role is to:
1. Parse natural language prompts about Harness infrastructure
2. Determine the appropriate scope (account/org/project)
3. Generate correctly structured YAML configuration files following the patterns above
4. Output valid Terraform/OpenTofu commands to apply the changes
5. Ensure identifiers follow naming conventions (lowercase, spaces→underscores, dashes→underscores)

When generating files:
- Follow the directory structure in platform-configs/
- Use proper YAML syntax with appropriate fields for each resource type
- Include tags, descriptions, and all required fields
- Reference built-in resources with _ prefix (_organization_admin, etc.)
- For connectors, use the correct auth method pattern (OIDC, IRSA, manual, etc.)
- For services, support multi-scope (account/org/project) placement

Output format:
1. **Analysis**: Brief summary of what will be created and at what scope
2. **Files**: Complete file paths and YAML content
3. **Commands**: Exact Terraform/OpenTofu commands to run
4. **Validation**: Any caveats or manual steps required

Be precise and follow the established patterns exactly."""

    def generate(self, prompt: str) -> dict:
        """Generate Terraform configuration from natural language prompt."""

        # Check for existing config structure to provide context
        context_files = []
        if CONFIGS_ROOT.exists():
            for org_dir in (CONFIGS_ROOT / "organizations").glob("*"):
                if org_dir.is_dir():
                    config_file = org_dir / "config.yaml"
                    if config_file.exists():
                        context_files.append({
                            "path": str(config_file.relative_to(Path(__file__).parent)),
                            "content": config_file.read_text()[:500]  # First 500 chars
                        })

        context_summary = "\n".join([
            f"Existing: {f['path']}" for f in context_files[:5]
        ]) if context_files else "No existing configurations found."

        messages = [
            {
                "role": "user",
                "content": f"""Generate Terraform configuration for the following request:

{prompt}

Current repository context:
{context_summary}

Provide:
1. Analysis of what will be created
2. Complete file paths and YAML content for all required files
3. Terraform/OpenTofu commands to execute
4. Any validation notes or manual steps

Format your response as JSON with keys: analysis, files (array of {{path, content}}), commands (array), notes"""
            }
        ]

        response = self.client.messages.create(
            model=CLAUDE_MODEL,
            max_tokens=4096,
            system=self.system_prompt,
            messages=messages
        )

        # Parse response
        response_text = response.content[0].text

        # Try to extract JSON if wrapped in markdown
        if "```json" in response_text:
            json_start = response_text.find("```json") + 7
            json_end = response_text.find("```", json_start)
            response_text = response_text[json_start:json_end].strip()

        try:
            result = json.loads(response_text)
        except json.JSONDecodeError:
            # Fallback: return raw response
            result = {
                "analysis": "See raw response below",
                "files": [],
                "commands": [],
                "notes": response_text
            }

        return result

    def write_files(self, files: list, dry_run: bool = True):
        """Write generated files to disk."""
        for file_info in files:
            file_path = Path(file_info["path"])
            content = file_info["content"]

            if dry_run:
                print(f"\n{'='*80}")
                print(f"File: {file_path}")
                print(f"{'='*80}")
                print(content)
            else:
                file_path.parent.mkdir(parents=True, exist_ok=True)
                file_path.write_text(content)
                print(f"✓ Written: {file_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Terraform Agent for Harness Platform Accelerator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python terraform-agent.py "Create org called Platform Team with admin group"
  python terraform-agent.py "Add AWS connector with IRSA auth for org DevOps"
  python terraform-agent.py --apply "Add production environment to project backend-services"
        """
    )
    parser.add_argument("prompt", help="Natural language description of infrastructure to create")
    parser.add_argument("--apply", action="store_true", help="Write files to disk (default: dry-run)")
    parser.add_argument("--api-key", help="Anthropic API key (or set ANTHROPIC_API_KEY env var)")

    args = parser.parse_args()

    # Initialize agent
    try:
        agent = TerraformAgent(api_key=args.api_key)
    except Exception as e:
        print(f"Error: Failed to initialize agent. Make sure ANTHROPIC_API_KEY is set.")
        print(f"Details: {e}")
        sys.exit(1)

    # Generate configuration
    print(f"🤖 Generating Terraform configuration...")
    print(f"Prompt: {args.prompt}\n")

    result = agent.generate(args.prompt)

    # Display analysis
    print(f"\n{'='*80}")
    print("ANALYSIS")
    print(f"{'='*80}")
    print(result.get("analysis", "No analysis provided"))

    # Display files
    if result.get("files"):
        print(f"\n{'='*80}")
        print("GENERATED FILES")
        print(f"{'='*80}")
        agent.write_files(result["files"], dry_run=not args.apply)

    # Display commands
    if result.get("commands"):
        print(f"\n{'='*80}")
        print("COMMANDS TO RUN")
        print(f"{'='*80}")
        for cmd in result["commands"]:
            print(f"  {cmd}")

    # Display notes
    if result.get("notes"):
        print(f"\n{'='*80}")
        print("NOTES")
        print(f"{'='*80}")
        print(result["notes"])

    # Summary
    if not args.apply:
        print(f"\n{'='*80}")
        print("DRY RUN MODE - No files written")
        print("Add --apply flag to write files to disk")
        print(f"{'='*80}")


if __name__ == "__main__":
    main()
