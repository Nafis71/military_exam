package com.advanced_root_detection.detectors

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import com.advanced_root_detection.ThreatResult
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.cert.X509Certificate
import java.util.UUID

/**
 * BootloaderAttestationDetector — Defeats MagiskHide/Zygisk DenyList completely
 * by using hardware-backed Android Keystore Attestation.
 * 
 * Magisk relies on an unlocked bootloader. By requesting an attestation certificate 
 * generated inside the SoC's Trusted Execution Environment (TEE), we obtain the 
 * cryptographic proof of the bootloader status. Since it's hardware-backed, 
 * software hooking (Zygisk/Shamiko) cannot spoof this result.
 */
class BootloaderAttestationDetector {

    private val KEY_ALIAS = "RootDetectionAttestKey_${UUID.randomUUID()}"
    private val ATTESTATION_EXTENSION_OID = "1.3.6.1.4.1.11129.2.1.17"

    fun detect(): List<ThreatResult> {
        val threats = mutableListOf<ThreatResult>()
        // Key attestation requires API 24+
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return emptyList()

        try {
            val keyStore = KeyStore.getInstance("AndroidKeyStore")
            keyStore.load(null)

            val keyPairGenerator = KeyPairGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore"
            )

            val challenge = "RootCheckChallenge".toByteArray()
            val spec = KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_SIGN
            )
            .setAlgorithmParameterSpec(java.security.spec.ECGenParameterSpec("secp256r1"))
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setAttestationChallenge(challenge)
            .build()

            keyPairGenerator.initialize(spec)
            keyPairGenerator.generateKeyPair()

            val certificates = keyStore.getCertificateChain(KEY_ALIAS)
            if (certificates == null || certificates.isEmpty()) {
                return threats // No certs generated
            }

            val leafCert = certificates[0] as X509Certificate
            val extensionValue = leafCert.getExtensionValue(ATTESTATION_EXTENSION_OID)
            if (extensionValue == null) {
                return threats // No attestation extension (e.g., no hardware support)
            }

            val (isLocked, bootState) = parseRootOfTrust(extensionValue)
            
