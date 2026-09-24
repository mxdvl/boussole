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
//!        SunRing    the next sunrise or sunset as a `ClockArc`
//!        StepsRing  progress towards the step goal, bar anchored at XII
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
        scene.addAll(SunRing.scene(layout, nextSunEvent(location, clock.timeZoneOffset)));
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

    //! Local minute of the next sunrise or sunset, or null without a known
    //! location.
    private function nextSunEvent(location as Position.Location?, utcOffset as Number) as Number? {
        if (location == null) {
            return null;
        }
        var degrees = location.toDegrees();
        return SunCalc.nextEvent(Time.now().value().toDouble(), degrees[0], degrees[1], utcOffset);
    }
}
