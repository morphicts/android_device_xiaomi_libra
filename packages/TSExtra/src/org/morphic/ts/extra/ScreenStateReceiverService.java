package org.morphic.ts.extra;

import android.app.Service;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.IBinder;
import android.util.Log;

import java.io.File;
import java.io.FileDescriptor;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;

import android.view.WindowManagerPolicy;

import android.content.BroadcastReceiver;

/**
 * Created by mikko on 24.1.2015.
 */
public class ScreenStateReceiverService extends Service
{
    private static final String TAG = "TsExtraScreenStateReceiverService";

    BroadcastReceiver mReceiver = null;
    
    public ScreenStateReceiverService() {
    }

    @Override
    public void onCreate() {
        Log.i(TAG, "Service onCreate");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) 
    {
        Log.i(TAG, "Service onStartCommand " + ((mReceiver == null) ? "NULL" : "Created"));
        
        /*if (intent == null) {
	    Log.i(TAG, "intent == null");
            stopSelf();
            return START_NOT_STICKY;
        }*/
        
		IntentFilter intentFilter = new IntentFilter(Intent.ACTION_SCREEN_ON);
		intentFilter.addAction(Intent.ACTION_SCREEN_OFF);
		mReceiver = new ScreenReceiver();
		registerReceiver(mReceiver, intentFilter);
        
        return Service.START_STICKY;
    }

    @Override
    public IBinder onBind(Intent arg0) {
        Log.i(TAG, "Service onBind");
        return null;
    }

    @Override
    public void onDestroy() {
        Log.i(TAG, "Service onDestroy");
        unregisterReceiver(mReceiver);
        Log.i(TAG, "Service onDestroy DONE");
    }
}
