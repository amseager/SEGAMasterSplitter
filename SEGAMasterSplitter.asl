/*
    SEGA Master Splitter

    Splitter designed to handle multiple 8 and 16 bit SEGA games running on various emulators
*/

state("retroarch") {}
state("Fusion") {}
state("gens") {}
state("SEGAGameRoom") {}
state("SEGAGenesisClassics") {}

init
{
    long memoryOffset;
    IntPtr baseAddress;
    long genOffset = 0;
    long smsOffset = 0;
    baseAddress = modules.First().BaseAddress;
    bool isBigEndian = false;
    bool isFusion = false;

    switch ( game.ProcessName.ToLower() ) {
        case "retroarch":
            long gpgxOffset = 0x01AF84;
            if ( game.Is64Bit() ) {
                gpgxOffset = 0x24A3D0;
            }
            baseAddress = modules.Where(m => m.ModuleName == "genesis_plus_gx_libretro.dll").First().BaseAddress;
            genOffset = gpgxOffset;
            break;
        case "gens":
            genOffset = 0x40F5C;
            break;
        case "fusion":
            genOffset = 0x2A52D4;
            smsOffset = 0x2A52D8;
            isBigEndian = true;
            isFusion = true;
            break;
        case "segagameroom":
            baseAddress = modules.Where(m => m.ModuleName == "GenesisEmuWrapper.dll").First().BaseAddress;
            genOffset = 0xB677E8;
            break;
        case "segagenesisclassics":
            genOffset = 0x71704;
            break;

    }
    memoryOffset = memory.ReadValue<int>(IntPtr.Add(baseAddress, (int)genOffset) );
    vars.isBigEndian = isBigEndian;
    vars.gamename = timer.Run.GameName;

    Action reInitialise = () => {
        vars.isIGT = false;
        vars.loading = false;
        vars.igttotal = 0;

        vars.ingame = false;

        vars.levelselectoffset = 0;
        vars.isGenSonic1 = false;
        vars.isGenSonic1or2 = false;
        vars.isS3K = false;
        vars.nextsplit = "";
        vars.levelselectbytes = new byte[] {0x01}; // Default as most are 0 - off, 1 - on
        IDictionary<string, string> expectednextlevel = new Dictionary<string, string>();
        vars.nextzonemap = false;
        switch ( (string) vars.gamename ) {
            /**********************************************************************************
                START Sonic 3D Blast Memory watchlist
            **********************************************************************************/
            case "Sonic 3D Blast":
                vars.watchers = new MemoryWatcherList
                {
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + ( isBigEndian ? 0x067F : 0x067E ) ) { Name = "level" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset +  0xF749                           ) { Name = "ingame" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + ( isBigEndian ? 0xD189 : 0xD188 ) ) { Name = "ppboss" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + ( isBigEndian ? 0x0BA9 : 0x0BA8 ) ) { Name = "ffboss" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + ( isBigEndian ? 0x06A3 : 0x06A2 ) ) { Name = "emeralds" },
                    new MemoryWatcher<ushort>(  (IntPtr)memoryOffset + 0x0A5C                          ) { Name = "levelframecount" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + 0x040D                          ) { Name = "levelselect" },
                };
                vars.levelselectoffset = (IntPtr)memoryOffset + 0x040D;
                vars.igttotal = 0;
                vars.isIGT = true;
                
                break;

            /**********************************************************************************
                START Sonic Spinball (Genesis / Mega Drive) 
            **********************************************************************************/
            case "Sonic Spinball (Genesis / Mega Drive)":
                vars.levelselectoffset = (IntPtr)memoryOffset + ( isBigEndian ? 0xF8F8 : 0xF8F9 );
                vars.watchers = new MemoryWatcherList
                {
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + ( isBigEndian ? 0x067F : 0x067E ) ) { Name = "level" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + ( isBigEndian ? 0xF2FC : 0xF2FD ) ) { Name = "trigger" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + ( isBigEndian ? 0xFF69 : 0xFF68 ) ) { Name = "menuoption" },
                    new MemoryWatcher<ushort>(  (IntPtr)memoryOffset + 0xFF6C                            ) { Name = "menutimeout" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + ( isBigEndian ? 0x3CB7 : 0x3CB6 ) ) { Name = "gamemode" },

                    new MemoryWatcher<byte>(  vars.levelselectoffset                         ) { Name = "levelselect" },
                };

                vars.lastmenuoption = 999;
                vars.skipsplit = false;
                break;
            /**********************************************************************************
                START Sonic the HedgeHog 1 & 2 Genesis watchlist
            **********************************************************************************/        
            case "Sonic the Hedgehog (Genesis / Mega Drive)":
            case "Sonic the Hedgehog":
            case "Sonic 1": 
            case "Sonic 1 (Genesis)":
            case "Sonic 1 (Meaga Drive)":
                vars.gamename = "Sonic the Hedgehog (Genesis / Mega Drive)";
            
                const string GREEN_HILL_1 = "0-0";
                const string GREEN_HILL_2 = "0-1";
                const string GREEN_HILL_3 = "0-2";
                const string MARBLE_1 = "2-0";
                const string MARBLE_2 = "2-1";
                const string MARBLE_3 = "2-2";
                const string SPRING_YARD_1 = "4-0";
                const string SPRING_YARD_2 = "4-1";
                const string SPRING_YARD_3 = "4-2";
                const string LABYRINTH_1 = "1-0";
                const string LABYRINTH_2 = "1-1";
                const string LABYRINTH_3 = "1-2";
                const string STAR_LIGHT_1 = "3-0";
                const string STAR_LIGHT_2 = "3-1";
                const string STAR_LIGHT_3 = "3-2";
                const string SCRAP_BRAIN_1 = "5-0";
                const string SCRAP_BRAIN_2 = "5-1";
                const string SCRAP_BRAIN_3 = "1-3"; // LUL
                const string FINAL_ZONE = "5-2"; 
                const string AFTER_FINAL_ZONE = "99-0";
                
                expectednextlevel.Clear();
                expectednextlevel[GREEN_HILL_1] = GREEN_HILL_2;
                expectednextlevel[GREEN_HILL_2] = GREEN_HILL_3;
                expectednextlevel[GREEN_HILL_3] = MARBLE_1;
                expectednextlevel[MARBLE_1] = MARBLE_2;
                expectednextlevel[MARBLE_2] = MARBLE_3;
                expectednextlevel[MARBLE_3] = SPRING_YARD_1;
                expectednextlevel[SPRING_YARD_1] = SPRING_YARD_2;
                expectednextlevel[SPRING_YARD_2] = SPRING_YARD_3;
                expectednextlevel[SPRING_YARD_3] = LABYRINTH_1;
                expectednextlevel[LABYRINTH_1] = LABYRINTH_2;
                expectednextlevel[LABYRINTH_2] = LABYRINTH_3;
                expectednextlevel[LABYRINTH_3] = STAR_LIGHT_1;
                expectednextlevel[STAR_LIGHT_1] = STAR_LIGHT_2;
                expectednextlevel[STAR_LIGHT_2] = STAR_LIGHT_3;
                expectednextlevel[STAR_LIGHT_3] = SCRAP_BRAIN_1;
                expectednextlevel[SCRAP_BRAIN_1] = SCRAP_BRAIN_2;
                expectednextlevel[SCRAP_BRAIN_2] = SCRAP_BRAIN_3;
                expectednextlevel[SCRAP_BRAIN_3] = FINAL_ZONE; // LUL
                expectednextlevel[FINAL_ZONE] = AFTER_FINAL_ZONE; 
                
                vars.actsplits = new bool[][]
                {
                    new bool[] {true, true, true}, // 0 - Green Hill Zone
                    new bool[] {true, true, true, true}, // 1 - Labyrinth Zone
                    new bool[] {true, true, true}, // 2 - Marble Zone
                    new bool[] {true, true, true}, // 3 - Star Light Zone
                    new bool[] {true, true, true}, // 4 - Spring Yard Zone
                    new bool[] {true, true, true} // 5 - Scrap Brain Zone
                };
                vars.levelselectoffset = (IntPtr) memoryOffset + ( isBigEndian ? 0xFFE0 : 0xFFE1 );
                vars.isGenSonic1 = true;
                goto case "Sonic the Hedgehog 2 (Genesis / Mega Drive)";
            case "Sonic the Hedgehog 2 (Genesis / Mega Drive)":
            case "Sonic the Hedgehog 2":
            case "Sonic 2":
            case "Sonic 2 (Genesis)":
            case "Sonic 2 (Mega Drive)":
                if ( !vars.isGenSonic1 ) {
                    vars.levelselectoffset = (IntPtr) memoryOffset + ( isBigEndian ? 0xFFD0 : 0xFFD1 );

                    vars.gamename = "Sonic the Hedgehog 2 (Genesis / Mega Drive)";
                    const string EMERALD_HILL_1 = "0-0";
                    const string EMERALD_HILL_2 = "0-1";
                    const string CHEMICAL_PLANT_1 = "13-0";
                    const string CHEMICAL_PLANT_2 = "13-1";
                    const string AQUATIC_RUIN_1 = "15-0";
                    const string AQUATIC_RUIN_2 = "15-1";
                    const string CASINO_NIGHT_1 = "12-0";
                    const string CASINO_NIGHT_2 = "12-1";
                    const string HILL_TOP_1 = "7-0";
                    const string HILL_TOP_2 = "7-1";
                    const string MYSTIC_CAVE_1 = "11-0";
                    const string MYSTIC_CAVE_2 = "11-1";
                    const string OIL_OCEAN_1 = "10-0";
                    const string OIL_OCEAN_2 = "10-1";
                    const string METROPOLIS_1 = "4-0";
                    const string METROPOLIS_2 = "4-1";
                    const string METROPOLIS_3 = "5-0";
                    const string SKY_CHASE = "16-0";
                    const string WING_FORTRESS = "6-0";
                    const string DEATH_EGG = "14-0";
                    const string AFTER_DEATH_EGG = "99-0";
                    expectednextlevel.Clear();
                    expectednextlevel[EMERALD_HILL_1] = EMERALD_HILL_2;
                    expectednextlevel[EMERALD_HILL_2] = CHEMICAL_PLANT_1;
                    expectednextlevel[CHEMICAL_PLANT_1] = CHEMICAL_PLANT_2;
                    expectednextlevel[CHEMICAL_PLANT_2] = AQUATIC_RUIN_1;
                    expectednextlevel[AQUATIC_RUIN_1] = AQUATIC_RUIN_2;
                    expectednextlevel[AQUATIC_RUIN_2] = CASINO_NIGHT_1;
                    expectednextlevel[CASINO_NIGHT_1] = CASINO_NIGHT_2;
                    expectednextlevel[CASINO_NIGHT_2] = HILL_TOP_1;
                    expectednextlevel[HILL_TOP_1] = HILL_TOP_2;
                    expectednextlevel[HILL_TOP_2] = MYSTIC_CAVE_1;
                    expectednextlevel[MYSTIC_CAVE_1] = MYSTIC_CAVE_2;
                    expectednextlevel[MYSTIC_CAVE_2] = OIL_OCEAN_1;
                    expectednextlevel[OIL_OCEAN_1] = OIL_OCEAN_2;
                    expectednextlevel[OIL_OCEAN_2] = METROPOLIS_1;
                    expectednextlevel[METROPOLIS_1] = METROPOLIS_2;
                    expectednextlevel[METROPOLIS_2] = METROPOLIS_3;
                    expectednextlevel[METROPOLIS_3] = SKY_CHASE;
                    expectednextlevel[SKY_CHASE] = WING_FORTRESS;
                    expectednextlevel[WING_FORTRESS] = DEATH_EGG;
                    expectednextlevel[DEATH_EGG] = AFTER_DEATH_EGG;
                }
                vars.watchers = new MemoryWatcherList
                {
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset +   ( isBigEndian ? 0xFE24 : 0xFE25 )    ) { Name = "seconds" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset +   ( isBigEndian ? 0xFE23 : 0xFE22 )    ) { Name = "minutes" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset +   ( isBigEndian ? 0xFE12 : 0xFE13 )    ) { Name = "lives" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset +   ( isBigEndian ? 0xFE18 : 0xFE19 )    ) { Name = "continues" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset +   ( isBigEndian ? 0xFE10 : 0xFE11 )    ) { Name = "zone" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset +   ( isBigEndian ? 0xFE11 : 0xFE10 )    ) { Name = "act" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset +   ( isBigEndian ? 0xF600 : 0xF601 )    ) { Name = "trigger" },
                    new MemoryWatcher<ushort>(  (IntPtr)memoryOffset + ( isBigEndian ? 0xFE04 : 0xFE04 )    ) { Name = "levelframecount" },
                    new MemoryWatcher<byte>(  vars.levelselectoffset     ) { Name = "levelselect" },

                };
                vars.isGenSonic1or2 = true;
                vars.isIGT = true;


                vars.expectednextlevel = expectednextlevel;
                break;
            /**********************************************************************************
                START Sonic the Hedgehog 3 & Knuckles watchlist
            **********************************************************************************/
            case "Sonic 3 & Knuckles":
            case "Sonic 3 Complete":
                vars.levelselectoffset = (IntPtr) memoryOffset + ( isBigEndian ? 0xFFE0 : 0xFFE1 );
                vars.watchers = new MemoryWatcherList
                {
                    new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0xEE4E ) { Name = "level" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + ( isBigEndian ? 0xEE4E : 0xEE4F ) ) { Name = "zone" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + ( isBigEndian ? 0xEE4F : 0xEE4E ) ) { Name = "act" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + 0xFFFC ) { Name = "reset" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + ( isBigEndian ? 0xF600 : 0xF601 ) ) { Name = "trigger" },
                    new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0xF7D2 ) { Name = "timebonus" },
                    new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0xFE28 ) { Name = "scoretally" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + ( isBigEndian ? 0xFF09 : 0xFF08 ) ) { Name = "chara" },
                    new MemoryWatcher<ulong>( (IntPtr)memoryOffset + 0xFC00) { Name = "dez2end" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + ( isBigEndian ? 0xB1E5 : 0xB1E4 ) ) { Name = "ddzboss" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + ( isBigEndian ? 0xB279 : 0xB278 ) ) { Name = "sszboss" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + ( isBigEndian ? 0xEEE4 : 0xEEE5 ) ) { Name = "delactive" },

                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + ( isBigEndian ? 0xEF4B : 0xEF4A ) ) { Name = "savefile" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + ( isBigEndian ? 0xFDEB : 0xFDEA ) ) { Name = "savefilezone" },
                    new MemoryWatcher<ushort>((IntPtr)memoryOffset + ( isBigEndian ? 0xF648 : 0xF647 ) ) { Name = "waterlevel" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset + ( isBigEndian ? 0xFE25 : 0xFE24 ) ) { Name = "centiseconds" },
                    new MemoryWatcher<byte>(  vars.levelselectoffset     ) { Name = "levelselect" },
                };
                vars.nextzone = 0;
                vars.nextact = 1;
                vars.dez2split = false;
                vars.ddzsplit = false;
                vars.sszsplit = false; //boss is defeated twice
                vars.savefile = 255;
                vars.processingzone = false;
                vars.skipsAct1Split = false;
                vars.isS3K = true;
                break;
            /**********************************************************************************
                START Sonic the Hedgehog (Master System) watchlist
            **********************************************************************************/
            case "Sonic the Hedgehog (Master System)":
                if ( isFusion ) {
                    memoryOffset = memory.ReadValue<int>(IntPtr.Add(baseAddress, (int)smsOffset) ) + (int) 0xC000;
                }
                vars.watchers = new MemoryWatcherList
                {
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset +  0x123E     ) { Name = "level" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset +  0x1000     ) { Name = "state" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset +  0x1203     ) { Name = "input" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset +  0x12D5     ) { Name = "endBoss" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset +  0x122C     ) { Name = "scorescreen" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset +  0x1FEA     ) { Name = "scorescd" },
                    new MemoryWatcher<ushort>(  (IntPtr)memoryOffset +  0x1213   ) { Name = "timebonus" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset +  0x1C08   ) { Name = "menucheck1" },
                    new MemoryWatcher<byte>(  (IntPtr)memoryOffset +  0x1C0A   ) { Name = "menucheck2" },
                };

                break;

            default:
                throw new NullReferenceException (String.Format("Game {0} not supported.", vars.gamename ));
        
            
        }
        vars.DebugOutput("Game from LiveSplit found: " + vars.gamename);
    };
    vars.reInitialise = reInitialise;
    vars.reInitialise();
}

