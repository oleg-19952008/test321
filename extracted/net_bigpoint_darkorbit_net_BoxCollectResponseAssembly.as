package net.bigpoint.darkorbit.net
{
   import com.bigpoint.utils.BPLocale;
   import flash.utils.Dictionary;
   import net.bigpoint.darkorbit.Hero;
   import net.bigpoint.darkorbit.InGameCatalog;
   import net.bigpoint.darkorbit.Main;
   import net.bigpoint.darkorbit.collectable.CollectableManager;
   import net.bigpoint.darkorbit.config.items.SysItem;
   import net.bigpoint.darkorbit.gui.LogMessageProfileFactory;
   import net.bigpoint.darkorbit.gui.container.SimpleContainer;
   import net.bigpoint.darkorbit.gui.elements.SimpleElement;
   import net.bigpoint.darkorbit.gui.windows.SimpleWindow;
   import net.bigpoint.darkorbit.map.Map;
   import net.bigpoint.darkorbit.pattern.PatternManager;
   import net.bigpoint.darkorbit.ship.MapObject;
   import net.bigpoint.darkorbit.ship.effects.CollectorBeamEffect;
   import net.bigpoint.darkorbit.ship.effects.EffectBase;
   import net.bigpoint.darkorbit.ship.effects.EffectIDList;
   import net.bigpoint.darkorbit.ship.effects.EffectsManager;
   import net.bigpoint.darkorbit.ship.effects.EntityEffectEvent;
   import net.bigpoint.darkorbit.vo.ItemSysMine;
   
   public class BoxCollectResponseAssembly extends BaseAssembly
   {
      
      private static var _instance:BoxCollectResponseAssembly;
      
      private var param1:String;
      
      private var param2:String;
      
      private var delegateDict:Dictionary;
      
      private var mineTypesDict:Dictionary;
      
      private var main:Main;
      
      private var effectsManager:EffectsManager = EffectsManager.getInstance();
      
      public function BoxCollectResponseAssembly(param1:Function)
      {
         super();
         if(param1 !== hidden)
         {
            throw new Error("SettingsAssembly is a Singleton and can only be accessed through BoxCollectResponseAssembly.getInstance()");
         }
         this.main = _main;
         this.initDelegateDict();
      }
      
      public static function getInstance() : BoxCollectResponseAssembly
      {
         if(_instance == null)
         {
            _instance = new BoxCollectResponseAssembly(hidden);
         }
         return _instance;
      }
      
      private static function hidden() : void
      {
      }
      
      private function initDelegateDict() : void
      {
         this.delegateDict = new Dictionary();
         this.delegateDict[ServerCommands.BOX_CONTENT_ORE] = this.assembleOre;
         this.delegateDict[ServerCommands.BOX_CONTENT_JACKPOT] = this.assembleJackpot;
         this.delegateDict[ServerCommands.BOX_CONTENT_CREDITS] = this.assembleCredits;
         this.delegateDict[ServerCommands.BOX_CONTENT_URIDIUM] = this.assembleUridium;
         this.delegateDict[ServerCommands.BOX_CONTENT_EXPERIENCE_POINTS] = this.assembleExperiencePoints;
         this.delegateDict[ServerCommands.BOX_CONTENT_HONOR_POINTS] = this.assembleHonorPoints;
         this.delegateDict[ServerCommands.BOX_CONTENT_HITPOINTS] = this.assembleHitPoints;
         this.delegateDict[ServerCommands.BOX_CONTENT_FIREWORK] = this.assembleFireworks;
         this.delegateDict[ServerCommands.BOX_CONTENT_ROCKETS] = this.assembleRockets;
         this.delegateDict[ServerCommands.BOX_CONTENT_LASER_BATTERIES] = this.assembleLaserBatteries;
         this.delegateDict[ServerCommands.BOX_CONTENT_BANKING_MULTIPLIKATOR] = this.assembleBankingMultiplier;
         this.delegateDict[ServerCommands.BOX_CONTENT_DEDUCTION_HITPOINTS] = this.assembleHitpointDeduct;
         this.delegateDict[ServerCommands.BOX_CONTENT_EXTRA_ENERGY] = this.assembleExtraEnergy;
         this.delegateDict[ServerCommands.BOX_CONTENT_JUMP_VOUCHERS] = this.assembleJumpVoucherLoot;
         this.delegateDict[ServerCommands.BOX_CONTENT_MINE] = this.assembleMineLoot;
         this.delegateDict[ServerCommands.BOX_CONTENT_PET_FUEL] = this.assemblePetFuelLoot;
         this.delegateDict[ServerCommands.ITEM_LOOT] = this.assembleItemLoot;
         this.delegateDict[ServerCommands.BOX_TOO_BIG] = this.assembleBoxTooBig;
         this.delegateDict[ServerCommands.BOX_ALREADY_COLLECTED] = this.assembleAlreadyCollectedBox;
         this.delegateDict[ServerCommands.MINE_EXPLODE] = this.assembleMineExplode;
         this.delegateDict[ServerCommands.AVAILABLE_SHIPS_ON_MAP] = this.assembleAvailableShipsOnMap;
         this.delegateDict[ServerCommands.ROCKETLAUNCHER] = this.assembleRocketLauncher;
         this.delegateDict[ServerCommands.LOGFILE] = this.assembleLogFile;
         this.delegateDict[ServerCommands.DISCOUNT_MESSAGE] = this.assembleDiscountMessage;
         this.delegateDict[ServerCommands.SET_ITEM_LOOTING_ACTIVE] = this.assembleItemLootActive;
         this.delegateDict[ServerCommands.SET_ITEM_LOOTING_CANCELLED] = this.assembleItemLootCancelling;
         this.mineTypesDict = new Dictionary();
         this.mineTypesDict[ServerCommands.MINE_ACM] = new ItemSysMine("mine_acm-01","ACM-01");
         this.mineTypesDict[ServerCommands.MINE_DDM] = new ItemSysMine("mine_ddm-01","DDM-01");
         this.mineTypesDict[ServerCommands.MINE_EMP] = new ItemSysMine("mine_empm-01","EMPM-01");
         this.mineTypesDict[ServerCommands.MINE_SAB] = new ItemSysMine("mine_sabm-01","SABM-01");
         this.delegateDict[ServerCommands.NEWBIE_BOOSTER] = this.assembleBoosterMessage;
      }
      
      private function assembleBoosterMessage(param1:Array) : void
      {
         var _loc5_:String = null;
         var _loc2_:String = param1[2];
         var _loc3_:String = param1[4];
         var _loc4_:int = int(param1[5]);
         switch(_loc3_)
         {
            case ServerCommands.BOOSTER_QUEST_REWARD:
               _loc5_ = "msg_info_booster_quest_reward_higher_loot_level";
               break;
            case ServerCommands.BOOSTER_BONUS_BOX:
               _loc5_ = "msg_info_booster_bonus_box_higher_box_content_level";
         }
         if(_loc4_ > 0)
         {
            this.main.getGuiManager().writeToLog(BPLocale.getText(_loc5_).replace(/%AMOUNT%/,_loc4_),_loc2_);
         }
      }
      
      private function assembleDiscountMessage(param1:Array) : void
      {
         var _loc5_:String = null;
         var _loc2_:String = param1[2];
         var _loc3_:String = param1[4];
         var _loc4_:int = int(param1[5]);
         switch(_loc3_)
         {
            case ServerCommands.LOOT_DISCOUNT:
               if(_loc4_ > 0)
               {
                  _loc5_ = "msg_warning_less_box_content_level";
               }
               else
               {
                  _loc5_ = "msg_warning_no_box_content_level";
               }
               break;
            case ServerCommands.REWARD_DISCOUNT:
               if(_loc4_ > 0)
               {
                  _loc5_ = "msg_warning_less_loot_level";
               }
               else
               {
                  _loc5_ = "msg_warning_no_loot_level";
               }
         }
         this.main.getGuiManager().writeToLog(BPLocale.getText(_loc5_).replace(/%AMOUNT%/,_loc4_),_loc2_);
      }
      
      private function assembleLogFile(param1:Array) : void
      {
         var _loc5_:String = null;
         var _loc2_:int = int(param1[4]);
         var _loc3_:String = param1[2];
         var _loc4_:int = int(param1[5]);
         if(_loc2_ == 1)
         {
            _loc5_ = BPLocale.getText("log_msg_gather_log-file_s");
         }
         else
         {
            _loc5_ = BPLocale.getText("log_msg_gather_log-file_p").replace(/%COUNT%/,_loc2_);
         }
         this.main.getGuiManager().writeToLog(_loc5_,_loc3_);
      }
      
      private function assembleRocketLauncher(param1:Array) : void
      {
         var _loc5_:String = null;
         var _loc2_:int = int(param1[4]);
         var _loc3_:int = int(param1[5]);
         var _loc4_:String = param1[2];
         _loc5_ = BPLocale.getText("getbonusrok").replace(/%!/,BPLocale.roundInteger(_loc3_)).replace(/%2!/,InGameCatalog.instance.rocketNames[_loc2_]);
         this.main.getGuiManager().writeToLog(_loc5_,_loc4_);
      }
      
      private function assembleMineLoot(param1:Array) : void
      {
         var _loc6_:String = null;
         var _loc2_:String = param1[4];
         var _loc3_:int = int(param1[5]);
         var _loc4_:String = "log_msg_gather_mine_";
         var _loc5_:String = param1[2];
         if(_loc3_ == 1)
         {
            _loc6_ = BPLocale.getText(_loc4_ + "s");
         }
         else
         {
            _loc6_ = BPLocale.getText(_loc4_ + "p").replace(/%COUNT%/,BPLocale.roundInteger(_loc3_));
         }
         _loc6_ = _loc6_.replace(/%TYPE%/,(this.mineTypesDict[_loc2_] as ItemSysMine).name);
         this.main.getGuiManager().writeToLog(_loc6_,_loc5_);
      }
      
      private function assembleAvailableShipsOnMap(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         this.main.getGuiManager().writeToLog(BPLocale.getText("msg_jackpot_players_left").replace(/%COUNT%/,param1[4]),_loc2_);
      }
      
      private function assembleMineExplode(param1:Array) : void
      {
         var _loc2_:String = param1[4];
         var _loc3_:Map = this.main.screenManager.map;
         if(_loc3_ != null)
         {
            this.main.screenManager.map.getMineManager().removeMine(_loc2_,true);
         }
      }
      
      private function assembleAlreadyCollectedBox(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         var _loc3_:Map = this.main.screenManager.map;
         if(_loc3_ != null)
         {
            this.main.screenManager.map.getCollectableManager().setLastSelectedHash(null);
         }
         this.main.getGuiManager().writeToLog(BPLocale.getText("boxdisabled"),_loc2_);
      }
      
      private function assembleBoxTooBig(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         var _loc3_:Map = this.main.screenManager.map;
         if(_loc3_ != null)
         {
            this.main.screenManager.map.getCollectableManager().setLastSelectedHash(null);
         }
         this.main.getGuiManager().writeToLog(BPLocale.getText("boxtoobig"),_loc2_);
      }
      
      private function assembleExtraEnergy(param1:Array) : void
      {
         var _loc5_:String = null;
         var _loc2_:int = int(param1[4]);
         var _loc3_:String = param1[2];
         var _loc4_:String = "log_msg_gather_extra-energy_";
         if(_loc2_ > 1)
         {
            _loc5_ = BPLocale.getText(_loc4_ + "p").replace(/%COUNT%/,_loc2_);
         }
         else
         {
            _loc5_ = BPLocale.getText(_loc4_ + "s");
         }
         this.main.getGuiManager().writeToLog(_loc5_,_loc3_);
      }
      
      private function assembleJumpVoucherLoot(param1:Array) : void
      {
         var _loc5_:String = null;
         var _loc2_:int = int(param1[4]);
         var _loc3_:String = param1[2];
         var _loc4_:String = "log_msg_gather_jump-voucher_";
         if(_loc2_ == 1)
         {
            _loc5_ = BPLocale.getText(_loc4_ + "s");
         }
         else
         {
            _loc5_ = BPLocale.getText(_loc4_ + "p").replace(/%COUNT%/,_loc2_);
         }
         this.main.getGuiManager().writeToLog(_loc5_,_loc3_);
      }
      
      private function assemblePetFuelLoot(param1:Array) : void
      {
         var _loc5_:String = null;
         var _loc2_:int = int(param1[4]);
         var _loc3_:String = param1[2];
         var _loc4_:String = "log_msg_gather_pet-fuel_";
         if(_loc2_ == 1)
         {
            _loc5_ = BPLocale.getText(_loc4_ + "s");
         }
         else
         {
            _loc5_ = BPLocale.getText(_loc4_ + "p").replace(/%COUNT%/,_loc2_);
         }
         this.main.getGuiManager().writeToLog(_loc5_,_loc3_);
      }
      
      private function assembleItemLoot(param1:Array) : void
      {
         var _loc7_:String = null;
         var _loc2_:String = param1[4];
         var _loc3_:int = int(param1[5]);
         var _loc4_:String = param1[2];
         var _loc5_:String = "log_msg_gather_";
         var _loc6_:SysItem = InGameCatalog.getInstance().sysItems[_loc2_] as SysItem;
         if(_loc3_ == 1)
         {
            _loc7_ = BPLocale.getText(_loc5_ + _loc6_.category + "_s").replace(/%TYPE%/,_loc6_.name);
         }
         else
         {
            _loc7_ = BPLocale.getText(_loc5_ + _loc6_.category + "_p").replace(/%TYPE%/,_loc6_.name).replace(/%COUNT%/,BPLocale.roundInteger(_loc3_));
         }
         this.main.getGuiManager().writeToLog(_loc7_,_loc4_);
      }
      
      private function assembleItemLootActive(param1:Array) : void
      {
         var _loc5_:CollectorBeamEffect = null;
         var _loc2_:int = int(param1[4]);
         var _loc3_:MapObject = this.main.screenManager.map.getShipManager().getHero();
         if(!this.effectsManager.doesEffectExistOn(_loc3_,EffectIDList.COLLECTOR_BEAM))
         {
            _loc5_ = new CollectorBeamEffect(EffectIDList.COLLECTOR_BEAM,PatternManager.effectPatterns[EffectIDList.COLLECTOR_BEAM],false,[_loc2_,_loc3_,true]);
            this.effectsManager.addEffect(_loc5_,_loc3_,EffectsManager.BEHIND_MAP_OBJECT_EFFECT);
         }
         var _loc4_:String = BPLocale.getText("msg_loot_harvest_init");
         this.main.getGuiManager().writeToLog(_loc4_);
      }
      
      private function assembleItemLootCancelling(param1:Array) : void
      {
         var _loc2_:MapObject = this.main.screenManager.map.getShipManager().getHero();
         this.effectsManager.removeEffectByIdFromEntity(_loc2_,EffectIDList.COLLECTOR_BEAM);
         var _loc3_:String = BPLocale.getText("msg_loot_error_generic");
         this.main.getGuiManager().writeToLog(_loc3_);
      }
      
      private function handleLootComplete(param1:EntityEffectEvent) : void
      {
         var _loc2_:MapObject = this.main.screenManager.map.getShipManager().getHero();
         var _loc3_:EffectBase = this.effectsManager.getEffectFromEntity(_loc2_,EffectIDList.COLLECTOR_BEAM);
         if(_loc3_ != null)
         {
            _loc3_.removeEventListener(EntityEffectEvent.EFFECT_FINISHED,this.handleLootComplete);
         }
      }
      
      private function handleStopLooting(param1:EntityEffectEvent) : void
      {
         var _loc2_:MapObject = this.main.screenManager.map.getShipManager().getHero();
         var _loc3_:EffectBase = this.effectsManager.getEffectFromEntity(_loc2_,EffectIDList.COLLECTOR_BEAM);
         if(_loc3_ != null)
         {
            _loc3_.removeEventListener(EntityEffectEvent.EFFECT_CANCELLED,this.handleStopLooting);
         }
      }
      
      private function assembleHitpointDeduct(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         var _loc3_:int = int(param1[4]);
         this.main.getGuiManager().writeToLog(BPLocale.getText("minushp").replace(this.param1,_loc3_),_loc2_);
      }
      
      private function assembleBankingMultiplier(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         var _loc3_:int = int(param1[4]);
         this.main.getGuiManager().writeToLog(BPLocale.getText("banking_multiplier_active").replace(this.param1,_loc3_),_loc2_);
      }
      
      private function assembleLaserBatteries(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         var _loc3_:int = parseInt(param1[4]);
         var _loc4_:int = int(param1[5]);
         this.main.getGuiManager().writeToLog(BPLocale.getText("getbonuslas").replace(this.param1,_loc4_).replace(this.param2,InGameCatalog.instance.battery_types[_loc3_]),_loc2_);
      }
      
      private function assembleRockets(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         var _loc3_:int = int(param1[4]);
         var _loc4_:int = int(param1[5]);
         this.main.getGuiManager().writeToLog(BPLocale.getText("getbonusrok").replace(this.param1,_loc4_).replace(this.param2,InGameCatalog.instance.rocketNames[_loc3_]),_loc2_);
      }
      
      private function assembleFireworks(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         var _loc3_:int = int(param1[4]);
         var _loc4_:int = int(param1[5]);
         this.main.getGuiManager().writeToLog(BPLocale.getText("log_collected_firework").replace(this.param1,_loc4_).replace(this.param2,InGameCatalog.instance.explosive_types[_loc3_]),_loc2_);
      }
      
      private function assembleHitPoints(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         var _loc3_:Number = parseFloat(param1[4]);
         this.main.getGuiManager().writeToLog(BPLocale.getText("gethp").replace(this.param1,_loc3_),_loc2_);
      }
      
      private function assembleHonorPoints(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         var _loc3_:Number = Number(param1[4]);
         this.main.getGuiManager().writeToLog(BPLocale.getText("gatherep").replace(this.param1,_loc3_),_loc2_);
         Hero.honorPoints = param1[5];
         this.updateInfoField(SimpleWindow.WINDOW_CLASS_USER,SimpleContainer.CONTAINER_CLASS_HERO_INFO_2,SimpleElement.TYPE_HONOR);
      }
      
      private function assembleExperiencePoints(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         var _loc3_:Number = parseFloat(param1[4]);
         this.main.getGuiManager().writeToLog(BPLocale.getText("getexp").replace(this.param1,BPLocale.roundInteger(_loc3_)),_loc2_);
         Hero.experiencePoints = parseFloat(param1[5]);
         this.updateInfoField(SimpleWindow.WINDOW_CLASS_USER,SimpleContainer.CONTAINER_CLASS_HERO_INFO_2,SimpleElement.TYPE_EXPERIENCE);
         Hero.level = int(param1[6]);
         this.updateInfoField(SimpleWindow.WINDOW_CLASS_USER,SimpleContainer.CONTAINER_CLASS_HERO_INFO_2,SimpleElement.TYPE_LEVEL);
      }
      
      private function assembleUridium(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         var _loc3_:Number = parseFloat(param1[4]);
         this.main.getGuiManager().writeToLog(BPLocale.getText("geturidium").replace(this.param1,BPLocale.roundInteger(_loc3_)),_loc2_);
         Hero.uridiumAmount = parseFloat(param1[5]);
         this.updateInfoField(SimpleWindow.WINDOW_CLASS_USER,SimpleContainer.CONTAINER_CLASS_HERO_INFO_3,SimpleElement.TYPE_URIDIUM);
      }
      
      private function assembleCredits(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         var _loc3_:Number = parseFloat(param1[4]);
         this.main.getGuiManager().writeToLog(BPLocale.getText("getcredits").replace(this.param1,BPLocale.roundInteger(_loc3_)),_loc2_);
         Hero.creditsAmount = Number(param1[5]);
         this.updateInfoField(SimpleWindow.WINDOW_CLASS_USER,SimpleContainer.CONTAINER_CLASS_HERO_INFO_3,SimpleElement.TYPE_CREDITS);
      }
      
      private function assembleJackpot(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         var _loc3_:Number = parseFloat(param1[4]);
         this.main.getGuiManager().writeToLog(BPLocale.getText("getjackpot").replace(this.param1,BPLocale.round(_loc3_,2)),_loc2_);
         Hero.jackpotAmount = parseFloat(param1[5]);
         this.updateInfoField(SimpleWindow.WINDOW_CLASS_USER,SimpleContainer.CONTAINER_CLASS_HERO_INFO_3,SimpleElement.TYPE_JACKPOT);
      }
      
      private function assembleOre(param1:Array) : void
      {
         var _loc7_:int = 0;
         var _loc2_:String = param1[2];
         var _loc3_:String = BPLocale.getText("farmresult");
         var _loc4_:int = 4;
         var _loc5_:int = 11;
         var _loc6_:int = _loc4_;
         while(_loc6_ < _loc5_)
         {
            _loc7_ = int(param1[_loc6_]);
            if(_loc7_ > 0)
            {
               _loc3_ += "\n" + _loc7_ + " " + BPLocale.getText(CollectableManager.loot_ore_keys[_loc6_ - _loc4_]);
            }
            _loc6_++;
         }
         if(_loc3_.length != BPLocale.getText("farmresult").length)
         {
            this.main.getGuiManager().writeToLog(_loc3_,_loc2_);
         }
      }
      
      private function updateInfoField(param1:int, param2:int, param3:int) : void
      {
         this.main.getGuiManager().updateInfoField(param1,param2,param3);
      }
      
      public function assembleBoxCollectResponse(param1:Array) : void
      {
         var _loc3_:String = null;
         param1 = this.formatLegacy(param1);
         var _loc2_:String = param1[3];
         if(this.delegateDict[_loc2_] != null)
         {
            this.delegateDict[_loc2_](param1);
         }
         else
         {
            _loc3_ = BPLocale.getText(_loc2_);
            if(_loc3_.length > 0)
            {
               this.main.getGuiManager().writeToLog(_loc3_,param1[2]);
            }
         }
      }
      
      private function formatLegacy(param1:Array) : Array
      {
         if(param1[1] == ServerCommands.BOX_COLLECT_RESPONSE)
         {
            param1[0] = ServerCommands.LOG_MESSAGE;
            param1[1] = LogMessageProfileFactory.STANDARD_MESSAGE;
            param1.unshift("0");
         }
         return param1;
      }
      
      public function setParams(param1:String, param2:String) : void
      {
         this.param1 = param1;
         this.param2 = param2;
      }
   }
}

