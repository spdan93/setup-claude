---
name: microservices-analyzer
description: Comprehensive architectural analysis and documentation generation for microservices systems using only repository access. Use when users need to (1) Analyze microservices architecture from code, (2) Generate C4 diagrams and architecture documentation, (3) Create service catalogs and dependency matrices, (4) Assess technical debt and security, (5) Document APIs and event flows, (6) Perform architecture reviews or onboarding documentation. Triggers on requests like "analyze the architecture", "document microservices", "create C4 diagrams", "map service dependencies", or "generate architecture report".
---

# Microservices Analyzer

## Overview

Performs deep architectural analysis of microservices systems by reading code repositories to reverse-engineer comprehensive documentation including C4 diagrams, service catalogs, dependency matrices, and technical assessments.

## Analysis Workflow

Analyze microservices architecture following these sequential phases:

### Phase 1: Discovery and Inventory
1. Map repository structure (monorepo vs multi-repo)
2. Identify all services using markers:
   - Build files: `package.json`, `pom.xml`, `go.mod`, `requirements.txt`
   - Deploy configs: `Dockerfile`, `docker-compose.yml`, K8s manifests
   - Service directories: `/services`, `/apps`, `/cmd`
3. Create initial inventory with confidence levels

### Phase 2: Deep Service Analysis
For EACH service, analyze:
1. **Stack**: Dependencies, frameworks, versions
2. **APIs**: REST/GraphQL/gRPC endpoints from code
3. **Data**: Databases, schemas, migrations
4. **Communication**: Service calls, message queues
5. **Security**: Auth patterns, secrets handling
6. **Observability**: Logging, metrics, tracing
7. **Testing**: Coverage, test types

### Phase 3: System Correlation
1. Build dependency graph (service→service, service→infra)
2. Identify domain boundaries and bounded contexts
3. Trace critical business flows
4. Detect architectural patterns (API Gateway, CQRS, Saga)

### Phase 4: Documentation Generation
1. Executive Summary with confidence levels
2. Service Catalog (detailed matrix)
3. C4 Diagrams (System, Container, Component)
4. Flow diagrams (Sequence, Data, Event)
5. Technical assessments (Security, Debt, Quality)

## Confidence Marking

Mark ALL findings with confidence levels:
- **HIGH**: Directly observable in code/configs
- **MEDIUM**: Strongly inferred from patterns  
- **LOW**: Educated guess with rationale
- **UNKNOWN**: Not derivable from code alone

Example:
```markdown
**Authentication**: JWT-based [HIGH - jwt library in package.json]
**Scale capacity**: ~10K users [LOW - no explicit configs found]
**Multi-tenancy**: Unknown (not derivable from code)
```

## Quick Start

For complete analysis:
```bash
# Run full architecture analysis
python scripts/analyze_structure.py .
python scripts/map_dependencies.py
python scripts/generate_c4.py
```

For specific artifacts:
```bash
# Generate only API documentation
python scripts/extract_apis.py --output api_catalog.md

# Create dependency matrix
python scripts/map_dependencies.py --format matrix

# Detect technical debt
python scripts/analyze_tech_debt.py --threshold medium
```

## Service Analysis Patterns

### Identifying Services

Service indicators by language:

**Node.js/JavaScript**:
```javascript
// Look for package.json with:
"scripts": { "start": "node server.js" }
// Main files: index.js, app.js, server.js
// Frameworks: express, fastify, nestjs, koa
```

**Java/Spring**:
```java
// Look for @SpringBootApplication
// Build files: pom.xml, build.gradle
// Main class with public static void main
```

**Python**:
```python
# Frameworks: Flask, FastAPI, Django
# Entry points: app.py, main.py, wsgi.py
# Requirements: requirements.txt, Pipfile
```

**Go**:
```go
// Look for main package
// go.mod file with module declaration
// cmd/ directory structure
```

### API Extraction Patterns

Extract endpoints from:

**REST APIs**:
```javascript
// Express: app.get('/users', ...)
// Spring: @GetMapping("/users")
// FastAPI: @app.get("/users")
// Gin: router.GET("/users", ...)
```

**GraphQL**:
```graphql
# Schema files: *.graphql
# Resolvers in code
# Type definitions
```

**gRPC**:
```protobuf
// *.proto files
service UserService {
  rpc GetUser(GetUserRequest) returns (User);
}
```

### Dependency Detection

Service communication patterns:
```javascript
// HTTP calls
axios.get('http://user-service/api/users')
fetch(`${process.env.ORDER_SERVICE_URL}/orders`)

// Message queues
kafka.producer.send('order.created', payload)
channel.consume('user.events', handler)

// Service discovery
consul.health.service('payment-service')
```

## Output Templates

### Service Catalog Entry
```markdown
| Service | user-service |
|---------|-------------|
| **Path** | `/services/user` |
| **Stack** | Node.js 18, Express 4.18 [HIGH] |
| **Purpose** | User authentication and management [HIGH] |
| **APIs** | REST: 12 endpoints [HIGH] |
| **Database** | PostgreSQL 14 [HIGH] |
| **Dependencies** | auth-service, email-service [MEDIUM] |
| **Test Coverage** | 78% [HIGH] |
| **Confidence** | HIGH (code verified) |
```

### C4 Diagram Structure
See `references/c4-templates.md` for complete C4 diagram templates and Mermaid syntax.

### Technical Debt Entry
```markdown
**TD-001**: Deprecated MongoDB driver
- Service: order-service
- Evidence: `package.json:18` - mongodb v2.2.36
- Impact: Security vulnerabilities [HIGH]
- Fix: Upgrade to v6.x [HIGH confidence]
```

## Advanced Analysis

### Pattern Detection

For architectural patterns, check:
- **API Gateway**: Central routing service, path rewriting
- **BFF**: Frontend-specific APIs, GraphQL aggregation
- **CQRS**: Separate read/write models, event sourcing
- **Saga**: Distributed transaction orchestration
- **Circuit Breaker**: Resilience patterns (Hystrix, Polly)

### Security Assessment

Analyze:
```yaml
Authentication:
  - JWT validation middleware
  - OAuth2 flows
  - API key management

Authorization:
  - Role-based checks (@PreAuthorize, hasRole)
  - Permission guards
  - Multi-tenancy isolation

Secrets:
  - Environment variables usage
  - Vault/SecretManager integration
  - Encrypted configs (SOPS, sealed-secrets)
```

### Quality Metrics

Calculate per service:
- Lines of code (use `cloc` or parse files)
- Cyclomatic complexity (from linters)
- Test coverage (from test configs)
- Dependency freshness (outdated packages)
- Code duplication (pattern matching)

## Resources

### scripts/
- `analyze_structure.py` - Repository and service discovery
- `extract_apis.py` - API endpoint extraction
- `map_dependencies.py` - Service dependency mapping
- `generate_c4.py` - C4 diagram generation
- `analyze_tech_debt.py` - Technical debt detection

### references/
- `c4-templates.md` - C4 diagram templates and examples
- `analysis-patterns.md` - Code analysis patterns by language
- `confidence-levels.md` - Detailed confidence marking guide
- `artifact-templates.md` - Documentation templates

### assets/
- `report-template/` - Markdown report structure
- `diagram-styles/` - Mermaid and PlantUML styles
