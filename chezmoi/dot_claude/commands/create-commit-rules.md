# Create Commit Rules Command

**Usage:** `/create-commit-rules`
**Description:** Analyzes Git repository to generate precise `.claude/rules/git-commits.md` with project-specific patterns.

## Analysis Workflow

### Extract Data
```bash
# 1. Count commits, limit analysis to 50 (exclude bots)
TOTAL_COMMITS=$(git rev-list --count HEAD)
git log --oneline --no-merges -50 --pretty=format:"%s" --author="^(?!.*(dependabot|renovate)).*" > commits.txt

# 2. Extract scopes and types with categorization
grep -o "([^)]*)" commits.txt | sed 's/[()]//g' | sort | uniq -c | sort -nr > scopes.txt
grep -o "^:[a-z_]*:" commits.txt | sort | uniq -c | sort -nr > emojis.txt
grep -o -E "^[a-z]+(\([^)]*\))?:" commits.txt | sed 's/(.*)://' | sed 's/://' | sort | uniq -c | sort -nr > types.txt

# Categorize scopes by mapping to directories and functionality
find . -type d -maxdepth 3 | grep -v -E "\.(git|node_modules)" > directories.txt
# Map scopes to categories: Component, Directory, Feature, Technology
while read -r count scope; do
    CATEGORY="Feature"
    if find . -type d -name "*${scope}*" | head -1 | grep -q .; then
        CATEGORY="Directory"
    elif echo "$scope" | grep -qE "(api|backend|frontend|mobile|web|server|client)"; then
        CATEGORY="Technology"
    elif echo "$scope" | grep -qE "(auth|payment|user|admin|dashboard|profile)"; then
        CATEGORY="Component"
    fi
    echo "${count} ${scope} ${CATEGORY}" >> scopes_categorized.txt
done < scopes.txt

# 3. Detect format (>60% threshold)
GITMOJI_COUNT=$(grep -c "^:" commits.txt)
CONVENTIONAL_COUNT=$(grep -c -E "^(feat|fix|docs|style|refactor|test|chore)" commits.txt)
PRIMARY_FORMAT="Custom"
[ $GITMOJI_COUNT -gt 30 ] && PRIMARY_FORMAT="Gitmoji"
[ $CONVENTIONAL_COUNT -gt 30 ] && PRIMARY_FORMAT="Conventional"

# 4. Analyze format details
# Case detection
UPPERCASE_START=$(grep -c -E ": [A-Z]" commits.txt)
LOWERCASE_START=$(grep -c -E ": [a-z]" commits.txt)
DETECTED_CASE="uppercase"
[ $LOWERCASE_START -gt $UPPERCASE_START ] && DETECTED_CASE="lowercase"

# Tense detection
IMPERATIVE_COUNT=$(grep -c -E "(Add|Fix|Update|Remove|Create)" commits.txt)
PAST_TENSE_COUNT=$(grep -c -E "(Added|Fixed|Updated|Removed|Created)" commits.txt)
DETECTED_TENSE="Imperative"
[ $PAST_TENSE_COUNT -gt $IMPERATIVE_COUNT ] && DETECTED_TENSE="Past tense"

# Period detection
NO_PERIOD_COUNT=$(grep -c -E "[^.]$" commits.txt)
PERIOD_COUNT=$(grep -c -E "\.$" commits.txt)
FINAL_PERIOD_RULE="No final period"
[ $PERIOD_COUNT -gt $NO_PERIOD_COUNT ] && FINAL_PERIOD_RULE="Final period required"

# Length analysis
awk -F': ' '{if(NF>1) print length($0)}' commits.txt | awk '{sum+=$1; count++} END {print int(sum/count)}' > avg_length.txt
AVERAGE_LENGTH=$(cat avg_length.txt)
MAX_LENGTH=$(awk -F': ' '{if(NF>1) print length($0)}' commits.txt | sort -nr | head -1)

# Body usage analysis
git log --no-merges -50 --pretty=format:"%B" | grep -c "^$" > body_count.txt
BODY_PERCENTAGE=$(( $(cat body_count.txt) * 100 / 50 ))

# Scope usage analysis
SCOPE_COUNT=$(grep -c "([^)]*)" commits.txt)
SCOPE_PERCENTAGE=$(( SCOPE_COUNT * 100 / 50 ))

# Multiple scope detection
MULTIPLE_SCOPE_COUNT=$(grep -c "([^,)]*,[^)]*)" commits.txt)
MULTIPLE_SCOPE_USAGE="Rare"
[ $MULTIPLE_SCOPE_COUNT -gt 5 ] && MULTIPLE_SCOPE_USAGE="Common (comma-separated)"
[ $MULTIPLE_SCOPE_COUNT -eq 0 ] && MULTIPLE_SCOPE_USAGE="Not used"

# Breaking change detection
BREAKING_CHANGE_COUNT=$(grep -c -E "(BREAKING|!:|breaking)" commits.txt)
BREAKING_CHANGE_PATTERN="Not detected"
[ $BREAKING_CHANGE_COUNT -gt 0 ] && BREAKING_CHANGE_PATTERN="Uses BREAKING or ! notation"

# Pattern detection based on format
DETECTED_PATTERN="Custom format"
[ "$PRIMARY_FORMAT" = "Gitmoji" ] && DETECTED_PATTERN=":emoji:(scope): Description"
[ "$PRIMARY_FORMAT" = "Conventional" ] && DETECTED_PATTERN="type(scope): description"

# 5. Check commitlint config
find . -maxdepth 2 -name "*commitlint*" > config.txt
```

