# Task 3 - Robot Claw Machine

**Status: first version of the program written, testing on the robot next.**
We'll update this page as we build it.

File: [`Main.prg`](Main.prg) (v1). It contains two programs:
- `main`: the game.
- `main1`: an I/O test that prints every input that changes. We use it to find
  which input each button of the I/O box is connected to.

New points for this task (taught with Tool 1 in **Local 0 / world**, because
the program reads the current position with `P*`, which is in world
coordinates):

| Point | What it is |
|---|---|
| `ClawA` | One corner of the prize area, nozzle touching the top of a prize |
| `ClawB` | Opposite corner of the prize area (only X and Y are used) |
| `ClawHigh` | Above the prize area, at travel height (also the home position) |
| `ChuteDrop` | Where the prize is released, just above the chute |

The program only uses the differences between these points, so the direction
of "up" always comes from the points themselves.

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
   - **Caught:** it takes the prize to the chute and the prize comes out to
     the player. Win sound on the buzzer.
   - **Missed:** lose sound and it goes back home.
5. If nobody presses the button in time, it drops by itself, like a real
   claw machine.

## How it works (technical idea)

| Part | How we plan to do it |
|---|---|
| Stopping the robot with a button | SPEL+ `Move ... Till Sw(n) = On`: the move stops as soon as the input turns on, then we read the position where it stopped. |
| Did it catch a prize? | Vacuum pressure switch (Chelic PS-40) connected to a robot input. After going down, wait a short time for the signal. If it doesn't come, it's a miss. |
| Prize area | New fixture with its own local coordinate system. The sweep limits and the drop height are defined in that local. |
| Running out of prizes | The robot counts the prizes. When the area is empty it refills it from the infeed, putting the prizes in random positions (`Rnd`). This reuses the code from Task 1 and Task 2. |
| Stop / Reset | Stop (red) finishes the current move and goes home safely. Reset (orange) clears an alarm and restarts the game. |
| Memory | The prize count is kept in `Global Preserve` variables, so it survives a stop or a power cut. |
| HMI (if it works) | "Insert coin" screen, time left, prizes won and record of the day. The game also works without it. |

## Parts we will design and 3D print

- **Prize area:** a base with low walls that sits on the table.
- **Prize capsules:** small containers with a flat top (so the vacuum can hold
  them) and a candy inside.
- **Prize chute:** a funnel and ramp that brings the prize out to the player,
  outside the robot's work area, so nobody has to put their hands near the robot.

## Plan

- [ ] Find which inputs/outputs the I/O box buttons, buzzer and vacuum sensor use
- [x] First version of the program (`Main.prg` v1): sweeps with `Till`, drop, sensor check, chute, buzzer, score kept with `Global Preserve`
- [ ] Test v1 on the robot with the course tokens as prizes (dry run first, then with vacuum)
- [ ] Design and print the prize area, capsules and chute
- [ ] Automatic refill from the infeed + prize counter
- [ ] Stop / Reset handling and recovery after a stop
- [ ] HMI screen (if the HMI works)
- [ ] Video + documentation
