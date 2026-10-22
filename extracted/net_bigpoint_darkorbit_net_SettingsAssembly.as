package net.bigpoint.darkorbit.net
{
   import flash.geom.Point;
   import flash.utils.Dictionary;
   import net.bigpoint.darkorbit.Hero;
   import net.bigpoint.darkorbit.Main;
   import net.bigpoint.darkorbit.audio.AudioManager;
   import net.bigpoint.darkorbit.collectable.Box;
   import net.bigpoint.darkorbit.collectable.CollectablePattern;
   import net.bigpoint.darkorbit.gui.BarStatus;
   import net.bigpoint.darkorbit.gui.CPUItem;
   import net.bigpoint.darkorbit.gui.GuiManager;
   import net.bigpoint.darkorbit.gui.WindowSetting;
   import net.bigpoint.darkorbit.gui.windows.SimpleWindow;
   import net.bigpoint.darkorbit.map.Map;
   import net.bigpoint.darkorbit.map.MinimapManager;
   import net.bigpoint.darkorbit.menu.QuickMenu;
   import net.bigpoint.darkorbit.pattern.PatternManager;
   import net.bigpoint.darkorbit.resolution.ResolutionPattern;
   import net.bigpoint.darkorbit.settings.Settings;
   
   public class SettingsAssembly extends BaseAssembly
   {
      
      private static var _instance:SettingsAssembly;
      
      private var delegateDict:Dictionary;
      
      private var main:Main;
      
      public function SettingsAssembly(param1:Function)
      {
         super();
         if(param1 !== hidden)
         {
            throw new Error("SettingsAssembly is a Singleton and can only be accessed through SettingsAssembly.getInstance()");
         }
         this.main = _main;
         this.initDelegateDict();
      }
      
      public static function getInstance() : SettingsAssembly
      {
         if(_instance == null)
         {
            _instance = new SettingsAssembly(hidden);
         }
         return _instance;
      }
      
      private static function hidden() : void
      {
      }
      
      public function assembleSetting(param1:Array) : void
      {
         var _loc2_:String = param1[0];
         var _loc3_:String = param1[1];
         if(this.delegateDict[_loc2_] != null)
         {
            this.delegateDict[_loc2_](_loc3_);
         }
         else if(_loc2_.length > 15 && _loc2_.substring(0,15) == "WINDOW_SETTINGS")
         {
            this.assembleSetWindowProperties(_loc2_,_loc3_);
         }
      }
      
      public function assembleSettingsChunk(param1:Array) : void
      {
         Settings.autoBoost = Boolean(int(param1[0]));
         Settings.displayPlayerNames = Boolean(int(param1[4]));
         Settings.displayResources = Boolean(int(param1[7]));
         Settings.displayBonusBoxes = Boolean(int(param1[8]));
         Settings.displayHitpointBubbles = Boolean(int(param1[14]));
         Settings.playSFX = Boolean(int(param1[11]));
         Settings.playMusic = Boolean(int(param1[12]));
         Settings.selectedLaser = int(param1[15]);
         Settings.selectedRocket = int(param1[16]);
         Settings.displayChat = Boolean(int(param1[18]));
         Settings.displayFreeCargoBoxes = Boolean(int(param1[21]));
         Settings.displayNotFreeCargoBoxes = Boolean(int(param1[22]));
         Settings.autochangeAmmo = Boolean(int(param1[23]));
         var _loc2_:Map = _main.screenManager.map;
         if(!Settings.playMusic)
         {
            AudioManager.stopMusic();
         }
         else if(_loc2_ != null)
         {
            _loc2_.loadMusic();
         }
         if(_loc2_ != null)
         {
            _loc2_.getShipManager().updateLabelVisibility();
            _loc2_.getCollectableManager().setCollectableVisibility(CollectablePattern.TYPE_ORE,-1,Settings.displayResources);
            _loc2_.getCollectableManager().setCollectableVisibility(CollectablePattern.TYPE_BOX,Box.TYPE_BONUS_BOX,Settings.displayBonusBoxes);
            _loc2_.getCollectableManager().setCollectableVisibility(CollectablePattern.TYPE_BOX,Box.TYPE_FREE_CARGO_BOX,Settings.displayFreeCargoBoxes);
            _loc2_.getCollectableManager().setCollectableVisibility(CollectablePattern.TYPE_BOX,Box.TYPE_NOT_FREE_CARGO_BOX,Settings.displayNotFreeCargoBoxes);
         }
         _main.getGuiManager().createTopMenu();
         _main.getGuiManager().createSettingsWindow();
      }
      
      private function initDelegateDict() : void
      {
         this.delegateDict = new Dictionary();
         this.delegateDict[ServerCommands.MAP_READY_HANDSHAKE] = this.assembleClientInitialized;
         this.delegateDict[ServerCommands.SET_SLOTMENU_POSITION + ServerCommands.SETTING_KEY_SEPERATOR + Settings.resolutionID] = this.assembleSetSlotMenuPosition;
         this.delegateDict[ServerCommands.SET_MAINMENU_POSITION + ServerCommands.SETTING_KEY_SEPERATOR + Settings.resolutionID] = this.assembleSetMainMenuPosition;
         this.delegateDict[ServerCommands.SET_SLOTMENU_ORDER + ServerCommands.SETTING_KEY_SEPERATOR + Settings.resolutionID] = this.assembleSetSlotMenuAlign;
         this.delegateDict[ServerCommands.SET_RESIZABLE_WINDOWS + ServerCommands.SETTING_KEY_SEPERATOR + Settings.resolutionID] = this.assembleSetWindowSizes;
         this.delegateDict[ServerCommands.SET_MINIMAP_SCALE + ServerCommands.SETTING_KEY_SEPERATOR + Settings.resolutionID] = this.assembleSetMinimapScale;
         this.delegateDict[ServerCommands.SET_BAR_STATUS] = this.assembleSetBarStatus;
         this.delegateDict[ServerCommands.SET_DISPLAY_HITPOINT_BUBBLES] = this.assembleSetDisplayHitpointBubbles;
         this.delegateDict[ServerCommands.SET_DISPLAY_PLAYER_NAMES] = this.assembleSetDisplayPlayerNames;
         this.delegateDict[ServerCommands.SET_PLAY_SFX] = this.assembleSetPlaySFX;
         this.delegateDict[ServerCommands.SET_PLAY_MUSIC] = this.assembleSetPlayMusic;
         this.delegateDict[ServerCommands.SET_DOUBLECLICK_ATTACK] = this.assembleSetDoubleClickAttack;
         this.delegateDict[ServerCommands.SET_QUICKSLOT_STOP_ATTACK] = this.assembleSetQuickSlotStopAttack;
         this.delegateDict[ServerCommands.SET_QUICKBAR_SLOT] = this.assembleSetQuickSlots;
         this.delegateDict[ServerCommands.SET_SHOW_DRONES] = this.assembleSetDisplayDrones;
         this.delegateDict[ServerCommands.SET_DISPLAY_NOTIFICATIONS] = this.assembleSetDisplayNotifications;
         this.delegateDict[ServerCommands.SET_DISPLAY_CHAT] = this.assembleSetDisplayChat;
         this.delegateDict[ServerCommands.SET_AUTO_REFINEMENT] = this.assembleSetAutoRefinement;
         this.delegateDict[ServerCommands.SET_AUTO_BOOST] = this.assembleSetAutoBoost;
         this.delegateDict[ServerCommands.SET_DISPLAY_ORE] = this.assembleSetDisplayOre;
         this.delegateDict[ServerCommands.SET_DISPLAY_BONUS_BOXES] = this.assembleSetDisplayBonusBoxes;
         this.delegateDict[ServerCommands.SET_DISPLAY_FREE_CARGO_BOXES] = this.assembleSetDisplayFreeCargoBoxes;
         this.delegateDict[ServerCommands.SET_DISPLAY_NOT_FREE_CARGO_BOXES] = this.assembleSetDisplayNotFreeCargoBoxes;
         this.delegateDict[ServerCommands.SET_AUTO_AMMO_CHANGE] = this.assembleSetAutoChangeAmmo;
         this.delegateDict[ServerCommands.SET_AUTO_START] = this.assembleSetAutostart;
         this.delegateDict[ServerCommands.SET_DISPLAY_WINDOW_BACKGROUND] = this.assembleSetDisplayWindowsBackground;
         this.delegateDict[ServerCommands.SET_ALWAYS_DRAGGABLE_WINDOWS] = this.assembleSetWindowsAlwaysDraggable;
         this.delegateDict[ServerCommands.SET_PRELOAD_USER_SHIPS] = this.assembleSetPreloadUserShips;
         this.delegateDict[ServerCommands.SET_RESOLUTION] = this.assembleSetResolution;
         this.delegateDict[ServerCommands.SET_QUALITY_PRESETTING] = this.assembleSetQualityPresetting;
         this.delegateDict[ServerCommands.SET_QUALITY_CUSTOMIZED] = this.assembleSetQualityCustomized;
         this.delegateDict[ServerCommands.SET_QUALITY_BACKGROUND] = this.assembleSetQualityBackground;
         this.delegateDict[ServerCommands.SET_QUALITY_POIZONE] = this.assembleSetQualityPoizone;
         this.delegateDict[ServerCommands.SET_QUALITY_SHIP] = this.assembleSetQualityShip;
         this.delegateDict[ServerCommands.SET_QUALITY_ENGINE] = this.assembleSetQualityEngine;
         this.delegateDict[ServerCommands.SET_QUALITY_COLLECTABLE] = this.assembleSetQualityCollectable;
         this.delegateDict[ServerCommands.SET_QUALITY_ATTACK] = this.assembleSetQualityAttack;
         this.delegateDict[ServerCommands.SET_QUALITY_EFFECT] = this.assembleSetQualityEffect;
         this.delegateDict[ServerCommands.SET_QUALITY_EXPLOSION] = this.assembleSetQualityExplosion;
         this.delegateDict[ServerCommands.SET_SELECTED_BATTERY] = this.assembleSetSelectedBattery;
         this.delegateDict[ServerCommands.SET_SELECTED_ROCKET] = this.assembleSetSelectedRocket;
      }
      
      private function assembleSetResolution(param1:String) : void
      {
         Settings.resolutionID = int(param1);
      }
      
      private function assembleSetPreloadUserShips(param1:String) : void
      {
         Settings.preloadUserShips = Boolean(int(param1));
      }
      
      private function assembleSetQualityPresetting(param1:String) : void
      {
         Settings.qualityPresetting = int(param1);
      }
      
      private function assembleSetQualityCustomized(param1:String) : void
      {
         Settings.qualityCustomized = Boolean(int(param1));
      }
      
      private function assembleSetQualityBackground(param1:String) : void
      {
         var _loc2_:int = Settings.qualityBackground;
         Settings.qualityBackground = int(param1);
         var _loc3_:Map = _main.screenManager.map;
         if(_loc3_ != null)
         {
            _loc3_.getBackgroundManager().updateBackgroundQuality(_loc2_);
            _loc3_.getPlanetManager().updatePlanetQuality(_loc2_);
            _loc3_.getLensflareManager().updateLensflareQuality(_loc2_);
         }
      }
      
      private function assembleSetQualityPoizone(param1:String) : void
      {
         Settings.qualityPoizone = int(param1);
         var _loc2_:Map = _main.screenManager.map;
         if(_loc2_ != null)
         {
            _loc2_.poiManager.updatePOIZoneVisualStyle();
         }
      }
      
      private function assembleSetQualityShip(param1:String) : void
      {
         Settings.qualityShip = int(param1);
         var _loc2_:Map = _main.screenManager.map;
         if(_loc2_ != null)
         {
            _loc2_.getShipManager().updateShipVisualStyle();
         }
      }
      
      private function assembleSetQualityEngine(param1:String) : void
      {
         Settings.qualityEngine = int(param1);
         var _loc2_:Map = _main.screenManager.map;
         if(_loc2_ != null)
         {
            _loc2_.getShipManager().updateEngineSmokeTimers();
         }
      }
      
      private function assembleSetQualityCollectable(param1:String) : void
      {
         Settings.qualityCollectable = int(param1);
      }
      
      private function assembleSetQualityAttack(param1:String) : void
      {
         Settings.qualityAttack = int(param1);
      }
      
      private function assembleSetQualityEffect(param1:String) : void
      {
         Settings.qualityEffect = int(param1);
      }
      
      private function assembleSetQualityExplosion(param1:String) : void
      {
         Settings.qualityExplosion = int(param1);
      }
      
      private function assembleClientInitialized(param1:Array) : void
      {
         this.main.getGuiManager().updateSpacemapWindow();
         if(Hero.cpuItems[CPUItem.TYPE_ADVANCED_JUMP] as CPUItem != null)
         {
            this.main.getGuiManager().requestSpacemapWindowServerUpdate();
         }
      }
      
      private function assembleSetQuickSlotStopAttack(param1:String) : void
      {
         Settings.quickSlotStopAttack = Boolean(int(param1));
      }
      
      private function assembleSetDisplayDrones(param1:String) : void
      {
         Settings.displayDrones = Boolean(int(param1));
         var _loc2_:Map = _main.screenManager.map;
         if(_loc2_ != null)
         {
            if(!Settings.displayDrones)
            {
               _loc2_.getDroneManager().removeAllDrones();
            }
         }
      }
      
      private function assembleSetAutostart(param1:String) : void
      {
         Settings.autoStartEnabled = Boolean(int(param1));
      }
      
      private function assembleSetDisplayWindowsBackground(param1:String) : void
      {
         var _loc3_:SimpleWindow = null;
         Settings.showWindowsBackground = Boolean(int(param1));
         var _loc2_:Array = _main.getGuiManager().getWindows();
         for each(_loc3_ in _loc2_)
         {
            if(Settings.showWindowsBackground)
            {
               _loc3_.removeListeners();
               _loc3_.fadeInWindow();
            }
            else
            {
               _loc3_.setListeners();
               _loc3_.fadeOutWindow();
            }
         }
      }
      
      private function assembleSetWindowsAlwaysDraggable(param1:String) : void
      {
         var _loc3_:SimpleWindow = null;
         Settings.dragWindowsAlways = Boolean(int(param1));
         var _loc2_:Array = _main.getGuiManager().getWindows();
         for each(_loc3_ in _loc2_)
         {
            _loc3_.updateDraggerButtonMode();
         }
      }
      
      private function assembleSetQuickSlots(param1:String) : void
      {
         if(param1.length > 0)
         {
            QuickMenu.predefinedActions = param1.split(ServerCommands.SETTING_PROPERTY_SEPERATOR);
         }
      }
      
      private function assembleSetDoubleClickAttack(param1:String) : void
      {
         Settings.doubleclickAttackEnabled = Boolean(int(param1));
      }
      
      private function assembleSetAutoRefinement(param1:String) : void
      {
         Settings.autoRefinement = Boolean(int(param1));
      }
      
      private function assembleSetMainMenuPosition(param1:String) : void
      {
         var _loc2_:Array = param1.split(ServerCommands.SETTING_PROPERTY_SEPERATOR);
         var _loc3_:ResolutionPattern = PatternManager.resolutionPatterns[Settings.resolutionID];
         _loc3_.setMainMenuPosition(new Point(int(_loc2_[0]),int(_loc2_[1])));
      }
      
      private function assembleSetSlotMenuPosition(param1:String) : void
      {
         var _loc2_:Array = param1.split(ServerCommands.SETTING_PROPERTY_SEPERATOR);
         var _loc3_:ResolutionPattern = PatternManager.resolutionPatterns[Settings.resolutionID];
         _loc3_.setSlotMenuPosition(new Point(int(_loc2_[0]),int(_loc2_[1])));
      }
      
      private function assembleSetSlotMenuAlign(param1:String) : void
      {
         QuickMenu.slotOrder = int(param1);
      }
      
      private function assembleSetBarStatus(param1:String) : void
      {
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc2_:Array = param1.split(ServerCommands.SETTING_PROPERTY_SEPERATOR);
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = int(_loc2_[_loc3_]);
            _loc5_ = int(_loc2_[_loc3_ + 1]);
            _main.getGuiManager().addBarStatus(new BarStatus(_loc4_,_loc5_));
            _loc3_ += 2;
         }
      }
      
      private function assembleSetMinimapScale(param1:String) : void
      {
         MinimapManager.scaleFactor = int(param1);
      }
      
      private function assembleSetWindowSizes(param1:String) : void
      {
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc2_:Array = param1.split(ServerCommands.SETTING_PROPERTY_SEPERATOR);
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = int(_loc2_[_loc3_]);
            _loc5_ = int(_loc2_[_loc3_ + 1]);
            _loc6_ = int(_loc2_[_loc3_ + 2]);
            GuiManager.resizableWindowSizes[_loc4_] = new Point(_loc5_,_loc6_);
            _loc3_ += 3;
         }
      }
      
      private function assembleSetAutoChangeAmmo(param1:String) : void
      {
         Settings.autochangeAmmo = Boolean(int(param1));
      }
      
      private function assembleSetDisplayNotFreeCargoBoxes(param1:String) : void
      {
         Settings.displayNotFreeCargoBoxes = Boolean(int(param1));
         var _loc2_:Map = _main.screenManager.map;
         if(_loc2_ != null)
         {
            _loc2_.getCollectableManager().setCollectableVisibility(CollectablePattern.TYPE_BOX,Box.TYPE_NOT_FREE_CARGO_BOX,Settings.displayNotFreeCargoBoxes);
         }
      }
      
      private function assembleSetDisplayFreeCargoBoxes(param1:String) : void
      {
         Settings.displayFreeCargoBoxes = Boolean(int(param1));
         var _loc2_:Map = _main.screenManager.map;
         if(_loc2_ != null)
         {
            _loc2_.getCollectableManager().setCollectableVisibility(CollectablePattern.TYPE_BOX,Box.TYPE_FREE_CARGO_BOX,Settings.displayFreeCargoBoxes);
         }
      }
      
      private function assembleSetSelectedRocket(param1:String) : void
      {
         Settings.selectedRocket = int(param1);
      }
      
      private function assembleSetDisplayNotifications(param1:String) : void
      {
         Settings.displayNotifications = Boolean(int(param1));
         if(Settings.displayNotifications)
         {
            _main.getProfiler().start();
         }
      }
      
      private function assembleSetDisplayChat(param1:String) : void
      {
         Settings.displayChat = Boolean(int(param1));
      }
      
      private function assembleSetSelectedBattery(param1:String) : void
      {
         Settings.selectedLaser = int(param1);
      }
      
      private function assembleSetPlayMusic(param1:String) : void
      {
         Settings.playMusic = Boolean(int(param1));
         var _loc2_:Map = _main.screenManager.map;
         if(!Settings.playMusic)
         {
            AudioManager.stopMusic();
         }
         else if(_loc2_ != null)
         {
            _loc2_.loadMusic();
         }
      }
      
      private function assembleSetPlaySFX(param1:String) : void
      {
         Settings.playSFX = Boolean(int(param1));
      }
      
      private function assembleSetAutoBoost(param1:String) : void
      {
         Settings.autoBoost = Boolean(int(param1));
      }
      
      private function assembleSetDisplayPlayerNames(param1:String) : void
      {
         Settings.displayPlayerNames = Boolean(int(param1));
         var _loc2_:Map = _main.screenManager.map;
         if(_loc2_ != null)
         {
            _loc2_.getShipManager().updateLabelVisibility();
         }
      }
      
      private function assembleSetDisplayOre(param1:String) : void
      {
         Settings.displayResources = Boolean(int(param1));
         var _loc2_:Map = _main.screenManager.map;
         if(_loc2_ != null)
         {
            _loc2_.getCollectableManager().setCollectableVisibility(CollectablePattern.TYPE_ORE,-1,Settings.displayResources);
         }
      }
      
      private function assembleSetDisplayBonusBoxes(param1:String) : void
      {
         Settings.displayBonusBoxes = Boolean(int(param1));
         var _loc2_:Map = _main.screenManager.map;
         if(_loc2_ != null)
         {
            _loc2_.getCollectableManager().setCollectableVisibility(CollectablePattern.TYPE_BOX,Box.TYPE_BONUS_BOX,Settings.displayBonusBoxes);
         }
      }
      
      private function assembleSetWindowProperties(param1:String, param2:String) : void
      {
         var _loc5_:Array = null;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:Boolean = false;
         var _loc11_:WindowSetting = null;
         var _loc3_:Array = param1.split(ServerCommands.SETTING_KEY_SEPERATOR);
         var _loc4_:int = int(_loc3_[1]);
         if(Settings.resolutionID == _loc4_)
         {
            _loc5_ = param2.split(ServerCommands.SETTING_PROPERTY_SEPERATOR);
            if(_loc5_.length > 3)
            {
               _loc6_ = 0;
               while(_loc6_ < _loc5_.length)
               {
                  _loc7_ = int(_loc5_[_loc6_]);
                  _loc8_ = int(_loc5_[_loc6_ + 1]);
                  _loc9_ = int(_loc5_[_loc6_ + 2]);
                  _loc10_ = Boolean(int(_loc5_[_loc6_ + 3]));
                  _loc11_ = new WindowSetting(_loc7_,_loc8_,_loc9_,_loc10_);
                  _main.getGuiManager().addWindowSetting(_loc11_);
                  _loc6_ += 4;
               }
            }
         }
      }
      
      private function assembleSetDisplayHitpointBubbles(param1:String) : void
      {
         Settings.displayHitpointBubbles = Boolean(int(param1));
      }
   }
}

