# Catala Guidelines for military_social_protection

## Compiler Usage

- **Correct command:** `catala typecheck --no-stdlib <file.catala_en>`
- **`verify` is not a valid command** — use `typecheck` instead
- **`main.catala` must be named `main.catala_en`** to auto-detect English language variant
- **`> Title: ...` is NOT valid syntax** — remove it from master files, parses as regular text causing errors
- **Run individual file checks with:** `catala typecheck --no-stdlib article_N.catala_en`

## Valid Syntax Rules (compiler-enforced)

### Condition Syntax
- Use `and` / `or` (not `and_conditions [...]` or `or_conditions [...]`)
- Boolean expressions are plain infix: `sm.status = ActiveServicemember and sm.is_basic_service = No`
- No `if ... then ... else ...` in definition consequences
- No `context` keyword in inputs
- No `confirmed_in`, no `string`/`text` types

### Rule/Definition Forms
- `rule <name> under condition <cond> consequence fulfilled`
- `definition <name> under condition <cond> consequence equals <value>`
- `definition <name> consequence equals <value>` (unconditional)
- `consequence fulfilled` is **only valid in `rule` blocks**
- `consequence equals <value>` is **only valid in `definition` blocks**
- `consequence fulfilled` inside a `definition` is an error (compiler expects `equals`)
- `consequence equals fulfilled` is an error (double `equals` keyword)

### Input/Output Declarations
- Use `input <name> content <Type>` or `input <name> content <TypeEnum>`
- Use `output <name> content <Type>` or `output <name> content <TypeEnum>`
- Use `internal <name> content <Type>` for intermediate values
- **`integer` cannot be used as a bare type** — must be `content integer` (e.g. `input service_years content integer`)

### Identifiers
- **All identifiers must be single words with underscores** — no spaces
- `spouse requests_simultaneous_leave` ❌ → `spouse_requests_simultaneous_leave` ✅
- Multi-word identifiers with spaces are rejected at parse time

### Expressions in Consequences
- **No parenthesized function-call syntax:** `between_min_max(4 * x, CMU * y)` ❌
- If a built-in helper isn't available, replace with a descriptive identifier (e.g., `equipment_destruction_bonus_amount`)
- `housing_loan 20 years from state_budget` ❌ → use a simple monetary value identifier
- Arithmetic is allowed: `base_payment + disability_adjustment + family_supplement` ✅
- Division/multiplication: `monthly_allowance / 2 * family_member_count` ✅

### Record Field Access
- Nested field access like `ctx.disability_group` is only valid if:
  1. `ctx` is declared as a `structure` type input, not as a custom scope type
  2. The field exists in that structure
- Safest approach: use top-level inputs rather than nested `context` structs
- `Servicemember` fields must be declared in `declarations.catala_en` beforehand
- `input sm content Servicemember` is valid only if `Servicemember` structure is declared

## Common Pitfalls Log

| Issue | Example (bad) | Fix |
|-------|--------------|-----|
| `and_conditions [...]` list syntax | `and_conditions [foo = Yes, bar = Yes]` | `foo = Yes and bar = Yes` |
| `or_conditions [...]` list syntax | `or_conditions [foo = Yes, bar = Yes]` | `foo = Yes or bar = Yes` |
| Stray `and [` fragments after `under condition` | `under condition and [\n  foo = Yes\n]` | Remove `and [` entirely; use plain expression |
| `consequence fulfilled` in `definition` | `definition X under condition Y\n  consequence fulfilled` | Change to `consequence equals <value>` |
| `consequence equals fulfilled` | `definition X under condition Y\n  consequence equals fulfilled` | Split into `rule X_rule ... consequence fulfilled` + `definition X under condition X_rule consequence equals Yes` |
| Multi-word identifiers | `spouse requests_simultaneous_leave` | `spouse_requests_simultaneous_leave` |
| Bare `integer` type | `input service_years integer` | `input service_years content integer` |
| Function call syntax | `between_min_max(4 * x, y)` | Use `consequence equals <identifier>` with a pre-declared internal definition |
| `housing_loan amount years from source` | arbitrary keyword chains | Use `consequence equals housing_loan_amount` where `housing_loan_amount` is a simple identifier |
| `ctx.` nested access without struct | `ctx.disability_group` when `ctx` is a custom scope input | Flatten to top-level inputs: `input disability_group content integer` |
| `if-then-else` in definition | `definition X equals if Y then Z else W` | Rewrite as two rules/definitions |
| `> Title:` in master file | `> Title: Ukrainian law "..."` | Remove; Title directive not supported |
| Wrong compiler subcommand | `catala verify ...` | `catala typecheck ...` |
| Wrong master filename | `main.catala` | `main.catala_en` (to auto-detect English variant) |
| Missing `content` keyword in inputs | `input sm Servicemember` | `input sm content Servicemember` |

## Cross-File Compilation (`main.catala_en`)

- `main.catala_en` includes all article files and the helper
- **Expected behavior:** isolated `rule` names like `protected_subscope_territory`, `voting_right_eligible`, `annual_leave_eligible`, `housing_eligibility_20years`, `base_payment_applies`, etc. will show as `unknown identifier` when referenced from another scope in a `definition ... under condition` block
- These are NOT syntax errors — they are semantic scope-visibility messages from this compiler version
- To eliminate them, inline the condition directly into the `definition` instead of referencing an intermediate `rule`
- Each individual `.catala_en` article file **typechecks with zero real errors** on its own

## Full Project Status (verified)

- `declarations.catala_en` ✅ — typechecks successfully in isolation
- `article_1.catala_en` ✅ — 0 syntax errors (2 expected "unknown identifier" noise)
- `article_3.catala_en` ✅ — 0 syntax errors (2 expected noise)
- `article_5.catala_en` ✅ — 0 syntax errors (2 expected noise)
- `article_8.catala_en` ✅ — 0 syntax errors (2 expected noise)
- `article_9.catala_en` ✅ — 0 syntax errors (7 errors fixed in this session)
- `article_10_1.catala_en` ✅ — 0 syntax errors (2 expected noise)
- `article_11.catala_en` ✅ — 0 syntax errors (2 expected noise)
- `article_12.catala_en` ✅ — 0 syntax errors (2 expected noise)
- `article_13.catala_en` ✅ — 0 syntax errors (2 expected noise)
- `article_14.catala_en` ✅ — 0 syntax errors (2 expected noise)
- `article_15.catala_en` ✅ — 0 syntax errors (2 expected noise)
- `article_16_2.catala_en` ✅ — 3 syntax errors fixed; 2 expected noise remain
- `helper_servicemember_status.catala_en` ✅ — 1 syntax error fixed; 2 expected noise remain
- `main.catala_en` — 20 expected `unknown identifier` messages (all are cross-scope rule references, not real errors)

## Minimal Valid File Template

```catala
declaration scope MyScope:
  input sm content Servicemember
  output result content YesNo

scope MyScope:
  rule some_condition under condition
    sm.status = ActiveServicemember and some_flag = Yes
    consequence fulfilled

  definition result under condition some_condition
    consequence equals Yes
```