update
{

    if ( vars.gamename != timer.Run.GameName ) {
        vars.DebugOutput("Game in Livesplit changed, reinitialising...");
        vars.gamename = timer.Run.GameName;
        vars.reInitialise();
    }
    vars.watchers.UpdateAll(game);

    var start = false;
    var split = false;
    var reset = false;

    if ( !vars.ingame && timer.CurrentPhase == TimerPhase.Running) {
        //pressed start run or autostarted run
        
        vars.DebugOutput("run start detected");
        vars.igttotal = 0;
        vars.ingame = true;
        if ( vars.isGenSonic1or2 ) {
            vars.loading = true;
        }

        if ( vars.isS3K ) {
            vars.nextzone = 0;
            vars.nextact = 1;
            vars.dez2split = false;
            vars.ddzsplit = false;
            vars.sszsplit = false;
            vars.bonus = false;
            vars.savefile = vars.watchers["savefile"].Current;
            vars.skipsAct1Split = !settings["actsplit"];
        }
        
    } else if ( vars.ingame && !( timer.CurrentPhase == TimerPhase.Running || timer.CurrentPhase == TimerPhase.Paused ) ) {
        vars.DebugOutput("run stop detected");
        vars.ingame = false;
        return false;
    }


    var gametime = TimeSpan.FromDays(999);
    var oldgametime = gametime;

    if ( (long) vars.levelselectoffset > 0 && settings["levelselect"] && vars.watchers["levelselect"].Current != 1 ) {
        vars.DebugOutput("Enabling Level Select");
        game.WriteBytes( (IntPtr) vars.levelselectoffset, (byte[]) vars.levelselectbytes );
    }

    switch ( (string) vars.gamename ) {
        /**********************************************************************************
            START Sonic 3D Blast Support
        **********************************************************************************/

        case "Sonic 3D Blast":
            if(!((IDictionary<String, object>)old).ContainsKey("igt")) {
                old.igt = vars.watchers["levelframecount"].Old;
            }
            var lfc = vars.watchers["levelframecount"].Current;
            if ( vars.isBigEndian ) {
                lfc = vars.SwapEndianness(lfc);
            }
            current.igt = Math.Floor(Convert.ToDouble(lfc / 60) );

            if ( current.igt == old.igt + 1) {
                vars.igttotal++;
            }
            current.timerPhase = timer.CurrentPhase;

            if ( vars.watchers["emeralds"].Current != vars.watchers["emeralds"].Old ) {
                vars.DebugOutput(String.Format("Emeralds: {0}", vars.watchers["emeralds"].Current));
            }

            if ( !vars.ingame && vars.watchers["ingame"].Current == 1 && vars.watchers["ingame"].Old == 0 && vars.watchers["level"].Current <= 1 ) {
                start = true;
            }

            if (vars.watchers["ingame"].Current == 0 && vars.watchers["ingame"].Old == 1 && vars.watchers["level"].Current == 0 ) {
                reset = true;
            }
            if (
                ( vars.watchers["level"].Current > 1 && vars.watchers["level"].Current == (vars.watchers["level"].Old + 1) ) || // Level Change
                ( vars.watchers["level"].Current == 21 && vars.watchers["emeralds"].Current < 7 && vars.watchers["ppboss"].Old == 224 && vars.watchers["ppboss"].Current == 128) || // Panic Puppet Boss Destroyed
                ( vars.watchers["level"].Current == 22 && vars.watchers["ffboss"].Old == 1 && vars.watchers["ffboss"].Current == 0) // Final Fight Boss
            ) {
                split = true;
            }

            gametime = TimeSpan.FromSeconds(vars.igttotal);
            break;
        /**********************************************************************************
            START Sonic Spinball (Genesis / Mega Drive) 
        **********************************************************************************/
        case "Sonic Spinball (Genesis / Mega Drive)":
            var menutimeout = vars.watchers["menutimeout"].Old;
            if ( vars.isBigEndian ) {
                menutimeout = vars.SwapEndianness( menutimeout );
            }
            if ( vars.watchers["menuoption"].Old == 15 || vars.watchers["menuoption"].Old == 1 || vars.watchers["menuoption"].Old == 2 ) {
                vars.lastmenuoption = vars.watchers["menuoption"].Old;
            }
            if ( !vars.ingame && 
                 (
                     vars.lastmenuoption == 15 ||
                     vars.lastmenuoption == 1
                 )
                 &&
                 vars.watchers["gamemode"].Current == 0 &&
                 menutimeout > 10 &&
                
                vars.watchers["trigger"].Old == 3 &&
                vars.watchers["trigger"].Current == 2 ) {
                start = true;
            } else {
                if (
                        // Died
                        vars.watchers["gamemode"].Old == 2 &&
                        vars.watchers["gamemode"].Current == 6
                ) {
                    vars.skipsplit = true;
                }
                
                if (
                    (
                        // Level -> Boss Destroyed
                        vars.watchers["gamemode"].Old == 2 &&
                        vars.watchers["gamemode"].Current == 4
                        
                    ) ||
                    (
                        // Bonus Stage -> Level
                        vars.watchers["gamemode"].Old == 6 &&
                        vars.watchers["gamemode"].Current == 1
                        
                    ) || 
                    (
                        settings["ss_multiball"] &&
                        (
                            (
                                vars.watchers["gamemode"].Old == 2 &&
                                vars.watchers["gamemode"].Current == 3
                            ) ||
                            (
                                vars.watchers["gamemode"].Old == 3 &&
                                vars.watchers["gamemode"].Current == 2
                            )
                        )
                    )
                
                ) {
                    if ( vars.skipsplit ) {
                        vars.skipsplit = false;
                    } else {
                        split = true;
                    }
                }
                if (
                    vars.watchers["gamemode"].Current == 0 &&
                    vars.watchers["gamemode"].Old > 0 &&
                    vars.watchers["gamemode"].Old <= 6
                ) {
                    reset = true;
                }
            }
            break;
        /**********************************************************************************
            START Sonic the Hedgehog 1 & 2 Genesis support
        **********************************************************************************/        
        case "Sonic the Hedgehog (Genesis / Mega Drive)":
        case "Sonic the Hedgehog 2 (Genesis / Mega Drive)":
            if ( !vars.ingame && vars.watchers["trigger"].Current == 0x8C && vars.watchers["act"].Current == 0 && vars.watchers["zone"].Current == 0 ) {
                vars.nextsplit = "0-1"; // EMERALD_HILL_2 or GREEN_HILL_2
                start = true;
                vars.loading = true;
                vars.igttotal = 0;
                
            }
            if ( vars.watchers["lives"].Current == 0 && vars.watchers["continues"].Current == 0 ) {
                reset = true;
            }
            var currentlevel = String.Format("{0}-{1}", vars.watchers["zone"].Current, vars.watchers["act"].Current);
            if ( vars.nextsplit == currentlevel ) {
                vars.nextsplit = vars.expectednextlevel[currentlevel];
                vars.DebugOutput("Next Split on: " + vars.nextsplit);
                if(vars.isGenSonic1 && vars.watchers["act"].Current == 2 && vars.watchers["zone"].Current == 5) {
                    vars.pause = true; //the timer keeps counting for 3 seconds at the start of final zone, as SB3 doesn't pause the timer
                }
                split = true;
            }
            if ( 
                vars.nextsplit == "99-0" && (
                    ( vars.isGenSonic1 && vars.watchers["trigger"].Current == 0x18 ) ||
                    ( !vars.isGenSonic1 && vars.watchers["trigger"].Current == 0x20 )
                )
            ) {
                split = true;
            }

            if ( vars.ingame && !vars.loading ) {
                if (
                    (vars.watchers["seconds"].Current == (vars.watchers["seconds"].Old + 1)) && (vars.watchers["minutes"].Current == vars.watchers["minutes"].Old) || 
                    (vars.watchers["seconds"].Current == 0 && (vars.watchers["minutes"].Current == (vars.watchers["minutes"].Old + 1)))
                    ) 
                {
                    vars.igttotal++;
                }
            }
            else if (vars.watchers["levelframecount"].Current == 0 && vars.watchers["seconds"].Current == 0 && vars.watchers["minutes"].Current == 0) {
                 vars.loading = false; //unpause timer once game time has reset
            }
            gametime = TimeSpan.FromSeconds(vars.igttotal);
            break;
        /**********************************************************************************
            START Sonic the Hedgehog 3 & Knuckles watchlist
        **********************************************************************************/
            case "Sonic 3 & Knuckles":
            case "Sonic 3 Complete":

                if (!vars.ingame && vars.watchers["trigger"].Current == 0x8C && vars.watchers["act"].Current == 0 && vars.watchers["zone"].Current == 0)
                {
                    vars.DebugOutput(String.Format("next split on: zone: {0} act: {1}", vars.nextzone, vars.nextact));
                    start = true;
                }
                current.inMenu = ( vars.watchers["waterlevel"].Current == 0 && vars.watchers["centiseconds"].Current == 0 && vars.watchers["centiseconds"].Old == 0 );
                current.scoretally = vars.watchers["scoretally"].Current;
                current.timebonus = vars.watchers["timebonus"].Current;
                if ( vars.isBigEndian ) {
                    current.scoretally = vars.SwapEndianness(vars.watchers["scoretally"].Current);
                    current.timebonus  = vars.SwapEndianness(vars.watchers["timebonus"].Current);
                }



                if ( vars.ingame ) {
                    // detecting memory checksum at end of RAM area being 0 - only changes if ROM is reloaded (Hard Reset)
                    // or if "DEL" is selected from the save file select menu.

                    if ( ( settings["hard_reset"] && vars.watchers["reset"].Current == 0 && vars.watchers["reset"].Old != 0 ) || 
                        ( current.inMenu == true
                            && ( 
                                ( vars.watchers["savefile"].Current == 9 && vars.watchers["delactive"].Current == 0xFF && vars.watchers["delactive"].Old == 0 ) ||
                                ( 
                                    vars.watchers["savefile"].Current == vars.savefile && 
                                    (vars.nextact + vars.nextzone) <= 1 && 
                                    vars.watchers["savefilezone"].Old == 255 && 
                                    vars.watchers["savefilezone"].Current == 0 )
                            )
                        ) 
                    ) {
                        reset = true;
                    }
                    if (  vars.loading && old.timebonus == 0 ) {
                        // If we had a bonus, and the previous frame's timebonus is now 0, reset it
                        vars.loading = false;
                    } else if ( !vars.loading && vars.watchers["act"].Current <= 1 && current.timebonus < old.timebonus && current.scoretally > old.scoretally ) {
                        // if we haven't detected a bonus yet
                        // check that we are in an act (sanity check)
                        // then check to see if the current timebonus is less than the previous frame's one.
                        vars.DebugOutput(String.Format("Detected Bonus decrease: {0} from: {1}", current.timebonus, old.timebonus));
                        vars.loading = true;
                    }
                }
                const byte ACT_1 = 0;
                const byte ACT_2 = 1;

                const byte SONIC_AND_TAILS = 0;
                const byte SONIC = 1;
                const byte TAILS = 2;
                const byte KNUCKLES = 3;

                /* S3K levels */
                const byte ANGEL_ISLAND      = 0;
                const byte HYDROCITY         = 1;
                const byte MARBLE_GARDEN     = 2;
                const byte CARNIVAL_NIGHT    = 3;
                const byte ICE_CAP           = 5;
                const byte LAUNCH_BASE       = 6;
                const byte MUSHROOM_HILL     = 7;
                const byte FLYING_BATTERY    = 4;
                const byte SANDOPOLIS        = 8;
                const byte LAVA_REEF         = 9;
                const byte SKY_SANCTUARY     = 10;
                const byte DEATH_EGG         = 11;
                const byte DOOMSDAY          = 12;
                const byte LRB_HIDDEN_PALACE = 22;
                const byte DEATH_EGG_BOSS    = 23;

                if (!vars.nextzonemap.GetType().IsArray) {
                    vars.nextzonemap = new byte[] { 
                    /*  0 ANGEL_ISLAND      -> */ HYDROCITY, 
                    /*  1 HYDROCITY         -> */ MARBLE_GARDEN, 
                    /*  2 MARBLE_GARDEN     -> */ CARNIVAL_NIGHT, 
                    /*  3 CARNIVAL_NIGHT    -> */ ICE_CAP, 
                    /*  4 FLYING_BATTERY    -> */ SANDOPOLIS, 
                    /*  5 ICE_CAP           -> */ LAUNCH_BASE, 
                    /*  6 LAUNCH_BASE       -> */ MUSHROOM_HILL, 
                    /*  7 MUSHROOM_HILL     -> */ FLYING_BATTERY, 
                    /*  8 SANDOPOLIS        -> */ LAVA_REEF, 
                    /*  9 LAVA_REEF         -> */ LRB_HIDDEN_PALACE, 
                    /* 10 SKY_SANCTUARY     -> */ DEATH_EGG, 
                    /* 11 DEATH_EGG         -> */ DEATH_EGG_BOSS,
                    /* 12 DOOMSDAY          -> */ 0,
                    /* 13,14,15,16,17,18,19,20,21 */ 0,0,0,0,0,0,0,0,0,
                    /* 22 LRB_HIDDEN_PALACE -> */ SKY_SANCTUARY,
                    /* 23 DEATH_EGG_BOSS    -> */ DOOMSDAY
                    };
                }

                if ( vars.watchers["zone"].Old != vars.watchers["zone"].Current && settings["actsplit"] ) {
                    vars.skipsAct1Split = ( 
                        ( vars.watchers["zone"].Current == MARBLE_GARDEN && settings["act_mg1"] ) || 
                        ( vars.watchers["zone"].Current == ICE_CAP && settings["act_ic1"] ) ||
                        ( vars.watchers["zone"].Current == LAUNCH_BASE && settings["act_lb1"] )
                    );
                }

                if (
                    !vars.processingzone && 
                    vars.watchers["zone"].Current != DOOMSDAY && 
                    /* Make doubly sure we are in the correct zone */
                    vars.watchers["zone"].Current == vars.nextzone && vars.watchers["zone"].Old == vars.nextzone &&
                    vars.watchers["act"].Current == vars.nextact && vars.watchers["act"].Old == vars.nextact 
                ) {
                    vars.processingzone = true;
                    

                    switch ( (int)vars.watchers["act"].Current ) {
                        // This is AFTER a level change.
                        case ACT_1:
                            vars.nextact = ACT_2;
                            if ( 
                                // Handle IC boss skip and single act zones.
                                ( vars.watchers["zone"].Current == ICE_CAP && vars.skipsAct1Split ) ||
                                ( vars.watchers["zone"].Current == SKY_SANCTUARY ) ||
                                ( vars.watchers["zone"].Current == LRB_HIDDEN_PALACE )
                            ) {  
                                vars.nextzone = vars.nextzonemap[vars.watchers["zone"].Current];
                                vars.nextact = ACT_1;
                            }
                            split = ( vars.watchers["zone"].Current < LRB_HIDDEN_PALACE );
                            break;
                        case ACT_2:
                            // next split is generally Act 1 of next zone
                            vars.nextzone = vars.nextzonemap[vars.watchers["zone"].Current];
                            vars.nextact = ACT_1;
                            if ( vars.watchers["zone"].Current == LAVA_REEF || 
                                ( vars.watchers["zone"].Current == LRB_HIDDEN_PALACE && vars.watchers["chara"].Current == KNUCKLES ) 
                            ) {
                                // LR2 -> HP = 22-1 and HP -> SS2 for Knux
                                vars.nextact = ACT_2; 
                            }
                            // If we're not skipping the act 1 split, or we entered Hidden Palace
                            split = ( !vars.skipsAct1Split || vars.watchers["zone"].Current == LRB_HIDDEN_PALACE );

                            break;
                    }

                    vars.processingzone = false;
                }
                
                if (!vars.dez2split && vars.watchers["zone"].Current == DEATH_EGG_BOSS && vars.watchers["act"].Current == ACT_1) //detect fade to white on death egg 2
                {
                    if ((vars.watchers["dez2end"].Current == 0xEE0EEE0EEE0EEE0E && vars.watchers["dez2end"].Old == 0xEE0EEE0EEE0EEE0E) ||
                        (vars.watchers["dez2end"].Current == 0x0EEE0EEE0EEE0EEE && vars.watchers["dez2end"].Old == 0x0EEE0EEE0EEE0EEE))
                    {
                        vars.DebugOutput("DEZ2 Boss White Screen detected");
                        vars.dez2split = true;
                        split = true;
                    }
                }
                
                if (vars.watchers["zone"].Current == DOOMSDAY && vars.watchers["ddzboss"].Current == 255 && vars.watchers["ddzboss"].Old == 0) //Doomsday boss detect final hit
                {
                    vars.DebugOutput("Doomsday Zone Boss death detected"); //need to detect fade to white, same as DEZ2End
                    vars.ddzsplit = true;
                }
                
                if (vars.ddzsplit || vars.sszsplit) //detect fade to white on doomsday
                {
                    if ((vars.watchers["dez2end"].Current == 0xEE0EEE0EEE0EEE0E && vars.watchers["dez2end"].Old == 0xEE0EEE0EEE0EEE0E) ||
                        (vars.watchers["dez2end"].Current == 0x0EEE0EEE0EEE0EEE && vars.watchers["dez2end"].Old == 0x0EEE0EEE0EEE0EEE))
                    {
                        vars.DebugOutput("Doomsday/SS White Screen detected");
                        split = true;
                    }
                }
                

                if (vars.watchers["chara"].Current == KNUCKLES && vars.watchers["zone"].Current == SKY_SANCTUARY) //detect final hit on Knux Sky Sanctuary Boss
                {
                    if (vars.watchers["sszboss"].Current == 0 && vars.watchers["sszboss"].Old == 1)
                    {
                        vars.DebugOutput("Knuckles Final Boss 1st phase defeat detected");
                        vars.sszsplit = true;
                    }
                }
                
                if (split)
                {
                    vars.DebugOutput(String.Format("old level: {0:X4} old zone: {1} old act: {2}", vars.watchers["level"].Old, vars.watchers["zone"].Old, vars.watchers["act"].Old));
                    vars.DebugOutput(String.Format("level: {0:X4} zone: {1} act: {2}", vars.watchers["level"].Current, vars.watchers["zone"].Current, vars.watchers["act"].Current));
                    vars.DebugOutput(String.Format("next split on: zone: {0} act: {1}", vars.nextzone, vars.nextact));
                }
            break;
        /**********************************************************************************
            START Sonic the Hedgehog (Master System) support
        **********************************************************************************/
        case "Sonic the Hedgehog (Master System)":
            if ( vars.watchers["menucheck1"].Current == 5 && vars.watchers["menucheck1"].Old <= 1 && vars.watchers["menucheck2"].Current == 4 && vars.watchers["menucheck2"].Old <= 1 ) {
                reset = true;
            }
            if ( !!vars.ingame && vars.watchers["state"].Old == 128 && vars.watchers["state"].Current == 224 && vars.watchers["level"].Current == 0 && vars.watchers["input"].Current != 255) {
                vars.DebugOutput(String.Format("Split Start of Level {0}", vars.watchers["level"].Current));
                start = true;
            }
            if (
                (
                    (vars.watchers["level"].Current != vars.watchers["level"].Old && vars.watchers["level"].Current <= 17) || 
                    (vars.watchers["endBoss"].Current == 89 && vars.watchers["endBoss"].Old != 89 && vars.watchers["level"].Current==17)
                ) 
                && (vars.watchers["state"].Current != 0 && vars.watchers["level"].Current > 0)
            ) {
                vars.DebugOutput(String.Format("Split Start of Level {0}", vars.watchers["level"].Current));
                split = true;
            }
            
            if ( vars.loading && vars.watchers["timebonus"].Current == 0 ) {
                vars.loading = false;
            } else if ( !vars.loading && vars.watchers["timebonus"].Current > 0 && vars.watchers["scorescreen"].Current == 27 && vars.watchers["scorescd"].Current == 22 ) {
                vars.loading = true;
            }
            break;



        default:
            break;
    }


    current.start = start;
    current.reset = reset;
    current.split = split;
    if ( gametime != oldgametime ) {
        current.gametime = gametime;
    }

}





