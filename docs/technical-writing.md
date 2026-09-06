---
id: repository-technical-writing
title: Repository technical writing policy
kind: principle
status: source-verified
zig: "n/a"
summary: Authors and reviewers apply short sentences, explicit actors, stable vocabulary, and exact-text exceptions to repository prose.
updated: 2026-09-06
sources:
  - "[[repository-technical-writing-2026-09-06]]"
proofs: []
platforms:
  - cross-platform
---

# Repository technical writing policy

The user adopted **Simplified Technical English (ASD-STE100), guided by Zinsser**, for repository prose.
The [captured instruction](../sources/repository-technical-writing-2026-09-06.md) defines the requirements below.
The repository does not claim independently verified compliance with the complete ASD-STE100 standard.
The instruction supplies no additional Zinsser rules.
The procedures below apply the user's requirements to documentation work.

## Author rules

A technical term names a concept specific to a subject.

- Authors express one idea per sentence.
- Authors keep each sentence within 20 words.
- Authors may use up to 25 words for a description.
- Authors use active voice and name the actor.
- Authors give each word one meaning.
- Authors never use the same word as both a noun and a verb.
- Authors define each technical term when the term first appears.
- Authors retain one term for each concept.
- Authors ensure every “that,” “this,” and “it” has a clear noun.

Authors repeat a noun when a pronoun could refer to several actors or resources.
Authors split a sentence when separate actions need separate explanations.

## Terms and ownership

An owner controls access to a resource.
A buffer holds bytes in reserved memory.
A request asks a component to perform work.
The following examples keep each term's meaning and grammatical role stable.

| Term | Role | Example |
| --- | --- | --- |
| owner | noun | The owner releases the buffer. |
| buffer | noun | The owner retains the buffer. |
| request | noun | The client submits a request. |
| submit | verb | The client submits a request. |

Authors identify the owner before describing who may release a resource.
Authors state when the owner may release each resource.
Authors describe the failing action before describing recovery.
Authors state which resources each owner retains after an error.
An error string is the exact text a program reports after failure.
Authors preserve the exact error string beside the explanation.

## Diagrams and readers

A caption explains a diagram's purpose and scope.
Alternative text describes an image for readers who cannot see the image.
Authors provide a caption and nearby explanation for each diagram.
Authors define diagram terms before their first appearance.
Authors describe each arrow's action and direction.
Authors provide alternative text for images.
Authors avoid color as the only distinction between states.
The nearby explanation must preserve the diagram's essential meaning without the image.

## Exceptions

A code identifier names a program element.
Quoted output reproduces text from a tool or program.
Exact-format text must retain characters required by its format.
The requirements govern prose, including comments and diagram explanations.
The requirements never govern code identifiers, quoted output, error strings, or exact-format text.
Authors preserve those exceptions when revising surrounding explanations.
Authors do not rename an identifier to repair prose.
Authors preserve immutable source captures and append-only history.

## Sentence and meaning review

Reviewers inspect the rendered prose after separating the listed exceptions.
Reviewers count each sentence's words, including sentences in table cells and captions.
Reviewers apply the 25-word allowance only to descriptions.
Reviewers inspect each sentence's idea, actor, terms, and pronouns.
Reviewers compare ownership and error explanations with the cited source.
Reviewers confirm captions and nearby text explain each diagram without relying on color.

A word counter can flag long sentences.
A word total cannot establish clear meaning, correct ownership, or external-standard compliance.
The repository requires manual review of meaning alongside its existing verification commands.
No automated Simplified Technical English certification follows from those commands.

Related guidance: [[naming-comments-and-api-shape]] and [[code-reading-and-mechanical-checks]].
