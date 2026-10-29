//
// Original autosplitter by liveth: https://www.speedrun.com/quake_3_arena/resources/644it
// Modified: added automatic reset when the Single Player save is reset or DM0 is restarted.
//
// 		This Autosplitter script will split automaticly when you enter the map,
// also it removes loadtimes which means Livesplit time will be paused on loading screens.
// Autosplitter was tested only on Point Release 1.32, 1.32c and steam version so there is probably
// no compability with older versions.
// **********************************IMPORTANT*****************************************				
// 	    For Autosplitter properly to work you will need to have exactly 26 splits in LiveSplit
// relating to 26 Quake 3 maps. Exact names of the splits dont really matter.
// For example you can use name DM6 or Camping grounds. If you want to use custom splits 
// Tier splits for example customize it in "Layout Settings" - "Scriptable Auto Splitter" tab.
// Autsosplitter will split at the start of "checked" maps.
// It will start and end the run despite of what maps were checked.
// Autosplitter will reset the run when you press RESET in the Single Player menu (wipes the SP save)
// or when DM0 is loaded again. Both can be turned off in settings.
// Also for Loading Removal to work you will need to set all Livesplit time settings to Game Time. Those settings are:
// 1.In Main Layout - Right Click - "Compare Against -> Game Time" , 
// 2.In Main Layout - Right Click - "Edit Layout..." - "Layout Settings" - "Splits" tab - 
// set all "Timing Method" settings to "Game Time" do the same in "Timer" tab.

state("quake3")
{
	string16 bsp : 0x0065F141;
	int loading: 0x6FFD00;
	int playerfrags: 0x65A1B8;
	string16 bsp2: 0x75F7C1;
	int loading2: 0x00002594, 0x0;
	int playerfrags2: 0x000077F8, 0xC0;
	
}

startup
{
	settings.Add("q3dm0.bsp", true, "DM0");
	settings.Add("q3dm1.bsp", true, "DM1");
	settings.Add("q3dm2.bsp", true, "DM2");
	settings.Add("q3dm3.bsp", true, "DM3");
	settings.Add("q3tourney1.bsp", true, "T1");
	settings.Add("q3dm4.bsp", true, "DM4");
	settings.Add("q3dm5.bsp", true, "DM5");
	settings.Add("q3dm6.bsp", true, "DM6");
	settings.Add("q3tourney2.bsp", true, "T2");
	settings.Add("q3dm7.bsp", true, "DM7");
	settings.Add("q3dm8.bsp", true, "DM8");
	settings.Add("q3dm9.bsp", true, "DM9");
	settings.Add("q3tourney3.bsp", true, "T3");
	settings.Add("q3dm10.bsp", true, "DM10");
	settings.Add("q3dm11.bsp", true, "DM11");
	settings.Add("q3dm12.bsp", true, "DM12");
	settings.Add("q3tourney4.bsp", true, "T4");
	settings.Add("q3dm13.bsp", true, "DM13");
	settings.Add("q3dm14.bsp", true, "DM14");
	settings.Add("q3dm15.bsp", true, "DM15");
	settings.Add("q3tourney5.bsp", true, "T5");
	settings.Add("q3dm16.bsp", true, "DM16");
	settings.Add("q3dm17.bsp", true, "DM17");
	settings.Add("q3dm18.bsp", true, "DM18");
	settings.Add("q3dm19.bsp", true, "DM19");
	settings.Add("q3tourney6.bsp", true, "T6");
	settings.Add("resetOnSaveWipe", true, "Reset when Single Player save is reset (RESET button in SP menu)");
	settings.Add("resetOnDm0", true, "Reset when DM0 is loaded again (restarting the run)");
	settings.Add("startAnyMap", false, "Start on any map, not only DM0 (practice)");

}

