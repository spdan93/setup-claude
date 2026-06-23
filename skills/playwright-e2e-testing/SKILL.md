---
name: playwright-e2e-testing
description: Comprehensive Playwright E2E testing guide covering best practices, common patterns, performance optimization, debugging strategies, and test architecture. Use when helping with Playwright tests for user flows (login, checkout, etc.), OAuth authentication, event testing, API testing, visual regression, performance optimization, test organization, debugging flaky tests, or improving overall test coverage and reliability.
---

# Playwright E2E Testing Skill

This skill provides expert guidance for creating, optimizing, and maintaining high-quality Playwright E2E tests.

## Quick Start

### When to Use This Skill

Use this skill when working with Playwright tests for:

- **User flows**: Login, checkout, onboarding, search
- **Authentication**: OAuth, session-based, token-based, SSO
- **Event testing**: Custom events, analytics, DOM mutations
- **API testing**: REST endpoints, GraphQL, WebSocket
- **Visual regression**: Screenshots, component snapshots
- **Performance**: Slow tests, optimization, profiling
- **Debugging**: Flaky tests, timing issues, selector problems
- **Architecture**: Test organization, Page Objects, fixtures

## Core Knowledge

### Essential Patterns

**1. Always use web-first assertions:**
```javascript
// ✅ Good - auto-waits and retries
await expect(page.getByText('Success')).toBeVisible();

// ❌ Bad - no auto-waiting
const text = await page.textContent('.message');
expect(text).toBe('Success');
```

**2. Prioritize accessible selectors:**
```javascript
// Best to worst:
page.getByRole('button', { name: 'Submit' })  // ✅ Semantic
page.getByLabel('Email')                      // ✅ For forms
page.getByText('Welcome')                     // ⚠️ OK if unique
page.locator('[data-testid="submit"]')       // ⚠️ Last resort
page.locator('.btn-primary')                  // ❌ Fragile
```

**3. Use Page Object Model for reusability:**
```javascript
class LoginPage {
  constructor(page) {
    this.page = page;
    this.emailInput = page.getByLabel('Email');
    this.submitButton = page.getByRole('button', { name: 'Sign in' });
  }
  
  async login(email, password) {
    await this.emailInput.fill(email);
    // ... rest of login flow
  }
}
```

### Quick Solutions

**OAuth Flow Testing:**
```javascript
test('OAuth login', async ({ page, context }) => {
  await page.goto('/login');
  await page.getByRole('button', { name: 'Sign in with Google' }).click();
  
  const popup = await context.waitForEvent('page');
  await popup.getByLabel('Email').fill('test@gmail.com');
  await popup.getByLabel('Password').fill('password');
  await popup.getByRole('button', { name: 'Sign in' }).click();
  
  await page.waitForURL('**/dashboard');
});
```

**Event Testing:**
```javascript
test('custom event fires', async ({ page }) => {
  const eventPromise = page.evaluate(() => {
    return new Promise(resolve => {
      document.addEventListener('userAction', (e) => {
        resolve(e.detail);
      }, { once: true });
    });
  });
  
  await page.getByRole('button', { name: 'Submit' }).click();
  const eventData = await eventPromise;
  expect(eventData.action).toBe('submit');
});
```

**Speed up tests with auth state:**
```javascript
// global-setup.js - login once
await page.goto('/login');
await page.getByLabel('Email').fill('test@example.com');
await page.getByLabel('Password').fill('password');
await page.getByRole('button', { name: 'Sign in' }).click();
await page.context().storageState({ path: 'auth.json' });

// tests - reuse auth
test.use({ storageState: 'auth.json' });
```

## Reference Documentation

For detailed guidance on specific topics, read the appropriate reference file:

### Best Practices (`references/best-practices.md`)
Read when you need:
- Core principles and guidelines
- Maintainable selector strategies
- Test isolation techniques
- Assertion patterns
- Test organization structure
- Coverage strategy
- Anti-patterns to avoid

### Testing Patterns (`references/patterns.md`)
Read when implementing:
- **Authentication flows**: OAuth, session-based, API tokens
- **Event testing**: Custom events, analytics, DOM mutations
- **API testing**: REST, GraphQL, request/response validation
- **Form testing**: Validation, file uploads, multi-step forms
- **Navigation**: Multi-step flows, back button, deep linking
- **WebSocket testing**: Real-time communication
- **Visual regression**: Screenshots, component snapshots
- **Mobile testing**: Responsive design, touch events
- **Accessibility testing**: ARIA, keyboard navigation

### Performance Optimization (`references/optimization.md`)
Read when:
- Tests are slow (>10s per test)
- Need to reduce execution time
- Optimizing for CI/CD
- Dealing with network bottlenecks
- Setting up parallel execution
- Profiling test performance
- Reducing flakiness

Covers:
- Optimal configuration
- Authentication state reuse
- Network optimization (blocking resources, mocking)
- API setup/teardown
- Parallel execution
- Smart waiting strategies
- CI/CD optimization
- Performance monitoring

### Debugging (`references/debugging.md`)
Read when:
- Tests fail unexpectedly
- Dealing with flaky tests
- Need to inspect page state
- Troubleshooting selectors
- Analyzing network issues
- Understanding timing problems

