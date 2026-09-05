---
id: source-http-overload-refusal
title: HTTP overload refusal semantics
kind: source
status: captured
summary: RFC 9110 defines 503 for temporary overload while allowing an overloaded server to refuse connections.
captured: 2026-09-05
revision: "RFC 9110 (June 2022), section 15.6.4"
url: https://www.rfc-editor.org/rfc/rfc9110#section-15.6.4
---

# Overload refusal

Inspected section 15.6.4 of the published RFC on 2026-09-05. A server can use
503 for temporary overload or scheduled maintenance and optionally supply
Retry-After. The status definition does not require an overloaded server to
deliver an HTTP error; refusing a connection is also possible.

Queue limits, reserved error capacity, deadlines and recovery watermarks in
M4 are proposed implementation policy, not guarantees imposed by this RFC.
