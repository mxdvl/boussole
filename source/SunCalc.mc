import Toybox.Lang;
import Toybox.Math;

//! Sunrise/sunset for a date and location, via the standard "sunrise equation"
//! (NOAA/Wikipedia). Pure math, no I/O. Longitude is east-positive (as returned
//! by `Position`), latitude north-positive. Times are Unix seconds (UTC); the
//! caller converts to local clock time via `Gregorian.info`.
module SunCalc {

    const DEG = Math.PI / 180.0;

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
        var jd = julian(nowUnix);
        var today = riseSet(jd, latDeg, lonDeg);
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

        var tomorrow = riseSet(jd + 1.0, latDeg, lonDeg);
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

    //! Sunrise and sunset for the solar day containing Julian date `jd`.
    //! Returns { :rise => Double, :set => Double } in Unix seconds, or null when
    //! the sun neither rises nor sets that day (polar day/night).
    function riseSet(jd as Double, latDeg as Double, lonDeg as Double) as Dictionary<Symbol, Double>? {
        var n = ((jd - 2451545.0 + 0.0008) + 0.5).toNumber().toDouble();

        var jStar = n + lonDeg / 360.0;                 // mean solar noon
        var m = mod360(357.5291 + 0.98560028 * jStar);  // solar mean anomaly, deg
        var mr = m * DEG;

        var c = 1.9148 * Math.sin(mr) + 0.02 * Math.sin(2.0 * mr) + 0.0003 * Math.sin(3.0 * mr);
        var lambda = mod360(m + c + 282.9372);          // ecliptic longitude, deg
        var lr = lambda * DEG;

        var jTransit = 2451545.0 + jStar + 0.0053 * Math.sin(mr) - 0.0069 * Math.sin(2.0 * lr);

        var sinDelta = Math.sin(lr) * Math.sin(23.4397 * DEG);
        var cosDelta = Math.sqrt(1.0 - sinDelta * sinDelta);

        var latR = latDeg * DEG;
        var cosOmega = (Math.sin(-0.833 * DEG) - Math.sin(latR) * sinDelta) / (Math.cos(latR) * cosDelta);
        if (cosOmega > 1.0 || cosOmega < -1.0) {
            return null;                                 // sun stays down / up all day
        }

        var omega = Math.acos(cosOmega) / DEG;           // hour angle, deg
        var jRise = jTransit - omega / 360.0;
        var jSet = jTransit + omega / 360.0;

        return {
            :rise => (jRise - 2440587.5) * 86400.0,
            :set => (jSet - 2440587.5) * 86400.0,
        };
    }

    //! Reduce an angle in degrees to [0, 360).
    function mod360(x as Double) as Double {
        var r = x - (x / 360.0).toNumber() * 360.0;
        if (r < 0.0) {
            r += 360.0;
        }
        return r;
    }
}
