package net.bigpoint.darkorbit.net
{
   import flash.utils.Dictionary;
   import net.bigpoint.darkorbit.Main;
   import net.bigpoint.darkorbit.map.Map;
   import net.bigpoint.darkorbit.net.models.TechModel;
   import net.bigpoint.darkorbit.net.models.techs.TechItem;
   import net.bigpoint.darkorbit.net.models.techs.TechNames;
   import net.bigpoint.darkorbit.pattern.EffectPattern;
   import net.bigpoint.darkorbit.ship.MapObject;
   import net.bigpoint.darkorbit.ship.effects.BattleRepBotTechEffect;
   import net.bigpoint.darkorbit.ship.effects.EffectIDList;
   import net.bigpoint.darkorbit.ship.effects.EffectsManager;
   import net.bigpoint.darkorbit.ship.effects.EnergyLeechTechEffect;
   import net.bigpoint.darkorbit.ship.effects.ShieldBackupTechEffect;
   
   public class TechAssembly extends BaseAssembly
   {
      
      private static var instance:TechAssembly;
      
      private static const TECH_ATTRIBUTES_COUNT:int = 3;
      
      private var map:Map;
      
      private var delegateDict:Dictionary;
      
      private var techModel:TechModel;
      
      private var main:Main;
      
      private var effectsManager:EffectsManager = EffectsManager.getInstance();
      
      public function TechAssembly(param1:Function)
      {
         super();
         if(param1 !== hidden)
         {
            throw new Error("TechAssembly is a Singleton and can only be accessed through TechAssembly.getInstance()");
         }
         this.main = _main;
         this.techModel = new TechModel(this.main);
         this.main.getGuiManager().techModel = this.techModel;
         this.initDelegateDict();
      }
      
      public static function getInstance() : TechAssembly
      {
         if(instance == null)
         {
            instance = new TechAssembly(hidden);
         }
         return instance;
      }
      
      private static function hidden() : void
      {
      }
      
      private function initDelegateDict() : void
      {
         this.delegateDict = new Dictionary();
         this.delegateDict[ServerCommands.SET_STATUS] = this.assembleSetStatusCommand;
         this.delegateDict[ServerCommands.CHAIN_BOLT] = this.assembleChainBoltCommand;
         this.delegateDict[ServerCommands.TECHS_ACTIVATE] = this.assembleActivateCommand;
         this.delegateDict[ServerCommands.TECHS_DEACTIVATE] = this.assembleDeactivateCommand;
      }
      
      public function assembleCommand(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         if(this.delegateDict[_loc2_] != null)
         {
            this.delegateDict[_loc2_](param1);
         }
      }
      
      public function assembleCooldownCommand(param1:String, param2:int) : void
      {
         var _loc3_:int = TechNames.getTypeByCode(param1);
         if(_loc3_ > 0)
         {
            this.techModel.setCooldown(_loc3_,param2);
         }
      }
      
      public function assembleSubCommand(param1:Array) : void
      {
         var _loc2_:String = param1[3];
         if(this.delegateDict[_loc2_] != null)
         {
            this.delegateDict[_loc2_](param1);
         }
      }
      
      private function assembleChainBoltCommand(param1:Array) : void
      {
         var _loc2_:int = int(param1[4]);
         var _loc3_:Array = [int(param1[5])];
         var _loc4_:int = 6;
         while(_loc4_ < param1.length)
         {
            if(param1[_loc4_] != undefined)
            {
               _loc3_.push(int(param1[_loc4_]));
            }
            _loc4_++;
         }
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            this.map.getCombatManager().addChainBoltAttack(_loc2_,_loc3_);
         }
      }
      
      private function assembleDeactivateCommand(param1:Array) : void
      {
         this.map = this.main.screenManager.map;
         var _loc2_:String = param1[4];
         var _loc3_:int = int(param1[5]);
         var _loc4_:MapObject = this.map.getShipManager().getShip(_loc3_);
         if(_loc4_ == null)
         {
            return;
         }
         switch(_loc2_)
         {
            case ServerCommands.TECH_ENERGY_LEECH:
               _loc4_.energyLeechActive = false;
               _loc4_.toggleEnergyLeechEffect(0);
               this.effectsManager.removeEffectByIdFromEntity(_loc4_,EffectIDList.TECH_ENERGY_LEECH_EFFECT);
               break;
            case ServerCommands.TECH_BATTLE_REP_BOT:
               this.effectsManager.removeEffectByIdFromEntity(_loc4_,EffectIDList.TECH_BATTLE_REP_BOT_EFFECT);
         }
      }
      
      private function assembleActivateCommand(param1:Array) : void
      {
         var _loc5_:ShieldBackupTechEffect = null;
         var _loc6_:EnergyLeechTechEffect = null;
         var _loc7_:BattleRepBotTechEffect = null;
         this.map = this.main.screenManager.map;
         var _loc2_:String = param1[4];
         var _loc3_:int = int(param1[5]);
         var _loc4_:MapObject = this.map.getShipManager().getShip(_loc3_);
         if(_loc4_ == null)
         {
            return;
         }
         switch(_loc2_)
         {
            case ServerCommands.TECH_SHIELD_BACK_UP:
               _loc5_ = new ShieldBackupTechEffect(EffectIDList.TECH_SHIELD_BACKUP_EFFECT,new EffectPattern(EffectIDList.TECH_SHIELD_BACKUP_EFFECT,"shield1"));
               _loc5_.resizeMC(Math.max(_loc4_.shipClip.height,_loc4_.shipClip.width) * 0.5 / 65);
               this.effectsManager.addEffect(_loc5_,_loc4_,EffectsManager.TIMEOUT_EFFECT);
               break;
            case ServerCommands.TECH_ENERGY_LEECH:
               _loc4_.energyLeechActive = true;
               _loc6_ = new EnergyLeechTechEffect(EffectIDList.TECH_ENERGY_LEECH_EFFECT,new EffectPattern(EffectIDList.TECH_ENERGY_LEECH_EFFECT,"ela0"));
               this.effectsManager.addEffect(_loc6_,_loc4_,EffectsManager.NORMAL_EFFECT);
               break;
            case ServerCommands.TECH_BATTLE_REP_BOT:
               _loc7_ = new BattleRepBotTechEffect(EffectIDList.TECH_BATTLE_REP_BOT_EFFECT,new EffectPattern(EffectIDList.TECH_BATTLE_REP_BOT_EFFECT,"battleRepairRobot1"));
               this.effectsManager.addEffect(_loc7_,_loc4_,EffectsManager.NORMAL_EFFECT);
         }
      }
      
      private function assembleSetStatusCommand(param1:Array) : void
      {
         var _loc3_:TechItem = null;
         var _loc2_:Array = [];
         var _loc4_:int = 1;
         var _loc5_:int = 3;
         while(_loc5_ < param1.length)
         {
            _loc3_ = new TechItem();
            _loc3_.type = _loc4_;
            if(int(param1[_loc5_] == 4))
            {
               _loc3_.status = 0;
            }
            else
            {
               _loc3_.status = int(param1[_loc5_]);
            }
            _loc3_.amount = int(param1[_loc5_ + 1]);
            _loc3_.secondsLeft = int(param1[_loc5_ + 2]);
            _loc3_.updateName();
            _loc2_.push(_loc3_);
            _loc4_++;
            _loc5_ += TECH_ATTRIBUTES_COUNT;
         }
         this.techModel.setItems(_loc2_);
      }
   }
}

