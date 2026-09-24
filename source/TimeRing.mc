import Toybox.Lang;

//! The current time, near the rim: a `ClockArc` in chalk, and the 12 hour
//! points along its track in brume - XII, III, VI and IX as numerals, dots for
//! the rest. The arc is never interrupted: points it covers (including its
//! ends) are simply not drawn.
module TimeRing {

    function scene(layout as Layout, minuteOfDay as Number) as Array<Shapes.Shape> {
        var span = ClockArc.span(minuteOfDay);
        var shapes = hourPoints(layout, span[0], span[1]);
        shapes.addAll(ClockArc.shapes(layout, layout.timeRadius, minuteOfDay, Palette.CHALK));
        return shapes;
    }

    //! The hour points the arc leaves uncovered: a numeral at the quarters,
    //! a dot elsewhere.
    function hourPoints(layout as Layout, start as Float, sweep as Float) as Array<Shapes.Shape> {
        var shapes = [] as Array<Shapes.Shape>;
        for (var hour = 0; hour < 12; hour++) {
            var position = hour / 12.0;
            if (isCovered(position, start, sweep)) {
                continue;
            }
            var pointX = layout.xAt(layout.timeRadius, position);
            var pointY = layout.yAt(layout.timeRadius, position);
            var text = numeral(hour);
            if (text != null) {
                shapes.addAll(Numerals.lines(
                    text, pointX, pointY, layout.numeralHeight,
                    Palette.BRUME, layout.numeralPenWidth
                ));
            } else {
                shapes.add(new Shapes.Dot(pointX, pointY, layout.penWidth / 2.0, Palette.BRUME));
            }
        }
        return shapes;
    }

    //! Roman numeral for the quarter hours, null for the others.
    function numeral(hour as Number) as String? {
        switch (hour) {
            case 0: return "XII";
            case 3: return "III";
            case 6: return "VI";
            case 9: return "IX";
            default: return null;
        }
    }

    //! Whether `position` lies on the arc from `start` clockwise for `sweep`,
    //! ends included (so the point under the hour bar is covered too).
    function isCovered(position as Float, start as Float, sweep as Float) as Boolean {
        var offset = position - start;
        if (offset < 0.0) {
            offset += 1.0;
        }
        return offset <= sweep + 0.0001;
    }
}
