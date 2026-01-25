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
export declare function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number;
/**
 * Location object with coordinates and radius
 */
export interface GeoLocation {
    id: string;
    name: string;
    latitude: number;
    longitude: number;
    radius_meters: number;
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
export declare function isWithinGeofence(userLat: number, userLon: number, locations: GeoLocation[]): GeoLocation | null;
/**
 * Validate GPS coordinates are within valid ranges
 * Latitude: -90 to 90
 * Longitude: -180 to 180
 */
export declare function validateCoordinates(lat: number, lon: number): boolean;
declare const _default: {
    calculateDistance: typeof calculateDistance;
    isWithinGeofence: typeof isWithinGeofence;
    validateCoordinates: typeof validateCoordinates;
};
export default _default;
//# sourceMappingURL=geoService.d.ts.map