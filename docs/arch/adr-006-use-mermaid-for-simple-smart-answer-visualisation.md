# ADR 006 - Use Mermaid for Simple Smart Answer Visualisation

## Status
Proposed

## Context
Following user research it was identified that Content Designers (CDs) were struggling to understand the flow of a smart answer, communicate this with colleagues and confidently edit it. They typically use third party tools to visualise smart answers that have complex flows. According to the user research, CDs would prefer to do this within Mainstream Publisher. 

A list of potential features were derived from the user research:

* Diagram that shows the full flow of questions, answers and outcomes.
* Illustrate the path from each answer to the next node (question/outcome)
* Flow lines and node boxes are in a sensible order to not create additional cognitive load
* Questions, answers and outcome boxes look different e.g. different shape/colours
* Interactive e.g. user can select a question/outcome and the flow to/from it, is highlighted

We carried out a spike to identify viable diagramming tools that meet the above requirements. The potential need for the diagram to be interactive limited our scope to Javascript based diagramming tools, which will allow us to modify the diagrams dynamically.

We evaluated the following options:

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

We tested implementation of mermaid.js in a standalone project using the api, and were able to render the diagram within a html page. We also ran the webpack demo which demonstrates the use of mermaid.js as a dependency.

We foresee a few limitations;
* The auto-positioning of the nodes (question/outcome boxes) is something we do not have control of i.e Mermaid rearranges their position depending on how the flowchart evolves
* Connecting lines do not always render in a visually appropriate way i.e sometimes they sit behind boxes or can overlap with other lines.

## Consequences
To be able to integrate mermaid.js into Publisher, we will need to build a data translation service, that takes the flow as described in the data model, and converts this into the mermaid.js syntax.
This is the largest remaining uncertainty, however, this concern is not specific to mermaid.js, and would have to tackled for any of the above visualisation libraries.
