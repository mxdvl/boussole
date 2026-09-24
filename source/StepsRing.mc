import Toybox.Lang;

//! Steps, in the same style as the clock rings: a brume arc with its hour bar
//! anchored at XII, filling clockwise towards today's step goal.
module StepsRing {

    function scene(layout as Layout, steps as Number, goal as Number) as Array<Shapes.Shape> {
        var progress = steps.toFloat() / goal.toFloat();
        if (progress > 1.0) {
            progress = 1.0;
        }
        return [
            new Shapes.Arc(
                layout.centreX, layout.centreY, layout.stepsRadius, 0.0, progress,
                Palette.BRUME, layout.arcWidth
            ),
            layout.bar(0.0, layout.stepsRadius, layout.capReach, layout.arcWidth, Palette.BRUME),
        ] as Array<Shapes.Shape>;
    }
}
