import Toybox.Lang;

//! The current time, near the rim: a `ClockArc` in craie, and the 12 hour
//! points along its track in brume.
//!
//! - Uncovered points: XII, III, VI and IX as numerals, dots for the rest.
//! - Points the arc covers (ends included) are not drawn, except the quarters
//!   the arc has run at least a minute past: those get a gap cut across the
//!   arc in encre with a thin brume tick inside it, so the dial stays readable.
//! - The current hour's point is left to its bar.
module TimeRing {

    const ONE_MINUTE = 1.0 / 60.0 - 0.0001;  // a minute of the minute hand, as a fraction of a turn

    function scene(layout as Layout, minuteOfDay as Number) as Array<Shapes.Shape> {
        var span = ClockArc.span(minuteOfDay);
        var currentHour = (minuteOfDay % ClockArc.TURN) / 60;
        var shapes = hourPoints(layout, span[0], span[1], currentHour);
        shapes.addAll(ClockArc.shapes(layout, layout.timeRadius, minuteOfDay, Palette.CRAIE));
        shapes.addAll(quarterGaps(layout, span[0], span[1], currentHour, (minuteOfDay % 60) / 60.0));
        return shapes;
    }

    //! The hour points the arc leaves uncovered: a numeral at the quarters,
    //! a dot elsewhere.
    function hourPoints(
        layout as Layout, start as Float, sweep as Float, currentHour as Number
    ) as Array<Shapes.Shape> {
        var shapes = [] as Array<Shapes.Shape>;
        for (var hour = 0; hour < 12; hour++) {
            var position = hour / 12.0;
            if (hour == currentHour || isCovered(position, start, sweep)) {
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

    //! Gaps across the arc at the quarters it has run at least a minute past,
    //! except the current hour's: an encre stroke twice the arc's width cuts
    //! the gap, and a brume tick half the arc's width sits inside it. Both
    //! reach as far either side of the arc as the hour bar does.
    function quarterGaps(
        layout as Layout, start as Float, sweep as Float,
        currentHour as Number, minuteHand as Float
    ) as Array<Shapes.Shape> {
        var shapes = [] as Array<Shapes.Shape>;
        var innerRadius = layout.timeRadius - layout.capReach;
        var outerRadius = layout.timeRadius + layout.capReach;
        for (var hour = 0; hour < 12; hour += 3) {
            var position = hour / 12.0;
            if (hour == currentHour
                || !isCovered(position, start, sweep)
                || distance(position, minuteHand) < ONE_MINUTE) {
                continue;
            }
            shapes.add(layout.radial(position, innerRadius, outerRadius, Palette.ENCRE, 2.0 * layout.arcWidth));
            shapes.add(layout.radial(position, innerRadius, outerRadius, Palette.BRUME, layout.arcWidth / 2.0));
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

    //! Distance between two positions, either way round the dial.
    function distance(first as Float, second as Float) as Float {
        var apart = first - second;
        if (apart < 0.0) {
            apart = -apart;
        }
        return apart > 0.5 ? 1.0 - apart : apart;
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
