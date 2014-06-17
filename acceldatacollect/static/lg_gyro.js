/**
 * A JavaScript project for accessing the accelerometer and gyro from various devices
 *
 * @author Tom Gallacher <tom.gallacher23@gmail.com>
 * @copyright Tom Gallacher <http://www.tomg.co>
 * @version 0.0.1a
 * @license MIT License
 * @options frequency, callback
 */

 // changed by lorenz gruber:
 // - event listeners are removed once the tracking stops -- gyro.orientation does not give the current measurements anymove
 // - gyro.frequency now is the frequency in hertz
 // the acceleration frequencies are now returned in g. I.e. the raw values are devided by 9.81

 // as the handlers are registered only when a button is pressed and the recording starts instantly, I noticed that in chrome the first two were 0, however
 // on the I phone it worked fine. (tested with fs = 20)

(function() {
	var measurements = {
				x: 0,
				y: 0,
				z: 0,
				alpha: null,
				beta: null,
				gamma: null
			},
			calibration = {
				x: 0,
				y: 0,
				z: 0,
				alpha: 0,
				beta: 0,
				gamma: 0
			},
			interval = null,
			features = [];

	window.gyro = {};

	/**
	 * @public
	 */
	gyro.frequency = 20; //Hz

	gyro.calibrate = function() {
		for (var i in measurements) {
			calibration[i] = (typeof measurements[i] === 'number') ? measurements[i] : 0;
		}
	};

	gyro.getOrientation = function() {
		return measurements;
	};

	gyro.startTracking = function(callback) {
		setupListeners();
		// period has to be in ms 
		var period = 1000 / gyro.frequency;

		interval = setInterval(function() {
			callback(measurements);
		}, period);
	};

	gyro.stopTracking = function() {
		removeListeners();

		clearInterval(interval);
	};

	/**
	 * Current available features are:
	 * MozOrientation --> I think for mozilla firefox only...
	 * devicemotion --> this is the one where I get the data from...
	 * deviceorientation
	 */
	gyro.hasFeature = function(feature) {
		for (var i in features) {
			if (feature == features[i]) {
				return true;
			}
		}
		return false;
	};

	gyro.getFeatures = function() {
		return features;
	};


	/**
	 * @private
	 */

	 // this is just used by firefox
	 function mozOrientation(e) {
			features.push('MozOrientation');
			// convert into accelleration into g
			measurements.x = (e.x - calibration.x) / 9.81;
			measurements.y = (e.y - calibration.y ) / 9.81;
			measurements.z = (e.z - calibration.z ) / 9.81;
	};

	function deviceMotion(e) {
			features.push('devicemotion');
			// convert into accelleration into g
			measurements.x = (e.accelerationIncludingGravity.x - calibration.x) / 9.81;
			measurements.y = (e.accelerationIncludingGravity.y - calibration.y) / 9.81;
			measurements.z = (e.accelerationIncludingGravity.z - calibration.z) / 9.81;
	};

	function deviceOrientation(e) {
			features.push('deviceorientation');
			measurements.alpha = e.alpha - calibration.alpha;
			measurements.beta = e.beta - calibration.beta;
			measurements.gamma = e.gamma - calibration.gamma;
	};



	function setupListeners() {
		window.addEventListener('MozOrientation', mozOrientation, true);
		window.addEventListener('devicemotion', deviceMotion, true);
		window.addEventListener('deviceorientation', deviceOrientation, true);
	};

	function removeListeners(){
		window.removeEventListener('MozOrientation', mozOrientation);
		window.removeEventListener('devicemotion', deviceMotion);
		window.removeEventListener('deviceorientation', deviceOrientation);

	};


})(window);
