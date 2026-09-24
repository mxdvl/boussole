import Toybox.Lang;
import Toybox.Position;
import Toybox.Time;

//! The next sunrise or sunset at the last known location: today's sunrise,
//! else today's sunset, else tomorrow's sunrise.
class SunEvent {

    public var moment as Time.Moment;
    public var isSunrise as Boolean;

    function initialize(moment as Time.Moment, isSunrise as Boolean) {
        self.moment = moment;
        self.isSunrise = isSunrise;
    }

    //! Null without a known location or during polar day/night.
    static function next() as SunEvent? {
        var loc = Position.getInfo().position;
        if (loc == null) {
            return null;
        }
        var deg = loc.toDegrees();
        var lat = deg[0];
        var lon = deg[1];

        var now = Time.now().value().toDouble();
        var jd = SunCalc.julian(now);
        var today = SunCalc.riseSet(jd, lat, lon);
        if (today == null) {
            return null;
        }
        var rise = today[:rise];
        var set = today[:set];
        if (rise == null || set == null) {
            return null;
        }

        if (now < rise) {
            return new SunEvent(new Time.Moment(rise.toNumber()), true);
        }
        if (now < set) {
            return new SunEvent(new Time.Moment(set.toNumber()), false);
        }

        var tomorrow = SunCalc.riseSet(jd + 1.0, lat, lon);
        if (tomorrow == null) {
            return null;
        }
        var nextRise = tomorrow[:rise];
        if (nextRise == null) {
            return null;
        }
        return new SunEvent(new Time.Moment(nextRise.toNumber()), true);
    }
}
