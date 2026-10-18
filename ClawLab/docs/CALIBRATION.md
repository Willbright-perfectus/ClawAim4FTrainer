# Match your phone and game

## 1. Match the display and grip

Use landscape orientation, the same grip, the same phone game mode and the same FPS limit in both apps. Start with 60 FPS. Enter HUD editor, choose each button and drag it inside the framed screen. The editor shrinks the full phone canvas so controls remain reachable beneath its toolbars. Size is relative to screen height; position is a fraction of the usable display. Save a named profile before making large changes.

Start with the large fire control under your left index finger, movement under your left thumb, ADS/lean/jump/stance under the right fingers, and an unobstructed area for aiming. The provided layout approximates the screenshots; it has not been physically tested with your hands.

## 2. Match hip turning

ClawLab’s sensitivity units are **degrees per full-screen-width swipe**, not Delta Force slider units. In **Aim → Swipe sensitivity**, start with overall multiplier 1.0 and disable acceleration. Gyro is under **View & gyro**. Adjust **Camera sensitivity** for hip/ADS movement when not firing.

In each app, face a recognizable vertical mark. Make the same comfortable horizontal swipe between two repeatable points. ClawLab’s Calibration drill shows heading. If the same swipe turns 180° in the game but 150° in ClawLab, multiply ClawLab’s hip sensitivity by 180/150 = 1.2. Repeat several times; avoid measuring one unusually fast or slow swipe.

Match horizontal FOV before comparing pixel motion. The preset treats 94° as horizontal; confirm the game’s behavior rather than assuming the label uses the same convention.

## 3. Match ADS and scopes

Repeat the swipe while fully aimed at 1×. Adjust ADS turn, then each magnification multiplier. Test the initial movement into ADS separately using Instant, After ADS or Gradual sensitivity transition. A numeric match at one scope does not establish a match at every scope.

Select the M14 optic under **Weapon → M14**, or tap the range's **SCOPE** control to cycle 1×/2×/3×/4×/6×/8×. The pistol always uses 1× iron sights. Set independent hip/ADS/scope values under **Aim → Fire sensitivity**, then compare swipes while firing. The shared Swipe multiplier and vertical/acceleration controls apply to both categories. Fire sensitivity applies while FIRE is held, shots are queued, or for 0.12 seconds after a shot.

For linear input: `turn = swipe fraction × overall swipe multiplier × camera/fire gain × scope multiplier (ADS only)`. Vertical input also uses the vertical multiplier. These are training units, not copies of the game's numbered sliders.

If you use acceleration, enable it after the linear match and compare slow and fast swipes. The trainer’s acceleration curve is its own approximation. Gyro is optional and starts off; if enabled, check axes and inversion on the actual phone before tuning gain.

## 4. Match recoil and spread

Use Recoil Board, the same target distance, the same stance, and a fixed seed. First set spread to zero temporarily to isolate recoil. Fire equal-length bursts without compensating; compare vertical displacement, horizontal direction, settling time and ADS timing. Adjust base recoil, horizontal kick, randomness and recovery before changing the screenshot’s attachment multipliers.

Then restore spread and compare group sizes. Spread values are interpreted as cone half-angles. Damage falloff and the armor model are separate from aiming feel.

## 5. Match movement

Compare known-distance travel times for walking, sprinting, ADS and prone. In Movement Course, compare jump apex and airtime, then stance transitions, repeated jumps, lean timing and mantle duration. Short video recordings with frame counts are more repeatable than tuning by memory. Capture mode, operator, weapon/loadout and FPS alongside each reference.

Version 0.2.0 defaults to a **1.25 movement pace multiplier** to address slow-feeling movement. This scales walking, sprinting, ADS, crouch, prone and silent speeds, as well as acceleration. Use 1.0 to return to the original speed values before a strict comparison. Quicker stance/lean/mantle timings and acceleration can be tuned separately. **Controls → Joystick travel** sets the fraction of joystick radius needed to reach full speed (default 0.52).

The firing line and side partition keep the player out of the target bay in every stance; bullets pass through. The movement bay remains accessible on the left, including its revised checkpoints.

ClawLab uses a capsule collider with different stance heights. It prevents standing beneath the low tunnel and checks the mantle destination. The geometry and character shape are simplified; passing a similar movement task does not prove the game uses the same collision model.

## 6. Save a reproducible setup

Save a named profile such as `M14 Operations 60fps v1`. Export its JSON from Profiles. Session history stores all settings plus a signature; compare results only when the configuration and drill match. The near-target metric uses an angular threshold, and an empty-space tap can be deliberate. Neither metric directly measures finger identity or guarantees in-game improvement.
