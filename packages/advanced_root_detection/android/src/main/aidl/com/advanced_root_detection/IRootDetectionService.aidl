package com.advanced_root_detection;

interface IRootDetectionService {
    /**
     * Evaluates root and tampering threats inside the isolated process.
     * @param configJson The detection configuration encoded as a JSON string.
     * @return A JSON string representing a List of ThreatResult objects.
     */
    String evaluateThreats(String configJson);
}
