package net.bigpoint.darkorbit.net
{
   import flash.utils.Dictionary;
   import net.bigpoint.darkorbit.Hero;
   import net.bigpoint.darkorbit.Main;
   import net.bigpoint.darkorbit.gui.GuiManager;
   import net.bigpoint.darkorbit.map.Map;
   import net.bigpoint.darkorbit.menu.MenuManager;
   import net.bigpoint.darkorbit.net.models.SkillDesignsModel;
   import net.bigpoint.darkorbit.net.models.skills.SkillDesignAbilities;
   import net.bigpoint.darkorbit.net.models.skills.SkillDesignItem;
   import net.bigpoint.darkorbit.net.models.skills.SkillDesignNames;
   import net.bigpoint.darkorbit.pattern.EffectPattern;
   import net.bigpoint.darkorbit.ship.MapObject;
   import net.bigpoint.darkorbit.ship.effects.EffectBase;
   import net.bigpoint.darkorbit.ship.effects.EffectsManager;
   import net.bigpoint.darkorbit.ship.effects.SkillEffect;
   
   public class SkillsAssembly extends BaseAssembly
   {
      
      private static var instance:SkillsAssembly;
      
      private var map:Map;
      
      private var delegateDict:Dictionary;
      
      private var skillDesignsModel:SkillDesignsModel;
      
      private var guiManager:GuiManager;
      
      private var menuManager:MenuManager;
      
      private var effectsManager:EffectsManager = EffectsManager.getInstance();
      
      private var main:Main;
      
      public function SkillsAssembly(param1:Function)
      {
         super();
         if(param1 !== hidden)
         {
            throw new Error("SkillsAssembly is a Singleton and can only be accessed through SkillsAssembly.getInstance()");
         }
         this.main = _main;
         this.skillDesignsModel = new SkillDesignsModel(this.main);
         this.guiManager = this.main.getGuiManager();
         this.menuManager = this.guiManager.getMenuManager();
         this.guiManager.skillDesignsModel = this.skillDesignsModel;
         this.initDelegateDict();
      }
      
      public static function getInstance() : SkillsAssembly
      {
         if(instance == null)
         {
            instance = new SkillsAssembly(hidden);
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
         this.delegateDict[ServerCommands.SKILLS_ACTIVATE] = this.assembleActivateCommand;
         this.delegateDict[ServerCommands.SKILLS_DEACTIVATE] = this.assembleDeactivateCommand;
         this.delegateDict[ServerCommands.REMOVE_SKILL_FX] = this.assembleRemoveCommand;
      }
      
      public function assembleSubCommand(param1:Array) : void
      {
         var _loc2_:String = param1[3];
         if(this.delegateDict[_loc2_] != null)
         {
            this.delegateDict[_loc2_](param1);
         }
      }
      
      public function assembleCommand(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         if(this.delegateDict[_loc2_] != null)
         {
            this.delegateDict[_loc2_](param1);
         }
      }
      
      private function assembleRemoveCommand(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = int(param1[4]);
         this.main.screenManager.map.getShipManager().getShip(_loc3_).getShipDecorator().stopAnimation(SkillDesignAbilities.getSkillAbilityBySkillID(_loc2_));
      }
      
      private function assembleSetStatusCommand(param1:Array) : void
      {
         var _loc2_:SkillDesignItem = null;
         _loc2_ = this.skillDesignsModel.skillDesigns[param1[3]];
         var _loc3_:int = int(param1[3]);
         var _loc4_:int = int(param1[4]);
         var _loc5_:int = int(param1[5]);
         if(_loc2_ == null)
         {
            return;
         }
         var _loc6_:MenuManager = this.guiManager.getMenuManager();
         if(_loc3_ == 0 && _loc4_ == 0)
         {
            this.skillDesignsModel.unequipAllSkills();
            this.menuManager.updateSelectedMenu();
            this.menuManager.updateTechs();
            _loc6_.updateSelectedMenu();
            _loc6_.updateTechs();
            return;
         }
         this.skillDesignsModel.unequipAllSkills();
         _loc2_.setEquipped();
         _loc2_.status = _loc4_;
         _loc2_.secondsLeft = _loc5_;
         if(this.menuManager != null)
         {
            this.menuManager.updateSelectedMenu();
            this.menuManager.updateTechs();
         }
         if(_loc6_ != null)
         {
            _loc6_.updateSelectedMenu();
            _loc6_.updateTechs();
         }
         var _loc7_:String = SkillDesignAbilities.getSkillAbilityBySkillID(_loc2_.type);
         if(_loc7_ != null && this.main.screenManager.map != null)
         {
         }
      }
      
      private function assembleActivateCommand(param1:Array) : void
      {
         var _loc8_:EffectBase = null;
         var _loc9_:MapObject = null;
         var _loc10_:int = 0;
         var _loc2_:int = int(param1[4]);
         var _loc3_:int = int(param1[5]);
         var _loc4_:Array = param1.splice(6,param1.length);
         var _loc5_:Boolean = param1.length > 5;
         var _loc6_:Boolean = false;
         if(_loc3_ == Hero.userID)
         {
            _loc6_ = true;
            this.skillDesignsModel.skillDesigns[_loc2_].status = SkillDesignItem.STATE_ACTIVE;
            this.skillDesignsModel.logHeroMessage(_loc2_,true);
         }
         else
         {
            this.skillDesignsModel.logNonHeroMessage(_loc2_,true);
         }
         var _loc7_:MapObject = this.main.screenManager.map.getShipManager().getShip(_loc3_);
         if(_loc7_ != null)
         {
            if(!this.effectsManager.doesEffectExistOn(_loc7_,SkillDesignNames.getEffectIDByCode(_loc2_)))
            {
               this.createEffectInEffectsManagerFor(_loc7_,_loc2_);
            }
            if(_loc2_ != SkillDesignNames.SHIP_SKILL_SPECTRUM)
            {
               _loc8_ = this.effectsManager.getEffectFromEntity(_loc7_,SkillDesignNames.getEffectIDByCode(_loc2_));
               if(_loc8_.pattern.resKey == SkillDesignAbilities.SHIP_INSTANT_HEAL_NAME)
               {
                  SkillEffect(_loc8_).startSolaceInstantAnimation();
               }
               else
               {
                  _loc8_.start();
               }
            }
         }
         if(_loc5_)
         {
            _loc10_ = 0;
            while(_loc10_ < _loc4_.length)
            {
               _loc9_ = this.main.screenManager.map.getShipManager().getShip(int(_loc4_[_loc10_]));
               if(_loc9_ != null)
               {
                  if(!this.effectsManager.doesEffectExistOn(_loc9_,SkillDesignNames.getEffectIDByCode(_loc2_)))
                  {
                     this.createEffectInEffectsManagerFor(_loc9_,_loc2_);
                  }
                  _loc8_ = this.effectsManager.getEffectFromEntity(_loc9_,SkillDesignNames.getEffectIDByCode(_loc2_));
                  if(_loc8_.pattern.resKey == SkillDesignAbilities.SHIP_INSTANT_HEAL_NAME)
                  {
                     SkillEffect(_loc8_).startSolaceInstantAnimation();
                  }
                  else
                  {
                     _loc8_.start();
                  }
               }
               _loc10_++;
            }
         }
         this.main.getGuiManager().getMenuManager().updateTechs();
      }
      
      private function createEffectInEffectsManagerFor(param1:MapObject, param2:int) : void
      {
         var _loc3_:String = SkillDesignAbilities.getSkillAbilityBySkillID(param2);
         var _loc4_:EffectPattern = new EffectPattern(param2,_loc3_);
         var _loc5_:SkillEffect = new SkillEffect(SkillDesignNames.getEffectIDByCode(param2),_loc4_,param1);
         this.effectsManager.addEffect(_loc5_,param1,EffectsManager.ROTATION_DEPENDANT_EFFECT);
      }
      
      private function assembleDeactivateCommand(param1:Array) : void
      {
         var _loc8_:EffectBase = null;
         var _loc9_:MapObject = null;
         var _loc10_:int = 0;
         var _loc2_:int = int(param1[4]);
         var _loc3_:int = int(param1[5]);
         var _loc4_:Array = param1.splice(6,param1.length);
         var _loc5_:Boolean = param1.length > 5;
         var _loc6_:Boolean = false;
         if(_loc3_ == Hero.userID)
         {
            _loc6_ = true;
            SkillDesignItem(this.skillDesignsModel.skillDesigns[_loc2_]).status = SkillDesignItem.STATE_READY;
            this.skillDesignsModel.logHeroMessage(_loc2_,false);
         }
         else
         {
            this.skillDesignsModel.logNonHeroMessage(_loc2_,false);
         }
         var _loc7_:MapObject = this.main.screenManager.map.getShipManager().getShip(_loc3_);
         if(_loc7_ != null)
         {
            _loc7_.getShipDecorator().stopAnimation(SkillDesignAbilities.getSkillAbilityBySkillID(_loc2_));
            _loc8_ = this.effectsManager.getEffectFromEntity(_loc7_,SkillDesignNames.getEffectIDByCode(_loc2_));
            _loc8_.stop();
         }
         if(_loc5_)
         {
            _loc10_ = 0;
            while(_loc10_ < _loc4_.length)
            {
               _loc9_ = this.main.screenManager.map.getShipManager().getShip(int(_loc4_[_loc10_]));
               if(_loc9_ != null)
               {
                  _loc8_ = this.effectsManager.getEffectFromEntity(_loc9_,SkillDesignNames.getEffectIDByCode(_loc2_));
                  _loc8_.stop();
               }
               _loc10_++;
            }
         }
         if(this.menuManager != null)
         {
            this.menuManager.updateTechs();
         }
      }
      
      public function assembleCooldownCommand(param1:String, param2:int) : void
      {
         var _loc3_:int = SkillDesignNames.getTypeByCode(param1);
         if(_loc3_ > 0)
         {
            this.skillDesignsModel.setCooldown(_loc3_,param2);
         }
      }
   }
}

