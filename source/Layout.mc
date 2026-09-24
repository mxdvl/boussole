import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Where things go, derived only from the screen size. Tracks, from the rim
//! inwards:
//!
//!   timeRadius   time arc and its 12 hour points, close to the rim; the hour
//!                cap crosses it, reaching capReach either side
//!   stepsRadius  steps arc, clear of the hour cap
//!
//! A position on a track is a fraction of a turn clockwise from 12 o'clock
//! (0.25 = 3 o'clock, 0.5 = 6 o'clock).
class Layout {

    public var centreX as Float;
    public var centreY as Float;

    public var arcWidth as Float;         // time arc, px
    public var penWidth as Float;         // steps arc and sun marker, px
    public var numeralPenWidth as Float;  // roman numeral strokes, px
    public var numeralHeight as Float;    // px
    public var capReach as Float;         // hour cap, px either side of the arc

    public var timeRadius as Float;
    public var stepsRadius as Float;

    function initialize(screenWidth as Number, screenHeight as Number) {
        var screenRadius = (screenWidth < screenHeight ? screenWidth : screenHeight) / 2.0;

        centreX = screenWidth / 2.0;
        centreY = screenHeight / 2.0;

        arcWidth = 6.0;
        penWidth = 3.0;
        numeralPenWidth = 2.0;
        numeralHeight = screenRadius * 0.075;
        capReach = screenRadius * 0.05;

        timeRadius = screenRadius - capReach - 6.0;
        stepsRadius = timeRadius - capReach - penWidth - 8.0;
    }

    //! Screen x of the point `radius` from the centre at `fraction` of a turn.
    function xAt(radius as Float, fraction as Float) as Float {
        return (centreX + radius * Math.sin(fraction * 2.0 * Math.PI)).toFloat();
    }

    //! Screen y of the point `radius` from the centre at `fraction` of a turn.
    function yAt(radius as Float, fraction as Float) as Float {
        return (centreY - radius * Math.cos(fraction * 2.0 * Math.PI)).toFloat();
    }

    //! A square-ended bar across the track of `radius` at `fraction` of a turn:
    //! `reach` px either side of the track, `thickness` px along it, centred
    //! exactly on the track.
    function bar(
        fraction as Float, radius as Float, reach as Float, thickness as Float,
        color as Graphics.ColorType
    ) as Shapes.Polygon {
        var angle = fraction * 2.0 * Math.PI;
        var outwardX = Math.sin(angle);
        var outwardY = -Math.cos(angle);
        var alongX = -outwardY * thickness / 2.0;
        var alongY = outwardX * thickness / 2.0;
        var innerX = xAt(radius - reach, fraction);
        var innerY = yAt(radius - reach, fraction);
        var outerX = xAt(radius + reach, fraction);
        var outerY = yAt(radius + reach, fraction);
        return new Shapes.Polygon([
            [innerX - alongX, innerY - alongY],
            [outerX - alongX, outerY - alongY],
            [outerX + alongX, outerY + alongY],
            [innerX + alongX, innerY + alongY],
        ] as Array<[Numeric, Numeric]>, color);
    }

    //! A radial stroke at `fraction` of a turn, from `innerRadius` to `outerRadius`.
    function radial(
        fraction as Float, innerRadius as Float, outerRadius as Float,
        color as Graphics.ColorType, strokeWidth as Float
    ) as Shapes.Line {
        return new Shapes.Line(
            xAt(innerRadius, fraction), yAt(innerRadius, fraction),
            xAt(outerRadius, fraction), yAt(outerRadius, fraction),
            color, strokeWidth
        );
    }
}