init
{
	vars.visited = new List<String>();

	// LiveSplit doesn't run the "reset" block after the run has ended,
	// so resets are done from "update" through the timer model
	vars.timerModel = new TimerModel { CurrentState = timer };

	// Single Player progress is stored in archived cvars (g_spScores1-5, g_spAwards, g_spVideos)
	// which the game writes to baseq3\q3config.cfg as soon as they change.
	// The RESET button in the SP menu clears all of them, so we watch that file.
	vars.cfgPath = System.IO.Path.Combine(System.IO.Path.GetDirectoryName(modules.First().FileName), "baseq3", "q3config.cfg");
	vars.cfgTime = DateTime.MinValue;
	vars.hadSave = false;

	// Returns true if the save is empty, false if not, null if the file could not be read
	vars.IsSaveEmpty = (Func<string, bool?>)(path => {
		try {
			string text;
			using (var fs = new System.IO.FileStream(path, System.IO.FileMode.Open, System.IO.FileAccess.Read, System.IO.FileShare.ReadWrite | System.IO.FileShare.Delete))
			using (var sr = new System.IO.StreamReader(fs))
				text = sr.ReadToEnd();

			var matches = System.Text.RegularExpressions.Regex.Matches(text,
				@"^seta\s+(g_spScores[1-5]|g_spAwards|g_spVideos)\s+""(.*)""\s*$",
				System.Text.RegularExpressions.RegexOptions.Multiline);

			// File is being rewritten or has no SP cvars yet
			if (matches.Count == 0) return null;

			foreach (System.Text.RegularExpressions.Match m in matches) {
				if (m.Groups[2].Value.Trim() != "") return false;
			}
			return true;
		}
		catch (Exception) {
			return null;
		}
	});

	// Returns true once when the save goes from "has progress" to "completely empty" (RESET was pressed).
	// Note: RESET on an already empty save changes nothing in the game and can't be detected here
	vars.CheckSaveWiped = (Func<bool>)(() => {
		DateTime time;
		try {
			time = System.IO.File.GetLastWriteTimeUtc(vars.cfgPath);
		}
		catch (Exception) {
			return false;
		}

		if (time == vars.cfgTime) return false;

		bool? empty = vars.IsSaveEmpty(vars.cfgPath);
		if (empty == null) return false; // try again next tick

		vars.cfgTime = time;

		if (empty == false) {
			vars.hadSave = true;
			return false;
		}
		if (vars.hadSave) {
			vars.hadSave = false;
			return true;
		}
		return false;
	});

}

update
{
	bool resetRun = false;

	// Save file has to be checked every tick to keep track of its state
	if (vars.CheckSaveWiped() && settings["resetOnSaveWipe"]) {
		resetRun = true;
	}

	// DM0 is only played at the start of the campaign, so loading it again means the run is restarted.
	// This also covers quitting DM0 and pressing RESET on a still empty save
	if (settings["resetOnDm0"]) {
		if ((current.bsp == "q3dm0.bsp" && old.loading != 8 && current.loading == 8) ||
			(current.bsp2 == "q3dm0.bsp" && old.loading2 != 8 && current.loading2 == 8)) {
			resetRun = true;
		}
	}

	// Works for both running and ended runs; "start" can then start a new run on the same tick
	if (resetRun && timer.CurrentPhase != TimerPhase.NotRunning) {
		vars.timerModel.Reset();
	}
}

start
{
	// Start only at the moment a map is entered, so a manual reset while in game
	// doesn't start the timer again right away
	if ((old.loading != 8 && current.loading == 8 && (current.bsp == "q3dm0.bsp" || settings["startAnyMap"])) ||
		(old.loading2 != 8 && current.loading2 == 8 && (current.bsp2 == "q3dm0.bsp" || settings["startAnyMap"]))) {
		vars.visited.Clear();
		vars.visited.Add("q3dm0.bsp");
		return true;
	}

}

split
{
	if(current.bsp == old.bsp && current.loading == 8) {
		if(settings[current.bsp] && !vars.visited.Contains(current.bsp))
		{
			vars.visited.Add(current.bsp);
			return true;
		}

	}

	if(current.bsp2 == old.bsp2 && current.loading2 == 8) {
		if(settings[current.bsp2] && !vars.visited.Contains(current.bsp2))
		{
			vars.visited.Add(current.bsp2);
			return true;
		}

	}
	
	if (current.bsp == "q3tourney6.bsp" && current.playerfrags == 10) {
		return true;
		}
	
	if (current.bsp2 == "q3tourney6.bsp" && current.playerfrags2 == 10) {
		return true;
		}
}

isLoading
{
	if(current.loading > 1 && current.loading < 8) {
		return true;
	}

	if(current.loading2 > 1 && current.loading2 < 8) {
		return true;
	}

	else {
		return false;
	}
}
