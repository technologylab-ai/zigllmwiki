---
id: source-rfc3986-uri-syntax
title: RFC 3986 URI syntax and scheme case
kind: source
status: captured
summary: Immutable URI grammar distinguishes case-insensitive schemes and authority syntax from path-sensitive routing.
captured: 2026-09-05
revision: "RFC 3986, January 2005"
url: https://www.rfc-editor.org/rfc/rfc3986.html
---

# URI syntax

The published January 2005 RFC is immutable; its RFC Editor identity was checked
on 2026-09-05. Sections 2 and 3 define URI characters, percent escapes, scheme,
authority and path syntax. Section 3.1 defines scheme names as case-insensitive;
section 6.2.2.1 distinguishes case normalization of scheme/host from other URI
components. Do not lowercase a request path as an incidental routing shortcut.

The bounded HTTP prototype accepts origin/absolute request targets and validates
authority syntax against this grammar plus [[http11-framing-and-limits]].
Parsing CONNECT authority or an Upgrade field does not implement tunnelling.
Its optional-header lookup remains a separate concern from request-target syntax.

Relevant synthesis: [[bounded-http-server-design]].