Includes:
- Debug mode and UI mode
- Trace viewer usage
- Console debugging
- Network monitoring
- Screenshot debugging
- Selector debugging
- State inspection
- Common issues and solutions

### Test Architecture (`references/architecture.md`)
Read when:
- Setting up a new test project
- Need test organization guidance
- Implementing Page Object Model
- Creating custom fixtures
- Structuring test suites
- Managing test data
- Configuring environments

Covers:
- Project structure
- Page Object Model patterns
- Component classes
- Custom fixtures
- Test organization strategies
- Environment configuration
- Global setup/teardown
- Best practices

## Utility Scripts

### Authentication Setup (`scripts/auth-setup.js`)

Automates authentication state creation for faster test execution.

**Usage:**
```bash
# With default config
node scripts/auth-setup.js

# With custom credentials
node scripts/auth-setup.js --email user@test.com --password pass123

# With config file
node scripts/auth-setup.js --config auth-config.json
```

**In tests:**
```javascript
test.use({ storageState: 'auth.json' });
```

### Performance Analyzer (`scripts/performance-analyzer.js`)

Analyzes test execution times and identifies bottlenecks.

**Usage:**
```bash
# Analyze latest results
node scripts/performance-analyzer.js

# With custom threshold
node scripts/performance-analyzer.js --threshold 3000

# Custom report path
node scripts/performance-analyzer.js --report-path ./results.json
```

**Provides:**
- Test execution summary
- Slow test identification
- Performance grade
- Optimization recommendations

## Templates

### Playwright Config (`assets/playwright.config.template.js`)

Optimized configuration template with:
- Parallel execution
- Retry logic for CI
- Multiple browser projects
- Authentication state
- Performance settings
- Reporter configuration

### Global Setup (`assets/global-setup.template.js`)

Template for:
- Authentication setup
- Test data seeding
- Service initialization

### Test Template (`assets/test-template.spec.js`)

Comprehensive test file template with:
- Proper test structure
- Descriptive test cases
- Authentication examples
- API testing
- Mobile testing
- Slow test handling
- Cross-browser tests

## Common Workflows

### 1. Testing OAuth Flow

1. Read `references/patterns.md` (Authentication Patterns section)
2. Implement OAuth flow with popup handling
3. Consider saving auth state for reuse
4. Test token expiration scenarios

### 2. Improving Slow Tests

1. Run `scripts/performance-analyzer.js` to identify bottlenecks
2. Read `references/optimization.md`
3. Apply recommended techniques:
   - Block unnecessary resources
   - Use auth state
   - Mock slow APIs
   - Enable parallel execution

### 3. Testing Event Interactions

1. Read `references/patterns.md` (Event Testing section)
2. Use `page.evaluate()` to listen for events
3. Verify event data and timing
4. Test event bubbling if needed

### 4. Setting Up New Test Project

1. Copy `assets/playwright.config.template.js` to project
2. Copy `assets/global-setup.template.js` if needed
3. Use `scripts/auth-setup.js` to create auth state
4. Read `references/architecture.md` for structure
5. Create Page Objects following patterns in Architecture guide
6. Use `assets/test-template.spec.js` for new tests

### 5. Debugging Flaky Tests

1. Enable trace collection: `trace: 'on-first-retry'`
2. Read `references/debugging.md`
3. Use UI mode: `npx playwright test --ui`
4. Check for:
   - Race conditions
   - Network timing issues
   - Animation timing
   - Selector stability

### 6. Optimizing for CI/CD

1. Read `references/optimization.md` (CI/CD section)
2. Configure workers: `workers: process.env.CI ? 4 : 2`
3. Enable sharding for parallel execution
4. Use retries: `retries: process.env.CI ? 2 : 0`
5. Collect artifacts only on failure

## Best Practices Summary

1. **Use web-first assertions** - Auto-waiting and retries
2. **Prioritize accessible selectors** - Role, label, text over CSS
3. **Implement Page Objects** - Reusability and maintainability
4. **Enable parallel execution** - Faster test runs
5. **Reuse authentication state** - Skip repetitive logins
6. **Mock slow APIs** - Focus on UI testing
7. **Collect traces on failure** - Better debugging
8. **Use custom fixtures** - Clean test setup
9. **Tag tests appropriately** - @critical, @slow, @mobile
10. **Monitor performance** - Track and optimize regularly

## When to Read Full References

- **Starting new project**: Read Architecture → Best Practices → Patterns
- **Optimizing existing tests**: Read Optimization → Performance Analyzer
- **Debugging issues**: Read Debugging → check specific issue
- **Implementing new patterns**: Read Patterns → find relevant section
- **General improvement**: Read Best Practices → apply recommendations

## Key Principles

1. Test user-visible behavior, not implementation
2. Maintain test isolation and independence
3. Optimize for readability and maintainability
4. Balance speed with reliability
5. Focus on critical paths first
6. Monitor and improve continuously

## Advanced Topics

For advanced scenarios not covered here:
- Check official Playwright documentation
- Review reference files for specific patterns
- Use utility scripts for automation
- Customize templates for project needs
- Profile tests individually for deep optimization
