import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

//! Watch face made of concentric rings. Each update is three steps:
//!
//!   1. read the device (time, steps, location) - the only impure inputs
//!   2. build a scene: pure functions turn those values into `Shapes`
//!        TimeRing   near the rim: the current time as a `ClockArc`, with
//!                   hour points and numerals
//!        SunRings   the next sunrise and sunset, each as a `ClockArc`
//!        StepsRing  bare inner arc: progress towards the step goal
//!   3. `Render` draws the scene
class BoussoleView extends WatchUi.WatchFace {

    private const DEFAULT_STEP_GOAL = 10000;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var clock = System.getClockTime();
        var activity = ActivityMonitor.getInfo();
        var location = Position.getInfo().position;

        var layout = new Layout(dc.getWidth(), dc.getHeight());
        var scene = StepsRing.scene(layout, orZero(activity.steps), stepGoal(activity.stepGoal));
        scene.addAll(SunRings.scene(layout, sunTimes(location, clock.timeZoneOffset)));
        scene.addAll(TimeRing.scene(layout, clock.hour * 60 + clock.min));

        Render.draw(dc, scene);
    }

    function onEnterSleep() as Void {
    }

    function onExitSleep() as Void {
    }

    private function orZero(value as Number?) as Number {
        return value != null ? value : 0;
    }

    private function stepGoal(goal as Number?) as Number {
        return (goal != null && goal > 0) ? goal : DEFAULT_STEP_GOAL;
    }

    //! Next sunrise and sunset, or null without a known location.
    private function sunTimes(location as Position.Location?, utcOffset as Number) as SunCalc.Times? {
        if (location == null) {
            return null;
        }
        var degrees = location.toDegrees();
        return SunCalc.upcoming(Time.now().value().toDouble(), degrees[0], degrees[1], utcOffset);
    }
}