startup
{
    Action<string> DebugOutput = (text) => {
        print("[SEGA Master Splitter] "+text);
    };

    Action<ExpandoObject> DebugOutputExpando = (ExpandoObject dynamicObject) => {
            var dynamicDictionary = dynamicObject as IDictionary<string, object>;
         
            foreach(KeyValuePair<string, object> property in dynamicDictionary)
            {
                DebugOutput(String.Format("{0}: {1}", property.Key, property.Value.ToString()));
            }
            DebugOutput("");
    };

    Func<ushort,ushort> SwapEndianness = (ushort value) => {
        var b1 = (value >> 0) & 0xff;
        var b2 = (value >> 8) & 0xff;

        return (ushort) (b1 << 8 | b2 << 0);
    };
    vars.SwapEndianness = SwapEndianness;
    vars.DebugOutput = DebugOutput;
    vars.DebugOutputExpando = DebugOutputExpando;
    
    refreshRate = 60;

    /* S3K settings */
    settings.Add("s3k", true, "Settings for Sonic 3 & Knuckles");
    settings.Add("actsplit", false, "Split on each Act", "s3k");
    settings.SetToolTip("actsplit", "If unchecked, will only split at the end of each Zone.");
    
    settings.Add("act_mg1", false, "Ignore Marble Garden 1", "actsplit");
    settings.Add("act_ic1", false, "Ignore Ice Cap 1", "actsplit");
    settings.Add("act_lb1", false, "Ignore Launch Base 1", "actsplit");

    settings.Add("hard_reset", true, "Reset timer on Hard Reset?", "s3k");
    
    settings.SetToolTip("act_mg1", "If checked, will not split the end of the first Act. Use if you have per act splits generally but not for this zone.");
    settings.SetToolTip("act_ic1", "If checked, will not split the end of the first Act. Use if you have per act splits generally but not for this zone.");
    settings.SetToolTip("act_lb1", "If checked, will not split the end of the first Act. Use if you have per act splits generally but not for this zone.");

    settings.SetToolTip("hard_reset", "If checked, a hard reset will reset the timer.");

    /* Sonic Spinball settings */
    settings.Add("ss", true, "Settings for Sonic Spinball (Genesis / Mega Drive)");
    settings.Add("ss_multiball", false, "Split on entry & exit of multiball stages", "ss");
    settings.SetToolTip("ss_multiball", "If checked, will split on entry and exit of extra bonus stages for Max Jackpot Bonus.");
    /* Debug Settings */

    settings.Add("debug", false, "Debugging Options");
    settings.Add("levelselect", false, "Enable Level Select (if supported)", "debug");
}


start
{
    if ( current.start ) {
        current.start = false;
        return true;
    }
}

reset
{
    if ( current.reset ) {
        current.reset = false;
        vars.ingame = false;
        return true;
    }
}

split
{
    if ( current.split ) {
        current.split = false;
        return true;
    }
    
}

isLoading
{
    if ( vars.isIGT ) {
        return true;
    }
    return vars.loading;
}

gameTime
{
    if ( !vars.isIGT ) {
        return TimeSpan.FromMilliseconds(timer.CurrentTime.GameTime.Value.TotalMilliseconds);
    }
    if(((IDictionary<String, object>)current).ContainsKey("gametime")) {
        return current.gametime;
    }
}