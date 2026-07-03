---
date: {{YYYY-MM-DD}}
time: {{HH:MM}}
author: {{git config user.name}}
branch: {{branch}}
type: {{feat|fix|refactor|docs|...}}
scope: {{scope}}
commit_title: {{type(scope): title [ISSUE-ID?]}}
files_changed: {{N}}
issue: {{ISSUE-ID|null}}
---

# {{commit title}}

## Causa
{{why the change was necessary}}

## Mudanças
{{files / functions / components changed}}

## Consequência
{{impact / result}}

## Funcionalidade
{{how it works}}

## Ganho
{{technical or business benefit}}

## Arquivos
{{- one bullet per changed file path}}
