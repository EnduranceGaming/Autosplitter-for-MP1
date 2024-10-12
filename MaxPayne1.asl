state("maxpayne")
{
	int onLoadScreen : 0x4A6400, 0x80, 0xB4;
	int viewingComic : "e2mfc.dll", 0x651DC;
	int inCutscene : 0x4B5080;
	int level : 0x4B1370;
	int lastLevelComplete : 0x4B408C, 0x154;
	int tutorialStatus : 0x4B3E7C;
	float playerX : 0x4B08C0;
	float playerY : 0x4B08C4;
	float playerZ : 0x4B08C8;
	float nymGameTime : 0x4B709C, 0x770;
}

startup
{
	vars.EPSILON = 0.0003;
	vars.START_POSITION_RANGE = 0.05;
	vars.NYM_SAVE_LOAD_PENALTY = 5; //5 second penalty per save loaded for NYM runs

	vars.LEVELS_START_POS = new Dictionary<int, Tuple<double, double, double>>()
	{
		{651, new Tuple<double, double, double>(-1.27900, -0.51500, -13.25000)}, 	//P1C0
		{1608, new Tuple<double, double, double>(-4.15398, -0.01500, 2.79962)}, 	//P1C1
		{1260, new Tuple<double, double, double>(-8.13992, -1.81498, 11.34619)}, 	//P1C2
		{2094, new Tuple<double, double, double>(5.72900, -1.51565, -0.26233)}, 	//P1C3
		{1656, new Tuple<double, double, double>(-0.12500, 3.85000, 1.65400)}, 		//P1C4
		{1338, new Tuple<double, double, double>(-34.00000, -11.01500, -12.02900)}, //P1C5
		{1254, new Tuple<double, double, double>(8.75107, -2.98375, -19.39504)},	//P1C6
		{1344, new Tuple<double, double, double>(-13.5, 4.01400, -21.75000)}, 		//P1C7
		{1347, new Tuple<double, double, double>(3.84185, -1.51500, 4.26432)}, 		//P1C8
		{234, new Tuple<double, double, double>(-4.00000, 1.46600, -11.75000)}, 	//P1C9
		{417, new Tuple<double, double, double>(-1.00000, -0.01500, -0.27900)}, 	//P2C0
		{1179, new Tuple<double, double, double>(1.75007, -2.01500, 6.40532)}, 		//P2C1
		{1086, new Tuple<double, double, double>(-5.37386, -6.01500, -8.34099)}, 	//P2C2
		{897, new Tuple<double, double, double>(7.74934, -4.01500, -15.27830)}, 	//P2C3
		{1581, new Tuple<double, double, double>(-4.52900, -1.01500, -12.00000)}, 	//P2C4
		{1620, new Tuple<double, double, double>(-3.3415, 3.11000, -0.37500)}, 		//P2C5
		{714, new Tuple<double, double, double>(-0.58702, -12.01500, 0.25898)}, 	//P3C0
		{1146, new Tuple<double, double, double>(18.44053, 8.27849, 22.06493)}, 	//P3C1
		{1920, new Tuple<double, double, double>(2.40400, -0.01500, -6.375)}, 		//P3C2
		{2781, new Tuple<double, double, double>(0.75, -0.01500, 0.77900)}, 		//P3C3
		{1209, new Tuple<double, double, double>(-17.49977, -2.51500, 27.77921)}, 	//P3C4
		{1401, new Tuple<double, double, double>(13.74994, -1.48600, 8.68750)}, 	//P3C5
		{1014, new Tuple<double, double, double>(-13.40400, -1.01500, -1.7500)}, 	//P3C6
		{1110, new Tuple<double, double, double>(3.62406, -6.37906, -0.00000)}, 	//P3C7
		{1374, new Tuple<double, double, double>(7.52900, -31.01500, -1.00000)}, 	//P3C8
		{531, new Tuple<double, double, double>(-0.17405, -5.51500, 14.68526)}, 	//Tutorial
		{402, new Tuple<double, double, double>(3.34600, -1.51500, 3.7500)} 		//Secret Finale
	};

	vars.LEVEL_NUMS = new int[27] {651, 1608, 1260, 2094, 1656, 1338, 1254, 1344, 1347, 234, 417, 1179, 1086, 897, 1581, 1620, 714, 1146, 1920, 2781, 1209, 1401, 1014, 1110, 1374, 531, 402};

	settings.Add("nymRunMode", false, "NYM Run Mode");
	settings.SetToolTip("nymRunMode", "Times the current run using the in-game New York Minute timer.");

	settings.Add("nymSaveLoadPenalty", true, "Apply Loading Penalty", "nymRunMode");
	settings.SetToolTip("nymSaveLoadPenalty", "On by default, as the loading penalty is applied to all runs on speedrun.com. A 5-second penalty is applied each time a save is loaded by the runner. But you can turn it off to match the raw in-game New York Minute timer for testing.");

	settings.Add("ilRunMode", false, "IL Run Mode");
	settings.SetToolTip("ilRunMode", "Starts the timer at the start of any level. Stops the timer when the level has been completed (autostop is not supported for Secret Finale).");
}

