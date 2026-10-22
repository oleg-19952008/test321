package net.bigpoint.darkorbit.net
{
   import com.bigpoint.filecollection.finish.SWFFinisher;
   import com.bigpoint.utils.BPLocale;
   import com.bigpoint.utils.ui.tooltip.ToolTipHook;
   import com.bigpoint.utils.ui.tooltip.TooltipControl;
   import flash.display.Bitmap;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.external.ExternalInterface;
   import flash.text.TextField;
   import flash.utils.Dictionary;
   import net.bigpoint.darkorbit.Hero;
   import net.bigpoint.darkorbit.InGameCatalog;
   import net.bigpoint.darkorbit.Main;
   import net.bigpoint.darkorbit.ResourceManager;
   import net.bigpoint.darkorbit.audio.AudioManager;
   import net.bigpoint.darkorbit.gui.BannerAd;
   import net.bigpoint.darkorbit.gui.BitmapFont;
   import net.bigpoint.darkorbit.gui.BuffCoolDown;
   import net.bigpoint.darkorbit.gui.container.SimpleContainer;
   import net.bigpoint.darkorbit.gui.elements.SimpleElement;
   import net.bigpoint.darkorbit.gui.windows.SimpleWindow;
   import net.bigpoint.darkorbit.gui.windows.components.BarComponent;
   import net.bigpoint.darkorbit.gui.windows.components.buff.BuffItem;
   import net.bigpoint.darkorbit.gui.windows.components.gear.GearComboBox;
   import net.bigpoint.darkorbit.gui.windows.components.gear.GearItem;
   import net.bigpoint.darkorbit.gui.windows.components.gear.GearMenuContainer;
   import net.bigpoint.darkorbit.gui.windows.components.gear.GearScroller;
   import net.bigpoint.darkorbit.lazyload.BannerAdLazyLoader;
   import net.bigpoint.darkorbit.map.Map;
   import net.bigpoint.darkorbit.pattern.BannerAdPattern;
   import net.bigpoint.darkorbit.pattern.BuffPattern;
   import net.bigpoint.darkorbit.pattern.EffectPattern;
   import net.bigpoint.darkorbit.pattern.GearPattern;
   import net.bigpoint.darkorbit.pattern.PatternManager;
   import net.bigpoint.darkorbit.settings.Settings;
   import net.bigpoint.darkorbit.ship.MapObject;
   import net.bigpoint.darkorbit.ship.Ship;
   import net.bigpoint.darkorbit.ship.ShipManager;
   import net.bigpoint.darkorbit.ship.effects.EffectBase;
   import net.bigpoint.darkorbit.ship.effects.EffectFactory;
   import net.bigpoint.darkorbit.ship.effects.EffectIDList;
   import net.bigpoint.darkorbit.ship.effects.EffectsManager;
   import net.bigpoint.darkorbit.ship.effects.LevelUpEffect;
   import net.bigpoint.darkorbit.ship.effects.PetEffect;
   import net.bigpoint.darkorbit.ship.pet.Gear;
   import net.bigpoint.darkorbit.ship.pet.GearFactory;
   import net.bigpoint.darkorbit.ship.pet.Pet;
   
   public class PetAssembly extends BaseAssembly
   {
      
      private static var instance:PetAssembly;
      
      public static const DELIMITER:String = "-";
      
      private var main:Main;
      
      private var delegateDict:Dictionary;
      
      private var effectsManager:EffectsManager = EffectsManager.getInstance();
      
      public function PetAssembly(param1:Function)
      {
         super();
         if(param1 !== hidden)
         {
            throw new Error("PetAssembly is a Singleton and can only be accessed through PetAssembly.getInstance()");
         }
         this.main = _main;
         this.initDelegateDict();
      }
      
      public static function getInstance() : PetAssembly
      {
         if(instance == null)
         {
            instance = new PetAssembly(hidden);
         }
         return instance;
      }
      
      private static function hidden() : void
      {
      }
      
      public function assembleCommand(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         if(this.delegateDict[_loc2_] != null)
         {
            this.delegateDict[_loc2_](param1);
         }
         else
         {
            this.playSound(73);
         }
      }
      
      public function assembleSubCommand(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         var _loc3_:String = param1[3];
         if(this.delegateDict[_loc2_ + DELIMITER + _loc3_] != null)
         {
            this.delegateDict[_loc2_ + DELIMITER + _loc3_](param1);
         }
         else
         {
            this.playSound(73);
         }
      }
      
      private function initDelegateDict() : void
      {
         this.delegateDict = new Dictionary();
         this.delegateDict[ServerCommands.PET_INIT] = this.assemblePetInitilization;
         this.delegateDict[ServerCommands.PET_ACQUIRED] = this.assembleRemoveBanner;
         this.delegateDict[ServerCommands.ACTIVATE_HERO_PET] = this.assembleHeroPetActivation;
         this.delegateDict[ServerCommands.ACTIVATE_EXTERNAL_PET] = this.assembleExternalPetActivation;
         this.delegateDict[ServerCommands.DEACTIVATE_PET] = this.assemblePetDeactivation;
         this.delegateDict[ServerCommands.PET_DISTROYED] = this.assemblePetDestroyed;
         this.delegateDict[ServerCommands.PET_STATUS] = this.assemblePetStatus;
         this.delegateDict[ServerCommands.REPAIR_PET] = this.assemblePetRepair;
         this.delegateDict[ServerCommands.BLOCK_PET_WINDOW] = this.assembleLockWindow;
         this.delegateDict[ServerCommands.TRADE_WINDOW_ACTIVATION] = this.assembleActivateTradeWindow;
         this.delegateDict[ServerCommands.OUT_OF_FUEL] = this.assembleFuelMissingMode;
         this.delegateDict[ServerCommands.PET_IDLE] = this.assembleInvisibleMode;
         this.delegateDict[ServerCommands.PET_STOP_LASER_ATTACK] = this.assembleStopLaserAttack;
         this.delegateDict[ServerCommands.PET_RESET] = this.assembleResetStatus;
         this.delegateDict[ServerCommands.PET_REPAIR_BUTTON] = this.assembleSetRepairButtonState;
         this.delegateDict[ServerCommands.PET_ATTRIBUTE_INFO] = this.assembleSubCommand;
         this.delegateDict[ServerCommands.PET_GEAR_INFO] = this.assembleSubCommand;
         this.delegateDict[ServerCommands.PET_BUFF_INFO] = this.assembleSubCommand;
         this.delegateDict[ServerCommands.PET_ATTRIBUTE_INFO + DELIMITER + ServerCommands.EXPERIENCE_POINTS_UPDATE] = this.assemblePetXPInfo;
         this.delegateDict[ServerCommands.PET_ATTRIBUTE_INFO + DELIMITER + ServerCommands.HITPOINTS_INFO] = this.assemblePetHPInfo;
         this.delegateDict[ServerCommands.PET_ATTRIBUTE_INFO + DELIMITER + ServerCommands.SHIELD_INFO] = this.assemblePetShieldInfo;
         this.delegateDict[ServerCommands.PET_ATTRIBUTE_INFO + DELIMITER + ServerCommands.FUEL_INFO] = this.assemblePetFuelInfo;
         this.delegateDict[ServerCommands.PET_ATTRIBUTE_INFO + DELIMITER + ServerCommands.PET_LEVEL_UP] = this.assembleLevelUp;
         this.delegateDict[ServerCommands.EVASION_PROTOCOL_INFO] = this.assembleEvasionProtocolInfo;
         this.delegateDict[ServerCommands.PET_GEAR_INFO + DELIMITER + ServerCommands.LOACTOR_GEAR_INFO] = this.assembleLocatorGearInfo;
         this.delegateDict[ServerCommands.PET_GEAR_INFO + DELIMITER + ServerCommands.GEAR_TARGET_LIST] = this.assembleGearTargetsList;
         this.delegateDict[ServerCommands.PET_GEAR_INFO + DELIMITER + ServerCommands.SELECT] = this.assembleSelectGear;
         this.delegateDict[ServerCommands.PET_GEAR_INFO + DELIMITER + ServerCommands.ADD_TO_PET] = this.assembleAddGear;
         this.delegateDict[ServerCommands.PET_BUFF_INFO + DELIMITER + ServerCommands.ADD_TO_PET] = this.assembleAddBuff;
         this.delegateDict[ServerCommands.PET_GEAR_INFO + DELIMITER + ServerCommands.REMOVE_FROM_PET] = this.assembleRemoveGear;
         this.delegateDict[ServerCommands.PET_BUFF_INFO + DELIMITER + ServerCommands.REMOVE_FROM_PET] = this.assembleRemoveBuff;
      }
      
      private function assembleSetRepairButtonState(param1:Array) : void
      {
         var _loc6_:String = null;
         var _loc7_:InteractiveObject = null;
         var _loc2_:SimpleContainer = this.getPetWindowContainer();
         var _loc3_:SimpleElement = _loc2_.getElement(SimpleElement.PET_WINDOW_REPAIR_BTN);
         var _loc4_:MovieClip = _loc3_.getChildAt(0) as MovieClip;
         var _loc5_:Boolean = Boolean(int(param1[3]));
         TooltipControl.getInstance().removeToolTip(_loc3_);
         TooltipControl.getInstance().removeToolTip(_loc4_);
         if(_loc5_)
         {
            _loc4_.gotoAndStop(1);
            _loc6_ = "ttip_repair_pet";
            _loc7_ = _loc4_;
         }
         else
         {
            _loc4_.gotoAndStop(3);
            _loc6_ = "ttip_pet_repair_disabled_through_money";
            _loc7_ = _loc3_;
         }
         _loc4_.mouseChildren = _loc5_;
         _loc4_.mouseEnabled = _loc5_;
         TooltipControl.getInstance().addToolTip(_loc7_,BPLocale.getText(_loc6_));
      }
      
      private function launchPet() : void
      {
         this.main.getGuiManager().getMain().getConnectionManager().sendCommand(ServerCommands.PET,[ServerCommands.ACTIVATE_HERO_PET]);
      }
      
      private function stopPet() : void
      {
         this.main.getGuiManager().getMain().getConnectionManager().sendCommand(ServerCommands.PET,[ServerCommands.DEACTIVATE_PET]);
      }
      
      private function requestRepair() : void
      {
         this.main.getGuiManager().getMain().getConnectionManager().sendCommand(ServerCommands.PET,[ServerCommands.REPAIR_PET]);
      }
      
      private function requestGearActivation(param1:int, param2:String) : void
      {
         this.main.getGuiManager().getMain().getConnectionManager().sendCommand(ServerCommands.PET,[ServerCommands.PET_GEAR_INFO,ServerCommands.ACTIVATE_HERO_PET,param1,param2]);
      }
      
      private function assembleFuelMissingMode(param1:Array) : void
      {
         this.setFuelMissingMode();
      }
      
      private function requestFuel() : void
      {
         if(ExternalInterface.available)
         {
            ExternalInterface.call("showPetFuel");
         }
      }
      
      private function handleClickFuelButton(param1:MouseEvent) : void
      {
         this.requestFuel();
      }
      
      private function handleClickRepairButton(param1:MouseEvent) : void
      {
         this.requestRepair();
      }
      
      private function assemblePetInitilization(param1:Array) : void
      {
         var _loc2_:int = 2;
         var _loc3_:Boolean = Boolean(int(param1[++_loc2_]));
         var _loc4_:Boolean = Boolean(int(param1[++_loc2_]));
         var _loc5_:Boolean = Boolean(int(param1[++_loc2_]));
         this.main.getGuiManager().createPetWindow();
         this.initPetWindow(_loc3_,_loc4_,!_loc5_);
      }
      
      private function initPetWindow(param1:Boolean, param2:Boolean, param3:Boolean) : void
      {
         var _loc4_:SimpleWindow = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_PET);
         var _loc5_:SimpleContainer = this.getPetWindowContainer();
         if(!_loc5_.getElement(SimpleElement.PET_WINDOW_PLAY_BTN).getChildAt(0).hasEventListener(MouseEvent.CLICK))
         {
            _loc5_.getElement(SimpleElement.PET_WINDOW_REPAIR_BTN).getChildAt(0).addEventListener(MouseEvent.CLICK,this.handleClickRepairButton);
            _loc5_.getElement(SimpleElement.PET_WINDOW_PLAY_BTN).getChildAt(0).addEventListener(MouseEvent.CLICK,this.handleClickPlayButton);
            _loc5_.getElement(SimpleElement.PET_WINDOW_STOP_BTN).getChildAt(0).addEventListener(MouseEvent.CLICK,this.handleClickStopButton);
            _loc5_.getElement(SimpleElement.PET_WINDOW_FUEL_BTN).getChildAt(0).addEventListener(MouseEvent.CLICK,this.handleClickFuelButton);
            _loc4_.addEventListener(SimpleWindow.ON_MINIMIZE,this.handleMinimizeWindow);
         }
         if(!param2)
         {
            this.setFuelMissingMode();
         }
         if(param3)
         {
            this.toggleRepairButtonVisbility(true);
         }
         if(!param1)
         {
            this.initPetBanner();
         }
         this.updatePetImage(-1);
      }
      
      private function assembleLockWindow(param1:Array) : void
      {
         var _loc2_:int = 3;
         var _loc3_:Boolean = Boolean(int(param1[_loc2_]));
         if(_loc3_)
         {
            this.blockPetWindow();
         }
         else
         {
            this.unblockPetWindow();
         }
      }
      
      private function blockPetWindow() : void
      {
         var _loc1_:SimpleWindow = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_PET);
         _loc1_.addLockOverlay(10,25,_loc1_.getWindowDimension().x,115);
      }
      
      private function unblockPetWindow() : void
      {
         var _loc1_:SimpleWindow = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_PET);
         if(_loc1_ != null)
         {
            _loc1_.removeLockOverlay();
         }
      }
      
      private function handleMinimizeWindow(param1:Event = null) : void
      {
         var _loc2_:SimpleWindow = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_PET);
         var _loc3_:GearComboBox = _loc2_.getContainer(SimpleContainer.CLASS_PET_WINDOW_CONTENT).getElement(SimpleElement.PET_WINDOW_GEAR_COMBO_CONTAINER).getChildAt(0) as GearComboBox;
         var _loc4_:GearScroller = this.getGearMenuContainer(_loc2_).mainMenu;
         _loc4_.visible = false;
         _loc3_.arrowButton.gotoAndStop(1);
         this.closeAllSubMenus();
      }
      
      private function assembleResetStatus(param1:Array) : void
      {
         this.resetPetWindowValues();
         var _loc2_:Array = this.main.screenManager.map.getShipManager().getHero().pet.gears;
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            this.removeGear(_loc2_[_loc3_]);
            _loc3_++;
         }
         var _loc4_:Ship = this.main.screenManager.map.getShipManager().getHero();
         this.effectsManager.removeAllEffects(_loc4_);
      }
      
      private function assembleStopLaserAttack(param1:Array) : void
      {
         var _loc2_:int = 2;
         var _loc3_:int = int(param1[++_loc2_]);
         var _loc4_:Map = this.main.screenManager.map;
         _loc4_.getCombatManager().removeLaserAttack(_loc3_);
      }
      
      private function assembleInvisibleMode(param1:Array) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:Boolean = false;
         var _loc6_:Pet = null;
         if(this.main.screenManager.map != null)
         {
            _loc2_ = 2;
            _loc3_ = int(param1[++_loc2_]);
            _loc4_ = int(param1[++_loc2_]);
            _loc5_ = Boolean(_loc4_);
            _loc6_ = this.main.screenManager.map.getShipManager().getPet(_loc3_);
            if(_loc6_ != null)
            {
               _loc6_.setIdle(_loc5_);
               _loc6_.getClipContainer().visible = !_loc5_;
            }
         }
      }
      
      private function assembleActivateTradeWindow(param1:Array) : void
      {
         var _loc2_:SimpleWindow = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_TRADE);
         _loc2_.addEventListener(SimpleWindow.ON_MINIMIZED,this.handleTradeWindowMinimized);
         _loc2_.unlockWindow();
         _loc2_.maximize();
         this.main.getGuiManager().updateTradeWindow();
      }
      
      private function handleTradeWindowMinimized(param1:Event) : void
      {
         var _loc2_:SimpleWindow = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_TRADE);
         _loc2_.removeEventListener(SimpleWindow.ON_MINIMIZED,this.handleTradeWindowMinimized);
         if(!Hero.inTradeArea)
         {
            _loc2_.lockWindow();
         }
      }
      
      private function assembleLevelUp(param1:Array) : void
      {
         var _loc2_:int = 3;
         var _loc3_:int = int(param1[++_loc2_]);
         var _loc4_:int = int(param1[++_loc2_]);
         var _loc5_:Pet = this.main.screenManager.map.getShipManager().getHero().pet;
         var _loc6_:LevelUpEffect = new LevelUpEffect(EffectIDList.LEVEL_UP_EFFECT,new EffectPattern(EffectIDList.LEVEL_UP_EFFECT,"levelUp"));
         this.effectsManager.addEffect(_loc6_,_loc5_,EffectsManager.TIMEOUT_EFFECT);
         this.main.getGuiManager().writeToLog(BPLocale.getText("msg_pet_level_up").replace("%LEVEL%",_loc3_));
         this.playSound(70);
      }
      
      private function assembleEvasionProtocolInfo(param1:Array) : void
      {
         var _loc2_:int = 3;
         var _loc3_:int = int(param1[_loc2_]);
         var _loc4_:Boolean = Boolean(int(param1[++_loc2_]));
         if(this.main.screenManager.map.getShipManager().getPet(_loc3_) != null)
         {
            this.main.screenManager.map.getShipManager().getPet(_loc3_).evasionProtocolEquiped = _loc4_;
         }
      }
      
      private function assembleLocatorGearInfo(param1:Array) : void
      {
         var _loc2_:int = 3;
         var _loc3_:Ship = this.main.screenManager.map.getShipManager().getHero();
         var _loc4_:int = int(param1[++_loc2_]);
         var _loc5_:int = int(param1[++_loc2_]);
         var _loc6_:EffectBase = this.effectsManager.getEffectFromEntity(_loc3_,1);
         _loc6_.update(this.main,[_loc4_,_loc5_]);
      }
      
      private function assemblePetDestroyed(param1:Array) : void
      {
         this.resetPetWindowValues();
         var _loc2_:Ship = this.main.screenManager.map.getShipManager().getHero();
         this.effectsManager.removeAllEffects(_loc2_);
         this.toggleRepairButtonVisbility(true);
         this.removeGearComboListeners();
         this.playSound(69);
         this.main.getGuiManager().writeToLog(BPLocale.getText("msg_pet_is_dead"));
      }
      
      private function assemblePetRepair(param1:Array) : void
      {
         this.playSound(71);
         this.toggleRepairButtonVisbility(false);
      }
      
      private function addCooldown(param1:int, param2:int) : void
      {
         var _loc3_:BuffItem = this.getBuff(param1);
         var _loc4_:BuffCoolDown = new BuffCoolDown(_loc3_,param2,_loc3_.tooltip,_loc3_.pattern.languageKey);
         _loc4_.addCoolDown();
      }
      
      private function addPetSpawnAnimation(param1:Pet) : void
      {
         var _loc3_:PetEffect = null;
         var _loc2_:EffectPattern = PatternManager.effectPatterns[EffectIDList.PET_SPAWN];
         if(_loc2_ != null)
         {
            _loc3_ = new PetEffect(EffectIDList.PET_SPAWN,_loc2_,false,[],false);
            this.effectsManager.addEffectControllerToObject(param1);
            this.effectsManager.addEffect(_loc3_,param1);
         }
      }
      
      private function assemblePetStatus(param1:Array) : void
      {
         var _loc2_:int = 2;
         var _loc3_:int = int(param1[++_loc2_]);
         var _loc4_:int = int(param1[++_loc2_]);
         var _loc5_:int = int(param1[++_loc2_]);
         var _loc6_:int = int(param1[++_loc2_]);
         var _loc7_:int = int(param1[++_loc2_]);
         var _loc8_:int = int(param1[++_loc2_]);
         var _loc9_:int = int(param1[++_loc2_]);
         var _loc10_:int = int(param1[++_loc2_]);
         var _loc11_:int = int(param1[++_loc2_]);
         var _loc12_:int = int(param1[++_loc2_]);
         var _loc13_:int = int(param1[++_loc2_]);
         var _loc14_:String = String(param1[++_loc2_]);
         this.setPetNameTextfieldValue(_loc14_);
         this.updateBar(SimpleElement.PET_WINDOW_HP_BAR,_loc7_,_loc8_);
         this.updateBar(SimpleElement.PET_WINDOW_SHIELD_BAR,_loc9_,_loc10_);
         this.updateBar(SimpleElement.PET_WINDOW_FUEL_BAR,_loc11_,_loc12_);
         this.updateBar(SimpleElement.PET_WINDOW_XP_BAR,_loc5_,_loc6_);
         this.updatePetImage(_loc4_);
      }
      
      public function assemblePetDeactivation(param1:Array = null) : void
      {
         var _loc3_:MapObject = null;
         var _loc2_:Map = this.main.screenManager.map;
         if(this.getPetWindowContainer() != null)
         {
            _loc3_ = _loc2_.getShipManager().getHero();
            if(_loc3_ != null)
            {
               this.effectsManager.removeAllEffects(_loc3_);
            }
            this.removeGearComboListeners();
            this.resetPetWindowValues();
            this.handleMinimizeWindow();
            this.togglePlayStopButtonVisibility(true);
            if(param1 != null)
            {
               this.playSound(68);
            }
         }
      }
      
      private function assembleHeroPetActivation(param1:Array) : void
      {
         var _loc2_:Pet = this.createPet(param1,"neutral");
         var _loc3_:ShipManager = this.main.screenManager.map.getShipManager();
         _loc3_.getHero().pet = _loc2_;
         var _loc4_:int = int(param1[12]);
         var _loc5_:int = int(param1[13]);
         var _loc6_:SimpleContainer = this.getPetWindowContainer();
         var _loc7_:GearComboBox = _loc6_.getElement(SimpleElement.PET_WINDOW_GEAR_COMBO_CONTAINER).getChildAt(0) as GearComboBox;
         if(!_loc7_.hasEventListener(MouseEvent.CLICK))
         {
            _loc7_.addEventListener(MouseEvent.CLICK,this.handleClickGearCombo);
         }
         _loc2_.setHitpoints(_loc4_);
         _loc2_.setMaxHitpoints(_loc5_);
         _loc2_.updateHitpointShieldBar();
         this.togglePlayStopButtonVisibility(false);
         _loc2_.setSelected(true);
         _loc2_.setSelected(false);
         _loc2_.setMinimapIcon("mapIcon_pet");
         this.playSound(67);
         this.addPetSpawnAnimation(_loc2_);
      }
      
      private function assembleExternalPetActivation(param1:Array) : void
      {
         var _loc3_:Boolean = false;
         var _loc4_:Pet = null;
         var _loc2_:int = int(param1[4]);
         if(this.main.screenManager.map.getShipManager().getPet(_loc2_) == null)
         {
            _loc3_ = Boolean(int(param1[15]));
            _loc4_ = this.createPet(param1);
            _loc4_.updateLabel();
            _loc4_.setIdle(_loc3_);
            _loc4_.getClipContainer().visible = !_loc3_;
            if(!_loc3_)
            {
               this.addPetSpawnAnimation(_loc4_);
            }
         }
      }
      
      private function createPet(param1:Array, param2:String = "") : Pet
      {
         var _loc3_:int = 2;
         var _loc4_:int = int(param1[++_loc3_]);
         var _loc5_:int = int(param1[++_loc3_]);
         var _loc6_:int = int(param1[++_loc3_]);
         var _loc7_:String = String(param1[++_loc3_]);
         var _loc8_:int = int(param1[++_loc3_]);
         var _loc9_:int = int(param1[++_loc3_]);
         var _loc10_:int = int(param1[++_loc3_]);
         var _loc11_:String = String(param1[++_loc3_]);
         var _loc12_:int = int(param1[++_loc3_]);
         var _loc13_:int = int(param1[++_loc3_]);
         var _loc14_:int = int(param1[++_loc3_]);
         var _loc15_:int = int(param1[++_loc3_]);
         var _loc16_:int = int(param1[++_loc3_]);
         var _loc17_:ShipManager = this.main.screenManager.map.getShipManager();
         return _loc17_.createPet(_loc6_,_loc5_,_loc4_,_loc13_,_loc14_,_loc15_,_loc7_,_loc10_,_loc8_,_loc9_,_loc11_,_loc12_,param2);
      }
      
      private function getPetWindowContainer() : SimpleContainer
      {
         var _loc2_:SimpleContainer = null;
         var _loc1_:SimpleWindow = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_PET);
         if(_loc1_ != null)
         {
            _loc2_ = _loc1_.getContainer(SimpleContainer.CLASS_PET_WINDOW_CONTENT);
         }
         return _loc2_;
      }
      
      private function getGearMenuContainer(param1:SimpleWindow) : GearMenuContainer
      {
         var _loc2_:GearMenuContainer = null;
         if(param1.getChildAt(param1.numChildren - 2) is GearMenuContainer)
         {
            _loc2_ = param1.getChildAt(param1.numChildren - 2) as GearMenuContainer;
         }
         else
         {
            _loc2_ = param1.getChildAt(param1.numChildren - 1) as GearMenuContainer;
         }
         return _loc2_;
      }
      
      private function initPetBanner() : void
      {
         var _loc1_:BannerAdPattern = PatternManager.bannerAdPatterns["buyPet"];
         if(_loc1_.price == -1)
         {
            BannerAdLazyLoader.loadBannerAdPatternAddon();
         }
         var _loc2_:BannerAdLazyLoader = new BannerAdLazyLoader(_loc1_);
         _loc2_.addEventListener(BannerAdLazyLoader.BANNERAD_LOADED,this.handleBannerAdLoaded);
         _loc2_.loadBannerAd();
      }
      
      private function handleBannerAdLoaded(param1:Event) : void
      {
         var _loc2_:BannerAdLazyLoader = param1.target as BannerAdLazyLoader;
         _loc2_.removeEventListener(BannerAdLazyLoader.BANNERAD_LOADED,this.handleBannerAdLoaded);
         var _loc3_:BannerAdPattern = PatternManager.bannerAdPatterns["buyPet"];
         var _loc4_:BannerAd = new BannerAd(_loc3_);
         var _loc5_:SimpleWindow = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_PET);
         var _loc6_:SimpleContainer = _loc5_.getContainer(SimpleContainer.CLASS_PET_WINDOW_BANNER);
         _loc5_.getContainer(SimpleContainer.CLASS_PET_WINDOW_CONTENT).getElement(SimpleElement.PET_WINDOW_EXPAND_BTN).visible = false;
         var _loc7_:SimpleElement = new SimpleElement(SimpleElement.PET_WINDOW_BANNER_CONTAINER);
         _loc4_.bannerAdClip.y = 20;
         _loc4_.bannerAdClip.x = 5;
         _loc4_.allTextsWrapper.x = 10;
         _loc4_.allTextsWrapper.y = 20;
         _loc4_.bannerAdClip.scaleX = 0.93;
         _loc4_.setButtonText("label_buy_achievement_reward_no_price");
         _loc4_.overrideMouseClick(this.handleBannerAdClicked);
         _loc7_.addChild(_loc4_.bannerAdClip);
         _loc6_.addElement(_loc7_,SimpleContainer.NO_ALIGN);
      }
      
      private function assembleRemoveBanner(param1:Array) : void
      {
         var _loc2_:SimpleWindow = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_PET);
         _loc2_.getContainer(SimpleContainer.CLASS_PET_WINDOW_CONTENT).getElement(SimpleElement.PET_WINDOW_EXPAND_BTN).visible = true;
         var _loc3_:SimpleElement = _loc2_.getContainer(SimpleContainer.CLASS_PET_WINDOW_BANNER).getElement(SimpleElement.PET_WINDOW_BANNER_CONTAINER);
         this.toggleRepairButtonVisbility(false);
         if(_loc3_.numChildren > 0)
         {
            _loc3_.removeChildAt(0);
         }
      }
      
      private function handleClickGearCombo(param1:MouseEvent) : void
      {
         this.toggleComboboxState();
      }
      
      private function handleBannerAdClicked() : void
      {
         if(ExternalInterface.available)
         {
            ExternalInterface.call("showPetFuel");
         }
      }
      
      private function resetPetWindowValues() : void
      {
         var _loc1_:SimpleWindow = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_PET);
         var _loc2_:GearComboBox = _loc1_.getContainer(SimpleContainer.CLASS_PET_WINDOW_CONTENT).getElement(SimpleElement.PET_WINDOW_GEAR_COMBO_CONTAINER).getChildAt(0) as GearComboBox;
         var _loc3_:GearMenuContainer = this.getGearMenuContainer(_loc1_);
         this.updateBar(SimpleElement.PET_WINDOW_SHIELD_BAR,0,0);
         this.updateBar(SimpleElement.PET_WINDOW_HP_BAR,0,0);
         this.updateBar(SimpleElement.PET_WINDOW_XP_BAR,0,0);
         this.updateBar(SimpleElement.PET_WINDOW_FUEL_BAR,0,0);
         this.setPetNameTextfieldValue("");
         this.updatePetImage(-1);
         _loc3_.mainMenu.removeAllElements();
         _loc3_.removeAllSubmenus();
         _loc2_.setIcon(null);
         _loc2_.setSelectedText("");
         this.removeAllBuffs();
      }
      
      private function updatePetImage(param1:int) : void
      {
         var _loc4_:Bitmap = null;
         var _loc5_:int = 0;
         var _loc6_:BitmapFont = null;
         var _loc2_:SimpleContainer = this.getPetWindowContainer();
         var _loc3_:Sprite = _loc2_.getElement(SimpleElement.PET_WINDOW_IMAGE_CONTAINER).getChildAt(0) as Sprite;
         if(_loc3_.numChildren > 0)
         {
            _loc5_ = 0;
            while(_loc5_ < _loc3_.numChildren)
            {
               _loc3_.removeChildAt(_loc5_);
               _loc5_++;
            }
         }
         if(param1 > -1)
         {
            this.updatePetLevelTooltip(_loc3_,param1);
            _loc4_ = SWFFinisher(ResourceManager.fileCollection.getFinisher("ui")).getEmbededBitmap("pet_level_" + param1 + ".jpg");
            _loc3_.addChild(_loc4_);
            _loc6_ = new BitmapFont(null);
            _loc6_.setText(param1.toString());
            _loc6_.x = _loc4_.width - _loc6_.width - 5;
            _loc6_.y = _loc4_.height - 10;
            _loc6_.scaleX = _loc6_.scaleY = 1.5;
            _loc3_.alpha = 1;
            _loc3_.addChild(_loc6_);
         }
         else
         {
            _loc4_ = SWFFinisher(ResourceManager.fileCollection.getFinisher("ui")).getEmbededBitmap("pet_level_0.jpg");
            _loc3_.addChild(_loc4_);
            _loc3_.alpha = 0.4;
         }
      }
      
      private function updatePetLevelTooltip(param1:InteractiveObject, param2:int) : void
      {
         TooltipControl.getInstance().removeToolTip(param1);
         TooltipControl.getInstance().addToolTip(param1,BPLocale.getText("title_pet") + " " + BPLocale.getText("ttip_level").replace("%COUNT%",param2));
      }
      
      private function setPetNameTextfieldValue(param1:String) : void
      {
         var _loc2_:SimpleContainer = this.getPetWindowContainer();
         var _loc3_:TextField = _loc2_.getElement(SimpleElement.PET_WINDOW_PETNAME_TEXT).getChildAt(0) as TextField;
         _loc3_.text = param1;
      }
      
      private function updateBar(param1:int, param2:int, param3:int) : void
      {
         var _loc4_:SimpleContainer = this.getPetWindowContainer();
         var _loc5_:BarComponent = _loc4_.getElement(param1).getChildAt(0) as BarComponent;
         _loc5_.update(param2,param3);
      }
      
      private function toggleRepairButtonVisbility(param1:Boolean) : void
      {
         var _loc2_:SimpleContainer = this.getPetWindowContainer();
         MovieClip(_loc2_.getElement(SimpleElement.PET_WINDOW_REPAIR_BTN).getChildAt(0)).gotoAndStop(1);
         _loc2_.getElement(SimpleElement.PET_WINDOW_REPAIR_BTN).getChildAt(0).visible = param1;
         _loc2_.getElement(SimpleElement.PET_WINDOW_STOP_BTN).getChildAt(0).visible = !param1;
         _loc2_.getElement(SimpleElement.PET_WINDOW_PLAY_BTN).getChildAt(0).visible = !param1;
      }
      
      public function setFuelMissingMode() : void
      {
         var _loc1_:SimpleContainer = this.getPetWindowContainer();
         _loc1_.getElement(SimpleElement.PET_WINDOW_STOP_BTN).getChildAt(0).visible = false;
         _loc1_.getElement(SimpleElement.PET_WINDOW_PLAY_BTN).getChildAt(0).visible = false;
         _loc1_.getElement(SimpleElement.PET_WINDOW_REPAIR_BTN).getChildAt(0).visible = false;
         MovieClip(_loc1_.getElement(SimpleElement.PET_WINDOW_FUEL_BTN).getChildAt(0)).gotoAndStop(1);
      }
      
      public function setFuelAvailableMode() : void
      {
         var _loc1_:SimpleContainer = this.getPetWindowContainer();
         _loc1_.getElement(SimpleElement.PET_WINDOW_STOP_BTN).getChildAt(0).visible = true;
         _loc1_.getElement(SimpleElement.PET_WINDOW_PLAY_BTN).getChildAt(0).visible = true;
         _loc1_.getElement(SimpleElement.PET_WINDOW_REPAIR_BTN).getChildAt(0).visible = false;
         MovieClip(_loc1_.getElement(SimpleElement.PET_WINDOW_FUEL_BTN).getChildAt(0)).gotoAndStop(1);
      }
      
      private function togglePlayStopButtonVisibility(param1:Boolean) : void
      {
         var _loc2_:SimpleContainer = this.getPetWindowContainer();
         MovieClip(_loc2_.getElement(SimpleElement.PET_WINDOW_PLAY_BTN).getChildAt(0)).gotoAndStop(1);
         MovieClip(_loc2_.getElement(SimpleElement.PET_WINDOW_STOP_BTN).getChildAt(0)).gotoAndStop(1);
         MovieClip(_loc2_.getElement(SimpleElement.PET_WINDOW_PLAY_BTN).getChildAt(0)).visible = param1;
         MovieClip(_loc2_.getElement(SimpleElement.PET_WINDOW_STOP_BTN).getChildAt(0)).visible = !param1;
         MovieClip(_loc2_.getElement(SimpleElement.PET_WINDOW_REPAIR_BTN).getChildAt(0)).visible = false;
      }
      
      private function assemblePetHPInfo(param1:Array) : void
      {
         var _loc2_:int = 3;
         var _loc3_:int = int(param1[++_loc2_]);
         var _loc4_:int = int(param1[++_loc2_]);
         var _loc5_:int = int(param1[++_loc2_]);
         var _loc6_:Pet = this.main.screenManager.map.getShipManager().getHero().pet;
         if(_loc6_ != null)
         {
            _loc6_.setHitpoints(_loc3_);
            _loc6_.setMaxHitpoints(_loc4_);
            this.updateBar(SimpleElement.PET_WINDOW_HP_BAR,_loc3_,_loc4_);
            _loc6_.updateHitpointShieldBar();
            if(_loc6_ != null && Boolean(_loc5_))
            {
               _loc6_.showRepairRobot(1);
            }
            else
            {
               _loc6_.hideRepairRobot();
            }
            this.playSound(71);
         }
      }
      
      private function assemblePetXPInfo(param1:Array) : void
      {
         var _loc2_:int = 3;
         var _loc3_:int = int(param1[++_loc2_]);
         var _loc4_:int = int(param1[++_loc2_]);
         this.updateBar(SimpleElement.PET_WINDOW_XP_BAR,_loc3_,_loc4_);
      }
      
      private function assemblePetShieldInfo(param1:Array) : void
      {
         var _loc2_:int = 3;
         var _loc3_:int = int(param1[++_loc2_]);
         var _loc4_:int = int(param1[++_loc2_]);
         var _loc5_:Pet = this.main.screenManager.map.getShipManager().getHero().pet;
         if(_loc5_ != null)
         {
            _loc5_.setShieldChunk(_loc3_,_loc4_,false);
         }
         this.updateBar(SimpleElement.PET_WINDOW_SHIELD_BAR,_loc3_,_loc4_);
      }
      
      private function assemblePetFuelInfo(param1:Array) : void
      {
         var _loc2_:int = 3;
         var _loc3_:int = int(param1[++_loc2_]);
         var _loc4_:int = int(param1[++_loc2_]);
         this.updateBar(SimpleElement.PET_WINDOW_FUEL_BAR,_loc3_,_loc4_);
      }
      
      private function handleClickPlayButton(param1:MouseEvent) : void
      {
         this.togglePlayStopButtonVisibility(false);
         var _loc2_:SimpleContainer = this.getPetWindowContainer();
         if(!Sprite(_loc2_.getElement(SimpleElement.PET_WINDOW_GEAR_COMBO_CONTAINER).getChildAt(0)).hasEventListener(MouseEvent.CLICK))
         {
            _loc2_.getElement(SimpleElement.PET_WINDOW_GEAR_COMBO_CONTAINER).getChildAt(0).addEventListener(MouseEvent.CLICK,this.handleClickGearCombo);
         }
         this.launchPet();
      }
      
      private function handleClickStopButton(param1:MouseEvent = null) : void
      {
         if(param1 != null)
         {
            this.stopPet();
         }
      }
      
      private function removeGearComboListeners() : void
      {
         var _loc2_:GearComboBox = null;
         var _loc1_:SimpleContainer = this.getPetWindowContainer();
         if(_loc1_ != null)
         {
            _loc2_ = _loc1_.getElement(SimpleElement.PET_WINDOW_GEAR_COMBO_CONTAINER).getChildAt(0) as GearComboBox;
            if(_loc2_.hasEventListener(MouseEvent.CLICK))
            {
               _loc2_.removeEventListener(MouseEvent.CLICK,this.handleClickGearCombo);
            }
         }
      }
      
      private function addEffect(param1:int, param2:Array) : void
      {
         var _loc3_:EffectBase = EffectFactory.getInstance().createEffect(param1,param2);
         var _loc4_:Ship = this.main.screenManager.map.getShipManager().getHero();
         this.effectsManager.removeAllEffects(_loc4_);
         if(_loc3_ != null)
         {
            this.effectsManager.addEffectControllerToObject(_loc4_);
            this.effectsManager.addEffect(_loc3_,_loc4_);
         }
      }
      
      private function removeEffect(param1:int) : void
      {
      }
      
      private function assembleRemoveBuff(param1:Array) : void
      {
         var _loc2_:int = 3;
         var _loc3_:int = int(param1[++_loc2_]);
         this.removeBuff(_loc3_);
      }
      
      private function assembleGearTargetsList(param1:Array) : void
      {
         var _loc2_:int = 3;
         var _loc3_:int = int(param1[++_loc2_]);
         var _loc4_:Array = param1.slice(5);
         this.addTargetsForGear(_loc3_,_loc4_);
      }
      
      private function assembleRemoveGear(param1:Array) : void
      {
         var _loc2_:int = 3;
         var _loc3_:int = int(param1[++_loc2_]);
         this.removeGear(_loc3_);
      }
      
      private function assembleAddGear(param1:Array) : void
      {
         var _loc2_:int = 3;
         var _loc3_:int = int(param1[++_loc2_]);
         var _loc4_:int = int(param1[++_loc2_]);
         var _loc5_:int = int(param1[++_loc2_]);
         this.addGear(_loc3_,_loc4_,_loc5_);
      }
      
      private function addGear(param1:int, param2:int, param3:int) : void
      {
         var _loc4_:SimpleWindow = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_PET);
         var _loc5_:Pet = this.main.screenManager.map.getShipManager().getHero().pet;
         _loc5_.gears.push(param1);
         var _loc6_:Gear = GearFactory.getGear(param1,param2,param3);
         var _loc7_:Bitmap = SWFFinisher(ResourceManager.fileCollection.getFinisher("ui")).getEmbededBitmap(_loc6_.pattern.resKey);
         var _loc8_:GearScroller = this.getGearMenuContainer(_loc4_).mainMenu;
         var _loc9_:GearItem = new GearItem(param1,_loc6_.pattern.gearName,_loc7_,_loc8_.width - 1);
         _loc9_.addEventListener(GearItem.MOUSE_OVER,this.closeAllSubMenus);
         _loc9_.addEventListener(GearItem.CLICKED,this.handleMenuClick);
         _loc8_.addElement(_loc9_);
      }
      
      private function removeGear(param1:int) : void
      {
         var _loc2_:SimpleWindow = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_PET);
         var _loc3_:Pet = this.main.screenManager.map.getShipManager().getHero().pet;
         delete _loc3_.gears[param1];
         var _loc4_:GearMenuContainer = this.getGearMenuContainer(_loc2_);
         var _loc5_:GearItem = _loc4_.mainMenu.getElementByID(param1);
         if(_loc5_ != null)
         {
            _loc4_.mainMenu.removeElement(_loc5_);
            if(_loc4_.getSubMenu(param1) != null)
            {
               _loc4_.removeSubMenu(param1);
            }
         }
      }
      
      private function assembleSelectGear(param1:Array) : void
      {
         var _loc2_:int = 4;
         var _loc3_:int = int(param1[_loc2_]);
         var _loc4_:SimpleWindow = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_PET);
         var _loc5_:GearMenuContainer = this.getGearMenuContainer(_loc4_);
         var _loc6_:GearItem = _loc5_.mainMenu.getElementByID(_loc3_);
         this.setSelectedItem(_loc6_.icon,_loc6_.title,_loc3_);
      }
      
      private function getGearItem(param1:int) : GearItem
      {
         var _loc2_:SimpleWindow = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_PET);
         var _loc3_:GearScroller = this.getGearMenuContainer(_loc2_).mainMenu;
         return _loc3_.getElementByID(param1);
      }
      
      private function addTargetsForGear(param1:int, param2:Array) : void
      {
         var _loc3_:Bitmap = null;
         var _loc5_:GearItem = null;
         var _loc11_:String = null;
         var _loc4_:String = "";
         var _loc6_:InGameCatalog = InGameCatalog.getInstance();
         var _loc7_:SimpleWindow = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_PET);
         var _loc8_:GearMenuContainer = this.getGearMenuContainer(_loc7_);
         var _loc9_:GearScroller = _loc8_.getSubMenu(param1);
         if(_loc9_ == null)
         {
            _loc9_ = new GearScroller(param1);
            _loc9_.x = _loc8_.mainMenu.width + 10;
            _loc9_.y = this.getGearItem(param1).y;
            _loc8_.addSubMenu(_loc9_);
            this.getGearItem(param1).drawArrow();
            this.addSubmenuListener(param1);
         }
         else
         {
            _loc9_.removeAllElements();
         }
         var _loc10_:GearPattern = PatternManager.petGearPatterns[param1];
         var _loc12_:int = 0;
         while(_loc12_ < param2.length)
         {
            _loc4_ = _loc6_[_loc10_.targetListKey + "_names"][param2[_loc12_]];
            _loc11_ = _loc6_[_loc10_.targetListKey + "_icons"][int(param2[_loc12_])] + _loc10_.suffix;
            _loc3_ = SWFFinisher(ResourceManager.fileCollection.getFinisher("icons")).getEmbededBitmap(_loc11_) as Bitmap;
            if(_loc3_ == null)
            {
               _loc3_ = SWFFinisher(ResourceManager.fileCollection.getFinisher("icons")).getEmbededBitmap("npc_unknown_placeholder_icon.png");
            }
            _loc5_ = new GearItem(param2[_loc12_],_loc4_,_loc3_,_loc8_.mainMenu.width - 1);
            _loc5_.addEventListener(GearItem.CLICKED,this.handleSubmenuClick);
            _loc9_.addElement(_loc5_);
            _loc12_++;
         }
      }
      
      private function closeAllSubMenus(param1:Event = null) : void
      {
         var _loc4_:GearScroller = null;
         var _loc2_:SimpleWindow = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_PET);
         var _loc3_:GearMenuContainer = this.getGearMenuContainer(_loc2_);
         for each(_loc4_ in _loc3_.submenus)
         {
            if(_loc4_ != null)
            {
               _loc4_.hide();
            }
         }
      }
      
      private function addSubmenuListener(param1:int) : void
      {
         var _loc2_:GearItem = this.getGearItem(param1);
         if(_loc2_ != null)
         {
            _loc2_.addEventListener(GearItem.MOUSE_OVER,this.showSubmenu);
         }
      }
      
      private function showSubmenu(param1:Event) : void
      {
         var _loc2_:GearScroller = this.getSubMenu(GearItem(param1.target).gearID);
         if(_loc2_ != null)
         {
            _loc2_.show();
         }
      }
      
      private function getSubMenu(param1:int) : GearScroller
      {
         var _loc2_:SimpleWindow = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_PET);
         var _loc3_:GearMenuContainer = this.getGearMenuContainer(_loc2_);
         return _loc3_.getSubMenu(param1);
      }
      
      private function handleMenuClick(param1:Event) : void
      {
         var _loc2_:GearItem = GearItem(param1.target);
         var _loc3_:String = "";
         var _loc4_:GearScroller = this.getSubMenu(_loc2_.gearID);
         if(_loc4_ != null)
         {
            if(_loc4_.getElement(0) != null)
            {
               _loc3_ = _loc4_.getElement(0).gearID.toString();
            }
         }
         this.setSelectedItem(_loc2_.icon,_loc2_.title,_loc2_.gearID,_loc3_);
         this.toggleComboboxState();
      }
      
      private function handleSubmenuClick(param1:Event) : void
      {
         var _loc2_:GearItem = GearItem(param1.target);
         var _loc3_:int = GearItem(param1.target).submenuID;
         var _loc4_:GearItem = this.getGearItem(_loc3_);
         this.setSelectedItem(_loc2_.icon,_loc4_.title,_loc3_,_loc2_.gearID.toString());
         this.toggleComboboxState();
      }
      
      private function setSelectedItem(param1:Bitmap, param2:String, param3:int, param4:String = "") : void
      {
         var _loc5_:SimpleContainer = this.getPetWindowContainer();
         var _loc6_:GearComboBox = _loc5_.getElement(SimpleElement.PET_WINDOW_GEAR_COMBO_CONTAINER).getChildAt(0) as GearComboBox;
         var _loc7_:GearPattern = PatternManager.petGearPatterns[param3];
         this.closeAllSubMenus();
         _loc6_.setIcon(new Bitmap(param1.bitmapData));
         _loc6_.setSelectedText(param2);
         this.addEffect(_loc7_.effect,[param4,new Bitmap(param1.bitmapData)]);
         this.requestGearActivation(param3,param4);
         this.playSound(72);
      }
      
      private function toggleComboboxState() : void
      {
         var _loc1_:SimpleContainer = this.getPetWindowContainer();
         var _loc2_:GearComboBox = Sprite(_loc1_.getElement(SimpleElement.PET_WINDOW_GEAR_COMBO_CONTAINER)).getChildAt(0) as GearComboBox;
         var _loc3_:SimpleWindow = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_PET);
         var _loc4_:GearScroller = this.getGearMenuContainer(_loc3_).mainMenu;
         this.closeAllSubMenus();
         _loc4_.toggleVisibility();
         this.toggleMovieClipState(_loc2_.arrowButton);
      }
      
      private function toggleMovieClipState(param1:MovieClip) : void
      {
         var _loc2_:int = 1;
         if(param1.currentFrame == _loc2_)
         {
            _loc2_ = 2;
         }
         param1.gotoAndStop(_loc2_);
      }
      
      private function assembleAddBuff(param1:Array) : void
      {
         var _loc5_:int = 0;
         var _loc2_:int = 4;
         var _loc3_:int = int(param1[_loc2_]);
         var _loc4_:BuffItem = this.addBuff(_loc3_);
         switch(_loc3_)
         {
            case BuffPattern.SINGULARITY_BUFF:
            case BuffPattern.WEAKENSHIELD_BUFF:
            case BuffPattern.SPEEDLEACH_BUFF:
               break;
            case BuffPattern.TRADE_BUFF:
               _loc5_ = int(param1[5]);
               this.addCooldown(BuffPattern.TRADE_BUFF,_loc5_);
         }
      }
      
      private function addBuff(param1:int) : BuffItem
      {
         var _loc2_:BuffPattern = PatternManager.petBuffPatterns[param1];
         var _loc3_:BuffItem = new BuffItem(_loc2_);
         var _loc4_:ToolTipHook = TooltipControl.getInstance().addToolTip(_loc3_,BPLocale.getText(_loc2_.languageKey));
         _loc3_.tooltip = _loc4_;
         var _loc5_:SimpleContainer = this.getPetWindowContainer();
         var _loc6_:Sprite = Sprite(_loc5_.getElement(SimpleElement.PET_WINDOW_BUFF_CONTAINER).getChildAt(0));
         _loc6_.addChild(_loc3_);
         this.positionBuffs();
         return _loc3_;
      }
      
      private function getBuff(param1:int) : BuffItem
      {
         var _loc5_:BuffItem = null;
         var _loc2_:SimpleContainer = this.getPetWindowContainer();
         var _loc3_:Sprite = _loc2_.getElement(SimpleElement.PET_WINDOW_BUFF_CONTAINER).getChildAt(0) as Sprite;
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_.numChildren)
         {
            _loc5_ = _loc3_.getChildAt(_loc4_) as BuffItem;
            if(_loc5_ != null && _loc5_.id == param1)
            {
               return _loc5_;
            }
            _loc4_++;
         }
         return null;
      }
      
      private function removeBuff(param1:int) : void
      {
         this.removeBuffById(param1);
         this.positionBuffs();
      }
      
      private function removeAllBuffs() : void
      {
         var _loc1_:SimpleContainer = this.getPetWindowContainer();
         var _loc2_:Sprite = _loc1_.getElement(SimpleElement.PET_WINDOW_BUFF_CONTAINER).getChildAt(0) as Sprite;
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.numChildren)
         {
            _loc2_.removeChild(_loc2_.getChildAt(_loc3_));
            _loc3_++;
         }
      }
      
      private function removeBuffById(param1:int) : void
      {
         var _loc4_:BuffItem = null;
         var _loc2_:SimpleContainer = this.getPetWindowContainer();
         var _loc3_:Sprite = _loc2_.getElement(SimpleElement.PET_WINDOW_BUFF_CONTAINER).getChildAt(0) as Sprite;
         var _loc5_:int = 0;
         while(_loc5_ < _loc3_.numChildren)
         {
            _loc4_ = _loc3_.getChildAt(_loc5_) as BuffItem;
            if(_loc4_ != null && _loc4_.id == param1)
            {
               TooltipControl.getInstance().removeToolTip(_loc4_ as InteractiveObject);
               _loc3_.removeChild(_loc4_);
               return;
            }
            _loc5_++;
         }
      }
      
      private function positionBuffs() : void
      {
         var _loc3_:BuffItem = null;
         var _loc1_:SimpleContainer = this.getPetWindowContainer();
         var _loc2_:Sprite = _loc1_.getElement(SimpleElement.PET_WINDOW_BUFF_CONTAINER).getChildAt(0) as Sprite;
         var _loc4_:int = 15;
         var _loc5_:int = 0;
         while(_loc5_ < _loc2_.numChildren)
         {
            _loc3_ = _loc2_.getChildAt(_loc5_) as BuffItem;
            _loc3_.setPosition(_loc5_ * _loc3_.getChildAt(0).width + _loc4_,_loc4_);
            _loc5_++;
         }
      }
      
      private function playSound(param1:int) : void
      {
         if(Settings.playSFX)
         {
            AudioManager.playSoundEffect(param1);
         }
      }
   }
}

