---
title: Comprehensive Pandoc WASM Test
author: Test Suite
date: 2026-01-28
---

# Part 1: Introduction

## Overview

This presentation tests the full capabilities of Pandoc compiled to WebAssembly.

## Goals

- Verify WASM compilation
- Test document conversion
- Ensure output quality

# Part 2: Text Features

## Formatting

This is **bold** and *italic* and ***bold italic***.

This is ~~strikethrough~~ and `inline code`.

## Lists

Ordered list:

1. First item
2. Second item
3. Third item

Unordered list:

- Apple
- Banana
- Cherry

## Nested Lists

1. Main point
   - Sub point A
   - Sub point B
2. Another main point
   - Sub point C
   - Sub point D

# Part 3: Code

## Python Example

```python
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

for i in range(10):
    print(f"F({i}) = {fibonacci(i)}")
```

## JavaScript Example

```javascript
const greet = (name) => {
    console.log(`Hello, ${name}!`);
};

greet('WASM');
```

# Part 4: Tables

## Simple Table

| Name  | Age | City     |
|-------|-----|----------|
| Alice | 30  | New York |
| Bob   | 25  | London   |
| Carol | 35  | Tokyo    |

## Complex Table

| Feature       | Status | Notes           |
|--------------|--------|-----------------|
| Markdown     | ✅     | Full support   |
| HTML         | ✅     | Basic support  |
| PPTX         | ✅     | Working!       |
| DOCX         | ✅     | Should work    |

# Part 5: Quotes

## Block Quote

> "The best way to predict the future is to invent it."
> — Alan Kay

## Multi-paragraph Quote

> This is a longer quote that spans
> multiple lines and demonstrates
> the full quote formatting.
>
> It even has multiple paragraphs!

# Part 6: Conclusion

## Summary

We have successfully:

1. Compiled Pandoc to WebAssembly
2. Tested various Markdown features
3. Generated valid PPTX output

## Thank You

Questions?
