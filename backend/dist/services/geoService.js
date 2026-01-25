"use strict";
// Geo-calculation Service
// Purpose: Calculate distances and validate geofences using Haversine formula
Object.defineProperty(exports, "__esModule", { value: true });
exports.calculateDistance = calculateDistance;
exports.isWithinGeofence = isWithinGeofence;
exports.validateCoordinates = validateCoordinates;
const logger_1 = require("../utils/logger");
// Earth's radius in meters
const EARTH_RADIUS_METERS = 6371000;
/**
 * Convert degrees to radians
 */
function toRadians(degrees) {
    return degrees * (Math.PI / 180);
}
/**
 * Calculate distance between two GPS coordinates using Haversine formula
 * This is the standard formula for calculating great-circle distance on a sphere
 *
 * @param lat1 - Latitude of first point
 * @param lon1 - Longitude of first point
 * @param lat2 - Latitude of second point
 * @param lon2 - Longitude of second point
 * @returns Distance in meters
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
    // Convert to radians
    const phi1 = toRadians(lat1);
    const phi2 = toRadians(lat2);
    const deltaPhi = toRadians(lat2 - lat1);
    const deltaLambda = toRadians(lon2 - lon1);
    // Haversine formula
    const a = Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
        Math.cos(phi1) * Math.cos(phi2) *
            Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    // Distance in meters
    const distance = EARTH_RADIUS_METERS * c;
    return Math.round(distance); // Round to nearest meter
}
/**
 * Check if a point is within any of the allowed geofences
 * Returns the matching location if found, null otherwise
 *
 * @param userLat - User's current latitude
 * @param userLon - User's current longitude
 * @param locations - Array of allowed office locations
 * @returns Matching location or null
 */
function isWithinGeofence(userLat, userLon, locations) {
    for (const location of locations) {
        const distance = calculateDistance(userLat, userLon, location.latitude, location.longitude);
        logger_1.logger.debug('Geofence check', {
            location: location.name,
            distance,
            radius: location.radius_meters,
            withinRange: distance <= location.radius_meters,
        });
        if (distance <= location.radius_meters) {
            return location;
        }
    }
    return null;
}
/**
 * Validate GPS coordinates are within valid ranges
 * Latitude: -90 to 90
 * Longitude: -180 to 180
 */
function validateCoordinates(lat, lon) {
    return (typeof lat === 'number' &&
        typeof lon === 'number' &&
        lat >= -90 && lat <= 90 &&
        lon >= -180 && lon <= 180);
}
exports.default = { calculateDistance, isWithinGeofence, validateCoordinates };
//# sourceMappingURL=geoService.js.map