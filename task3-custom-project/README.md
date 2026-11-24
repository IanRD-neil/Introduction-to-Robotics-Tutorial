# Task 3 - Robot Claw Machine

**Status: program v1.2 written, testing on the robot next.**
We'll update this page as we build it.

File: [`Main.prg`](Main.prg) (v1.2). It contains two programs:
- `main`: the game.
- `main1`: an I/O test that prints every input that changes. We use it to find
  which input each button of the I/O box is connected to.

New points for this task (taught with Tool 1 in **Local 0 / world**, because
the program reads the current position with `P*`, which is in world
coordinates):

| Point | What it is |
|---|---|
| `ClawA` | Front-left mark on the play floor, nozzle touching the top of a capsule |
| `ClawB` | Back-right mark on the play floor (only X and Y are used) |
| `ClawHigh` | Above the play floor, at travel height (only Z is used) |
| `HoleDrop` | Above the centre of the prize hole, at travel height. Home of the claw and the place where it always releases |

The program only uses the differences between these points, so the direction
of "up" always comes from the points themselves.

### Changes

- **v1:** first version, the prize was taken to a separate chute.
- **v1.1:** changed for the printed cabinet. Now the claw always goes back to
  the prize hole and releases there, like a real machine. The prize falls down
  the shaft, slides on a ramp inside the cabinet and comes out at the front.
  If the claw stops over the corner where the hole is, it doesn't go down.
- **v1.2:** Tool 1 is set by code at the start (`TLSet`), because the
  controller is shared and another group changed it on 24/11
  (see [`docs/workcell-setup.md`](../docs/workcell-setup.md#6-our-tool-and-local-values-robot-2)).

For the integration task we are turning the robot cell into an arcade **claw
machine**. The robot is the claw and the vacuum nozzle grabs the prize. The
players are our classmates, and the prizes are candies.

## How to play

1. Press **Start** (green). The game begins.
2. The robot moves **left and right** over the prize area. Press **Forward**
   (blue) to stop it over the prize you want.
3. Now it moves **forward and back**. Press **Reverse** (white) to stop it again.
4. The robot goes down with the vacuum on. The vacuum pressure sensor tells
   if it caught something:
   Then it always goes back to the prize hole and releases.
   - **Caught:** the prize falls down the hole and comes out at the front
     door. Win sound on the buzzer.
   - **Missed:** lose sound.
5. If nobody presses the button in time, it drops by itself, like a real
   claw machine.

## How it works (technical idea)

| Part | How we plan to do it |
|---|---|
| Stopping the robot with a button | SPEL+ `Move ... Till Sw(n) = On`: the move stops as soon as the input turns on, then we read the position where it stopped. |
| Did it catch a prize? | Vacuum pressure switch (Chelic PS-40) connected to a robot input. After going down, wait a short time for the signal. If it doesn't come, it's a miss. |
| Prize area | Play floor on top of the printed cabinet. The sweep limits and the drop height come from `ClawA`, `ClawB` and `ClawHigh`, taught in world coordinates. |
| Running out of prizes | The robot counts the prizes. When the area is empty it refills it from the infeed, putting the prizes in random positions (`Rnd`). This reuses the code from Task 1 and Task 2. |
| Stop / Reset | Stop (red) finishes the current move and goes home safely. Reset (orange) clears an alarm and restarts the game. |
| Memory | The prize count is kept in `Global Preserve` variables, so it survives a stop or a power cut. |
| HMI (if it works) | "Insert coin" screen, time left, prizes won and record of the day. The game also works without it. |

## Parts we will design and 3D print

- **Prize capsules:** small containers with a flat top (so the vacuum can hold
  them) and a candy inside.
- **Cabinet:** one printed box (about 251 x 281 x 117 mm) with the play floor on
  top, the prize hole and shaft in one corner and an internal ramp that brings
  the prize out to a platform at the front, so nobody has to put their hands
  near the robot. It is screwed to the M6 holes of the table.

## Plan

- [ ] Find which inputs/outputs the I/O box buttons, buzzer and vacuum sensor use
- [x] First version of the program (`Main.prg` v1): sweeps with `Till`, drop, sensor check, chute, buzzer, score kept with `Global Preserve`
- [x] v1.1 for the cabinet (release always over the prize hole) and v1.2 (Tool 1 set by code)
- [ ] Test v1 on the robot with the course tokens as prizes (dry run first, then with vacuum)
- [x] Design the cabinet and the prize capsules (CAD)
- [ ] Print the cabinet and capsules
- [ ] Automatic refill from the infeed + prize counter
- [ ] Stop / Reset handling and recovery after a stop
- [ ] HMI screen (if the HMI works)
- [ ] Video + documentation
