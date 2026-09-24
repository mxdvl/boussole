import Toybox.Lang;

//! The next sun event - sunrise or sunset, whichever comes first - shown as a
//! fixed time in the same style as the current time (a `ClockArc`), in
//! _brume_, just inside the time ring. Left out when the time is unknown (no
//! location, or polar day/night).
module SunRing {

    function scene(layout as Layout, minuteOfDay as Number?) as Array<Shapes.Shape> {
        if (minuteOfDay == null) {
            return [] as Array<Shapes.Shape>;
        }
        return ClockArc.shapes(layout, layout.sunRadius, minuteOfDay, Palette.BRUME);
    }
}
