---
id: source-http11-framing-and-limits
title: HTTP/1.1 framing and bounded request policy
kind: source
status: captured
summary: Published HTTP RFCs define framing, chunked decoding, persistence and rejection semantics without imposing unlimited application capacity.
captured: 2026-09-05
revision: "RFC 9110 and RFC 9112 (June 2022); RFC 6585 (April 2012)"
url: https://www.rfc-editor.org/rfc/rfc9112
---

# HTTP/1.1 framing and bounded request policy

Immutable published specifications, inspected for the initial M4 design:

- [RFC 9112](https://www.rfc-editor.org/rfc/rfc9112): sections 2–3 and 5–9
  define octet parsing, request targets, headers, framing, chunked decoding,
  incomplete messages, persistence and ordered pipelined responses.
- [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110): sections 5.4, 10.1.1,
  15.5.14 and 15.5.15 cover field limits, `Expect: 100-continue`, rejection of
  oversized content and oversized request targets.
- [RFC 6585](https://www.rfc-editor.org/rfc/rfc6585): section 5 defines 431
  for excessive header fields; section 7.3 allows dropping abusive connections.

A configured body limit is application policy. Content-Length permits early
rejection; chunked framing requires cumulative accounting. HTTP chunks remain
parts of one request. RFC 9112 requires chunked decoding capability and either
consuming the request body or closing before connection reuse. Its framing
rules address ambiguous length metadata and request smuggling.

Scope: selected published sections, not an exhaustive conformance or errata
audit. No parser implementation or runnable HTTP proof is established here.
