# Claude Octopus Agents

This file describes the autonomous agents available in this repository for
AI coding tools that support agent discovery (e.g., GitHub Copilot coding agent).

## Available Agents

| Agent | Description | Tools |
|-------|-------------|-------|
| `backend-architect` | Scalable API design, microservices, distributed systems | Read-only |
| `code-reviewer` | Code quality, security vulnerabilities, production reliability | All |
| `debugger` | Errors, test failures, unexpected behavior | All |
| `docs-architect` | Technical documentation from codebases | All |
| `frontend-developer` | React components, responsive layouts, client-side state | All |
| `performance-engineer` | Optimization, observability, scalable performance | All |
| `security-auditor` | DevSecOps, OWASP compliance, vulnerability assessment | Read-only |
| `tdd-orchestrator` | Red-green-refactor discipline, test-driven development | All |
| `database-architect` | Data modeling, schema design, migration planning | All |
| `cloud-architect` | AWS/Azure/GCP infrastructure, IaC, FinOps | All |

## Agent Configuration

Agent definitions are in `agents/` as markdown files with YAML frontmatter.
Each agent specifies its system prompt, available tools, and optional `readonly: true`
for agents that should only read, not modify files.

## MCP Integration

The MCP server (`mcp-server/`) exposes Claude Octopus workflows as MCP tools.
For MCP-aware coding agents, connect to the MCP server rather than invoking
agents directly.
