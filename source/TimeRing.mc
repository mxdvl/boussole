import Toybox.Lang;

//! The current time, near the rim: a `ClockArc` in _craie_, with the 12 hour
//! points along its track in _brume_.
//!
//! - Uncovered points: XII, III, VI and IX as numerals, dots for the rest.
//! - Once the arc has run at least a minute past an uncovered quarter, a gap
//!   is cut across it there instead, so the dial stays readable.
//! - The current hour's point is left to its bar.
//!
//! See `aodScene` for the pared-back Always-On version.
module TimeRing {

    const ONE_MINUTE = 1.0 / 60.0 - 0.0001;  // a minute of the minute hand, as a fraction of a turn

    function scene(layout as Layout, minuteOfDay as Number) as Array<Shapes.Shape> {
        var span = ClockArc.span(minuteOfDay);
        var currentHour = (minuteOfDay % ClockArc.TURN) / 60;
        var quarters = passedQuarters(span[0], span[1], currentHour, (minuteOfDay % 60) / 60.0);

        var shapes = hourPoints(layout, span[0], span[1], currentHour);
        shapes.addAll(ClockArc.shapes(layout, layout.timeRadius, minuteOfDay, Palette.CRAIE));
        shapes.addAll(quarterGaps(layout, layout.timeRadius, quarters));
        shapes.addAll(quarterTicks(layout, layout.timeRadius, quarters));
        return shapes;
    }

    //! The Always-On scene: the time arc and hour bar in _brume_ instead of
    //! _craie_, plus the quarter gaps - an _encre_ cut is free to keep, since
    //! it removes lit pixels rather than adding them. Everything else -
    //! numerals, dots, the _brume_ tick inside each gap - is dropped, to stay
    //! well inside the low-power luminance budget.
    function aodScene(layout as Layout, minuteOfDay as Number) as Array<Shapes.Shape> {
        var span = ClockArc.span(minuteOfDay);
        var currentHour = (minuteOfDay % ClockArc.TURN) / 60;
        var quarters = passedQuarters(span[0], span[1], currentHour, (minuteOfDay % 60) / 60.0);

        var shapes = ClockArc.shapes(layout, layout.timeRadius, minuteOfDay, Palette.BRUME);
        shapes.addAll(quarterGaps(layout, layout.timeRadius, quarters));
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

    //! The quarters (3/6/9 o'clock) the arc has run at least a minute past,
    //! except the current hour's: the positions where a gap should be cut so
    //! the dial stays legible once the arc has swallowed the point.
    function passedQuarters(
        start as Float, sweep as Float, currentHour as Number, minuteHand as Float
    ) as Array<Float> {
        var positions = [] as Array<Float>;
        for (var hour = 0; hour < 12; hour += 3) {
            var position = hour / 12.0;
            if (hour == currentHour
                || !isCovered(position, start, sweep)
                || distance(position, minuteHand) < ONE_MINUTE) {
                continue;
            }
            positions.add(position);
        }
        return positions;
    }

    //! An _encre_ stroke across the arc at each of `positions`, twice the
    //! arc's width, reaching as far either side of the track as the hour bar
    //! does.
    function quarterGaps(layout as Layout, radius as Float, positions as Array<Float>) as Array<Shapes.Shape> {
        var shapes = [] as Array<Shapes.Shape>;
        var innerRadius = radius - layout.capReach;
        var outerRadius = radius + layout.capReach;
        for (var index = 0; index < positions.size(); index++) {
            shapes.add(layout.radial(positions[index], innerRadius, outerRadius, Palette.ENCRE, 2.0 * layout.arcWidth));
        }
        return shapes;
    }

    //! A thin _brume_ tick inside each gap `quarterGaps` cuts, marking the
    //! quarter itself. Not included in `aodScene`, since _brume_ is dropped
    //! there to stay inside the low-power luminance budget.
    function quarterTicks(layout as Layout, radius as Float, positions as Array<Float>) as Array<Shapes.Shape> {
        var shapes = [] as Array<Shapes.Shape>;
        var innerRadius = radius - layout.capReach;
        var outerRadius = radius + layout.capReach;
        for (var index = 0; index < positions.size(); index++) {
            shapes.add(layout.radial(positions[index], innerRadius, outerRadius, Palette.BRUME, layout.arcWidth / 2.0));
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
