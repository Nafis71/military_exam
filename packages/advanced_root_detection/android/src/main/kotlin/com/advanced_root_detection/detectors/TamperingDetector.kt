package com.advanced_root_detection.detectors

import android.content.Context
import android.content.pm.PackageManager
import android.content.pm.Signature
import com.advanced_root_detection.DetectionConfig
import com.advanced_root_detection.ThreatResult
import java.security.MessageDigest

/**
 * Detects APK signing certificate mismatches, repackaging, and untrusted install sources.
 *
 * Reference: OWASP MASTG MSTG-RESILIENCE-3
 * https://mas.owasp.org/MASTG/tests/android/MASVS-RESILIENCE/MASTG-TEST-0047/
 */
class TamperingDetector(private val context: Context, private val config: DetectionConfig) {

    fun detect(): List<ThreatResult> {
        val threats = mutableListOf<ThreatResult>()

        // 1. Package name mismatch (repackaging)
        val expectedPkg = config.packageName
        if (!expectedPkg.isNullOrBlank()) {
            val actualPkg = context.packageName
            if (actualPkg != expectedPkg) {
                threats += ThreatResult(
                    category = "integrityViolation",
                    description = "Package name mismatch — possible repackaging attack",
                    severity = "critical",
                    details = mapOf("expected" to expectedPkg, "actual" to actualPkg)
                )
            }
        }

        // 2. Signing certificate SHA-256 check
        if (config.signingCertHashes.isNotEmpty()) {
            checkSigningCert(config.signingCertHashes)?.let { threats += it }
        }

        // 3. Installer source
        if (!config.allowSideload) {
            checkInstallerSource()?.let { threats += it }
        }

        return threats
    }

    @Suppress("DEPRECATION")
    private fun checkSigningCert(expectedHashes: List<String>): ThreatResult? {
        return try {
            val pm = context.packageManager
            val pkg = context.packageName
            val signatures: Array<Signature> = if (android.os.Build.VERSION.SDK_INT >= 28) {
                val info = pm.getPackageInfo(pkg, PackageManager.GET_SIGNING_CERTIFICATES)
                info.signingInfo?.apkContentsSigners ?: emptyArray()
            } else {
                val info = pm.getPackageInfo(pkg, PackageManager.GET_SIGNATURES)
                @Suppress("DEPRECATION")
                info.signatures ?: emptyArray()
            }

            val actualHashes = signatures.map { sig ->
                val md = MessageDigest.getInstance("SHA-256")
                md.update(sig.toByteArray())
                md.digest().joinToString("") { "%02X".format(it) }
            }

            val matched = actualHashes.any { actual ->
                expectedHashes.any { expected -> expected.equals(actual, ignoreCase = true) }
            }

            if (!matched) {
                ThreatResult(
                    category = "integrityViolation",
                    description = "APK signing certificate does not match expected hash",
                    severity = "critical",
                    details = mapOf("actualHash" to actualHashes.firstOrNull().orEmpty())
                )
            } else null
        } catch (_: Exception) {
            null
        }
    }

    private fun checkInstallerSource(): ThreatResult? {
        return try {
            val pm = context.packageManager
            val pkg = context.packageName
            val installer = if (android.os.Build.VERSION.SDK_INT >= 30) {
                pm.getInstallSourceInfo(pkg).installingPackageName
            } else {
                @Suppress("DEPRECATION")
                pm.getInstallerPackageName(pkg)
            }

            val installerToEnum = mapOf(
                "com.android.vending" to "googlePlay",
                "com.amazon.venezia" to "amazonAppstore",
                "com.huawei.appmarket" to "huaweiAppGallery",
                "com.sec.android.app.samsungapps" to "samsungGalaxyStore",
            )

            val enumName = installerToEnum[installer]

            if (installer != null && enumName != null && !config.allowedInstallers.contains(enumName)) {
                ThreatResult(
                    category = "untrustedSource",
                    description = "App installed from untrusted source: $installer",
                    severity = "high",
                    details = mapOf("installer" to installer)
                )
            } else if (installer == null) {
                ThreatResult(
                    category = "untrustedSource",
                    description = "Unknown install source — app may have been sideloaded",
                    severity = "medium"
                )
            } else null
        } catch (_: Exception) {
            null
        }
    }
}
