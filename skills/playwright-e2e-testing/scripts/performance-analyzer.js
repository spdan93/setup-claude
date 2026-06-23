#!/usr/bin/env node

/**
 * Performance Analyzer for Playwright Tests
 * 
 * Analyzes test execution times, identifies bottlenecks, and provides
 * optimization recommendations.
 * 
 * Usage:
 *   node performance-analyzer.js
 *   node performance-analyzer.js --report-path ./test-results/.last-run.json
 *   node performance-analyzer.js --threshold 5000
 */

const fs = require('fs');
const path = require('path');

const DEFAULT_CONFIG = {
  reportPath: './test-results/.last-run.json',
  threshold: 5000, // milliseconds
  outputPath: './performance-report.json'
};

function parseArgs() {
  const args = process.argv.slice(2);
  const config = { ...DEFAULT_CONFIG };

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    
    if (arg === '--report-path' && i + 1 < args.length) {
      config.reportPath = args[++i];
    } else if (arg === '--threshold' && i + 1 < args.length) {
      config.threshold = parseInt(args[++i], 10);
    } else if (arg === '--output' && i + 1 < args.length) {
      config.outputPath = args[++i];
    } else if (arg === '--help') {
      printHelp();
      process.exit(0);
    }
  }

  return config;
}

function printHelp() {
  console.log(`
Performance Analyzer for Playwright Tests

Usage:
  node performance-analyzer.js [options]

Options:
  --report-path <path>  Path to test results JSON (default: ./test-results/.last-run.json)
  --threshold <ms>      Threshold for slow tests in milliseconds (default: 5000)
  --output <path>       Output path for performance report (default: ./performance-report.json)
  --help                Show this help message

Examples:
  node performance-analyzer.js
  node performance-analyzer.js --threshold 3000
  node performance-analyzer.js --report-path ./custom-results.json
`);
}

function formatDuration(ms) {
  if (ms < 1000) return `${ms}ms`;
  if (ms < 60000) return `${(ms / 1000).toFixed(2)}s`;
  return `${Math.floor(ms / 60000)}m ${((ms % 60000) / 1000).toFixed(0)}s`;
}

function analyzeTestResults(resultsPath, threshold) {
  console.log(`📊 Analyzing test results from: ${resultsPath}\n`);

  if (!fs.existsSync(resultsPath)) {
    // Try to find the latest report
    const resultsDir = path.dirname(resultsPath);
    if (fs.existsSync(resultsDir)) {
      const files = fs.readdirSync(resultsDir)
        .filter(f => f.endsWith('.json'))
        .map(f => ({
          name: f,
          path: path.join(resultsDir, f),
          time: fs.statSync(path.join(resultsDir, f)).mtime.getTime()
        }))
        .sort((a, b) => b.time - a.time);
      
      if (files.length > 0) {
        resultsPath = files[0].path;
        console.log(`📁 Using latest results: ${resultsPath}\n`);
      } else {
        console.error(`❌ No test results found in ${resultsDir}`);
        console.error('💡 Run tests first: npx playwright test');
        process.exit(1);
      }
    } else {
      console.error(`❌ Results not found: ${resultsPath}`);
      console.error('💡 Run tests first: npx playwright test');
      process.exit(1);
    }
  }

  const results = JSON.parse(fs.readFileSync(resultsPath, 'utf-8'));
  
  // Extract test data
  const tests = [];
  
  if (results.suites) {
    // Playwright report format
    extractTestsFromSuites(results.suites, tests);
  } else if (Array.isArray(results)) {
    // Custom format
    tests.push(...results);
  }

  if (tests.length === 0) {
    console.error('❌ No test data found in results');
    process.exit(1);
  }

  // Analyze tests
  const analysis = {
    totalTests: tests.length,
    totalDuration: tests.reduce((sum, t) => sum + (t.duration || 0), 0),
    passed: tests.filter(t => t.status === 'passed').length,
    failed: tests.filter(t => t.status === 'failed').length,
    skipped: tests.filter(t => t.status === 'skipped').length,
    slowTests: tests.filter(t => t.duration > threshold).sort((a, b) => b.duration - a.duration),
    averageDuration: 0,
    medianDuration: 0
  };

  // Calculate average
  const durations = tests.map(t => t.duration).filter(d => d > 0);
  analysis.averageDuration = durations.reduce((a, b) => a + b, 0) / (durations.length > 0 ? durations.length : 1);

  // Calculate median
  durations.sort((a, b) => a - b);
  const mid = Math.floor(durations.length / 2);
  analysis.medianDuration = durations.length % 2 === 0
    ? (durations[mid - 1] + durations[mid]) / 2
    : durations[mid];

  return { tests, analysis };
}