### Generate Rules File Template

```markdown
# Project Git Commit Rules

## COMMIT CONTENT

**Core Principle - EXPLAIN WHY, NOT WHAT:**
- Commits must explain the reasoning, problem solved, or requirement addressed
- Focus on business context, technical constraints, or user impact
- NEVER describe implementation details in commit message
- Use objective facts, avoid subjective judgments ("comprehensive", "enhanced", etc.)

**Good WHY examples:**
- "Previous threshold of 7 days was causing unnecessary renewals and hitting Let's Encrypt rate limits"
- "ADR-006 requires validation before final architecture decision"
- "Current approach has HTTP/HTTPS-only limitations that prevent TCP service exposure"

**Bad WHAT examples:**
- ❌ "adds prometheus servicemonitor for api metrics endpoint" 
- ❌ "Creates implementation guide with testing framework"
- ❌ "Updates configuration files and documentation"

## COMMIT FORM

**Project Format: [PRIMARY_FORMAT]**

**Format Rules:**
- Pattern: [DETECTED_PATTERN]
- Description starts with [DETECTED_CASE] letter
- [DETECTED_TENSE] tense
- [FINAL_PERIOD_RULE]
- Average length: [AVERAGE_LENGTH] characters
- Subject line max: [MAX_LENGTH] characters (detected from longest)
- Body usage: [BODY_PERCENTAGE]% of commits include explanatory bodies
- Scope usage: [SCOPE_PERCENTAGE]% of commits include scopes
- Multiple scopes: [MULTIPLE_SCOPE_USAGE] (e.g., "scope1,scope2")
- Breaking changes: [BREAKING_CHANGE_PATTERN] (if detected)

**Project Scopes (detected):**
[CATEGORIZED_SCOPES_WITH_USAGE]

**Project Types/Emojis (detected):**
[CATEGORIZED_TYPES_WITH_USAGE]

**Universal Rules (Always Apply):**
- Use `-s` (signoff) and `-S` (GPG) flags when available
- Atomic commits (one logical change)
- Uppercase start, imperative tense, no final period
- Max 100 chars subject, 80 chars body lines
- Body for non-trivial changes explaining WHY
- Co-authored-by trailers: `Co-authored-by: Claude <claude@anthropic.com>`
- NEVER auto-update GitHub issues without confirmation
- NEVER assume - ask for missing info

**Project Examples (from repository):**
[3_REAL_COMMIT_EXAMPLES_WITH_WHY_EXPLANATION]
```

### Analysis Logic
1. **Format Detection**: Count gitmoji vs conventional patterns
2. **Scope Mapping**: Extract parenthetical scopes, map to directories
3. **Style Analysis**: Detect case/tense from first words
4. **Config Integration**: Parse commitlint if exists
5. **Generate**: Merge universal content rules + project patterns

### Output Optimization
- **Skip metadata**: No dates, stats, confidence scores
- **Focus essentials**: Format, scopes, examples only
- **Token efficient**: Bullet points, no verbose explanations
- **Claude-optimized**: Direct rules Claude can apply immediately

The generated file contains only what git-commit-assistant needs to create proper commits for this specific project.
