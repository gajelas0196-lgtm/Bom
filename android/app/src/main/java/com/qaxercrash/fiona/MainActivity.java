package com.qaxercrash.fiona;

import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.Signature;
import android.os.Build;

import androidx.annotation.NonNull;

import java.security.MessageDigest;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "app_security";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                CHANNEL
        ).setMethodCallHandler((call, result) -> {

            if ("getSignature".equals(call.method)) {
                try {
                    result.success(getSignatureSha256());
                } catch (Exception e) {
                    result.error(
                            "SIGNATURE_ERROR",
                            e.getMessage(),
                            null
                    );
                }
            } else {
                result.notImplemented();
            }
        });
    }

    private String getSignatureSha256() throws Exception {

        PackageManager pm = getPackageManager();
        Signature signature;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {

            PackageInfo packageInfo = pm.getPackageInfo(
                    getPackageName(),
                    PackageManager.GET_SIGNING_CERTIFICATES
            );

            if (packageInfo.signingInfo == null) {
                throw new Exception(
                        "Signing information tidak ditemukan"
                );
            }

            Signature[] signatures =
                    packageInfo.signingInfo.getApkContentsSigners();

            if (signatures == null || signatures.length == 0) {
                throw new Exception(
                        "Certificate tidak ditemukan"
                );
            }

            signature = signatures[0];

        } else {

            PackageInfo packageInfo = pm.getPackageInfo(
                    getPackageName(),
                    PackageManager.GET_SIGNATURES
            );

            if (packageInfo.signatures == null ||
                    packageInfo.signatures.length == 0) {
                throw new Exception(
                        "Certificate tidak ditemukan"
                );
            }

            signature = packageInfo.signatures[0];
        }

        return sha256(signature.toByteArray());
    }

    private String sha256(byte[] data) throws Exception {

        MessageDigest digest =
                MessageDigest.getInstance("SHA-256");

        byte[] hash = digest.digest(data);

        StringBuilder result = new StringBuilder();

        for (byte b : hash) {
            result.append(
                    String.format("%02x", b)
            );
        }

        return result.toString();
    }
}