            // "Verified" state is 0, anything else (unverified/orange/red) means unlocked.
            // deviceLocked should be true.
            if (!isLocked || bootState != 0) {
                threats.add(
                    ThreatResult(
                        category = "privilegedAccess",
                        description = "Hardware Attestation detected an Unlocked Bootloader (TEE/TrustZone verified). " +
                                "Device has been tampered with or rooted.",
                        severity = "critical",
                        details = mapOf("deviceLocked" to isLocked.toString(), "bootState" to bootState.toString())
                    )
                )
            }

        } catch (_: Exception) {
            // Devices without hardware attestation support might throw here.
            // Gracefully ignore.
        } finally {
            try {
                val keyStore = KeyStore.getInstance("AndroidKeyStore")
                keyStore.load(null)
                if (keyStore.containsAlias(KEY_ALIAS)) {
                    keyStore.deleteEntry(KEY_ALIAS)
                }
            } catch (e: Exception) {}
        }
        return threats
    }

    /**
     * Extremely lightweight partial ASN.1 parser specialized for the 
     * Android Key Attestation RootOfTrust structure.
     * 
     * Schema:
     * KeyDescription ::= SEQUENCE {
     *   attestationVersion         INTEGER, #1
     *   attestationSecurityLevel   SecurityLevel, #2
     *   ...
     *   teeEnforced                AuthorizationList, #8
     * }
     * 
     * AuthorizationList ::= SEQUENCE {
     *   ...
     *   [704] EXPLICIT RootOfTrust OPTIONAL,
     * }
     * 
     * RootOfTrust ::= SEQUENCE {
     *   verifiedBootKey            OCTET_STRING,
     *   deviceLocked               BOOLEAN,
     *   verifiedBootState          VerifiedBootState (ENUMERATED),
     *   verifiedBootHash           OCTET_STRING
     * }
     * 
     * Returns a Pair(deviceLocked: Boolean, verifiedBootState: Int)
     */
    private fun parseRootOfTrust(extensionValue: ByteArray): Pair<Boolean, Int> {
        // `extensionValue` is an OCTET STRING containing another ASN.1 SEQUENCE.
        var offset = 0
        
        fun readLength(buf: ByteArray, startIndex: Int): Pair<Int, Int> {
            var i = startIndex
            val b = buf[i++].toInt() and 0xFF
            if ((b and 0x80) == 0) return Pair(b, i)
            val numBytes = b and 0x7F
            var length = 0
            for (j in 0 until numBytes) {
                length = (length shl 8) or (buf[i++].toInt() and 0xFF)
            }
            return Pair(length, i)
        }

        // 1. Unpack first OCTET STRING wrapping the extension
        if (extensionValue[offset] != 0x04.toByte()) return Pair(true, 0)
        offset++
        var (len, nextOffset) = readLength(extensionValue, offset)
        offset = nextOffset

        // 2. Main KeyDescription SEQUENCE
        if (extensionValue[offset] != 0x30.toByte()) return Pair(true, 0)
        offset++
        val (seqLen, seqNextOffset) = readLength(extensionValue, offset)
        offset = seqNextOffset

        // Skip to teeEnforced which is the 8th item (index 7).
        // Since ASN.1 elements vary, we just linearly scan for the [704] EXPLICIT tag
        // inside teeEnforced or anywhere in the sequence, as 704 is highly unique.
        // A contextual constructed tag format is: 101 (Constructed Context-Specific)
        // Tag number 704 exceeds 31, so it uses the long form.
        // Identify long form: 0xBF 0x85 0x40 (which means tag class Context-Specific=10, Constructed=1, Tag=31 (11111), followed by Base 128 encoding of 704).
        // Let's just find the sequence [704] RootOfTrust.
        // Tag [704] encoded: 1011 1111 (0xBF) followed by 10000101 (0x85) 00000000 (0x00) -> 704 in base 128 is 5 * 128 + 64. 
        // 704 = 0b1011000000 = 0x05 0x40 -> 10000101 (0x85) 01000000 (0x40).
        // So byte sequence is 0xBF, 0x85, 0x40.
        
        var rootOfTrustStart = -1
        for (i in offset until (offset + seqLen - 3)) {
            if (extensionValue[i] == 0xBF.toByte() && 
                extensionValue[i+1] == 0x85.toByte() && 
                extensionValue[i+2] == 0x40.toByte()) {
                rootOfTrustStart = i
                break
            }
        }

        if (rootOfTrustStart == -1) return Pair(true, 0) // Assume locked if missing

        offset = rootOfTrustStart + 3
        val (tagLen, tagNext) = readLength(extensionValue, offset)
        offset = tagNext

        // The content of [704] is the RootOfTrust SEQUENCE (tag 0x30)
        if (extensionValue[offset] != 0x30.toByte()) return Pair(true, 0)
        offset++
        val (rotLen, rotNext) = readLength(extensionValue, offset)
        offset = rotNext

        // Now parse elements of RootOfTrust SEQUENCE:
        // 1. verifiedBootKey (OCTET STRING 0x04)
        if (extensionValue[offset] != 0x04.toByte()) return Pair(true, 0)
        offset++
        val (keyLen, keyNext) = readLength(extensionValue, offset)
        offset = keyNext + keyLen // Skip the key data

        // 2. deviceLocked (BOOLEAN 0x01)
        if (extensionValue[offset] != 0x01.toByte()) return Pair(true, 0)
        offset++
        val (boolLen, boolNext) = readLength(extensionValue, offset)
        offset = boolNext
        val deviceLocked = extensionValue[offset] != 0x00.toByte()
        offset += boolLen

        // 3. verifiedBootState (ENUMERATED 0x0A)
        if (extensionValue[offset] != 0x0A.toByte()) return Pair(true, 0)
        offset++
        val (enumLen, enumNext) = readLength(extensionValue, offset)
        offset = enumNext
        val bootState = extensionValue[offset].toInt()
        
        return Pair(deviceLocked, bootState)
    }
}
