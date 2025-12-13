# Bolt Journal

## FlutterFlow Learnings
*   **Custom Widget Wrappers & Scrolling:** Custom widgets wrapping 3rd party UI libs often erroneously add `SingleChildScrollView` to "be safe". In `ListView` context (common in FF lists), this causes performance issues (nested scrollables) or layout errors (unbounded height).
*   **Constraint Propagation:** FlutterFlow often puts custom widgets inside `Columns` or `Containers`. If the custom widget assumes it needs to scroll itself without checking constraints (like `height`), it fights with the parent structure.
*   **Optimization:** Conditional `SingleChildScrollView` based on explicit `height` parameter is a safe pattern for FF custom widgets to support both "expand to fit" (chat bubble) and "scroll within box" (terms of use) use cases.
