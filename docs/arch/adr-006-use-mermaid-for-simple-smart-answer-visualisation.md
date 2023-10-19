# ADR 006 - Use Mermaid for Simple Smart Answer Visualisation

## Status
Proposed

## Context
Following user research it was identified that Content Designers (CDs) were struggling to understand the flow of a smart answer, communicate this with colleagues and confidently edit it. 

To arrive at our proposed solution, we evaluated the following options:

| Option                                     | Decision |                                                  Reason                                                   |
|:-------------------------------------------|:--------:|:---------------------------------------------------------------------------------------------------------:|
| [Mermaid](https://mermaid.js.org/)         |   Yes    |  Open source, visualisation library that supports flowcharts, is easily configurable, and implementable   |
| Build our own visualisation tool           |    No    |                          Problem not novel enough to require a bespoke solution                           |
| [D3](https://d3js.org/)                    |    No    |                   Doesn't specifically cover flow diagrams, so not fit for our purpose                    |
| [Flowchart.js](https://flowchart.js.org/)  |    No    |            Standalone visualisation generator, not possible to integrate into our application             |
| [JointJS](https://www.jointjs.com/)        |    No    |                                    Not open source, $1,495 per licence                                    |
| [Graphviz](https://graphviz.org/)          |    No    |                       Graph visualisation is not quite what we need for our purpose                       |
| [GoJS](https://gojs.net/latest/index.html) |    No    |                              No open source, $6,990 for 3 developer licences                              |
| [Kroki](https://kroki.io/)                 |    No    | Unified API wrapper around a suite of visualisation libraries. This is not functionality that we require. |

## Decision
Having performed a high level review of a variety of visualisation libraries, we have decided to use mermaid.js.

It has the right balance of simplicity and functionality that we require. It is also possible to customise the presentation of the visualisations.

We tested implementation of mermaid.js in a standalone project using the api, and were able to render the diagram within an html page. We also ran the webpack demo which demonstrates the use of mermaid.js as a dependency.

We foresee a few limitations;
* the auto-positioning of the nodes is something we do not have control of.
* we do not have the ability to control the shape of connecting lines.

## Consequences
To be able to integrate mermaid.js into Publisher, we will need to build a data translation service, that takes the flow as described in the data model, and converts this into the mermaid.js syntax.
This is the largest remaining uncertainty, however, this concern is not specific to mermaid.js, and would have to tackled for any of the above visualisation libraries.
