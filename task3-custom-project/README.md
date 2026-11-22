# Task 3 - Custom project

**Status: not defined yet.** This page will be updated when we choose the
project.

For the final exam the third task is our own application with the robot cell.
We want to reuse what we already have working (TCP, locals, the pick and place
and stacking functions) and add something new.

## Ideas we are considering (brainstorm, nothing decided)

| Idea | What the robot would do | What's new compared to Task 1 and 2 |
|---|---|---|
| Palletizing pattern | Fill the tray (or a grid on the table) following a pattern, for example tokens and blocks in a checkerboard | SPEL+ `Pallet` command, 2D loops |
| Push-button menu | The operator chooses with buttons/inputs which program to run (pick and place, stacking, unstacking) | Digital inputs, `Sw()`, program selection |
| Build and unbuild | Build the tower, then take it apart and put the parts back in the infeed, in a loop | Reverse sequence, cycle counting |
| Drawing with a pen | Mount a pen as a new tool and draw a shape or letters on paper | New TCP (Tool 2), `Move`/`Arc` paths |

## Plan

- [ ] Choose the project with the group
- [ ] Check what we need (points, new fixtures or tools, I/O)
- [ ] Write the program and test it (dry run first, like in Task 2)
- [ ] Document it here and record a video
