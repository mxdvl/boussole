import Toybox.Graphics;
import Toybox.Lang;

//! Steps: a bare arc near the rim, filled clockwise from 12 o'clock towards
//! today's step goal. No tick, no number.
module StepsRing {

    function scene(layout as Layout, steps as Number, goal as Number) as Array<Shapes.Shape> {
        var fraction = steps.toFloat() / goal.toFloat();
        if (fraction > 1.0) {
            fraction = 1.0;
        }
        return [
            new Shapes.Arc(
                layout.cx, layout.cy, layout.stepsR, 0.0, fraction,
                Graphics.COLOR_WHITE, layout.pen
            ),
        ] as Array<Shapes.Shape>;
    }
}
