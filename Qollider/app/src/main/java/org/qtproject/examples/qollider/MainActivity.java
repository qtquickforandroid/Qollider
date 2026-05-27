package org.qtproject.examples.qollider;

import android.Manifest;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.Matrix;
import android.os.Bundle;
import android.util.Log;
import android.hardware.display.DisplayManager;
import android.view.View;
import android.view.WindowManager;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.Preview;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import com.google.common.util.concurrent.ListenableFuture;
import android.content.SharedPreferences;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import org.json.JSONArray;
import org.json.JSONObject;
import org.qtproject.qt.android.QtQuickView;
import org.qtproject.example.qollider.Qollider_qml.Main;
import com.google.mediapipe.formats.proto.LandmarkProto.NormalizedLandmark;
import com.google.mediapipe.solutions.hands.HandLandmark;
import com.google.mediapipe.solutions.hands.Hands;
import com.google.mediapipe.solutions.hands.HandsOptions;

public class MainActivity extends AppCompatActivity {
    private static final String TAG = "HandTracking";
    private static final int CAMERA_PERMISSION_CODE = 100;
    private static final boolean RUN_ON_GPU = true;

    private static final float POSITION_ALPHA = 0.3f;
    private static final double ROTATION_ALPHA = 0.7;

    private PreviewView previewView;
    private QtQuickView qmlView;
    private FrameLayout qmlFrame;

    private ExecutorService cameraExecutor;
    private ProcessCameraProvider cameraProvider;
    private final Main qollider_main = new Main();
    private Hands hands;
    private View rotateOverlay;
    private DisplayManager displayManager;
    private int lastBoundRotation = -1;
    private final DisplayManager.DisplayListener displayListener = new DisplayManager.DisplayListener() {
        @Override public void onDisplayAdded(int displayId) {
            runOnUiThread(() -> rebindIfRotationChanged());
        }
        @Override public void onDisplayRemoved(int displayId) {
            runOnUiThread(() -> rebindIfRotationChanged());
        }
        @Override public void onDisplayChanged(int displayId) {
            runOnUiThread(() -> rebindIfRotationChanged());
        }
    };

    private float normPosX = 0.5f, normPosY = 0.5f;
    private float normMidX = 0.5f, normMidY = 0.5f;
    private double smoothPitch = 0.0, smoothYaw = 0.0, smoothRoll = 0.0;

