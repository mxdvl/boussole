import Toybox.Lang;
import Toybox.Test;

//! Simulator-only regression tests; omitted from normal and release builds.
(:test)
module SunCalcTests {

    // 21 June 2026 at noon UTC, and 22 June at midnight UTC.
    const JUNE_21_NOON = 2461213.0d;
    const JUNE_22_MIDNIGHT = 1782086400.0d;

    (:test)
    function longitudeDirection(logger as Test.Logger) as Boolean {
        var east = SunCalc.riseSet(JUNE_21_NOON, 0.0d, 30.0d);
        var west = SunCalc.riseSet(JUNE_21_NOON, 0.0d, -30.0d);
        if (east == null || west == null) { return false; }
        // At the equator, 60 degrees of longitude shifts both events by
        // approximately four hours, with the eastern event occurring first.
        var events = [:rise, :set];
        for (var index = 0; index < events.size(); index++) {
            var event = events[index];
            var hours = ((west[event] as Double) - (east[event] as Double)) / 3600.0d;
            if (hours < 3.9d || hours > 4.1d) {
                logger.error("West minus east event time (hours): " + hours);
                return false;
            }
        }
        return true;
    }

    (:test)
    function cycleChangesAtUtcMidnight(logger as Test.Logger) as Boolean {
        var noon = SunCalc.riseSet(JUNE_21_NOON, 0.0d, 0.0d);
        var beforeMidnight = SunCalc.riseSet(SunCalc.julian(JUNE_22_MIDNIGHT - 1.0d), 0.0d, 0.0d);
        var midnight = SunCalc.riseSet(SunCalc.julian(JUNE_22_MIDNIGHT), 0.0d, 0.0d);
        if (noon == null || beforeMidnight == null || midnight == null) { return false; }
        if (noon[:rise] != beforeMidnight[:rise]) { return false; }
        var elapsed = (midnight[:rise] as Double) - (noon[:rise] as Double);
        return elapsed > 86000.0d && elapsed < 86800.0d;
    }

    (:test)
    function sunsetAcrossUtcMidnight(logger as Test.Logger) as Boolean {
        // At 65 N, 60 W near the summer solstice, sunset is around 03:03
        // UTC on the following calendar day. Crossing UTC midnight must
        // not replace that upcoming sunset with the later sunrise.
        var before = SunCalc.nextEvent(JUNE_22_MIDNIGHT - 120.0d, 65.0d, -60.0d, 0);
        var after = SunCalc.nextEvent(JUNE_22_MIDNIGHT, 65.0d, -60.0d, 0);
        logger.debug("Next event before/after midnight: " + before + "/" + after);
        if (before == null || after == null) { return false; }
        if (before != after) { return false; }
        return after >= 178 && after <= 188;
    }

    (:test)
    function advanceAfterSunset(logger as Test.Logger) as Boolean {
        var cycle = SunCalc.riseSet(JUNE_21_NOON, 65.0d, -60.0d);
        if (cycle == null) { return false; }
        var sunset = cycle[:set] as Double;
        var justBefore = SunCalc.nextEvent(sunset - 1.0d, 65.0d, -60.0d, 0);
        var atSunset = SunCalc.nextEvent(sunset, 65.0d, -60.0d, 0);
        var justAfter = SunCalc.nextEvent(sunset + 1.0d, 65.0d, -60.0d, 0);
        // At and after sunset, the next event must be the ~05:00 sunrise.
        if (atSunset == null) { return false; }
        if (justBefore != SunCalc.localMinuteOfDay(sunset, 0)) { return false; }
        if (justAfter != atSunset) { return false; }
        return atSunset >= 295 && atSunset <= 310;
    }

    (:test)
    function localOffsetWrapsDate(logger as Test.Logger) as Boolean {
        var utc = SunCalc.nextEvent(JUNE_22_MIDNIGHT, 65.0d, -60.0d, 0);
        var local = SunCalc.nextEvent(JUNE_22_MIDNIGHT, 65.0d, -60.0d, -4 * 3600);
        if (utc == null || local == null) { return false; }
        return local == (utc - 240 + 1440) % 1440;
    }

    (:test)
    function dateLineSunrise(logger as Test.Logger) as Boolean {
        // These longitudes describe neighbouring places on either side of
        // the date line. Their next sunrise must be only minutes apart.
        var east = SunCalc.nextEvent(JUNE_22_MIDNIGHT + 12.0d * 3600.0d, 0.0d, 179.0d, 0);
        var west = SunCalc.nextEvent(JUNE_22_MIDNIGHT + 12.0d * 3600.0d, 0.0d, -179.0d, 0);
        if (east == null || west == null) { return false; }
        if (east < 1070 || east > 1090) { return false; }
        if (west < 1070 || west > 1090) { return false; }
        return east > west;
    }

    (:test)
    function polarDayAndNight(logger as Test.Logger) as Boolean {
        return SunCalc.nextEvent(JUNE_22_MIDNIGHT, 89.0d, 0.0d, 0) == null
            && SunCalc.nextEvent(JUNE_22_MIDNIGHT, -89.0d, 0.0d, 0) == null;
    }
}
