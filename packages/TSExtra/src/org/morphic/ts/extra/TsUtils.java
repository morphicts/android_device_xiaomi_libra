package org.morphic.ts.extra;

import android.util.Log;
import android.os.SystemProperties;

import java.io.BufferedReader;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.File;

class TsUtils
{
	private static final String TAG = "TsUtils";    

	public static boolean writeLine(String fileName, String value) {
        try {
            FileOutputStream fos = new FileOutputStream(fileName);
            fos.write(value.getBytes());
            fos.flush();
            fos.close();
        } catch (Exception e) {
            Log.e(TAG, "Could not write to file " + fileName, e);
            return false;
        }

        return true;
    }

	static public String getInputControlPath(String extra) 
	{
		return "/sys/touchscreen/" + extra;
	}

	public static boolean setActiveEdgeMode(boolean state) {
		String path = getInputControlPath("edge_mode");
		if (path.equals(""))
			return false;
    	return writeLine(path, (state ? "2" : "0"));
	}

	public static boolean setActiveDT2W(boolean state) {
		String path = getInputControlPath("wake_gesture");
		if (path.equals(""))
			return false;
    	return writeLine(path, (state ? "1" : "0"));
	}
	
	public static boolean setKeyDisabler(boolean state) {
		String path = getInputControlPath("ts_hw_keys_disable");
		if (path.equals(""))
			return false;
    	return writeLine(path, (state ? "1" : "0"));
	}
}

