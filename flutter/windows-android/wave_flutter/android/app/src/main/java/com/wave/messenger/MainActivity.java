package com.wave.messenger;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;

import androidx.annotation.NonNull;
import androidx.core.content.FileProvider;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String UPDATER_CHANNEL = "com.wave.messenger/updater";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                UPDATER_CHANNEL
        ).setMethodCallHandler(this::handleUpdaterMethodCall);
    }

    private void handleUpdaterMethodCall(
            @NonNull MethodCall call,
            @NonNull MethodChannel.Result result
    ) {
        if (!"installDownloadedUpdate".equals(call.method)) {
            result.notImplemented();
            return;
        }

        final String filePath = call.argument("filePath");
        if (filePath == null || filePath.trim().isEmpty()) {
            result.error("invalid_args", "Expected a non-empty filePath.", null);
            return;
        }

        installDownloadedUpdate(filePath, result);
    }

    private void installDownloadedUpdate(
            @NonNull String filePath,
            @NonNull MethodChannel.Result result
    ) {
        final File updateFile = new File(filePath);
        if (!updateFile.exists()) {
            result.success(buildResponse(
                    "failed",
                    "Downloaded update file was not found."
            ));
            return;
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                    && !getPackageManager().canRequestPackageInstalls()) {
                final Intent permissionIntent = new Intent(
                        Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                        Uri.parse("package:" + getPackageName())
                );
                permissionIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(permissionIntent);
                result.success(buildResponse(
                        "permission_required",
                        "Allow installation from unknown sources for Wave, then tap update again."
                ));
                return;
            }

            final Uri apkUri = FileProvider.getUriForFile(
                    this,
                    getPackageName() + ".fileprovider",
                    updateFile
            );

            final Intent installIntent = new Intent(Intent.ACTION_VIEW);
            installIntent.setDataAndType(
                    apkUri,
                    "application/vnd.android.package-archive"
            );
            installIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            installIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            installIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
            startActivity(installIntent);

            result.success(buildResponse(
                    "installer_launched",
                    "Android installer opened."
            ));
        } catch (ActivityNotFoundException error) {
            result.success(buildResponse(
                    "failed",
                    "No package installer was found on this device."
            ));
        } catch (Exception error) {
            result.success(buildResponse(
                    "failed",
                    error.getMessage() == null ? "Could not start installer." : error.getMessage()
            ));
        }
    }

    @NonNull
    private Map<String, Object> buildResponse(
            @NonNull String status,
            @NonNull String message
    ) {
        final Map<String, Object> response = new HashMap<>();
        response.put("status", status);
        response.put("message", message);
        return response;
    }
}
