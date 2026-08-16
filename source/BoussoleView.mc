import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

//! Analog watch face that draws hour and minute hands over a simple
//! 12-tick dial. Kept intentionally minimal as the base to build on.
class BoussoleView extends WatchUi.WatchFace {

    function initialize() {
        WatchFace.initialize();
    }

    //! Load the resource layout. Nothing to load yet since everything is
    //! drawn procedurally in onUpdate.
    function onLayout(dc as Graphics.Dc) as Void {
    }

    //! Called once per minute in low-power mode (and on wake). Draws the
    //! whole face from scratch.
    function onUpdate(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2.0;
        var centerY = height / 2.0;
        var radius = (width < height ? width : height) / 2.0;

        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        // Clear to black.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        drawTicks(dc, centerX, centerY, radius);

        var clockTime = System.getClockTime();
        var minute = clockTime.min;
        var hour = clockTime.hour % 12;

        // Angles in radians, 0 pointing up, increasing clockwise.
        var minuteAngle = (minute / 60.0) * Math.PI * 2.0;
        var hourAngle = ((hour + minute / 60.0) / 12.0) * Math.PI * 2.0;

        // Hour hand: shorter and thicker.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawHand(dc, centerX, centerY, hourAngle, radius * 0.52, 7.0);

        // Minute hand: longer and thinner.
        drawHand(dc, centerX, centerY, minuteAngle, radius * 0.82, 4.0);

        // Center hub.
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, 5);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, 2);
    }

    //! Draw a hand as a rotated rectangle pointing outward from center.
    private function drawHand(
        dc as Graphics.Dc,
        cx as Float,
        cy as Float,
        angle as Float,
        length as Float,
        thickness as Float
    ) as Void {
        var halfWidth = thickness / 2.0;
        // Rectangle corners for a hand pointing straight up from center.
        var cornerX = [ -halfWidth, -halfWidth, halfWidth, halfWidth ];
        var cornerY = [ 0.0, -length, -length, 0.0 ];

        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        var points = new Array<[Numeric, Numeric]>[4];
        for (var i = 0; i < 4; i++) {
            var x = cornerX[i];
            var y = cornerY[i];
            points[i] = [
                cx + x * cos - y * sin,
                cy + x * sin + y * cos
            ];
        }

        dc.fillPolygon(points);
    }

    //! Draw 12 tick marks around the dial, with the quarter marks longer.
    private function drawTicks(
        dc as Graphics.Dc,
        cx as Float,
        cy as Float,
        radius as Float
    ) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < 12; i++) {
            var angle = (i / 12.0) * Math.PI * 2.0;
            var sin = Math.sin(angle);
            var cos = Math.cos(angle);

            var isQuarter = (i % 3 == 0);
            var innerLength = isQuarter ? radius - 16 : radius - 9;
            dc.setPenWidth(isQuarter ? 4 : 2);

            dc.drawLine(
                cx + radius * sin,
                cy - radius * cos,
                cx + innerLength * sin,
                cy - innerLength * cos
            );
        }
    }

    //! Called when the device enters low-power (sleep) mode.
    function onEnterSleep() as Void {
    }

    //! Called when the device exits low-power (sleep) mode.
    function onExitSleep() as Void {
    }
}
