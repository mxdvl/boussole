import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Application entry point for the Boussole watch face.
class BoussoleApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    //! Called on application start up.
    function onStart(state as Dictionary?) as Void {
    }

    //! Called when the application is exiting.
    function onStop(state as Dictionary?) as Void {
    }

    //! Return the initial view for the watch face. A watch face has no
    //! input delegate, so we return just the view.
    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [ new BoussoleView() ];
    }
}
