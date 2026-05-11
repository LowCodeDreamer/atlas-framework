---
description: Initialize a new domain in the current or specified folder
argument-hint: "[path]"
id: command_init_domain
type: command
created_at: 2025-12-23T14:46:00Z
---

# Init Domain

Initialize a new domain by creating a `_domain.md` file.

## Usage

```
/init-domain [path]
```

If no path provided, initializes in current working directory.

## Arguments

- `$1` — Optional: Path to folder (absolute or relative to Atlas root)
  - Example: `<domain>/marketing`
  - Example: `/Users/derek/${INSTANCE_HOME}/ventures/eno`
  - If omitted: uses current directory

## Workflow

### 1. Determine Target

```
IF $1 provided:
  target = resolve_path($1)
ELSE:
  target = current_working_directory

IF target is outside Atlas root:
  WARN: "Path is outside Atlas. Create domain anyway? (domains should live in Atlas)"
```

### 2. Check Existing

```
IF _domain.md exists in target:
  ASK: "Domain already exists. Update it? (y/n)"
  IF no: EXIT
  IF yes: LOAD existing domain for update
ELSE:
  CREATE new domain
```

### 3. Gather Information

For new domains, ask:

1. **Name:** "What should this domain be called?"
   - Default: folder name, title case

2. **Purpose:** "What is this domain about? (1-2 sentences)"

3. **Parent:** Auto-detect from folder structure
   - Check parent folders for `_domain.md`
   - If found: "Link to parent domain [name]? (y/n)"

4. **Related:** "Any related domains to link? (comma-separated paths or skip)"

### 4. Create Domain File

Invoke meta-domain agent pattern:

```markdown
---
id: domain_[path_underscored]
type: domain
parent: [parent_domain_id or null]
created_at: [now]
updated_at: [now]
version: 1
status: active
---

# [Domain Name]

[Purpose from input]

## Purpose

[Expanded purpose]

## Related Domains

- [[parent/_domain|Parent Name]] — Parent domain
- [[related/_domain|Related Name]] — [relationship]

## Expertise

- (none yet — use `/create-expertise` to add)

## Prompts

- (none yet — use `/create-prompt` to add)

## Skills

- (none yet — use `/create-skill` to add)

## Key Files

- (add key files as domain develops)

## External Resources

- Code repos: (none)
- Tools: (none)
- MCPs: (none)

## Notes

Domain initialized [date].
```

### 5. Offer Next Steps

```
📁 Domain created: [name]
📍 Location: [path]/_domain.md

Next steps:
- [ ] Create initial expertise? (recommended for new domains)
- [ ] Add key files to track?
- [ ] Link external resources?

Run `/create-expertise [domain]` to build the mental model.
```

## Examples

### New Domain

```
> /init-domain <domain>/clients/acme

What should this domain be called? [Acme]
> Acme Corp

What is this domain about?
> Enterprise client, implementing supply chain optimization

Link to parent domain "<Parent Domain>"? (y/n)
> y

Any related domains to link?
> <domain>/marketing

📁 Domain created: Acme Corp
📍 Location: <domain>/clients/acme/_domain.md
🔗 Parent: [[<domain>/clients/_domain|<Parent Domain>]]
🔗 Related: [[<domain>/marketing/_domain|<Sibling Domain>]]
```

### Update Existing

```
> /init-domain ventures/eno

Domain already exists. Update it? (y/n)
> y

Current purpose: "Digital sovereignty through modular home servers"
Update purpose? (enter new or press enter to keep)
>

Add related domains? (comma-separated or skip)
> personal/homelab

📁 Domain updated: Eno Project
📍 Location: ventures/eno/_domain.md
🔗 Added: [[personal/homelab/_domain|Homelab]]
```

## Related Commands

- `/create-expertise` — Create expertise for a domain
- `/create-prompt` — Create domain-specific prompts
- `/prime` — Load domain context for work session
