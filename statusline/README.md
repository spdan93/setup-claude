# Statusline

Statusline de 3 linhas para o Claude Code: modelo (com tag `(1M)`), diretório, custo,
duração, tokens (↓in / ↑out), barra de uso de contexto, rate limits (5h / 7d com tempo
até reset), branch git + arquivos staged/modificados, link do repo e linhas +/-.

## Escolha o script do seu SO

| SO | Arquivo | Interpretador |
|----|---------|---------------|
| macOS | `statusline-command-macos.sh` | `bash` (usa `stat -f`, BSD) |
| Linux | `statusline-command-linux.sh` | `bash` (usa `stat -c`, GNU) |
| Windows | `statusline-command-windows.ps1` | Windows PowerShell 5.1+ (`powershell`) ou `pwsh` |

> As três produzem a mesma saída. A versão Windows usa glyphs ASCII no lugar de
> alguns ícones unicode, por compatibilidade de terminal.

## Como ligar (settings.json)

Adicione um bloco `statusLine` ao seu `settings.json` (do projeto em `.claude/` ou
global em `~/.claude/`). Escolha **uma** linha conforme o SO:

```jsonc
{
  // macOS / Linux (project-local)
  "statusLine": {
    "type": "command",
    "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/statusline/statusline-command-macos.sh\""
  }
}
```

```jsonc
{
  // macOS / Linux (global ~/.claude)
  "statusLine": {
    "type": "command",
    "command": "bash \"$HOME/.claude/statusline/statusline-command-linux.sh\""
  }
}
```

```jsonc
{
  // Windows (global)
  "statusLine": {
    "type": "command",
    "command": "powershell -NoProfile -File \"%USERPROFILE%\\.claude\\statusline\\statusline-command-windows.ps1\""
  }
}
```

## Dependências

- **macOS/Linux**: `jq`, `git`, `bc` (todos comuns; instale via brew/apt se faltar).
- **Windows**: PowerShell 5.1+ (nativo) e `git`. Não precisa de `jq` (usa `ConvertFrom-Json`).

## Permissão de execução (macOS/Linux)

```bash
chmod +x .claude/statusline/statusline-command-*.sh
```

## Caching

Status de git é cacheado por 5s e o link do repo por 30s (em `/tmp` ou `%TEMP%`),
pra não rodar `git` a cada render.
