# tf-gen - Terraform Generator Wrapper

A simple wrapper that formats prompts for generating Harness Terraform configs within your Claude Code session. No API key needed!

## Why This Tool?

Instead of making separate API calls (and paying extra), this tool works with your **active Claude Code session**. It formats your request into a clear prompt that Claude can process efficiently.

## Installation

```bash
# No dependencies required for basic usage
chmod +x tf-gen.py

# Optional: for clipboard support
pip install pyperclip
```

## Usage

### Basic (Preview Mode)

```bash
python tf-gen.py "Create organization Platform Team with admin group"
```

This outputs a formatted prompt. Copy and paste it to Claude Code.

### Apply Mode (Write Files)

```bash
python tf-gen.py --apply "Add AWS connector to org DevOps"
```

Adds instruction to write files to disk.

### With Clipboard

```bash
python tf-gen.py --copy "Add production environment to project backend"
```

Automatically copies formatted prompt to clipboard.

## Examples

### Create Organization

```bash
python tf-gen.py "Create org DevOps Team with admin and developer groups"
```

### Add Project

```bash
python tf-gen.py "Add project backend-api to org Platform Team"
```

### Add Resources

```bash
python tf-gen.py --apply "Add GCP connector with service account to project cloud-ops"
```

### Complex Request

```bash
python tf-gen.py "Create org Platform with projects frontend and backend, add production environments to both"
```

## Workflow

```
┌─────────────────┐
│   Your Prompt   │
└────────┬────────┘
         │
         v
┌─────────────────┐
│    tf-gen.py    │ Formats prompt with context
└────────┬────────┘
         │
         v
┌─────────────────┐
│  Claude Code    │ Generates configs
│   (this session)│
└────────┬────────┘
         │
         v
┌─────────────────┐
│  YAML Files +   │
│  TF Commands    │
└─────────────────┘
```

## What It Does

1. **Scans context** - Checks existing organizations
2. **Formats prompt** - Creates structured request with proper format
3. **Outputs** - Displays formatted prompt for Claude Code
4. **Optional clipboard** - Copies to clipboard for easy pasting

## What It Doesn't Do

- ❌ Make API calls (no cost!)
- ❌ Require API keys
- ❌ Execute Terraform commands
- ❌ Validate YAML syntax

## Comparison

| Feature | terraform-agent.py | tf-gen.py |
|---------|-------------------|-----------|
| API calls | Yes (paid) | No (free) |
| API key needed | Yes | No |
| Works in session | No | Yes |
| Formatting | JSON output | Structured prompt |
| Best for | Automation | Interactive use |

## Tips

**Quick iteration:**
```bash
# Generate multiple related configs
python tf-gen.py --copy "Create org Platform Team"
# Paste to Claude, review

python tf-gen.py --copy "Add project frontend to org Platform Team"
# Paste to Claude, review

python tf-gen.py --copy --apply "Add production env to project frontend"
# Paste to Claude, writes files
```

**Check context first:**
```bash
# tf-gen shows existing orgs automatically
python tf-gen.py "anything"
# Look at "Existing organizations" line
```

**Copy-paste workflow:**
```bash
python tf-gen.py --copy "your request"
# Now paste (Cmd+V) directly to Claude Code
```

## Output Format

The formatted prompt asks Claude to provide:

1. **Analysis** - What will be created, what scope
2. **Files** - Complete paths and YAML content
3. **Commands** - Exact `tofu` commands to run
4. **Notes** - Validation steps, manual actions

## Advanced Usage

### Custom Templates

Edit the prompt template in `tf-gen.py` to customize output format or add project-specific context.

### Integration with Scripts

```bash
#!/bin/bash
# generate-infra.sh
python tf-gen.py --copy "Create org $1 with admin group"
echo "Prompt copied - paste to Claude Code"
```

### Batch Requests

```bash
# requests.txt contains one prompt per line
while read prompt; do
    python tf-gen.py "$prompt"
    echo "Press enter to continue..."
    read
done < requests.txt
```

## Troubleshooting

**Nothing happens after running**
- Tool only formats the prompt
- Copy the output and paste it to Claude Code
- Or use `--copy` flag

**"No such file or directory" for platform-configs**
- Normal if starting fresh
- Tool will note "no existing organizations"

**Want automatic execution**
- Use `terraform-agent.py` instead (requires API key)
- Or use Claude Code's agent features directly

## Next Steps

After Claude generates the configs:

1. Review the YAML files
2. Run `tofu validate` to check syntax
3. Run `tofu plan` to preview changes
4. Run `tofu apply` to create resources
5. Verify in Harness UI

## See Also

- [terraform-agent.py](./terraform-agent.py) - Full agent with API calls
- [README-AGENT.md](./README-AGENT.md) - Agent documentation
- [CLAUDE.md](./CLAUDE.md) - Architecture patterns
