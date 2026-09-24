import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! Watch face made of concentric rings, each filling clockwise from 12 o'clock.
//! From the rim inwards (radii in `Face`):
//!
//!   StepsRing  bare arc: progress towards today's step goal
//!   TimeRing   one 12-hour arc with 12 hour points (XII/III/VI/IX); an outward
//!              tick points to the minutes, an inward tick to the hour, and the
//!              next sunrise/sunset is marked across it
class BoussoleView extends WatchUi.WatchFace {

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var face = new Face(dc);
        StepsRing.draw(dc, face);
        TimeRing.draw(dc, face);
    }

    function onEnterSleep() as Void {
    }

    function onExitSleep() as Void {
    }
}
