package org.morphic.ts.extra;

import android.app.ActivityManager;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.Context;
import android.os.Bundle;
import android.preference.PreferenceActivity;
import android.preference.Preference;
import android.util.Log;
import android.net.Uri;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.app.Notification;
import android.app.NotificationManager;

import android.os.SystemProperties;
import android.os.PowerManager;

import java.io.File;

import android.provider.Settings;

import java.io.BufferedReader;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;

/**
 * A {@link PreferenceActivity} that presents a set of application settings. On
 * handset devices, settings are presented as a single list. On tablets,
 * settings are split by category, with category headers shown to the left of
 * the list of settings.
 * <p/>
 * See <a href="http://developer.android.com/design/patterns/settings.html">
 * Android Design: Settings</a> for design guidelines and the <a
 * href="http://developer.android.com/guide/topics/ui/settings.html">Settings
 * API Guide</a> for more information on developing a Settings UI.
 */
public class SettingsActivity extends PreferenceActivity implements SharedPreferences.OnSharedPreferenceChangeListener {

		private static final String TAG = "TsSettingsActivity";

		private static final String PAYPAL_DONATE_URL =
		    "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=morphic%2ets%40gmail%2ecom&lc=FI&item_name=Team%20Superluminal%20ROM%20%2d%20Morphic&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donate_SM%2egif%3aNonHosted";

		private static final String MARKET_DONATE_URL =
		    "market://details?id=org.teamsuperluminal.support";

		private void reboot(String reason)
		{
			AlertDialog.Builder builder = new AlertDialog.Builder(this);
			builder
			.setTitle(getString(R.string.reboot_needed))
			.setMessage(reason)
			.setIcon(android.R.drawable.ic_dialog_alert)
			.setPositiveButton(getString(R.string.yes), new DialogInterface.OnClickListener()
			{
				public void onClick(DialogInterface dialog, int which)
				{
					PowerManager pm = (PowerManager)SettingsActivity.this.getSystemService(Context.POWER_SERVICE);
					pm.reboot(null);
				}
			});
			builder.setNegativeButton(getString(R.string.no), new DialogInterface.OnClickListener()
			{
				public void onClick(DialogInterface dialog, int which)
				{
					dialog.dismiss();
				}
			});

			AlertDialog alert = builder.create();
			alert.show();
		}

		private void error(String reason)
		{
			AlertDialog.Builder builder = new AlertDialog.Builder(this);
			builder
			.setTitle(getString(R.string.error))
			.setMessage(reason)
			.setIcon(android.R.drawable.ic_dialog_alert)
			.setPositiveButton(getString(R.string.ok), new DialogInterface.OnClickListener()
			{
				public void onClick(DialogInterface dialog, int which)
				{
					dialog.dismiss();
				}
			});

			AlertDialog alert = builder.create();
			alert.show();
		}

		public void onSharedPreferenceChanged(SharedPreferences sharedPreferences, String key)
		{
			Log.d(TAG, key);

			if (key.endsWith("_b")) // Boolean settings ends with "_b"
			{
				saveSettingToProp(key, sharedPreferences.getBoolean(key, false) ? "1" : "0");
			}
			else
			{
				saveSettingToProp(key, sharedPreferences.getString(key, ""));
			}

			if (key.equals("capt_en_b"))
			{
				Settings.Global.putInt(this.getContentResolver(),
				                       Settings.Global.CAPTIVE_PORTAL_DETECTION_ENABLED, sharedPreferences.getBoolean(key, true) ? 1 : 0);
				reboot(getString(R.string.reboot_reason_captive));
			}
			else if (key.equals("etap_en_b"))
			{
				TsUtils.setActiveEdgeMode(sharedPreferences.getBoolean(key, false));
			}
		}

		@Override
		protected void onResume() {
			super.onResume();
			getPreferenceScreen().getSharedPreferences()
			.registerOnSharedPreferenceChangeListener(this);
		}