function extractTestsFromSuites(suites, tests, parentTitle = '') {
  for (const suite of suites) {
    const suiteTitle = parentTitle ? `${parentTitle} > ${suite.title}` : suite.title;
    
    if (suite.tests) {
      for (const test of suite.tests) {
        tests.push({
          title: test.title,
          suite: suiteTitle,
          duration: test.duration || 0,
          status: test.status,
          file: test.location?.file || ''
        });
      }
    }
    
    if (suite.suites) {
      extractTestsFromSuites(suite.suites, tests, suiteTitle);
    }
  }
}

function printReport(analysis, threshold) {
  console.log('═══════════════════════════════════════════════════');
  console.log('             PERFORMANCE ANALYSIS REPORT            ');
  console.log('═══════════════════════════════════════════════════\n');

  // Summary
  console.log('📈 Test Summary');
  console.log('─────────────────────────────────────────────────');
  console.log(`Total Tests:      ${analysis.totalTests}`);
  console.log(`✅ Passed:        ${analysis.passed}`);
  console.log(`❌ Failed:        ${analysis.failed}`);
  console.log(`⏭️  Skipped:       ${analysis.skipped}`);
  console.log(`Total Duration:   ${formatDuration(analysis.totalDuration)}`);
  console.log(`Average:          ${formatDuration(analysis.averageDuration)}`);
  console.log(`Median:           ${formatDuration(analysis.medianDuration)}\n`);

  // Slow tests
  if (analysis.slowTests.length > 0) {
    console.log(`⚠️  Slow Tests (>${formatDuration(threshold)})`);
    console.log('─────────────────────────────────────────────────');
    analysis.slowTests.slice(0, 10).forEach((test, i) => {
      console.log(`${i + 1}. ${formatDuration(test.duration).padEnd(10)} ${test.suite} > ${test.title}`);
    });
    
    if (analysis.slowTests.length > 10) {
      console.log(`\n   ... and ${analysis.slowTests.length - 10} more slow tests`);
    }
    console.log('');
  } else {
    console.log('✅ No slow tests detected!\n');
  }

  // Performance grade
  const avgTime = analysis.averageDuration;
  let grade = 'A';
  let gradeEmoji = '🏆';
  
  if (avgTime > 10000) {
    grade = 'D';
    gradeEmoji = '😰';
  } else if (avgTime > 7000) {
    grade = 'C';
    gradeEmoji = '😐';
  } else if (avgTime > 5000) {
    grade = 'B';
    gradeEmoji = '😊';
  }

  console.log(`${gradeEmoji} Performance Grade: ${grade}`);
  console.log('─────────────────────────────────────────────────\n');

  // Recommendations
  console.log('💡 Optimization Recommendations');
  console.log('─────────────────────────────────────────────────');

  if (analysis.slowTests.length > 0) {
    console.log('1. ⚡ Optimize slow tests:');
    console.log('   - Use storageState to skip authentication');
    console.log('   - Block unnecessary network requests');
    console.log('   - Mock slow APIs');
    console.log('   - Use API for setup/teardown instead of UI\n');
  }

  if (analysis.totalDuration / analysis.totalTests > 5000) {
    console.log('2. 🔄 Enable parallel execution:');
    console.log('   - Set fullyParallel: true in config');
    console.log('   - Increase workers count');
    console.log('   - Ensure tests are isolated\n');
  }

  if (analysis.averageDuration > 3000) {
    console.log('3. 🚫 Reduce unnecessary waits:');
    console.log('   - Replace waitForTimeout() with smart waits');
    console.log('   - Use auto-waiting features');
    console.log('   - Optimize selectors\n');
  }

  console.log('4. 📊 Monitor regularly:');
  console.log('   - Track test duration over time');
  console.log('   - Set up alerts for regressions');
  console.log('   - Profile slow tests individually\n');

  console.log('═══════════════════════════════════════════════════\n');
}

function generateDetailedReport(tests, analysis, outputPath) {
  const report = {
    timestamp: new Date().toISOString(),
    summary: {
      totalTests: analysis.totalTests,
      passed: analysis.passed,
      failed: analysis.failed,
      skipped: analysis.skipped,
      totalDuration: analysis.totalDuration,
      averageDuration: analysis.averageDuration,
      medianDuration: analysis.medianDuration
    },
    slowTests: analysis.slowTests.map(t => ({
      title: t.title,
      suite: t.suite,
      duration: t.duration,
      file: t.file
    })),
    allTests: tests.map(t => ({
      title: t.title,
      suite: t.suite,
      duration: t.duration,
      status: t.status,
      file: t.file
    }))
  };

  fs.writeFileSync(outputPath, JSON.stringify(report, null, 2));
  console.log(`📄 Detailed report saved to: ${outputPath}\n`);
}

async function main() {
  try {
    const config = parseArgs();
    const { tests, analysis } = analyzeTestResults(config.reportPath, config.threshold);
    
    printReport(analysis, config.threshold);
    generateDetailedReport(tests, analysis, config.outputPath);

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

main();