    // --- Calibration ---
    private android.os.Handler setupPollHandler;
    private final Runnable setupPollRunnable = new Runnable() {
        @Override public void run() {
            String saveReq = qollider_main.getSaveScoreRequest();
            if (saveReq != null && !saveReq.isEmpty()) {
                qollider_main.setSaveScoreRequest("");
                saveHighScore(saveReq);
            }
            if (setupPollHandler != null) setupPollHandler.postDelayed(this, 100);
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        previewView = findViewById(R.id.previewView);
        qmlFrame = findViewById(R.id.qmlFrame);

        previewView.setScaleX(-1f);

        cameraExecutor = Executors.newSingleThreadExecutor();

        setupHand();
        checkPermissionsAndStartCamera();

        // Must load before QtQuickView — dpr_fix's __attribute__((constructor)) sets
        // QT_ENABLE_HIGHDPI_SCALING=0 before Qt reads display density, preventing
        // Screen.devicePixelRatio from changing when an external display connects at runtime.
        System.loadLibrary("dpr_fix");

        qmlView = new QtQuickView(this);
        qmlFrame.addView(qmlView, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        qmlView.loadContent(qollider_main);
        loadAndPushHighScores();

        // connectSignalListener returns -1 for custom QML properties in Qt 6.10, so
        // poll every 100ms as the only reliable way to receive QML→Java notifications.
        setupPollHandler = new android.os.Handler(android.os.Looper.getMainLooper());
        setupPollHandler.postDelayed(setupPollRunnable, 200);

        rotateOverlay = findViewById(R.id.rotateOverlay);
        updateRotateOverlay(getResources().getConfiguration().orientation);

        displayManager = (DisplayManager) getSystemService(DISPLAY_SERVICE);
        displayManager.registerDisplayListener(displayListener,
                new android.os.Handler(android.os.Looper.getMainLooper()));

        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }

    // --- Permissions and Camera Startup ---

    private void checkPermissionsAndStartCamera() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
                != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this,
                    new String[]{Manifest.permission.CAMERA}, CAMERA_PERMISSION_CODE);
        } else {
            startCamera();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == CAMERA_PERMISSION_CODE && grantResults.length > 0
                && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            startCamera();
        }
    }

    private void startCamera() {
        ListenableFuture<ProcessCameraProvider> cameraProviderFuture =
                ProcessCameraProvider.getInstance(this);
        cameraProviderFuture.addListener(() -> {
            try {
                cameraProvider = cameraProviderFuture.get();
                bindCameraUseCases();
            } catch (Exception e) {
                Log.e(TAG, "Camera initialization failed", e);
            }
        }, ContextCompat.getMainExecutor(this));
    }

    @SuppressWarnings("deprecation")
    private int currentDisplayRotation() {
        return getWindowManager().getDefaultDisplay().getRotation();
    }

    private void rebindIfRotationChanged() {
        if (cameraProvider == null) return;
        int rotation = currentDisplayRotation();
        if (rotation != lastBoundRotation) bindCameraUseCases();
    }

    private void bindCameraUseCases() {
        int rotation = currentDisplayRotation();
        lastBoundRotation = rotation;
        Preview preview = new Preview.Builder().build();
        preview.setSurfaceProvider(previewView.getSurfaceProvider());
        ImageAnalysis imageAnalysis = new ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_YUV_420_888)
                .setTargetRotation(rotation)
                .build();

        imageAnalysis.setAnalyzer(cameraExecutor, imageProxy -> {
            if (imageProxy.getImage() == null) {
                imageProxy.close();
                return;
            }

            int imageRotation = imageProxy.getImageInfo().getRotationDegrees();
            Bitmap raw = imageProxy.toBitmap();
            Bitmap small = downsample(raw, 320);
            if (small != raw) raw.recycle();
            Bitmap bmp = rotateBitmap(small, imageRotation);
            if (bmp != small) small.recycle();
            hands.send(bmp, imageProxy.getImageInfo().getTimestamp());
            imageProxy.close();
        });

        try {
            cameraProvider.unbindAll();
            cameraProvider.bindToLifecycle(this,
                    CameraSelector.DEFAULT_FRONT_CAMERA, preview, imageAnalysis);
        } catch (Exception e) {
            Log.e(TAG, "Use case binding failed", e);
        }
    }

    private Bitmap rotateBitmap(Bitmap source, float angle) {
        Matrix matrix = new Matrix();
        matrix.postRotate(angle);
        return Bitmap.createBitmap(source, 0, 0, source.getWidth(), source.getHeight(), matrix, true);
    }

    private Bitmap downsample(Bitmap source, int maxDim) {
        int w = source.getWidth(), h = source.getHeight();
        int longest = Math.max(w, h);
        if (longest <= maxDim) return source;
        float scale = (float) maxDim / longest;
        return Bitmap.createScaledBitmap(source, Math.round(w * scale), Math.round(h * scale), false);
    }

    // --- Math Helpers ---
    // After rotateBitmap(getRotationDegrees()), the image is display-aligned for any orientation.
    // The front-camera X mirror is corrected in QML (1-x), so we pass raw X through here.
    // Y is pre-inverted so that the QML's second 1-y cancels back to display-top-=0 convention.
    // Z is negated to match Qt3D depth direction.
    private double[] mapLandmark(NormalizedLandmark lm) {
        return new double[]{ lm.getX(), 1.0 - lm.getY(), -lm.getZ() };
    }

    // --- Hand Tracking Logic ---
    private void setupHand() {
        hands = new Hands(this, HandsOptions.builder()
                .setStaticImageMode(false)
                .setMaxNumHands(1)
                .setRunOnGpu(RUN_ON_GPU)
                .setModelComplexity(0)
                .build());

        hands.setErrorListener((message, e) -> Log.e(TAG, "MediaPipe Hands error: " + message));

        hands.setResultListener(handsResult -> {
            if (handsResult.multiHandLandmarks().isEmpty()) {
                return;
            }

            var landmarks = handsResult.multiHandLandmarks().get(0).getLandmarkList();

            double[] wrist  = mapLandmark(landmarks.get(HandLandmark.WRIST));
            double[] thumb  = mapLandmark(landmarks.get(HandLandmark.THUMB_TIP));
            double[] middle = mapLandmark(landmarks.get(HandLandmark.MIDDLE_FINGER_TIP));
            double[] pinky  = mapLandmark(landmarks.get(HandLandmark.PINKY_TIP));

            normPosX = (normPosX * (1f - POSITION_ALPHA)) + ((float) wrist[0] * POSITION_ALPHA);
            normPosY = (normPosY * (1f - POSITION_ALPHA)) + ((float) wrist[1] * POSITION_ALPHA);
            normMidX = (normMidX * (1f - POSITION_ALPHA)) + ((float) middle[0] * POSITION_ALPHA);
            normMidY = (normMidY * (1f - POSITION_ALPHA)) + ((float) middle[1] * POSITION_ALPHA);

            // TODO: rotation uses atan2 on raw depth which wraps at ±90° — replace with
            // a proper 3D cross-product normal to remove the 0.5 fudge factors and clamping.

            // wrist→middle = paddle up-axis; thumb→pinky = paddle horizontal axis
            double wmX = middle[0] - wrist[0];
            double wmY = middle[1] - wrist[1];
            double wmZ = middle[2] - wrist[2];

            double tpX = pinky[0] - thumb[0];
            double tpY = pinky[1] - thumb[1];
            double tpZ = pinky[2] - thumb[2];

            // Roll: stable 2D tilt, no clamping needed
            double roll = Math.toDegrees(Math.atan2(wmX, wmY));

            // Pitch/yaw: scaled by 0.5 and clamped to prevent wrap-around spinning
            double pitch = -Math.toDegrees(Math.atan2(wmZ, wmY)) * 0.5;
            pitch = Math.max(-60.0, Math.min(60.0, pitch));

            double yaw = Math.toDegrees(Math.atan2(tpZ, tpX)) * 0.5;
            yaw = Math.max(-45.0, Math.min(45.0, yaw));

            smoothRoll  = (ROTATION_ALPHA * roll)  + (1.0 - ROTATION_ALPHA) * smoothRoll;
            smoothPitch = (ROTATION_ALPHA * pitch) + (1.0 - ROTATION_ALPHA) * smoothPitch;
            smoothYaw   = (ROTATION_ALPHA * yaw)   + (1.0 - ROTATION_ALPHA) * smoothYaw;

            qollider_main.setHandRotation(String.format(Locale.US, "%.2f,%.2f,%.2f",
                    smoothPitch, smoothYaw, smoothRoll));
            qollider_main.setMoveDiff(String.format(Locale.US, "%.3f,%.3f,%.3f,%.3f",
                    normPosX, normPosY, normMidX, normMidY));
        });
    }

    private void saveHighScore(String request) {
        String[] parts = request.split("\\|", 2);
        if (parts.length != 2) return;
        String name = parts[0].trim();
        int score;
        try { score = Integer.parseInt(parts[1].trim()); }
        catch (NumberFormatException e) { return; }

        SharedPreferences prefs = getSharedPreferences("qollider_scores", MODE_PRIVATE);
        try {
            JSONArray arr = new JSONArray(prefs.getString("scores", "[]"));
            JSONObject entry = new JSONObject();
            entry.put("name", name);
            entry.put("score", score);
            arr.put(entry);

            List<JSONObject> list = new ArrayList<>();
            for (int i = 0; i < arr.length(); i++) list.add(arr.getJSONObject(i));
            list.sort((a, b) -> {
                try { return b.getInt("score") - a.getInt("score"); }
                catch (Exception e2) { return 0; }
            });

            JSONArray sorted = new JSONArray();
            for (int i = 0; i < Math.min(10, list.size()); i++) sorted.put(list.get(i));

            prefs.edit().putString("scores", sorted.toString()).apply();
            qollider_main.setHighScoreData(buildHighScoreString(sorted));
        } catch (Exception e) {
            Log.e(TAG, "Failed to save high score", e);
        }
    }

    private void loadAndPushHighScores() {
        SharedPreferences prefs = getSharedPreferences("qollider_scores", MODE_PRIVATE);
        try {
            JSONArray arr = new JSONArray(prefs.getString("scores", "[]"));
            qollider_main.setHighScoreData(buildHighScoreString(arr));
        } catch (Exception e) {
            Log.e(TAG, "Failed to load high scores", e);
        }
    }

    private String buildHighScoreString(JSONArray arr) {
        StringBuilder sb = new StringBuilder();
        try {
            for (int i = 0; i < arr.length(); i++) {
                if (i > 0) sb.append(";");
                JSONObject obj = arr.getJSONObject(i);
                sb.append(obj.getString("name")).append("|").append(obj.getInt("score"));
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to build high score string", e);
        }
        return sb.toString();
    }

    private void updateRotateOverlay(int orientation) {
        if (rotateOverlay == null) return;
        boolean portrait = (orientation == Configuration.ORIENTATION_PORTRAIT);
        rotateOverlay.setVisibility(portrait ? View.VISIBLE : View.GONE);
    }

    @Override
    public void onConfigurationChanged(@NonNull Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        updateRotateOverlay(newConfig.orientation);
        rebindIfRotationChanged();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        cameraExecutor.shutdown();
        if (hands != null) hands.close();
        if (setupPollHandler != null) {
            setupPollHandler.removeCallbacks(setupPollRunnable);
            setupPollHandler = null;
        }
        if (displayManager != null) displayManager.unregisterDisplayListener(displayListener);
    }
}