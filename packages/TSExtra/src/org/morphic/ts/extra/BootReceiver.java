package org.morphic.ts.extra;

import android.app.Service;
import android.os.IBinder;
import android.util.Log;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.os.SystemProperties;

import android.provider.Settings;

import java.io.BufferedReader;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import android.content.IntentFilter;

import cyanogenmod.providers.CMSettings;

import static android.provider.Settings.Secure.DOUBLE_TAP_TO_WAKE;
import android.os.UserHandle;

public class BootReceiver extends BroadcastReceiver 
{
	private static final String TAG = "TsBootReceiver";    

    @Override
    public void onReceive(Context context, Intent intent) 
    {
        String action = intent.getAction();
        Log.i(TAG, "onReceive " + action);

		String wakeGesturePath = TsUtils.getInputControlPath("wake_gesture");
		Log.i(TAG, "wakeGesturePath " + wakeGesturePath);

		// Start screen on/off service
		Intent svc = new Intent(context, ScreenStateReceiverService.class);
     	context.startService(svc);        

		// Restore edge mode
		if (SystemProperties.get("persist.sys.ts.etap_en_b").equals("1"))
		{
			Log.i(TAG, "activate edgemode");
			TsUtils.setActiveEdgeMode(true);
		}

		// Restore dt2w
		boolean doubleTapWakeEnabled = Settings.Secure.getIntForUser(context.getContentResolver(), 
				Settings.Secure.DOUBLE_TAP_TO_WAKE, 0, UserHandle.USER_CURRENT) != 0;
		if (doubleTapWakeEnabled)
		{
			Log.i(TAG, "activate DT2W");
			TsUtils.setActiveDT2W(true);
		}

		// Restore key disabler
		boolean keyDisablerEnabled = CMSettings.Secure.getInt(context.getContentResolver(),
                CMSettings.Secure.DEV_FORCE_SHOW_NAVBAR, 0) != 0;
		if (keyDisablerEnabled)
		{
			Log.i(TAG, "Disable HW keys");
			TsUtils.setKeyDisabler(true);
		}

		// Check ROM update
		checkRomUpdate(context);
    }

	void checkRomUpdate(Context context)
	{
		String val = SystemProperties.get("persist.sys.ts.bc");
        String val2 = SystemProperties.get("ro.ts.build");
        String title = "";
        String subject = "";
        String msg = "";        
        
        if (val.equals(""))
        {
            title = "Team Superluminal CM13.0";
            msg = context.getResources().getString(R.string.newinstall_welcome);
            subject = context.getResources().getString(R.string.newinstall_subject);
            SystemProperties.set("persist.sys.ts.bc", val2);
        }
        else if (!val.equals(val2))
        {
            title = "Team Superluminal CM13.0";
            msg = context.getResources().getString(R.string.update_welcome);
            subject = context.getResources().getString(R.string.update_subject);
            SystemProperties.set("persist.sys.ts.bc", val2);
        }
      
		if (!msg.equals(""))
		{
			int id = (int) System.currentTimeMillis();
		  
			Intent notifIntent = new Intent(context, SettingsActivity.class);
			notifIntent.setAction("OPEN");		
			PendingIntent pIntent = PendingIntent.getActivity(context, id, notifIntent, 0);

			Intent donateReceive = new Intent(context, SettingsActivity.class);  
			donateReceive.setAction("DONATE");		
			PendingIntent pendingIntentDonate = PendingIntent.getActivity(context, id, donateReceive, 0);
			
			// Build notification
			Notification noti = new Notification.Builder(context)
				.setAutoCancel(true)
				.setContentTitle(title)
				.setContentText(subject)
				.setSmallIcon(R.drawable.ic_launcher)
				.setContentIntent(pIntent)
				.setStyle(new Notification.BigTextStyle().bigText(msg)) 
				.addAction(0, "Donate!", pendingIntentDonate)
				.addAction(0, "ROM Extra Settings", pIntent).build();
			
			// hide the notification after its selected
			noti.flags |= Notification.FLAG_AUTO_CANCEL;

			NotificationManager notificationManager = (NotificationManager)context.getSystemService(Context.NOTIFICATION_SERVICE);
			notificationManager.notify(0, noti);
		}

	}
}
