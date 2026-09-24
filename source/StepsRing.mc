import Toybox.Graphics;
import Toybox.Lang;

//! Steps: a bare arc near the rim, filled clockwise from 12 o'clock towards
//! today's step goal. No tick, no number.
module StepsRing {

    function scene(layout as Layout, steps as Number, goal as Number) as Array<Shapes.Shape> {
        var progress = steps.toFloat() / goal.toFloat();
        if (progress > 1.0) {
            progress = 1.0;
        }
        return [
            new Shapes.Arc(
                layout.centreX, layout.centreY, layout.stepsRadius, 0.0, progress,
                Graphics.COLOR_WHITE, layout.penWidth
            ),
        ] as Array<Shapes.Shape>;
    }
}
