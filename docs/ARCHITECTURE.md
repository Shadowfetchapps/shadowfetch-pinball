# Architecture

`PinEngine` is the rules table. Collisions on the 3D cabinet emit typed events. The engine awards points, advances missions, starts multiball, and records a drain once per `ball_id`.

Missions are a single path: SHADOW MODE → FETCH MULTIBALL → SYSTEM OVERLOAD → NIGHT RUN → FINAL JACKPOT.

`PinSim` is a 2D twin used by tests for walls, flipper kicks, bumper pops, drain, and escape recovery. The live cabinet uses Jolt with CCD, velocity caps, and a stuck-ball teleport above the flippers.
