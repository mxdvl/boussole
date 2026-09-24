import Toybox.Lang;
import Toybox.Math;

//! Sunrise/sunset for a date and location, via the standard "sunrise equation"
//! (NOAA/Wikipedia). Pure math, no I/O. Longitude is east-positive (as returned
//! by `Position`), latitude north-positive. Times are Unix seconds (UTC) until
//! `nextEvent` converts them to a local time of day.
module SunCalc {

    const DEG = Math.PI / 180.0;  // radians per degree

    //! A sunrise or sunset, at a local time of day.
    class Event {
        public var minuteOfDay as Number;
        public var isSunrise as Boolean;

        function initialize(minuteOfDay as Number, isSunrise as Boolean) {
            self.minuteOfDay = minuteOfDay;
            self.isSunrise = isSunrise;
        }
    }

    //! The next sun event after `nowUnix` at (`latDeg`, `lonDeg`): today's
    //! sunrise, else today's sunset, else tomorrow's sunrise. `utcOffset` is
    //! the local offset in seconds (DST included), used for the time of day.
    //! Null during polar day/night.
    function nextEvent(nowUnix as Double, latDeg as Double, lonDeg as Double, utcOffset as Number) as Event? {
        var julianDate = julian(nowUnix);
        var today = riseSet(julianDate, latDeg, lonDeg);
        if (today == null) {
            return null;
        }
        var rise = today[:rise];
        var set = today[:set];
        if (rise == null || set == null) {
            return null;
        }
        if (nowUnix < rise) {
            return new Event(localMinuteOfDay(rise, utcOffset), true);
        }
        if (nowUnix < set) {
            return new Event(localMinuteOfDay(set, utcOffset), false);
        }

        var tomorrow = riseSet(julianDate + 1.0, latDeg, lonDeg);
        if (tomorrow == null) {
            return null;
        }
        var nextRise = tomorrow[:rise];
        if (nextRise == null) {
            return null;
        }
        return new Event(localMinuteOfDay(nextRise, utcOffset), true);
    }

    //! Local minute of the day (0-1439) for a moment in Unix seconds.
    function localMinuteOfDay(unixSeconds as Double, utcOffset as Number) as Number {
        return (((unixSeconds.toLong() + utcOffset) / 60) % 1440).toNumber();
    }

    //! Julian date for a moment given as Unix seconds.
    function julian(unixSeconds as Double) as Double {
        return unixSeconds / 86400.0 + 2440587.5;
    }

    //! Sunrise and sunset for the solar day containing `julianDate`.
    //! Returns { :rise => Double, :set => Double } in Unix seconds, or null when
    //! the sun neither rises nor sets that day (polar day/night).
    function riseSet(julianDate as Double, latDeg as Double, lonDeg as Double) as Dictionary<Symbol, Double>? {
        var dayNumber = ((julianDate - 2451545.0 + 0.0008) + 0.5).toNumber().toDouble();

        var meanNoon = dayNumber + lonDeg / 360.0;
        var meanAnomaly = mod360(357.5291 + 0.98560028 * meanNoon);  // deg
        var meanAnomalyRad = meanAnomaly * DEG;

        var equationOfCentre = 1.9148 * Math.sin(meanAnomalyRad)
            + 0.02 * Math.sin(2.0 * meanAnomalyRad)
            + 0.0003 * Math.sin(3.0 * meanAnomalyRad);
        var eclipticLongitude = mod360(meanAnomaly + equationOfCentre + 282.9372);  // deg
        var eclipticLongitudeRad = eclipticLongitude * DEG;

        var transit = 2451545.0 + meanNoon
            + 0.0053 * Math.sin(meanAnomalyRad)
            - 0.0069 * Math.sin(2.0 * eclipticLongitudeRad);

        var sinDeclination = Math.sin(eclipticLongitudeRad) * Math.sin(23.4397 * DEG);
        var cosDeclination = Math.sqrt(1.0 - sinDeclination * sinDeclination);

        var latRad = latDeg * DEG;
        var cosHourAngle = (Math.sin(-0.833 * DEG) - Math.sin(latRad) * sinDeclination)
            / (Math.cos(latRad) * cosDeclination);
        if (cosHourAngle > 1.0 || cosHourAngle < -1.0) {
            return null;  // sun stays down / up all day
        }

        var hourAngle = Math.acos(cosHourAngle) / DEG;  // deg
        var riseJulian = transit - hourAngle / 360.0;
        var setJulian = transit + hourAngle / 360.0;

        return {
            :rise => (riseJulian - 2440587.5) * 86400.0,
            :set => (setJulian - 2440587.5) * 86400.0,
        };
    }

    //! Reduce an angle in degrees to [0, 360).
    function mod360(degrees as Double) as Double {
        var reduced = degrees - (degrees / 360.0).toNumber() * 360.0;
        if (reduced < 0.0) {
            reduced += 360.0;
        }
        return reduced;
    }
}
