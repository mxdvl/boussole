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

        for (var i = 0; i < scene.size(); i++) {
            var s = scene[i];
            if (s instanceof Shapes.Arc) {
                drawArc(dc, s as Shapes.Arc);
            } else if (s instanceof Shapes.Line) {
                var l = s as Shapes.Line;
                dc.setColor(l.color, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(l.pen);
                dc.drawLine(l.x1, l.y1, l.x2, l.y2);
            } else if (s instanceof Shapes.Dot) {
                var d = s as Shapes.Dot;
                dc.setColor(d.color, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(d.x, d.y, d.r);
            } else if (s instanceof Shapes.Box) {
                var b = s as Shapes.Box;
                dc.setColor(b.color, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(b.x - b.w / 2.0, b.y - b.h / 2.0, b.w, b.h);
            }
        }
    }

    function drawArc(dc as Graphics.Dc, a as Shapes.Arc) as Void {
        dc.setColor(a.color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(a.pen);
        if (a.sweep >= 1.0) {
            dc.drawCircle(a.cx, a.cy, a.r);
            return;
        }
        if (a.sweep * 360.0 < 0.5) {
            return;
        }
        dc.drawArc(
            a.cx, a.cy, a.r, Graphics.ARC_CLOCKWISE,
            degrees(a.start), degrees(a.start + a.sweep)
        );
    }

    //! A fraction of a turn clockwise from 12 o'clock, as the Dc's angle:
    //! degrees counter-clockwise from 3 o'clock, in [0, 360).
    function degrees(fraction as Float) as Float {
        var d = 90.0 - fraction * 360.0;
        while (d < 0.0) {
            d += 360.0;
        }
        return d;
    }
}
