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

	private static String INPUTNUM = "";
    private static String CONTROL_PATH = "";

	static public boolean fileExists(String path)
	{
		if (path.equals("")) return false;
		File file = new File(path);
		return file.exists();
	}

	static public String findInputNum()
	{
		for (int n=0; n<20; n++)
		{
			String path = String.format("/sys/class/input/input%d/wake_gesture", n);
			if (fileExists(path))
				return "input"+n;
		}
		return "";
	} 

    static public String getInputControlPath(String extra) 
	{
		// Check if we need to find correct input path
		if (!fileExists(CONTROL_PATH)) {
			CONTROL_PATH = "";
			INPUTNUM = findInputNum();
		}

		if (!INPUTNUM.isEmpty())
		{
			if (!SystemProperties.get("ts.touchinput").equals(INPUTNUM)) {
				// Set ts.touchinput property if changed
				// Log.i("TsUtils", "ts.touchinput = " + INPUTNUM + "; extra = " + extra);
		    	SystemProperties.set("ts.touchinput", INPUTNUM);
			}
       		CONTROL_PATH = "/sys/class/input/"+INPUTNUM+"/"+extra;
		} 

		// Double check path+extra really exists
		if (!fileExists(CONTROL_PATH)) {
			CONTROL_PATH = "";
		}
		return CONTROL_PATH;
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

