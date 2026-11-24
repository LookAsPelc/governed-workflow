# Model Selection and Verification

Choose a worker based on the work required, not only the topic or task size. Adjust the starting choices for model availability, reasoning effort, worker experience, and results. Do not pretend an unavailable model or effort is available. Choose a suitable available alternative and state the limitation.

| Work | Recommended starting point |
| --- | --- |
| Mechanical edit, simple test, extraction | Luna High |
| Routine implementation, endpoint, bug fix | Luna XHigh |
| Difficult algorithm, tightly coupled components, or concurrency | Luna Max; Sol High when the cause is unclear |
| Architecture and trade-offs | Sol Medium; High for major consequences |
| Forms and routine application work | Terra Low |
| Multi-step GUI, visual inspection, research | Terra Medium; XHigh for a complex drawing or 3D |
| Documentation and communication | Terra Medium/High; Sol for difficult expert content |
| Publication and bibliography | Luna High, with primary-source verification |
| Data extraction and Python | Luna High/XHigh for extraction, Max for difficult processing; Terra for complex charts |
| XRD, DSC, TGA, and experiments | Sol High for interpretation and experiment design |
| SEM/TEM and expert charts | Terra High for images, Sol High for scientific conclusions |
| Mathematical derivation | Sol High, with symbolic computation when needed |
| Frontend from a reference | Luna XHigh/Max for implementation, Terra High for visual inspection |
| CSS and responsiveness | Luna XHigh, Terra High for visual inspection |
| Blender or CAD | Terra High/XHigh for GUI, Luna Max for parametric scripting; Sol for difficult geometry |
| Visual identity or UX | Terra High; Sol Medium for critique when needed |
| Security and threat modeling | Sol 6.2 High; Sol 5.6 as a possible independent second opinion |

For scientific work, distinguish measurements, calculations, interpretations, and hypotheses. For visual deliverables, verify both appearance and function. Sol can answer a question without taking over implementation or scope decisions.

Luna Max is appropriate from the start for tightly coupled system components, reconstructing an unknown algorithm, or difficult causal analysis. File count alone does not determine complexity. Luna can handle a large implementation. Sol can then answer expert questions based on the results, such as whether the strategy, algorithm, or architecture makes sense.

For GUI work, delegate the outcome, not individual clicks. Verify the saved result. Consider security review based on risks such as authentication, authorization, secrets, external data, and untrusted input, not line count.

When a result fails, identify the cause. Supply missing information or access. Return a specific error to the worker. Discuss a flawed plan. Change the model or tool when a capability is missing. Address insufficient verification with a test or independent review. Compare conflicting conclusions against the evidence. Changing effort and changing the model are separate choices, not a required ladder.

Choose verification based on risk and how easy the result is to verify. A simple, measurable result may need a direct test. A more consequential or difficult-to-verify problem may need independent expert judgment and more evidence. Parallelize independent tasks and increase concurrency only when it helps.

As a rough guide, standard prices for the same volume of ordinary input and output tokens have these ratios: Luna 1 : Terra 10 : Sol 6.2 20 : Sol 5.6 40. Task cost also depends on token count, effort, retries, review, and the quality of your delegation.
