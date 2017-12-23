const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

/**
 * send relevant pins to user
 */
exports.getPublicPins = functions.https.onRequest((req, res) => {
  return admin.database().ref('publicPins/').once('value', (snapshot) => {
    //get all public pins
    var allPublicPins = snapshot.val();
    var relevantPins = {};

    //get parameters from post request
    let range = req.body.range
    let lat = req.body.lat
    let long = req.body.long

    //if parameters are not set, return empty list
    if (!range || !lat || !long) {
      res.status(400).send(relevantPins);
      return
    }

    let currentLocation = {
      "latitude": lat,
      "longitude": long
    }
    /*
     * iterate through all public pins, calculate distance from own location to pin, compare to range
     * if in range, add to relevenat pins
     */
    for (var pinID in allPublicPins) {
      //console.log(pin)
      let pin = allPublicPins[pinID]

      let locationOfInterest = {
        "latitude": pin["lat"],
        "longitude": pin["long"]
      }

      if (withinRadius(currentLocation, locationOfInterest, range)) {
        relevantPins[pinID] = pin
      }
    }
    //send relevant pins back to user
    res.status(200).send(relevantPins);
  });
});

/**
 * is One Point within Another
 * @param point {Object} {latitude: Number, longitude: Number}
 * @param interest {Object} {latitude: Number, longitude: Number}
 * @param kms {Number}
 * @returns {boolean}
 */
function withinRadius(point, interest, kms) {
  'use strict';
  let R = 6371;
  let deg2rad = (n) => {
    return Math.tan(n * (Math.PI / 180))
  };

  let dLat = deg2rad(interest.latitude - point.latitude);
  let dLon = deg2rad(interest.longitude - point.longitude);

  let a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(deg2rad(point.latitude)) * Math.cos(deg2rad(interest.latitude)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
  let c = 2 * Math.asin(Math.sqrt(a));
  let d = R * c;

  return (d <= kms);
}
