package net.bigpoint.darkorbit.net
{
   import com.bigpoint.utils.BPLocale;
   import flash.external.ExternalInterface;
   import flash.utils.Dictionary;
   import mx.utils.StringUtil;
   import net.bigpoint.darkorbit.Hero;
   import net.bigpoint.darkorbit.InGameCatalog;
   import net.bigpoint.darkorbit.Main;
   import net.bigpoint.darkorbit.audio.AudioManager;
   import net.bigpoint.darkorbit.data.RankedHuntingEventData;
   import net.bigpoint.darkorbit.data.vo.RankedHuntStatsVO;
   import net.bigpoint.darkorbit.fireworks.FireworksManager;
   import net.bigpoint.darkorbit.gui.CPUItem;
   import net.bigpoint.darkorbit.gui.GuiManager;
   import net.bigpoint.darkorbit.gui.MenuButton;
   import net.bigpoint.darkorbit.gui.container.SimpleContainer;
   import net.bigpoint.darkorbit.gui.elements.SimpleElement;
   import net.bigpoint.darkorbit.gui.windows.SimpleWindow;
   import net.bigpoint.darkorbit.map.Map;
   import net.bigpoint.darkorbit.menu.ActionButton;
   import net.bigpoint.darkorbit.menu.MenuManager;
   import net.bigpoint.darkorbit.menu.SuperActionButton;
   import net.bigpoint.darkorbit.pattern.EffectPattern;
   import net.bigpoint.darkorbit.pattern.RepairInfo;
   import net.bigpoint.darkorbit.settings.Settings;
   import net.bigpoint.darkorbit.ship.MapObject;
   import net.bigpoint.darkorbit.ship.Ship;
   import net.bigpoint.darkorbit.ship.effects.EffectIDList;
   import net.bigpoint.darkorbit.ship.effects.EffectsManager;
   import net.bigpoint.darkorbit.ship.effects.LevelUpEffect;
   
   public class SetAttributeAssembly extends BaseAssembly
   {
      
      private static var instance:SetAttributeAssembly;
      
      private var map:Map;
      
      private var hero:Ship;
      
      private var cpuDict:Dictionary;
      
      private var delegateDict:Dictionary;
      
      private var settingsAssembly:SettingsAssembly;
      
      private var cooldownClassToButtonIDs:Dictionary;
      
      private var main:Main;
      
      private var effectsManager:EffectsManager = EffectsManager.getInstance();
      
      public function SetAttributeAssembly(param1:Function)
      {
         super();
         if(param1 !== hidden)
         {
            throw new Error("SetAttributeAssembly is a Singleton and can only be accessed through SetAttributeAssembly.getInstance()");
         }
         this.main = _main;
         this.initDelegateDict();
         this.initDicts();
         this.settingsAssembly = SettingsAssembly.getInstance();
      }
      
      public static function getInstance() : SetAttributeAssembly
      {
         if(instance == null)
         {
            instance = new SetAttributeAssembly(hidden);
         }
         return instance;
      }
      
      private static function hidden() : void
      {
      }
      
      private function initDicts() : void
      {
         this.cpuDict = new Dictionary();
         this.cpuDict[3] = CPUItem.TYPE_DRONE_REPAIR;
         this.cpuDict[4] = CPUItem.TYPE_RADAR;
         this.cpuDict[5] = CPUItem.TYPE_JUMP;
         this.cpuDict[6] = CPUItem.TYPE_AMMOBUY;
         this.cpuDict[7] = CPUItem.TYPE_ROBOT;
         this.cpuDict[8] = CPUItem.TYPE_HM7;
         this.cpuDict[10] = CPUItem.TYPE_SMARTBOMB;
         this.cpuDict[11] = CPUItem.TYPE_INSTASHIELD;
         this.cpuDict[12] = CPUItem.TYPE_MINETURBO;
         this.cpuDict[13] = CPUItem.TYPE_AIM;
         this.cpuDict[14] = CPUItem.TYPE_AROL;
         this.cpuDict[15] = CPUItem.TYPE_CLOAK;
         this.cpuDict[16] = CPUItem.TYPE_RLLB;
         this.cpuDict[17] = CPUItem.TYPE_ROCKETBUY;
         this.cpuDict[18] = CPUItem.TYPE_ADVANCED_JUMP;
         this.cooldownClassToButtonIDs = new Dictionary();
         this.cooldownClassToButtonIDs[ServerCommands.MINE_COOLDOWN] = new CooldownCommandMap(this.addCoolDown,[SuperActionButton.SELECTION_MINE,SuperActionButton.SELECTION_MINE_EMP,SuperActionButton.SELECTION_MINE_SAB,SuperActionButton.SELECTION_MINE_DDM]);
         this.cooldownClassToButtonIDs[ServerCommands.SMARTBOMB_COOLDOWN] = new CooldownCommandMap(this.addCoolDown,[SuperActionButton.SELECTION_SMARTBOMB]);
         this.cooldownClassToButtonIDs[ServerCommands.INSTASHIELD_COOLDOWN] = new CooldownCommandMap(this.addCoolDown,[SuperActionButton.SELECTION_INSTASHIELD]);
         this.cooldownClassToButtonIDs[ServerCommands.EMP_COOLDOWN] = new CooldownCommandMap(this.addCoolDown,[SuperActionButton.SELECTION_EMP]);
         this.cooldownClassToButtonIDs[ServerCommands.ROCKET_COOLDOWN] = new CooldownCommandMap(this.addCoolDown,[SuperActionButton.SELECTION_ROCKET_R_310,SuperActionButton.SELECTION_ROCKET_PLT_2026,SuperActionButton.SELECTION_ROCKET_PLT_2021,SuperActionButton.SELECTION_ROCKET_PLT_3030]);
         this.cooldownClassToButtonIDs[ServerCommands.RSB_COOLDOWN] = new CooldownCommandMap(this.addCoolDown,[SuperActionButton.SELECTION_LASER_6]);
         this.cooldownClassToButtonIDs[ServerCommands.PLASMA_DISCONNECT_COOLDOWN] = new CooldownCommandMap(this.addCoolDown,[SuperActionButton.SELECTION_ROCKET_PLD_8]);
         this.cooldownClassToButtonIDs[ServerCommands.WIZ_ROCKET] = new CooldownCommandMap(this.addCoolDown,[SuperActionButton.SELECTION_ROCKET_WIZ]);
         this.cooldownClassToButtonIDs[ServerCommands.DCR_ROCKET] = new CooldownCommandMap(this.addCoolDown,[SuperActionButton.SELECTION_ROCKET_DCR_250]);
         this.cooldownClassToButtonIDs[ServerCommands.ROCKETLAUNCHER] = new CooldownCommandMap(this.addCoolDown,[SuperActionButton.SELECTION_LOAD_ROCKET_LAUNCHER]);
         this.cooldownClassToButtonIDs[ServerCommands.TECH_SHIELD_BACK_UP] = new CooldownCommandMap(this.addTechCooldown,[ServerCommands.TECH_SHIELD_BACK_UP]);
         this.cooldownClassToButtonIDs[ServerCommands.TECH_ENERGY_LEECH] = new CooldownCommandMap(this.addTechCooldown,[ServerCommands.TECH_ENERGY_LEECH]);
         this.cooldownClassToButtonIDs[ServerCommands.TECH_ELECTRIC_CHAIN_IMPULSE] = new CooldownCommandMap(this.addTechCooldown,[ServerCommands.TECH_ELECTRIC_CHAIN_IMPULSE]);
         this.cooldownClassToButtonIDs[ServerCommands.TECH_ROCKET_PROBABILITY_MAXIMIZER] = new CooldownCommandMap(this.addTechCooldown,[ServerCommands.TECH_ROCKET_PROBABILITY_MAXIMIZER]);
         this.cooldownClassToButtonIDs[ServerCommands.TECH_BATTLE_REP_BOT] = new CooldownCommandMap(this.addTechCooldown,[ServerCommands.TECH_BATTLE_REP_BOT]);
         this.cooldownClassToButtonIDs[ServerCommands.SKILL_SOLACE] = new CooldownCommandMap(this.addSkillDesignCooldown,[ServerCommands.SKILL_SOLACE]);
         this.cooldownClassToButtonIDs[ServerCommands.SKILL_DIMINISHER] = new CooldownCommandMap(this.addSkillDesignCooldown,[ServerCommands.SKILL_DIMINISHER]);
         this.cooldownClassToButtonIDs[ServerCommands.SKILL_SPECTRUM] = new CooldownCommandMap(this.addSkillDesignCooldown,[ServerCommands.SKILL_SPECTRUM]);
         this.cooldownClassToButtonIDs[ServerCommands.SKILL_SENTINEL] = new CooldownCommandMap(this.addSkillDesignCooldown,[ServerCommands.SKILL_SENTINEL]);
         this.cooldownClassToButtonIDs[ServerCommands.SKILL_VENOM] = new CooldownCommandMap(this.addSkillDesignCooldown,[ServerCommands.SKILL_VENOM]);
         this.cooldownClassToButtonIDs[ServerCommands.SPEED_BUFF_COOL_DOWN] = new CooldownCommandMap(this.addSkillDesignCooldown,[ServerCommands.SPEED_BUFF_COOL_DOWN]);
         this.cooldownClassToButtonIDs[ServerCommands.ADVANCED_JUMP_CPU_COOLDOWN] = new CooldownCommandMap(this.addCoolDown,[SuperActionButton.SELECT_CPU_JUMP_TARGET]);
      }
      
      public function assembleCommand(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         if(this.delegateDict[_loc2_] != null)
         {
            this.delegateDict[_loc2_](param1);
         }
      }
      
      private function initDelegateDict() : void
      {
         this.delegateDict = new Dictionary();
         this.delegateDict[ServerCommands.SERVER_MSG] = this.assembleLogMessage;
         this.delegateDict[ServerCommands.LOCALIZED_SERVER_MSG] = this.assembleLocalizedLogMessage;
         this.delegateDict[ServerCommands.EXTRAS_INFO] = this.assembleCpuHeroInfo;
         this.delegateDict[ServerCommands.SET_FLASH_SETTINGS] = this.assembleFlashSettings;
         this.delegateDict[ServerCommands.SHIELD_INFO] = this.assembleShieldInfo;
         this.delegateDict[ServerCommands.HITPOINTS_INFO] = this.assembleHitPointsInfo;
         this.delegateDict[ServerCommands.HEAL] = this.assembleHealInfo;
         this.delegateDict[ServerCommands.ROCKET_COOLDOWN_COMPLETED] = this.assembleRocketCooldownCompleted;
         this.delegateDict[ServerCommands.EXPERIENCE_POINTS_UPDATE] = this.assembleExperiencePointsUpdate;
         this.delegateDict[ServerCommands.CREDITS_UPDATE] = this.assembleCreditsUpdate;
         this.delegateDict[ServerCommands.LEVEL_UPDATE] = this.assembleLevelUpdate;
         this.delegateDict[ServerCommands.VELOCITY_UPDATE] = this.assembleVelocityUpdate;
         this.delegateDict[ServerCommands.CARGO_CHANGE] = this.assembleCargoChange;
         this.delegateDict[ServerCommands.AMMUNITION_CAPACITY_CHANGE] = this.assembleAmmunitionChange;
         this.delegateDict[ServerCommands.UPDATE_CONFIGURATION_COUNT] = this.assembleConfigurationCountUpdate;
         this.delegateDict[ServerCommands.INIT_UPDATE_BOOSTERS] = this.assembleInitBoostersUpdate;
         this.delegateDict[ServerCommands.RANKED_HUNT_EVENT_UPDATE] = this.assembleInitRankedHuntEventStatsUpdate;
         this.delegateDict[ServerCommands.SHIELD_SKILL_UPDATE] = this.assembleShieldSkillUpdate;
         this.delegateDict[ServerCommands.REPAIR_SKILL_UPDATE] = this.assembleRepairSkillUpdate;
         this.delegateDict[ServerCommands.FIREWORKS] = this.assembleFireworksInfo;
         this.delegateDict[ServerCommands.SET_COOLDOWN] = this.assembleCooldown;
         this.delegateDict[ServerCommands.COOLDOWN_COMPLETED] = this.assembleCooldownCompleted;
         this.delegateDict[ServerCommands.CPU_INFO] = this.assembleCPUInfo;
         this.delegateDict[ServerCommands.SET_REPAIR_DATA] = this.assembleRepairData;
         this.delegateDict[ServerCommands.SET_SPECIAL_OFFERS_NEEDED] = this.assembleSpecialOffersData;
         this.delegateDict[ServerCommands.SET_GS_IO_LOGGING] = this.assembleIOLogging;
         this.delegateDict[ServerCommands.SET_DISPLAY_CROSSHAIR] = this.assembleDisplayCrosshair;
         this.delegateDict[ServerCommands.SERVER_VERSION] = this.assembleServerVersion;
         this.delegateDict[ServerCommands.ADVANCED_JUMP_CPU] = this.assembleAdvancedJumpCpuCommands;
         this.delegateDict[ServerCommands.JUMP_VOUCHERS_UPDATE] = this.assembleJumpVouchersUpdate;
         this.delegateDict[ServerCommands.BOOTY_KEYS_UPDATE] = this.assembleBootyKeysUpdate;
      }
      
      private function assembleAdvancedJumpCpuCommands(param1:Array) : void
      {
         var _loc2_:String = String(param1[3]);
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         switch(_loc2_)
         {
            case ServerCommands.ADVANCED_JUMP_CPU_INIT:
               this.assembleAdvancedJumpCpuInitialization(param1);
               break;
            case ServerCommands.ADVANCED_JUMP_CPU_SELECTED_MAP_FEEDBACK:
               this.assembleAdvancedJumpCpuMapFeedback(param1);
               break;
            case ServerCommands.SET_STATUS:
               _loc3_ = int(param1[4]);
               _loc4_ = int(param1[5]);
               this.main.getGuiManager().startCastingCostTick(_loc3_,_loc4_);
         }
      }
      
      private function assembleAdvancedJumpCpuMapFeedback(param1:Array) : void
      {
         var _loc2_:int = 3;
         var _loc3_:int = int(param1[++_loc2_]);
         var _loc4_:int = int(param1[++_loc2_]);
         var _loc5_:int = int(param1[++_loc2_]);
         this.main.getGuiManager().setAvailableJump(_loc3_,_loc4_,_loc5_);
      }
      
      private function assembleAdvancedJumpCpuInitialization(param1:Array) : void
      {
         var _loc2_:String = "";
         var _loc3_:String = "-1";
         var _loc4_:String = "-2";
         var _loc5_:Array = [];
         var _loc6_:Array = [];
         var _loc7_:Array = [];
         var _loc8_:Array = param1.slice(4,param1.length);
         if(param1.length < 5)
         {
            this.main.getGuiManager().setAllSpacemapMapsBlocked();
            return;
         }
         var _loc9_:int = 0;
         while(_loc9_ < _loc8_.length)
         {
            _loc2_ = String(_loc8_[_loc9_]);
            if(_loc2_.split(";").length < 2)
            {
               if(_loc2_ == _loc3_)
               {
                  _loc5_ = this.getMapIDsList(_loc8_,_loc9_);
               }
               else if(_loc2_ == _loc4_)
               {
                  _loc6_ = this.getMapIDsList(_loc8_,_loc9_);
               }
               else
               {
                  _loc7_.push([_loc2_,this.getMapIDsList(_loc8_,_loc9_)]);
               }
            }
            _loc9_++;
         }
         this.main.getGuiManager().updateAdvancedSpacemapWindow(_loc7_,_loc5_,_loc6_);
      }
      
      private function getMapIDsList(param1:Array, param2:int) : Array
      {
         var _loc3_:Array = String(param1[param2 + 1]).split(";");
         _loc3_.pop();
         return _loc3_;
      }
      
      private function assembleIOLogging(param1:Array) : void
      {
         var _loc2_:Boolean = Boolean(int(param1[3]));
         this.main.getConnectionManager().isLoggingGameServerIO = _loc2_;
      }
      
      private function assembleDisplayCrosshair(param1:Array) : void
      {
         var _loc2_:Boolean = Boolean(int(param1[3]));
         if(Main.showCross && !_loc2_)
         {
            this.main.getGuiManager().hideCrosshair();
         }
         else if(!Main.showCross && _loc2_)
         {
            this.main.getGuiManager().showCrosshair();
         }
         Main.showCross = _loc2_;
      }
      
      private function assembleServerVersion(param1:Array) : void
      {
         Main.serverVersion = param1[3];
         this.main.getGuiManager().writeToLog("Server Version: " + Main.serverVersion);
      }
      
      private function assembleSpecialOffersData(param1:Array) : void
      {
         this.main.getGuiManager().prepareSpecialOffers();
      }
      
      private function assembleRepairData(param1:Array) : void
      {
         var _loc2_:String = param1[3];
         var _loc3_:String = StringUtil.trim(param1[4]);
         Hero.repairInfo = new RepairInfo(_loc2_,_loc3_);
      }
      
      private function assembleCPUInfo(param1:Array) : void
      {
         var _loc2_:CPUItem = null;
         var _loc3_:Boolean = false;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         switch(param1[3])
         {
            case ServerCommands.TRADE_DRONE_INFO:
               _loc4_ = int(param1[4]);
               _loc2_ = Hero.cpuItems[CPUItem.TYPE_HM7];
               if(_loc2_ != null)
               {
                  _loc2_.amount = _loc4_;
               }
               if(_loc4_ == 0)
               {
                  Hero.cpuItems[CPUItem.TYPE_HM7] = null;
               }
               break;
            case ServerCommands.JUMP_CPU:
               _loc5_ = int(param1[6]);
               _loc2_ = Hero.cpuItems[CPUItem.TYPE_JUMP];
               if(_loc2_ != null)
               {
                  _loc2_.amount = _loc5_;
               }
               if(_loc5_ == 0)
               {
                  Hero.cpuItems[CPUItem.TYPE_JUMP] = null;
               }
               break;
            case ServerCommands.DRONEREPAIR_CPU_INFO:
               _loc6_ = int(param1[4]);
               _loc2_ = Hero.cpuItems[CPUItem.TYPE_DRONE_REPAIR];
               if(_loc2_ != null)
               {
                  _loc2_.amount = _loc6_;
               }
               if(_loc6_ == 0)
               {
                  Hero.cpuItems[CPUItem.TYPE_DRONE_REPAIR] = null;
               }
               break;
            case ServerCommands.AIM_CPU_INFO:
               _loc7_ = int(param1[4]);
               _loc3_ = Boolean(int(param1[5]));
               _loc2_ = Hero.cpuItems[CPUItem.TYPE_AIM];
               if(_loc2_ != null)
               {
                  _loc2_.amount = _loc7_;
                  _loc2_.state = _loc3_;
               }
               break;
            case ServerCommands.CLOAK_CPU_INFO:
               _loc8_ = int(param1[4]);
               _loc2_ = Hero.cpuItems[CPUItem.TYPE_CLOAK];
               if(_loc2_ != null)
               {
                  _loc2_.amount = _loc8_;
               }
               if(_loc8_ == 0)
               {
                  Hero.cpuItems[CPUItem.TYPE_CLOAK] = null;
               }
               break;
            case ServerCommands.AUTO_ROCKET_CPU_INFO:
               _loc3_ = Boolean(int(param1[4]));
               _loc2_ = Hero.cpuItems[CPUItem.TYPE_AROL];
               if(_loc2_ != null)
               {
                  _loc2_.state = _loc3_;
               }
               break;
            case ServerCommands.ROCKETLAUNCHER_AUTO_CPU_INFO:
               _loc3_ = Boolean(int(param1[4]));
               _loc2_ = Hero.cpuItems[CPUItem.TYPE_RLLB];
               if(_loc2_ != null)
               {
                  _loc2_.state = _loc3_;
               }
         }
         this.main.getGuiManager().getMenuManager().updateAllCPUButtons();
         this.main.getGuiManager().getMenuManager().invalidateCPUButtons();
      }
      
      private function assembleCooldownCompleted(param1:Array) : void
      {
         switch(param1[3])
         {
            case ServerCommands.TECH_BATTLE_REP_BOT:
               this.killCooldownsForTechID(5);
               break;
            case ServerCommands.TECH_ENERGY_LEECH:
               this.killCooldownsForTechID(1);
               break;
            case ServerCommands.TECH_SHIELD_BACK_UP:
               this.killCooldownsForTechID(4);
               break;
            case ServerCommands.TECH_ELECTRIC_CHAIN_IMPULSE:
               this.killCooldownsForTechID(2);
               break;
            case ServerCommands.TECH_ROCKET_PROBABILITY_MAXIMIZER:
               this.killCooldownsForTechID(3);
         }
      }
      
      private function killCooldownsForTechID(param1:int) : void
      {
         var _loc5_:ActionButton = null;
         var _loc2_:GuiManager = this.main.getGuiManager();
         var _loc3_:MenuManager = _loc2_.getMenuManager();
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_.actionButtons.length)
         {
            _loc5_ = _loc3_.actionButtons[_loc4_];
            if(_loc5_.actionID == _loc3_.techIDToButtonID[param1])
            {
               _loc5_.cooldownCompleted();
            }
            _loc4_++;
         }
      }
      
      private function assembleCooldown(param1:Array) : void
      {
         var _loc2_:int = int(param1[4]);
         var _loc3_:CooldownCommandMap = this.cooldownClassToButtonIDs[param1[3]];
         if(_loc3_ != null)
         {
            _loc3_.callMappedFunction(_loc2_);
         }
      }
      
      private function addCoolDown(param1:int, param2:int) : void
      {
         this.main.getGuiManager().addCoolDown(param1,param2);
      }
      
      private function addTechCooldown(param1:String, param2:int) : void
      {
         var _loc3_:TechAssembly = null;
         if(_loc3_ == null)
         {
            _loc3_ = TechAssembly.getInstance();
         }
         _loc3_.assembleCooldownCommand(param1,param2);
      }
      
      private function addSkillDesignCooldown(param1:String, param2:int) : void
      {
         var _loc3_:SkillsAssembly = null;
         if(_loc3_ == null)
         {
            _loc3_ = SkillsAssembly.getInstance();
         }
         _loc3_.assembleCooldownCommand(param1,param2);
      }
      
      private function assembleFireworksInfo(param1:Array) : void
      {
         switch(param1[3])
         {
            case ServerCommands.FIREWORKS_LEFT:
               Hero.fireworksAmounts[FireworksManager.FIREWORK_SMALL] = int(param1[4]);
               Hero.fireworksAmounts[FireworksManager.FIREWORK_MEDIUM] = int(param1[5]);
               Hero.fireworksAmounts[FireworksManager.FIREWORK_LARGE] = int(param1[6]);
               this.main.getGuiManager().getMenuManager().updateFireworkButtonAmounts();
               break;
            case ServerCommands.FIREWORK_INSTALLATIONS_LEFT:
               Settings.fireworksLoaded = int(param1[4]);
               this.main.getGuiManager().getMenuManager().updateFireworkButtonAmounts();
         }
      }
      
      private function assembleRepairSkillUpdate(param1:Array) : void
      {
         Hero.repairSkillId = int(param1[3]);
      }
      
      private function assembleShieldSkillUpdate(param1:Array) : void
      {
         Hero.showSkinShieldRandomly = Boolean(int(param1[3]));
         Hero.minSkinShieldTwinkle = int(param1[4]);
         Hero.maxSkinShieldTwinkle = int(param1[5]);
         if(this.main.screenManager.map != null)
         {
            this.map = this.main.screenManager.map;
            this.hero = this.map.getShipManager().getHero();
            if(this.hero != null && this.hero.getShield() > 0)
            {
               this.hero.updateShieldTwinkle();
            }
         }
      }
      
      private function assembleInitBoostersUpdate(param1:Array) : void
      {
         var _loc2_:String = param1[3];
         var _loc3_:Array = _loc2_.split("/");
         this.main.getGuiManager().initUpdateBoosters(_loc3_);
      }
      
      private function assembleInitRankedHuntEventStatsUpdate(param1:Array) : void
      {
         var _loc6_:String = null;
         var _loc7_:String = null;
         var _loc8_:int = 0;
         var _loc9_:Array = null;
         var _loc10_:String = null;
         var _loc11_:int = 0;
         var _loc12_:String = null;
         var _loc2_:int = int(param1[3]);
         var _loc3_:String = param1[4];
         var _loc4_:int = int(param1[5]);
         if(Hero.rankedHuntingEventData == null)
         {
            Hero.rankedHuntingEventData = new RankedHuntingEventData();
         }
         if(Hero.rankedHuntingEventData.eventVOs == null)
         {
            Hero.rankedHuntingEventData.eventVOs = [];
         }
         var _loc5_:RankedHuntStatsVO = Hero.rankedHuntingEventData.eventVOs[_loc2_] as RankedHuntStatsVO;
         if(_loc5_ == null)
         {
            this.main.getConnectionManager().sendCommand(ClientCommands.REQUEST,[ServerCommands.RANKED_HUNT_EVENT_UPDATE,_loc2_]);
            _loc5_ = new RankedHuntStatsVO();
            Hero.rankedHuntingEventData.eventVOs[_loc2_] = _loc5_;
         }
         switch(_loc3_)
         {
            case ServerCommands.RANKED_HUNT_EVENT_STATS_CLASS_PLAYER:
               if(_loc5_.bountyPoints != 0)
               {
                  _loc5_.bountyDelta = _loc4_ - _loc5_.bountyPoints;
               }
               _loc5_.bountyPoints = _loc4_;
               if(_loc5_.bountyDelta > 0)
               {
                  if(_loc5_.bountyDelta == 1)
                  {
                     this.main.getGuiManager().writeToLog(BPLocale.getText("log_msg_npc_hunt_point_s"));
                  }
                  else
                  {
                     this.main.getGuiManager().writeToLog(BPLocale.getText("log_msg_npc_hunt_point_p").replace(/%AMOUNT%/,BPLocale.roundInteger(_loc5_.bountyDelta)));
                  }
               }
               _loc5_.clanBountyPointsInSync = false;
               break;
            case ServerCommands.RANKED_HUNT_EVENT_STATS_CLASS_CLAN:
               _loc5_.bountyDelta = 0;
               _loc5_.clanBountyPointsInSync = false;
               _loc5_.clanBountyPoints = _loc4_;
               _loc5_.clanBountyPointsInSync = true;
               break;
            case ServerCommands.RANKED_HUNT_EVENT_INFO:
               _loc6_ = param1[5];
               _loc7_ = param1[6];
               switch(_loc6_)
               {
                  case ServerCommands.RANKED_HUNT_EVENT_TARGET_MATCH_CLASS_NPC:
                     _loc5_ = Hero.rankedHuntingEventData.eventVOs[_loc2_] as RankedHuntStatsVO;
                     if(_loc5_ != null)
                     {
                        _loc5_.targetList = [_loc7_];
                        _loc8_ = int(_loc5_.targetList.length);
                        _loc9_ = InGameCatalog.instance.npc_names;
                        _loc10_ = "";
                        _loc11_ = 0;
                        while(_loc11_ < _loc8_)
                        {
                           _loc12_ = _loc9_[_loc5_.targetList[_loc11_]];
                           if(_loc12_ != null)
                           {
                              _loc10_ += ", " + _loc12_;
                           }
                           _loc11_++;
                        }
                        _loc10_ = _loc10_.substring(2);
                        _loc5_.targetVerbose = BPLocale.getText("q2_condition_KILL_NPCS").replace(/%npcs%/,_loc10_);
                     }
                     break;
                  case ServerCommands.RANKED_HUNT_EVENT_TARGET_MATCH_CLASS_PLAYER:
               }
         }
         Hero.rankedHuntingEventData.currentID = _loc2_;
         this.main.getGuiManager().initUpdateRankedHuntStats(_loc2_);
      }
      
      private function assembleConfigurationCountUpdate(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         Settings.selectedConfiguration = _loc2_;
         this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_SHIP,SimpleContainer.CONTAINER_CLASS_HERO_INFO_1,SimpleElement.TYPE_CONFIGURATION);
      }
      
      private function assembleAmmunitionChange(param1:Array) : void
      {
         Hero.maxLaserCapacity = int(param1[3]);
         this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_SHIP,SimpleContainer.CONTAINER_CLASS_HERO_INFO_1,SimpleElement.TYPE_LASER);
         Hero.maxRocketCapacity = int(param1[4]);
         this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_SHIP,SimpleContainer.CONTAINER_CLASS_HERO_INFO_1,SimpleElement.TYPE_ROCKETS);
      }
      
      private function assembleCargoChange(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            this.hero = this.map.getShipManager().getHero();
            if(this.hero != null)
            {
               this.hero.setMaxCargo(_loc2_);
            }
         }
         this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_SHIP,SimpleContainer.CONTAINER_CLASS_HERO_INFO_0,SimpleElement.TYPE_CARGO);
      }
      
      private function assembleVelocityUpdate(param1:Array) : void
      {
         var _loc3_:int = 0;
         var _loc2_:int = int(param1[3]);
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            this.hero = this.map.getShipManager().getHero();
            if(this.hero != null)
            {
               _loc3_ = this.hero.getSpeed();
               this.hero.setSpeed(_loc2_);
               if(_loc3_ != _loc2_)
               {
                  this.map.getEventManager().updateShipMovement();
               }
            }
         }
      }
      
      private function assembleLevelUpdate(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = int(param1[4]);
         this.main.getGuiManager().logLevelUpdate(_loc2_,_loc3_);
         var _loc4_:LevelUpEffect = new LevelUpEffect(EffectIDList.LEVEL_UP_EFFECT,new EffectPattern(EffectIDList.LEVEL_UP_EFFECT,"levelUp"));
         this.effectsManager.addEffect(_loc4_,this.map.getShipManager().getHero(),EffectsManager.TIMEOUT_EFFECT);
         if(ExternalInterface.available)
         {
            ExternalInterface.call("clientEvent","userLevelUp");
         }
      }
      
      private function assembleJumpVouchersUpdate(param1:Array) : void
      {
         Hero.jumpVouchersAmount = int(param1[3]);
         var _loc2_:GuiManager = this.main.getGuiManager();
         _loc2_.updateInfoField(SimpleWindow.WINDOW_CLASS_USER,SimpleContainer.CONTAINER_CLASS_HERO_INFO_2,SimpleElement.TYPE_JUMP_VOUCHERS);
         _loc2_.getMenuManager().updateAllCPUButtons();
         _loc2_.getMenuManager().invalidateCPUButtons();
         _loc2_.updateJumpPriceLabel();
         _loc2_.updateJumpVoucherLabel();
      }
      
      private function assembleBootyKeysUpdate(param1:Array) : void
      {
         Hero.bootyKeysAmount = int(param1[3]);
         var _loc2_:GuiManager = this.main.getGuiManager();
         _loc2_.updateInfoField(SimpleWindow.WINDOW_CLASS_USER,SimpleContainer.CONTAINER_CLASS_HERO_INFO_3,SimpleElement.TYPE_BOOTY_KEYS);
      }
      
      private function assembleCreditsUpdate(param1:Array) : void
      {
         Hero.creditsAmount = Number(param1[3]);
         this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_USER,SimpleContainer.CONTAINER_CLASS_HERO_INFO_3,SimpleElement.TYPE_CREDITS);
         Hero.uridiumAmount = parseFloat(param1[4]);
         this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_USER,SimpleContainer.CONTAINER_CLASS_HERO_INFO_3,SimpleElement.TYPE_URIDIUM);
      }
      
      private function assembleExperiencePointsUpdate(param1:Array) : void
      {
         Hero.experiencePoints = int(param1[3]);
         this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_USER,SimpleContainer.CONTAINER_CLASS_HERO_INFO_2,SimpleElement.TYPE_EXPERIENCE);
      }
      
      private function assembleRocketCooldownCompleted(param1:Array) : void
      {
      }
      
      private function assembleHealInfo(param1:Array) : void
      {
         var _loc8_:int = 0;
         var _loc9_:MapObject = null;
         var _loc2_:int = 2;
         var _loc3_:int = int(param1[++_loc2_]);
         var _loc4_:int = int(param1[++_loc2_]);
         var _loc5_:String = param1[++_loc2_];
         var _loc6_:int = int(param1[++_loc2_]);
         var _loc7_:int = int(param1[++_loc2_]);
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            _loc9_ = this.map.getShipManager().getShip(_loc4_);
            if(_loc9_ != null)
            {
               if(_loc5_ == ServerCommands.STATS_TYPE_SHIELD)
               {
                  _loc9_.setShield(_loc6_);
                  _loc8_ = 3;
               }
               else if(_loc5_ == ServerCommands.STATS_TYPE_HITPOINTS)
               {
                  _loc9_.setHitpoints(_loc6_);
                  _loc8_ = 2;
               }
               _loc9_.updateHitpointShieldBar(true);
               if(Settings.displayHitpointBubbles)
               {
                  this.main.getGuiManager().showHitpointDelta(_loc9_,_loc7_,_loc8_,true);
               }
            }
         }
      }
      
      private function assembleHitPointsInfo(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = int(param1[4]);
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            this.hero = this.map.getShipManager().getHero();
            if(this.hero != null)
            {
               if(Settings.JS_EVENT_TRACKING_ENABLED)
               {
                  if(this.hero.getHitpoints() > _loc3_ / 10 && _loc2_ <= _loc3_ / 10)
                  {
                     if(ExternalInterface.available)
                     {
                        ExternalInterface.call("clientEvent","userLowHP");
                     }
                  }
               }
               this.hero.setHitpoints(_loc2_);
               this.hero.setMaxHitpoints(_loc3_);
               this.hero.updateHitpointShieldBar(true);
            }
         }
      }
      
      private function assembleShieldInfo(param1:Array) : void
      {
         var _loc4_:Ship = null;
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = int(param1[4]);
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            _loc4_ = this.map.getShipManager().getHero();
            if(_loc4_ != null)
            {
               _loc4_.setShieldChunk(_loc2_,_loc3_,true);
            }
         }
      }
      
      private function assembleFlashSettings(param1:Array) : void
      {
         this.settingsAssembly.assembleSettingsChunk(param1.splice(3));
      }
      
      private function assembleLocalizedLogMessage(param1:Array) : void
      {
         var _loc2_:String = null;
         var _loc3_:String = null;
         var _loc4_:String = null;
         var _loc5_:int = 0;
         _loc2_ = param1[3];
         param1.splice(0,4);
         switch(param1.length)
         {
            case 0:
               this.main.getGuiManager().writeToLog(BPLocale.getText(_loc2_));
               break;
            case 1:
               _loc3_ = BPLocale.getText(param1[0]);
               if(_loc3_.length == 0)
               {
                  _loc3_ = param1[0];
               }
               this.main.getGuiManager().writeToLog(BPLocale.getText(_loc2_).replace("%!",_loc3_));
               break;
            default:
               _loc4_ = BPLocale.getText(_loc2_);
               _loc5_ = 0;
               while(_loc5_ < param1.length)
               {
                  _loc4_ = _loc4_.replace(param1[_loc5_],param1[_loc5_ + 1]);
                  _loc5_++;
                  _loc5_++;
               }
               this.main.getGuiManager().writeToLog(_loc4_);
         }
         if(_loc2_ == "jump_cpu_failed_attack" || _loc2_ == "jump_cpu_failed_attack2" || _loc2_ == "jump_cpu_failed_ontarget" || _loc2_ == "jump_cpu_failed_map" || _loc2_ == "jump_cpu_malfunction" || _loc2_ == "jump_cpu_failed_time" || _loc2_ == "jump_cpu_failed_attack" || _loc2_ == "jumpgate_failed_pvp_map" || _loc2_ == "jumpgate_failed_no_gate")
         {
            AudioManager.playSoundEffect(29);
         }
      }
      
      private function assembleLogMessage(param1:Array) : void
      {
         var _loc2_:String = param1[3];
         this.main.getGuiManager().writeToLog(_loc2_);
      }
      
      private function assembleCpuHeroInfo(param1:Array) : void
      {
         var _loc2_:String = null;
         var _loc3_:MenuButton = null;
         for(_loc2_ in this.cpuDict)
         {
            this.processCpuHeroInfo(param1,int(_loc2_));
         }
         _loc3_ = this.main.getGuiManager().getMenuManager().getMainMenu().getMenuButton(3);
         if(_loc3_.isSelected())
         {
            _loc3_.updateButtonsInPool();
         }
         _loc3_ = this.main.getGuiManager().getMenuManager().getMainMenu().getMenuButton(2);
         if(_loc3_.isSelected())
         {
            _loc3_.updateButtonsInPool();
         }
         var _loc4_:MenuManager = this.main.getGuiManager().getMenuManager();
         _loc4_.invalidateCPUButtons();
         _loc4_.updateExplosiveButtonAmmounts();
         _loc4_.getQuickMenu().updateCPUButtonsInSlotMenu();
         _loc4_.getQuickMenu().updateQuickmenu();
      }
      
      private function processCpuHeroInfo(param1:Array, param2:int) : void
      {
         var _loc5_:CPUItem = null;
         var _loc6_:SimpleWindow = null;
         var _loc3_:int = int(param1[param2]);
         var _loc4_:int = int(this.cpuDict[param2]);
         if(_loc3_ == 0 && _loc4_ != CPUItem.TYPE_ADVANCED_JUMP)
         {
            Hero.cpuItems[_loc4_] = null;
         }
         else
         {
            _loc5_ = new CPUItem(_loc4_);
            _loc5_.level = _loc3_;
            Hero.cpuItems[_loc4_] = _loc5_;
            if(_loc4_ == CPUItem.TYPE_ADVANCED_JUMP)
            {
               _loc6_ = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_SPACEMAP);
               if(_loc6_.isMaximized())
               {
                  _loc6_.minimize();
               }
            }
         }
      }
   }
}

