# Workcell setup: TCP and local coordinates

Everything in Task 1 and Task 2 depends on this setup. If the tool or the local
coordinates are wrong, every point is wrong too, so this was the first thing we
did in the lab (weeks 4-5).

## 1. Components on the table

We placed the four components on the perforated table and measured their
positions with a ruler, so we could also build the cell in the simulator.

| Component | What it is for | Main dimensions (from the drawings) |
|---|---|---|
| Infeed | Holds the stacks of tokens and blocks, with guide pins | Base plate 48 x 62 x 10 mm (drawing "Infeed_Alignment") |
| Alignment station | Re-centers the part on the nozzle (Task 1 only) | Same base plate, with short pins |
| Tray ("part rack") | Final position of the parts | 110 x 60 x 10 mm, 3 round pockets Ø20 and 3 rectangular pockets 20 x 24, **30 mm pitch** |
| TCP setup tool | Pointed rod used as a fixed reference to calibrate the tool | 150 mm long, 60° tip |

Parts:
- **Token:** round, fits the Ø20 pockets of the tray, 6 mm thick.
- **Block:** 20 x 24 x 6 mm with R4 corners.

## 2. Tool calibration (TCP), X and Y

**Why:** the robot only knows where its flange (J6) is. Our vacuum nozzle is
mounted with an offset, so the robot doesn't know where the tip of the nozzle
is. If we don't define a tool, rotating the wrist moves the nozzle tip around
instead of rotating around it.

**How we did it (Tool Wizard in RC+):**
1. Put a toothpick in the vacuum nozzle, so the "tip" is easy to see.
2. Put the robot in a pose with W = 180° and J5 at -90°, and jog it close to
   the TCP setup tool.
3. Open the **Tool Wizard** (Tools) and touch the tip of the setup tool with the
   toothpick in three different orientations:
   - U = 0, V = 0, W = ±180°
   - U rotated to some non-zero value (V = 0, W = ±180°)
   - W rotated away from 180° (U = 0, V = 0)
4. With these three touches the wizard calculates the X and Y offset of the tip
   and saves it as **Tool 1**.

The wizard only calculates the tool. Moving the robot close to the setup tool is
done by hand with **Jog & Teach**.

## 3. Local coordinate systems

**Why:** each fixture gets its own coordinate system (a "local"), with the origin
on the fixture itself. Then the points are written relative to the fixture, and
the numbers make sense with the dimensional drawings (for example, the tray
pockets are 30 mm apart, so in the tray local the next pocket is just 30 mm
away in Y).

**How we did it (Local Wizard in RC+):**
1. Select **Tool 1** (the nozzle) before teaching anything.
2. Jog the robot close to the fixture.
3. Open the **Local Wizard**, choose the local number and the 3-point method:
   origin, a point on the +X axis and a point on the +Y axis.
4. Teach the three points on the fixture.

Locals we defined:

| Local | Fixture |
|---|---|
| 1 | Infeed |
| 2 | Alignment station |
| 3 | Tray |

**Important detail:** with the way the X and Y points were taught, the Z axis
of our locals points **down, into the table**. That's why in the programs
`-Z(50)` means "50 mm above the point" and not below. We kept this convention
in both tasks.

## 4. Tool calibration, Z axis

After the X/Y calibration the tool length still includes the toothpick, so the
Z was wrong (when Z = 0 the nozzle should touch the surface, but it didn't).

1. Go to the origin of a local we already had (we used Local 3, the tray).
2. Jog the nozzle down until it just touches the top surface of the tray.
3. Switch to **Tool 0** and write down the Z value.
4. In **Tools**, edit the Z of Tool 1 with that value.
5. Switch back to **Tool 1** before moving the robot again.

Now Z = 0 in the tray local means "nozzle touching the tray".

## 5. Points

With Tool 1 selected, we taught the points on the center of each part position
(using the drawings to check the numbers). The full list is in
[`task1-pick-and-place/Points.pts`](../task1-pick-and-place/Points.pts) and
explained in the [Task 1 README](../task1-pick-and-place/README.md#taught-points).

## 6. Our tool and local values (Robot 2)

These are the values that worked for us. We got them from the controller
backup of 17/11 (`CurrentMnp01.Prm`).

| | X | Y | Z | U | V | W |
|---|---|---|---|---|---|---|
| Tool 1 (vacuum nozzle) | -0.762 | -2.677 | 74.499 | 0 | 0 | 0 |
| Local 1 (infeed) | 336.263 | -34.705 | 16.586 | 0 | 0 | 180 |
| Local 2 (alignment) | 337.263 | 82.653 | 17.086 | 0 | 0 | 180 |
| Local 3 (tray) | 404.558 | 61.930 | 16.585 | 0 | 0 | 180 |

W = 180 is the reason why Z points down in our locals (see section 3).

### What happened on 24/11

Task 2 worked on Saturday (21/11), but on Tuesday all the points were wrong,
even though `Points.pts` didn't change. When we checked Robot Manager we saw
that another group had changed **Tool 1** (Z was about 20 mm longer, they
probably use a different nozzle or gripper) and **Local 3**. Local 1 and 2 were
still ok.

We wrote our values back in Robot Manager (Tools / Locals, then Apply). To avoid
this in the future, the programs now set the tool and the locals by code at the
start of `main`:

```
TLSet 1, XY(-0.762, -2.677, 74.499, 0, 0, 0)       ' vacuum nozzle
Local 1, XY(336.263, -34.705, 16.586, 0, 0, 180)   ' infeed
Local 3, XY(404.558, 61.930, 16.585, 0, 0, 180)    ' tray
```

Task 3 only sets Tool 1, because its points are taught in Local 0 (world).

## Things to check every lab session

- The robot is shared with other groups, and **tools and locals are stored in
  the controller, not in our project**. Before running, we go to a known point
  slowly (for example `Go Tray_Token -Z(10)` in the Command Window) and check
  that the nozzle is centered.
- First run of any program at low speed (`Speed 10`, low `SpeedS`) with a hand
  near the emergency stop.
