package org.morphic.ts.extra;

import android.app.Service;
import android.os.IBinder;
import android.util.Log;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

import android.os.SystemProperties;
import android.app.ActivityManager;
import android.app.ActivityManager.MemoryInfo;
import android.app.ActivityManager.RecentTaskInfo;
import android.app.ActivityManager.RunningAppProcessInfo;
import android.app.ActivityManager.RunningServiceInfo;
import android.os.Handler;
import java.util.ArrayList;
import java.util.List;
import java.util.Iterator;
import android.os.UserHandle;
import android.media.AudioManager;

public class ScreenReceiver extends BroadcastReceiver 
{
    private static final String TAG = "TsExtraScreenReceiver";
    
	final Handler handler = new Handler();

    @Override
    public void onReceive(Context context, Intent intent) 
    {
      	String action = intent.getAction();
      	Log.i(TAG, "onReceive " + action);
		final ActivityManager mAm = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);

		if (action.equals(Intent.ACTION_SCREEN_OFF)) 
		{
			AudioManager manager = (AudioManager)context.getSystemService(Context.AUDIO_SERVICE);
			boolean musicPlaying = manager.isMusicActive();
			String crec = SystemProperties.get("persist.sys.ts.crec_en_b", "0");
			
			Log.i(TAG, "crec_en_b = '" + crec + "'");
			Log.i(TAG, "musicPlaying = '" + musicPlaying + "'");

			if (!crec.equals("0") && !musicPlaying)
			{
				handler.postDelayed(new Runnable() {
					@Override
					public void run() {
						int userId = UserHandle.myUserId();
						Log.i(TAG, "Cleanup apps for userid = '" + userId + "'");
						SystemProperties.set("sys.am.keeprec", "1");

						List<ActivityManager.RecentTaskInfo> tasks = mAm.getRecentTasksForUser(
								ActivityManager.getMaxRecentTasksStatic(),
								ActivityManager.RECENT_IGNORE_HOME_STACK_TASKS |
								ActivityManager.RECENT_IGNORE_UNAVAILABLE |
								ActivityManager.RECENT_INCLUDE_PROFILES |
								ActivityManager.RECENT_WITH_EXCLUDED, userId);
						if (tasks != null) {
							Iterator<ActivityManager.RecentTaskInfo> iter = tasks.iterator();
							while (iter.hasNext()) {
								ActivityManager.RecentTaskInfo t = iter.next();
								if (t.persistentId > 0) {
									mAm.removeTask(t.persistentId);
								}
							}
						}
						SystemProperties.set("sys.am.keeprec", "0");
					}
				}, 1000);
			}			
		}
		else
		{
			try {
				handler.removeCallbacksAndMessages(null);
			} catch (Exception ex) {
				ex.printStackTrace();
			}
		}    
    }
}
