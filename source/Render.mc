import Toybox.Graphics;
import Toybox.Lang;

//! The only code that draws: turns a scene (an array of `Shapes`) into pixels,
//! in order, on a cleared black screen.
module Render {

    function draw(dc as Graphics.Dc, scene as Array<Shapes.Shape>) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        for (var index = 0; index < scene.size(); index++) {
            var shape = scene[index];
            if (shape instanceof Shapes.Arc) {
                drawArc(dc, shape as Shapes.Arc);
            } else if (shape instanceof Shapes.Line) {
                var line = shape as Shapes.Line;
                dc.setColor(line.color, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(line.penWidth);
                dc.drawLine(line.fromX, line.fromY, line.toX, line.toY);
            } else if (shape instanceof Shapes.Dot) {
                var dot = shape as Shapes.Dot;
                dc.setColor(dot.color, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dot.centreX, dot.centreY, dot.radius);
            } else if (shape instanceof Shapes.Polygon) {
                var polygon = shape as Shapes.Polygon;
                dc.setColor(polygon.color, Graphics.COLOR_TRANSPARENT);
                dc.fillPolygon(polygon.corners);
            }
        }
    }

    function drawArc(dc as Graphics.Dc, arc as Shapes.Arc) as Void {
        dc.setColor(arc.color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(arc.penWidth);
        if (arc.sweep >= 1.0) {
            dc.drawCircle(arc.centreX, arc.centreY, strokeRadius(arc));
            return;
        }
        if (arc.sweep * 360.0 < 0.5) {
            return;
        }
        dc.drawArc(
            arc.centreX, arc.centreY, strokeRadius(arc), Graphics.ARC_CLOCKWISE,
            degrees(arc.start), degrees(arc.start + arc.sweep)
        );
    }

    //! The Dc grows a thick arc inwards from the radius it is given, rather
    //! than centring the stroke on it. Push it out by half the pen width so
    //! the stroke is centred on `arc.radius`, matching every other shape.
    function strokeRadius(arc as Shapes.Arc) as Float {
        return arc.radius + arc.penWidth / 2.0;
    }

    //! A fraction of a turn clockwise from 12 o'clock, as the Dc's angle:
    //! degrees counter-clockwise from 3 o'clock, in [0, 360).
    function degrees(fraction as Float) as Float {
        var angle = 90.0 - fraction * 360.0;
        while (angle < 0.0) {
            angle += 360.0;
        }
        return angle;
    }
}
