---
name: mcp-server-installation
description: Installing and configuring MCP servers for Claude Code. Use when setting up new MCP integrations, installing servers like Supabase or ClickUp, troubleshooting configurations, or managing MCP authentication.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

# MCP Server Installation

Install and configure Model Context Protocol (MCP) servers for Claude Code integration with external services.

## Workflow

### 1. Identify MCP Server Requirements

```bash
# Check if specific MCP server exists
npm search @modelcontextprotocol/server-[service-name]
# or
npm search mcp-server-[service-name]
```

### 2. Install MCP Server Package

```bash
# Install globally (recommended for Claude Code)
npm install -g @modelcontextprotocol/server-[service-name]

# Or install locally in project
npm install @modelcontextprotocol/server-[service-name]
```

### 3. Configure Claude Code Integration

Add to Claude Code configuration file (`~/.claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "server-name": {
      "command": "node",
      "args": [
        "/path/to/mcp/server",
        "--arg1", "value1",
        "--arg2", "value2"
      ],
      "env": {
        "API_KEY": "your-api-key",
        "DATABASE_URL": "your-connection-string"
      }
    }
  }
}
```

### 4. Service-Specific Configurations

#### Supabase MCP Server

```bash
# Install
npm install -g @modelcontextprotocol/server-supabase

# Configure in claude_desktop_config.json
{
  "mcpServers": {
    "supabase": {
      "command": "mcp-server-supabase",
      "env": {
        "SUPABASE_URL": "https://your-project.supabase.co",
        "SUPABASE_ANON_KEY": "your-anon-key"
      }
    }
  }
}
```

#### ClickUp MCP Server

```bash
# Install (example - check actual package name)
npm install -g mcp-server-clickup

# Configure in claude_desktop_config.json
{
  "mcpServers": {
    "clickup": {
      "command": "mcp-server-clickup",
      "env": {
        "CLICKUP_API_TOKEN": "your-clickup-token"
      }
    }
  }
}
```

#### Generic MCP Server Template

```json
{
  "mcpServers": {
    "custom-service": {
      "command": "node",
      "args": [
        "/usr/local/lib/node_modules/@modelcontextprotocol/server-custom/build/index.js"
      ],
      "env": {
        "SERVICE_API_KEY": "your-api-key",
        "SERVICE_BASE_URL": "https://api.service.com",
        "SERVICE_CONFIG": "additional-config"
      }
    }
  }
}
```

### 5. Restart Claude Code

```bash
# Quit Claude Code completely and restart
# MCP servers are loaded on startup
```

### 6. Verify Installation

- Check Claude Code for new MCP tools
- Test basic functionality with the new server
- Review Claude Code logs for connection errors

## Best Practices

### Security
- Store sensitive API keys in environment variables
- Use read-only keys when possible
- Regularly rotate API credentials
- Review MCP server permissions and scopes

### Performance
- Install MCP servers globally to avoid path issues
- Use specific versions to prevent breaking changes
- Monitor MCP server memory usage
- Configure timeouts appropriately

### Maintenance
- Keep MCP servers updated
- Document custom configurations
- Test after Claude Code updates
- Backup working configurations

### Configuration Management
- Use version control for configuration files
- Document all environment variables required
- Create setup scripts for team environments
- Test configurations in staging first

## Troubleshooting

### Common Issues

#### MCP Server Not Loading
```bash
# Check if server executable exists
which mcp-server-name

# Verify package installation
npm list -g | grep mcp-server

# Check Claude Code logs for startup errors
```

#### Authentication Failures
- Verify API keys are correct and active
- Check environment variable names match server expectations
- Ensure API keys have necessary permissions
- Test API access outside of MCP context

#### Connection Timeouts
- Increase timeout values in configuration
- Check network connectivity to service
- Verify service status and uptime
- Review firewall and proxy settings

#### Command Not Found
```bash
# Find exact path to installed server
npm root -g
ls $(npm root -g)/@modelcontextprotocol/

# Use full path in configuration
{
  "command": "/usr/local/lib/node_modules/@modelcontextprotocol/server-name/build/index.js"
}
```

### Debug Mode
Enable verbose logging by adding to environment:
```json
"env": {
  "DEBUG": "mcp:*",
  "NODE_ENV": "development"
}
```

### Testing MCP Server Independently
```bash
# Run server directly to test
node /path/to/mcp/server --test-mode

# Check server health endpoint (if available)
curl http://localhost:port/health
```

## Related Skills

- [[.claude/skills/n8n-integration/SKILL|n8n Integration]] — Workflow automation MCP

## External Resources

- [MCP Documentation](https://modelcontextprotocol.io/)
- [Claude Code MCP Guide](https://docs.anthropic.com/claude/reference/mcp)
- [Available MCP Servers](https://github.com/modelcontextprotocol)
- [Supabase MCP Server](https://github.com/modelcontextprotocol/servers/tree/main/src/supabase)

## Notes

- MCP servers run as separate processes and communicate with Claude Code via stdin/stdout
- Configuration changes require Claude Code restart
- Test MCP integrations thoroughly before deploying to production
- Keep documentation of all custom MCP server configurations
- Monitor MCP server resource usage and performance
