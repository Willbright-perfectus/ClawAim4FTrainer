# Match your phone and game

## 1. Match the display and grip

Use landscape orientation, the same grip, the same phone game mode and the same FPS limit in both apps. Start with 60 FPS. Enter HUD editor, choose each button and drag it inside the framed screen. The editor shrinks the full phone canvas so controls remain reachable beneath its toolbars. Size is relative to screen height; position is a fraction of the usable display. Save a named profile before making large changes.

Start with the large fire control under your left index finger, movement under your left thumb, ADS/lean/jump/stance under the right fingers, and an unobstructed area for aiming. The provided layout approximates the screenshots; it has not been physically tested with your hands.

## 2. Match hip turning

ClawLab’s sensitivity units are **degrees per full-screen-width swipe**, not Delta Force slider units. Disable acceleration and gyro for the initial comparison.

In each app, face a recognizable vertical mark. Make the same comfortable horizontal swipe between two repeatable points. ClawLab’s Calibration drill shows heading. If the same swipe turns 180° in the game but 150° in ClawLab, multiply ClawLab’s hip sensitivity by 180/150 = 1.2. Repeat several times; avoid measuring one unusually fast or slow swipe.

Match horizontal FOV before comparing pixel motion. The preset treats 94° as horizontal; confirm the game’s behavior rather than assuming the label uses the same convention.

## 3. Match ADS and scopes

Repeat the swipe while fully aimed at 1×. Adjust ADS turn, then each magnification multiplier. Test the initial movement into ADS separately using Instant, After ADS or Gradual sensitivity transition. A numeric match at one scope does not establish a match at every scope.

If you use acceleration, enable it after the linear match and compare slow and fast swipes. The trainer’s acceleration curve is its own approximation. Gyro is optional and starts off; if enabled, check axes and inversion on the actual phone before tuning gain.

## 4. Match recoil and spread

Use Recoil Board, the same target distance, the same stance, and a fixed seed. First set spread to zero temporarily to isolate recoil. Fire equal-length bursts without compensating; compare vertical displacement, horizontal direction, settling time and ADS timing. Adjust base recoil, horizontal kick, randomness and recovery before changing the screenshot’s attachment multipliers.

Then restore spread and compare group sizes. Spread values are interpreted as cone half-angles. Damage falloff and the armor model are separate from aiming feel.

## 5. Match movement

Compare known-distance travel times for walking, sprinting, ADS and prone. In Movement Course, compare jump apex and airtime, then stance transitions, repeated jumps, lean timing and mantle duration. Short video recordings with frame counts are more repeatable than tuning by memory. Capture mode, operator, weapon/loadout and FPS alongside each reference.

ClawLab uses a capsule collider with different stance heights. It prevents standing beneath the low tunnel and checks the mantle destination. The geometry and character shape are simplified; passing a similar movement task does not prove the game uses the same collision model.

## 6. Save a reproducible setup

Save a named profile such as `M14 Operations 60fps v1`. Export its JSON from Profiles. Session history stores all settings plus a signature; compare results only when the configuration and drill match. The near-target metric uses an angular threshold, and an empty-space tap can be deliberate. Neither metric directly measures finger identity or guarantees in-game improvement.