init
{
	vars.playerInStartPosition = false;
	vars.resetValid = false;
	vars.nextLevelIndex = 1;
	vars.autoEndDone = false;
	vars.totalTimePenalty = 0;
	vars.tutorialStatusIncrementedCount = 0;

	//necessary to ensure that the timer will start correctly if the runner starts Livesplit while already loaded into a level
	if (current.level > 0)
	{
		// defines the coordinate range of Max's starting position for the current level
		// (to deal with float inaccuracies and slight differences in position due to inputs on the loading screen affecting Max's starting position)
		vars.startPositionX = new Tuple<double, double>(vars.LEVELS_START_POS[current.level].Item1 - vars.START_POSITION_RANGE, vars.LEVELS_START_POS[current.level].Item1 + vars.START_POSITION_RANGE);
		vars.startPositionY = new Tuple<double, double>(vars.LEVELS_START_POS[current.level].Item2 - vars.START_POSITION_RANGE, vars.LEVELS_START_POS[current.level].Item2 + vars.START_POSITION_RANGE);
		vars.startPositionZ = new Tuple<double, double>(vars.LEVELS_START_POS[current.level].Item3 - vars.START_POSITION_RANGE, vars.LEVELS_START_POS[current.level].Item3 + vars.START_POSITION_RANGE);
	}
	else
	{
		vars.startPositionX = new Tuple<double, double>(0, 0);
		vars.startPositionY = new Tuple<double, double>(0, 0);
		vars.startPositionZ = new Tuple<double, double>(0, 0);
	}
}

update
{
	// almost every time you kill an enemy in the tutorial, the so-called tutorial status will increment...
	// we can use this to tell when the tutorial is complete, since killing enemies is the main and final goal
	// note: interacting with the enemy dispenser and painkillers in the subway entrance also increments the tutorial status
	if (current.level == vars.LEVEL_NUMS[25] && current.tutorialStatus == old.tutorialStatus + 1)
	{
		vars.tutorialStatusIncrementedCount += 1;
	}

	if (current.level > 0 && current.level != old.level)
	{
		// defines the coordinate range of Max's starting position for the current level
		// (to deal with float inaccuracies and slight differences in position due to inputs on the loading screen affecting Max's starting position)
		vars.startPositionX = new Tuple<double, double>(vars.LEVELS_START_POS[current.level].Item1 - vars.START_POSITION_RANGE, vars.LEVELS_START_POS[current.level].Item1 + vars.START_POSITION_RANGE);
		vars.startPositionY = new Tuple<double, double>(vars.LEVELS_START_POS[current.level].Item2 - vars.START_POSITION_RANGE, vars.LEVELS_START_POS[current.level].Item2 + vars.START_POSITION_RANGE);
		vars.startPositionZ = new Tuple<double, double>(vars.LEVELS_START_POS[current.level].Item3 - vars.START_POSITION_RANGE, vars.LEVELS_START_POS[current.level].Item3 + vars.START_POSITION_RANGE);
	}

	vars.playerInStartPosition = current.level > 0 && (settings["ilRunMode"] || current.level == vars.LEVEL_NUMS[0]) &&
		current.onLoadScreen == 0 && current.viewingComic == 0 && current.inCutscene == 0 &&
		current.playerX >= vars.startPositionX.Item1 && current.playerX <= vars.startPositionX.Item2 &&
		current.playerY >= vars.startPositionY.Item1 && current.playerY <= vars.startPositionY.Item2 &&
		current.playerZ >= vars.startPositionZ.Item1 && current.playerZ <= vars.startPositionZ.Item2;

	if (!vars.playerInStartPosition)
	{
		vars.resetValid = true;
	}

	return true;
}

start
{
	if (vars.playerInStartPosition)
	{
		return true;
	}
}

onStart
{
	vars.autoEndDone = false;
	vars.tutorialStatusIncrementedCount = 0;
}

reset
{
	if (vars.resetValid && vars.playerInStartPosition)
	{
		return true;
	}
}

onReset
{
	vars.resetValid = false;
	vars.autoEndDone = false;
	vars.tutorialStatusIncrementedCount = 0;
	vars.nextLevelIndex = 1;
	vars.totalTimePenalty = 0;
}

split
{
	//see if the conditions are met to split for an IL run, there is a special case in this for the Tutorial
	bool shouldSplit = !vars.autoEndDone && settings["ilRunMode"] &&
		(current.level == vars.LEVEL_NUMS[25] && vars.tutorialStatusIncrementedCount == 8 ||
		current.level > 0 && current.level != old.level);

	//determine if the timer should split during a full game run
	if (!shouldSplit)
	{
		shouldSplit = !vars.autoEndDone && !settings["ilRunMode"] &&
			current.level > 0 && current.level != old.level &&
			current.level == vars.LEVEL_NUMS[vars.nextLevelIndex];

		if (shouldSplit)
		{
			vars.nextLevelIndex++;
		}
	}

	//special case to autosplit once the final cutscene in P3C8 has started
	if (!shouldSplit && !vars.autoEndDone)
	{
		shouldSplit = current.level == vars.LEVEL_NUMS[24] && current.inCutscene == 1 && current.lastLevelComplete == 0;
		vars.autoEndDone = shouldSplit;
	}

	if (shouldSplit)
	{
		return true;
	}
}

gameTime
{
	if (settings["nymRunMode"])
	{
		if (current.level > 0 && current.nymGameTime > vars.EPSILON)
		{
			if (settings["nymSaveLoadPenalty"] && current.nymGameTime < old.nymGameTime - vars.EPSILON)
			{
				vars.totalTimePenalty += vars.NYM_SAVE_LOAD_PENALTY;
			}

			//just take the time from the game, as it keeps the entire time of the run
			//doing it this way allows loading quick saves or autosaves to correctly adjust the timer
			
			return TimeSpan.FromSeconds(current.nymGameTime + vars.totalTimePenalty);
		}
	}
}

isLoading
{
	if (settings["nymRunMode"])
	{
		return true;
	}
	else
	{
		return current.onLoadScreen > 0 && current.viewingComic == 0;
	}
}
