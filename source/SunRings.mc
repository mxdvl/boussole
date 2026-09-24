import Toybox.Lang;

//! The next sunrise and the next sunset, each shown as a fixed time in the
//! same style as the current time (a `ClockArc`), in brume. Sunrise sits just
//! inside the time ring, sunset just inside that. A ring is left out when its
//! time is unknown (no location, or polar day/night).
module SunRings {

    function scene(layout as Layout, times as SunCalc.Times?) as Array<Shapes.Shape> {
        var shapes = [] as Array<Shapes.Shape>;
        if (times == null) {
            return shapes;
        }
        var sunrise = times.sunrise;
        if (sunrise != null) {
            shapes.addAll(ClockArc.shapes(layout, layout.sunriseRadius, sunrise, Palette.BRUME));
        }
        var sunset = times.sunset;
        if (sunset != null) {
            shapes.addAll(ClockArc.shapes(layout, layout.sunsetRadius, sunset, Palette.BRUME));
        }
        return shapes;
    }
}
