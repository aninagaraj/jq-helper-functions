# jq Helpers

A collection of useful jq functions and patterns for JSON processing.

## Overview

This repository contains practical jq helper functions for common JSON manipulation tasks. Each helper is designed to be modular, reusable, and focused on solving specific problems.

### Function Categories
- **Object Functions** - `collect_values`: Consolidate arrays of objects by merging values with matching keys
- **Math Functions** - `pow`, `normalize`, `round_to`: Exponentiation, array normalization, and decimal rounding
- **Float Functions** - `convert_units`: Convert numbers using binary prefixes (KiB, MiB, GiB, etc.)
- **String Functions** - `capitalize`, `trim`, `reverse`: Text manipulation utilities
- **Array Functions** - Statistical (`mean`, `median`, `stddev`, `percentile`), deduplication (`unique`, `duplicates`), frequency analysis (`freq`)
- **Validation Functions** - `is_empty`, `is_not_empty`, `deep_flatten`: Data validation and structure manipulation