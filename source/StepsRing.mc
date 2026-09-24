import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;

//! Steps: a bare arc near the rim, filled clockwise from 12 o'clock towards
//! today's step goal. No tick, no number.
module StepsRing {

    const DEFAULT_GOAL = 10000;

    function draw(dc as Graphics.Dc, face as Face) as Void {
        var info = ActivityMonitor.getInfo();
        var steps = 0;
        var s = info.steps;
        if (s != null) {
            steps = s;
        }
        var goal = DEFAULT_GOAL;
        var g = info.stepGoal;
        if (g != null && g > 0) {
            goal = g;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(face.pen);
        face.drawSweep(dc, face.stepsR, steps.toFloat() / goal.toFloat());
    }
}
