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

## Cause
{{why the change was necessary}}

## Changes
{{files / functions / components changed}}

## Consequence
{{impact / result}}

## Functionality
{{how it works}}

## Gain
{{technical or business benefit}}

## Files
{{- one bullet per changed file path}}
