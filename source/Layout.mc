import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Where things go, derived only from the screen size. Tracks, from the rim
//! inwards:
//!
//!   stepsRadius  steps arc
//!   timeRadius   time arc and its 12 hour points; the minute tick reaches out
//!                to timeRadius + tickLength, the hour tick in to
//!                timeRadius - tickLength
//!
//! A position on a track is a fraction of a turn clockwise from 12 o'clock
//! (0.25 = 3 o'clock, 0.5 = 6 o'clock).
class Layout {

    public var centreX as Float;
    public var centreY as Float;

    public var penWidth as Float;         // arcs and ticks, px
    public var numeralPenWidth as Float;  // roman numeral strokes, px
    public var numeralHeight as Float;    // px
    public var tickLength as Float;       // px

    public var stepsRadius as Float;
    public var timeRadius as Float;

    function initialize(screenWidth as Number, screenHeight as Number) {
        var screenRadius = (screenWidth < screenHeight ? screenWidth : screenHeight) / 2.0;

        centreX = screenWidth / 2.0;
        centreY = screenHeight / 2.0;

        penWidth = 3.0;
        numeralPenWidth = 2.0;
        numeralHeight = screenRadius * 0.075;
        tickLength = screenRadius * 0.06;

        stepsRadius = screenRadius - penWidth - 4.0;
        timeRadius = stepsRadius - penWidth - tickLength - 8.0;
    }

    //! Screen x of the point `radius` from the centre at `fraction` of a turn.
    function xAt(radius as Float, fraction as Float) as Float {
        return (centreX + radius * Math.sin(fraction * 2.0 * Math.PI)).toFloat();
    }

    //! Screen y of the point `radius` from the centre at `fraction` of a turn.
    function yAt(radius as Float, fraction as Float) as Float {
        return (centreY - radius * Math.cos(fraction * 2.0 * Math.PI)).toFloat();
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
