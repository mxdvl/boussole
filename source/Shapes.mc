import Toybox.Graphics;
import Toybox.Lang;

//! Plain drawing records: what to draw, never how. The ring modules build
//! arrays of these with pure functions; `Render` is the only code that turns
//! them into pixels. Arrays are drawn in order (painter's algorithm), so a
//! black shape later in the list cuts a gap in whatever came before it.
module Shapes {

    typedef Shape as Arc or Line or Dot or Box;

    //! Arc on the circle of radius `r` about (`cx`, `cy`), from `start`
    //! clockwise for `sweep`. Both are fractions of a turn from 12 o'clock;
    //! a sweep of 1 or more is a full circle.
    class Arc {
        public var cx as Float;
        public var cy as Float;
        public var r as Float;
        public var start as Float;
        public var sweep as Float;
        public var color as Graphics.ColorType;
        public var pen as Float;

        function initialize(
            cx as Float, cy as Float, r as Float,
            start as Float, sweep as Float,
            color as Graphics.ColorType, pen as Float
        ) {
            self.cx = cx;
            self.cy = cy;
            self.r = r;
            self.start = start;
            self.sweep = sweep;
            self.color = color;
            self.pen = pen;
        }
    }

    //! Straight stroke between two screen points.
    class Line {
        public var x1 as Float;
        public var y1 as Float;
        public var x2 as Float;
        public var y2 as Float;
        public var color as Graphics.ColorType;
        public var pen as Float;

        function initialize(
            x1 as Float, y1 as Float, x2 as Float, y2 as Float,
            color as Graphics.ColorType, pen as Float
        ) {
            self.x1 = x1;
            self.y1 = y1;
            self.x2 = x2;
            self.y2 = y2;
            self.color = color;
            self.pen = pen;
        }
    }

    //! Filled circle centred on (`x`, `y`).
    class Dot {
        public var x as Float;
        public var y as Float;
        public var r as Float;
        public var color as Graphics.ColorType;

        function initialize(x as Float, y as Float, r as Float, color as Graphics.ColorType) {
            self.x = x;
            self.y = y;
            self.r = r;
            self.color = color;
        }
    }

    //! Filled rectangle centred on (`x`, `y`).
    class Box {
        public var x as Float;
        public var y as Float;
        public var w as Float;
        public var h as Float;
        public var color as Graphics.ColorType;

        function initialize(x as Float, y as Float, w as Float, h as Float, color as Graphics.ColorType) {
            self.x = x;
            self.y = y;
            self.w = w;
            self.h = h;
            self.color = color;
        }
    }
}
