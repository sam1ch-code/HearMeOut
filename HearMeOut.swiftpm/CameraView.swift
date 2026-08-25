//
//  SwiftUIView.swift
//  HearMeOut
//
//  Created by Sukhrob on 22/08/26.
//

import SwiftUI

/*
 ## Weaknesses in the original, specifically as they affect a standalone Detector

 Looking at `processPupil`/`handleFaceLandmarks` with an eye toward "how would this look as an isolated frame-processing component," a few problems compound beyond what was flagged earlier:

 1. **Detection and decision-making are welded together.** Vision output flows directly into mistake-counting, scoring, and UI mutation inside one `DispatchQueue.main.async` block. There's no seam where you could unit-test "given this landmark data, what direction is the gaze" without also pulling in `UIColor`, `strokeOverlay`, and `resultOverall`.
 2. **State is four independent, unsynchronized trackers** (`shiftDownStart/Top/Right/Left`), each with its own timer and reset logic — one of which never resets. This isn't really "state," it's four coincidentally-related bugs waiting to diverge further.
 3. **The eye is treated as an axis-aligned box**, which silently breaks the moment the head rolls even slightly — the box's edges stop corresponding to "left/right of the eye" in any meaningful way.
 4. **Everything is computed in view/screen space** (`viewWidth`, `viewHeight`, the `(1-x)` flip) — so a coordinate bug corrupts gaze math and on-screen rendering identically, and there's no way to isolate which one is wrong when something looks off.
 5. **No smoothing** — each frame's instantaneous pupil-in-box ratio is compared directly against fixed thresholds, so landmark jitter translates directly into flicker between states.
 6. **Single eye, chosen arbitrarily** — no signal about *why* one eye was picked or how confident that reading is.

 ## Proposed design for the Detector

 Think of it as a pipeline with clean, separately-testable stages, rather than one function that does everything:

 **Stage 1 — Frame ingestion.** The Detector's only public entry point takes a `CVPixelBuffer` (handed to it by the delegate's `captureOutput`) plus the orientation to pass to Vision. It owns nothing about the capture session. It should apply the frame-rate cap here (skip frames if the previous one is still processing or too little time has passed) — that's a Detector concern, not a `ViewController` concern.

 **Stage 2 — Landmark extraction.** Same as before: `VNSequenceRequestHandler` + `VNDetectFaceLandmarksRequest`, kept sequential (not per-request handlers) so Vision can use temporal continuity across frames. Output: raw `VNFaceObservation` plus its `landmarks`.

 **Stage 3 — Per-eye geometry, done properly.** For *each* eye that's present (not "left, else right"):
 - Compute the eye's own local axis from its two corner landmark points (inner/outer corner), not from an axis-aligned bounding box. This gives you a vector that rotates *with* the eye when the head tilts.
 - Project the pupil's position into that local axis frame (essentially: rotate the pupil offset into eye-space before normalizing), rather than assuming "horizontal" and "vertical" line up with the screen. This is the fix for the roll-sensitivity problem — a true almond-shape-aware read instead of a box approximation.
 - Produce one signed, normalized offset per eye (e.g., -1...1 on each local axis) plus a confidence value (was the eye clearly open/visible, or partially occluded).

 **Stage 4 — Combine both eyes.** Average the two eyes' normalized offsets, weighted by confidence, instead of picking one. If only one eye is usable, use it but mark confidence as reduced — don't silently treat monocular and binocular readings the same way.

 **Stage 5 — Incorporate head pose.** Pull `roll`/`yaw` (and `pitch` if available) off the `VNFaceObservation`. This does two things the old code couldn't:
 - Rotates the per-eye local-axis reading back into a head-upright frame, so "left" means the same thing whether the head is tilted or not.
 - Combines head yaw/pitch with the eye-in-socket reading into one gaze estimate — this is what lets you distinguish "eyes drifted while head stayed still" from "head turned while eyes stayed centered," which the old code couldn't do at all since it only ever looked at eye-in-socket ratio.

 This is still a heuristic without a depth sensor or calibration step — worth being upfront that it's an approximation, not a metrically accurate gaze vector.

 **Stage 6 — Temporal smoothing.** Before any thresholding, run the combined estimate through a simple low-pass filter (exponential moving average is enough) across frames. This directly addresses the flicker problem — decisions get made on a stabilized signal, not raw per-frame noise.

 **Stage 7 — Single-state classification, not four parallel trackers.** Collapse "center / left / right / up / down" into one mutually-exclusive zone classification per frame, from non-overlapping angle ranges (unlike the old code's overlapping `0.25` / `0.35` / `0.3` bands). Track exactly one "time since last centered" timer, reset whenever the zone returns to `.center`. This eliminates the entire bug class of contradictory thresholds and dead reset paths, because there's structurally only one state to get right instead of four copies that can each go stale independently.

 **Stage 8 — Output as data, not side effects.** The Detector's output per frame should be a single, immutable value — direction/zone, angle, confidence, timestamp — handed to whoever's listening (delegate callback, closure, or Combine publisher). It should not know about `UIColor`, mistake counters, or scores. That logic belongs to a consumer above the Detector, which is what makes the Detector independently testable: you can feed it synthetic landmark fixtures and assert "offset X should classify as `.right`," which is exactly the kind of check that would have caught the old code's direction/axis mismatch before it shipped.

 **Stage 9 — Screen-boundary decision stays out of the Detector.** The Detector reports where the eyes/head are pointing, in a device-relative frame — not "did this exceed the screen." Whether that maps to on-screen or off-screen is a separate policy layer, since it depends on physical screen size, device-to-face distance, and ideally a short calibration step (having the user look at a few known on-screen points once, to fit a simple mapping from gaze estimate → screen coordinates). Baking screen-pixel thresholds directly into eye-landmark math, like the legacy code did, is exactly what made the old thresholds arbitrary and unverifiable — separating the two lets you improve or recalibrate the screen-mapping step later without touching the detection math at all.

 That's the shape I'd build the Detector file around. Want to go ahead and implement it next, or talk through the calibration-step idea in more detail first?
*/
