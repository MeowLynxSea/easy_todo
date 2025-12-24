package com.example.easy_todo.services;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;
import cn.meowdream.easytodo.R;

public class PomodoroForegroundService extends Service {
    private static final String TAG = "PomodoroForegroundService";
    private static final String CHANNEL_ID = "pomodoro_foreground_service";
    private static final int NOTIFICATION_ID = 1;

    private static final String ACTION_START = "START";
    private static final String ACTION_STOP = "STOP";
    private static final String ACTION_UPDATE = "UPDATE";

    public static final String EXTRA_TODO_ID = "todo_id";
    public static final String EXTRA_DURATION = "duration";
    public static final String EXTRA_REMAINING = "remaining";
    public static final String EXTRA_IS_BREAK = "is_break";

    private String currentTodoId = "";
    private int totalDuration = 0;
    private int remainingSeconds = 0;
    private boolean isBreak = false;

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent == null) {
            return START_NOT_STICKY;
        }

        String action = intent.getAction();
        if (action == null) {
            return START_NOT_STICKY;
        }

        switch (action) {
            case ACTION_START:
                currentTodoId = intent.getStringExtra(EXTRA_TODO_ID);
                totalDuration = intent.getIntExtra(EXTRA_DURATION, 0);
                remainingSeconds = intent.getIntExtra(EXTRA_REMAINING, 0);
                isBreak = intent.getBooleanExtra(EXTRA_IS_BREAK, false);
                startForegroundService();
                break;
            case ACTION_UPDATE:
                remainingSeconds = intent.getIntExtra(EXTRA_REMAINING, 0);
                updateNotification();
                break;
            case ACTION_STOP:
                stopForegroundService();
                break;
        }

        return START_STICKY;
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "Pomodoro Timer",
                NotificationManager.IMPORTANCE_DEFAULT
            );
            channel.setDescription("Pomodoro timer running in background");
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                channel.setShowBadge(false);
            }
            channel.setSound(null, null);
            channel.enableVibration(false);

            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);
        }
    }

    private void startForegroundService() {
        Notification notification = createNotification();
        startForeground(NOTIFICATION_ID, notification);
        Log.d(TAG, "Pomodoro foreground service started for todo: " + currentTodoId);
    }

    private Notification createNotification() {
        NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getNotificationTitle())
            .setContentText(getNotificationText())
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE);
        }

        return builder.build();
    }

    private String getNotificationTitle() {
        return isBreak ? "Break Time" : "Focus Time";
    }

    private String getNotificationText() {
        int minutes = remainingSeconds / 60;
        int seconds = remainingSeconds % 60;
        return String.format("Time remaining: %02d:%02d", minutes, seconds);
    }

    private void updateNotification() {
        if (remainingSeconds <= 0) {
            // Timer completed
            Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle(getNotificationTitle() + " Complete!")
                .setContentText("Time to " + (isBreak ? "get back to work!" : "take a break!"))
                .setSmallIcon(R.mipmap.ic_launcher)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setOngoing(false)
                .setAutoCancel(true)
                .build();

            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            notificationManager.notify(NOTIFICATION_ID + 1, notification);

            stopForegroundService();
        } else {
            // Update remaining time
            Notification notification = createNotification();
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            notificationManager.notify(NOTIFICATION_ID, notification);
        }
    }

    private void stopForegroundService() {
        stopForeground(true);
        stopSelf();
        Log.d(TAG, "Pomodoro foreground service stopped");
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        Log.d(TAG, "Pomodoro foreground service destroyed");
    }

    // Static methods to control the service
    public static Intent createStartIntent(android.content.Context context,
                                         String todoId,
                                         int duration,
                                         int remaining,
                                         boolean isBreak) {
        Intent intent = new Intent(context, PomodoroForegroundService.class);
        intent.setAction(ACTION_START);
        intent.putExtra(EXTRA_TODO_ID, todoId);
        intent.putExtra(EXTRA_DURATION, duration);
        intent.putExtra(EXTRA_REMAINING, remaining);
        intent.putExtra(EXTRA_IS_BREAK, isBreak);
        return intent;
    }

    public static Intent createUpdateIntent(android.content.Context context, int remaining) {
        Intent intent = new Intent(context, PomodoroForegroundService.class);
        intent.setAction(ACTION_UPDATE);
        intent.putExtra(EXTRA_REMAINING, remaining);
        return intent;
    }

    public static Intent createStopIntent(android.content.Context context) {
        Intent intent = new Intent(context, PomodoroForegroundService.class);
        intent.setAction(ACTION_STOP);
        return intent;
    }
}