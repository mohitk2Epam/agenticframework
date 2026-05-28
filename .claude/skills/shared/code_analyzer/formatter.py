#!/usr/bin/env python3
"""
Output Formatter - Terminal-friendly output for validation results.

Produces formatted output combining:
- Code Analyzer V5 findings
- Engine availability status
- Issue list with severity icons

Usage:
    output = format_validation_output(
        file_name="AccountService.cls",
        engines_used=["pmd", "regex"],
        engines_unavailable=["sfge"],
        issues=issues,
    )
    print(output)
"""

from typing import Dict, List, Any, Optional
from dataclasses import dataclass


# Severity icons for terminal display
SEVERITY_ICONS = {
    "CRITICAL": "",
    "HIGH": "",
    "MODERATE": "",
    "WARNING": "",
    "LOW": "",
    "INFO": "",
}


@dataclass
class FormattedIssue:
    """A formatted issue for display."""
    severity: str
    icon: str
    source: str
    line: int
    message: str
    fix: Optional[str] = None
    rule: Optional[str] = None


def format_validation_output(
    file_name: str,
    engines_used: List[str],
    engines_unavailable: List[str],
    issues: List[FormattedIssue],
    scan_time_ms: int = 0,
) -> str:
    """
    Format complete validation output for terminal display.

    Args:
        file_name: Name of file being validated
        engines_used: List of CA engines that ran
        engines_unavailable: List of unavailable engines
        issues: List of FormattedIssue objects
        scan_time_ms: Scan duration in milliseconds

    Returns:
        Formatted string for terminal output
    """
    lines = []

    # Header
    lines.append("")
    lines.append(f" Apex Validation: {file_name}")
    lines.append("" * 60)

    # Code Analyzer status
    if engines_used:
        lines.append(f" Code Analyzer Engines: {', '.join(engines_used)}")
    else:
        lines.append(" Code Analyzer: Not available")

    if engines_unavailable:
        lines.append(f"    Unavailable: {', '.join(engines_unavailable)}")

    if scan_time_ms > 0:
        lines.append(f"    Scan time: {scan_time_ms}ms")

    # Issues
    if issues:
        lines.append("")
        lines.append(f" Issues Found ({len(issues)}):")

        # Sort by severity
        severity_order = {"CRITICAL": 0, "HIGH": 1, "MODERATE": 2, "WARNING": 3, "LOW": 4, "INFO": 5}
        sorted_issues = sorted(issues, key=lambda x: severity_order.get(x.severity, 5))

        # Display up to 15 issues
        for issue in sorted_issues[:15]:
            source_tag = f"[{issue.source}]" if issue.source else ""
            line_tag = f"L{issue.line}" if issue.line else ""

            # Truncate message if too long
            message = issue.message
            if len(message) > 70:
                message = message[:67] + "..."

            lines.append(f"   {issue.icon} {issue.severity} {source_tag} {line_tag}: {message}")

            if issue.fix:
                fix = issue.fix
                if len(fix) > 60:
                    fix = fix[:57] + "..."
                lines.append(f"      Fix: {fix}")

        if len(issues) > 15:
            lines.append(f"   ... and {len(issues) - 15} more issues")
    else:
        lines.append("")
        lines.append(" No issues found!")

    # Footer
    lines.append("" * 60)

    return "\n".join(lines)


def format_issues_list(
    issues: List[FormattedIssue],
    max_issues: int = 15,
) -> str:
    """Format just the issues list."""
    if not issues:
        return " No issues found!"

    lines = [f" Issues Found ({len(issues)}):"]

    severity_order = {"CRITICAL": 0, "HIGH": 1, "MODERATE": 2, "WARNING": 3, "LOW": 4, "INFO": 5}
    sorted_issues = sorted(issues, key=lambda x: severity_order.get(x.severity, 5))

    for issue in sorted_issues[:max_issues]:
        source_tag = f"[{issue.source}]" if issue.source else ""
        line_tag = f"L{issue.line}" if issue.line else ""
        message = issue.message[:70] + "..." if len(issue.message) > 70 else issue.message

        lines.append(f"   {issue.icon} {issue.severity} {source_tag} {line_tag}: {message}")

    if len(issues) > max_issues:
        lines.append(f"   ... and {len(issues) - max_issues} more issues")

    return "\n".join(lines)


def format_engine_status(
    engines_used: List[str],
    engines_unavailable: List[str],
) -> str:
    """Format engine availability status."""
    lines = []

    if engines_used:
        lines.append(f" Code Analyzer Engines: {', '.join(engines_used)}")
    else:
        lines.append(" Code Analyzer: Not available")

    if engines_unavailable:
        lines.append(f"    Unavailable: {', '.join(engines_unavailable)}")

    return "\n".join(lines)


def create_issue(
    severity: str,
    source: str,
    message: str,
    line: int = 0,
    fix: Optional[str] = None,
    rule: Optional[str] = None,
) -> FormattedIssue:
    """Create a FormattedIssue with proper icon."""
    icon = SEVERITY_ICONS.get(severity.upper(), "")
    return FormattedIssue(
        severity=severity.upper(),
        icon=icon,
        source=source,
        line=line,
        message=message,
        fix=fix,
        rule=rule,
    )


def merge_issues(
    custom_issues: List[Dict[str, Any]],
    ca_violations: List[Dict[str, Any]],
) -> List[FormattedIssue]:
    """
    Merge custom issues and CA violations into formatted issues list.

    Args:
        custom_issues: Issues from custom sf-skills validator
        ca_violations: Violations from Code Analyzer

    Returns:
        Combined list of FormattedIssue objects
    """
    issues = []

    # Add custom issues
    for issue in custom_issues:
        issues.append(create_issue(
            severity=issue.get("severity", "INFO"),
            source="sf-skills",
            message=issue.get("message", ""),
            line=issue.get("line", 0),
            fix=issue.get("fix"),
            rule=issue.get("rule"),
        ))

    # Add CA violations
    for violation in ca_violations:
        engine = violation.get("engine", "CA")
        issues.append(create_issue(
            severity=violation.get("severity_label", "INFO"),
            source=f"CA:{engine}",
            message=violation.get("message", ""),
            line=violation.get("line", 0),
            rule=violation.get("rule"),
        ))

    return issues