		@Override
		protected void onPause() {
			super.onPause();
			getPreferenceScreen().getSharedPreferences()
			.unregisterOnSharedPreferenceChangeListener(this);
		}

		@Override
		public void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			// Get intent, action and MIME type
			Intent intent = getIntent();
			String action = (intent == null) ? "" : intent.getAction();

			if (action != null && (action.equals("DONATE") || action.equals("OPEN")))
			{
				NotificationManager notificationManager = (NotificationManager)getSystemService(Context.NOTIFICATION_SERVICE);
				notificationManager.cancelAll();

				if (action.equals("DONATE"))
				{
					try { 
						Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(PAYPAL_DONATE_URL));
						startActivity(browserIntent);
					} catch (Exception e) { }
					this.finish();
				}
			}
		}

		@Override
		protected void onPostCreate(Bundle savedInstanceState)
		{
			super.onPostCreate(savedInstanceState);

			getPreferenceManager().setSharedPreferencesName("TsExtra_preferences");

			SharedPreferences.Editor editor = getSharedPreferences("TsExtra_preferences", 0).edit();

			loadBoolSettingFromProp(editor, "psen_en_b");
			loadBoolSettingFromProp(editor, "etap_en_b");
			loadBoolSettingFromProp(editor, "crec_en_b");
			loadBoolSettingFromProp(editor, "nochgp_en_b");
			loadBoolSettingFromProp(editor, "lsst_en_b");
			loadBoolSettingFromProp(editor, "hroot_en_b");

			editor.putBoolean("capt_en_b", Settings.Global.getInt(this.getContentResolver(),
			                  Settings.Global.CAPTIVE_PORTAL_DETECTION_ENABLED, 1) == 1 ? true : false);

			editor.commit();

			// we use the older PreferenceActivity APIs.
			addPreferencesFromResource(R.xml.pref_allsettings);

			if (!SystemProperties.get("ro.ts.build").equals(""))
				setValueSummary("teamsuperluminal", "ro.ts.build");

			Preference button = (Preference)findPreference("donate");
			button.setOnPreferenceClickListener(new Preference.OnPreferenceClickListener() {
				@Override
				public boolean onPreferenceClick(Preference arg0) {
					try {
						Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(PAYPAL_DONATE_URL));
						startActivity(browserIntent);
					} catch (Exception e) { }
					return true;
				}
			});

			button = (Preference)findPreference("donate2");
			button.setOnPreferenceClickListener(new Preference.OnPreferenceClickListener() {
				@Override
				public boolean onPreferenceClick(Preference arg0) {
					try {
						Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(MARKET_DONATE_URL));
						startActivity(browserIntent);
					} catch (Exception e) { }
					return true;
				}
			});
		}

		private void setValueSummary(String preference, String property) {
			try {
				findPreference(preference).setSummary(SystemProperties.get(property));
			} catch (RuntimeException e) {
				// No recovery
			}
		}

		void loadBoolSettingFromProp(SharedPreferences.Editor editor, String setting)
		{
			Log.d(TAG, "Load " + setting);
			String val = SystemProperties.get("persist.sys.ts." + setting);
			Log.d(TAG, setting + " = " + val);
			editor.putBoolean(setting, "1".equals(val) ? true : false);
		}

		void loadSettingFromProp(SharedPreferences.Editor editor, String setting)
		{
			Log.d(TAG, "Load " + setting);
			String val = SystemProperties.get("persist.sys.ts." + setting);
			Log.d(TAG, setting + " = " + val);
			editor.putString(setting, val);
		}

		void saveSettingToProp(String setting, String val)
		{
			Log.d(TAG, setting + " => " + val);
			SystemProperties.set("persist.sys.ts." + setting, val);
		}

		/**
		 * {@inheritDoc}
		 */
		@Override
		public boolean onIsMultiPane() {
			return false;
		}
}
