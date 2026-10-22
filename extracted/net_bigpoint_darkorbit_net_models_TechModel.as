package net.bigpoint.darkorbit.net.models
{
   import flash.external.ExternalInterface;
   import mx.logging.ILogger;
   import mx.logging.Log;
   import net.bigpoint.darkorbit.Main;
   import net.bigpoint.darkorbit.gui.TechCooldown;
   import net.bigpoint.darkorbit.gui.TechView;
   import net.bigpoint.darkorbit.menu.MenuManager;
   import net.bigpoint.darkorbit.net.ServerCommands;
   import net.bigpoint.darkorbit.net.models.techs.TechItem;
   
   public class TechModel
   {
      
      private static const logger:ILogger = Log.getLogger("TechModel");
      
      private var main:Main;
      
      private var menuManager:MenuManager;
      
      private var techView:TechView;
      
      public var techs:Array;
      
      public var cooldowns:Array = [];
      
      public const NUMBER_OF_TECHS:int = 5;
      
      public const ENERGY_LEECH:int = 1;
      
      public const CHAIN_BOLT:int = 2;
      
      public const ROCKET_PRECISION:int = 3;
      
      public const SHIELD_BACKUP:int = 4;
      
      public const BATTLE_REP_BOT:int = 5;
      
      public const SPEED_LEECH:int = 6;
      
      public var techItemSlotReference:Array = [];
      
      public function TechModel(param1:Main)
      {
         super();
         this.main = param1;
         this.menuManager = param1.getGuiManager().getMenuManager();
         var _loc2_:int = 1;
         while(_loc2_ <= this.NUMBER_OF_TECHS)
         {
            this.cooldowns[_loc2_] = new TechCooldown(_loc2_,0);
            _loc2_++;
         }
      }
      
      public function setCooldown(param1:int, param2:int) : void
      {
         var _loc4_:TechItem = null;
         var _loc5_:Boolean = false;
         var _loc3_:TechCooldown = this.cooldowns[param1] as TechCooldown;
         _loc3_.seconds = param2;
         _loc3_.startingTime = param2;
         _loc3_.update();
         _loc3_.onCompleteCallback = this.handleCooldownReached;
         if(this.techs == null)
         {
            return;
         }
         var _loc6_:int = 1;
         while(_loc6_ < this.techs.length)
         {
            _loc4_ = this.techs[_loc6_] as TechItem;
            if(_loc4_.type == param1)
            {
               _loc5_ = true;
               _loc4_.cooldownSeconds = param2;
               _loc4_.hasRunningCooldown = param2 > 0;
            }
            _loc6_++;
         }
         if(_loc5_)
         {
            if(this.menuManager != null)
            {
               this.menuManager.updateTechs();
               this.menuManager.setActionButtonCooldown(param1,param2);
            }
         }
      }
      
      private function handleCooldownReached(param1:int) : void
      {
         var _loc2_:TechItem = null;
         var _loc3_:Boolean = false;
         if(this.techs == null)
         {
            return;
         }
         var _loc4_:int = 1;
         while(_loc4_ < this.techs.length)
         {
            _loc2_ = this.techs[_loc4_] as TechItem;
            if(_loc2_.type == param1)
            {
               if(_loc2_.hasRunningCooldown == true)
               {
                  _loc2_.hasRunningCooldown = false;
                  _loc3_ = true;
               }
            }
            _loc4_++;
         }
         if(_loc3_)
         {
            if(this.menuManager != null)
            {
               this.menuManager.updateTechs();
            }
         }
      }
      
      public function setItems(param1:Array) : void
      {
         var _loc2_:Boolean = false;
         var _loc3_:Boolean = false;
         var _loc4_:Boolean = false;
         var _loc5_:TechItem = null;
         var _loc6_:TechItem = null;
         this.menuManager = this.main.getGuiManager().getMenuManager();
         if(this.techs == null)
         {
            this.techs = [];
            _loc2_ = true;
         }
         var _loc7_:int = 0;
         while(_loc7_ < param1.length)
         {
            _loc5_ = param1[_loc7_] as TechItem;
            if(_loc5_.type != 0)
            {
               _loc4_ = true;
            }
            _loc6_ = this.techs[_loc5_.type] as TechItem;
            if(_loc6_ != null)
            {
               if((_loc6_.status == TechItem.STATE_READY || _loc6_.status == TechItem.STATE_ACTIVE) && _loc5_.status == TechItem.STATE_INACTIVE)
               {
                  _loc3_ = true;
               }
               _loc2_ = _loc6_.updateValues(_loc5_) || _loc2_;
            }
            else
            {
               this.techs[_loc5_.type] = _loc5_;
               _loc2_ = true;
            }
            (this.techs[_loc5_.type] as TechItem).hasRunningCooldown = (this.cooldowns[_loc5_.type] as TechCooldown).isRunning;
            (this.techs[_loc5_.type] as TechItem).cooldownSeconds = (this.cooldowns[_loc5_.type] as TechCooldown).seconds;
            _loc7_++;
         }
         if(_loc3_)
         {
            if(ExternalInterface.available)
            {
               ExternalInterface.call("onTechExpired");
            }
         }
         if(_loc2_ && _loc4_)
         {
            if(this.menuManager != null)
            {
               this.menuManager.updateTechs();
            }
         }
         this.updateTechSlotReference();
         if(this.main.getGuiManager().getMenuManager() != null)
         {
            this.main.getGuiManager().getMenuManager().updateTechs();
         }
      }
      
      public function updateTechSlotReference() : void
      {
         var _loc1_:TechItem = null;
         this.techItemSlotReference = [];
         for each(_loc1_ in this.techs)
         {
            this.techItemSlotReference[_loc1_.type] = _loc1_.slot;
         }
      }
      
      public function activateTechByID(param1:int) : void
      {
         this.main.getConnectionManager().sendCommand(ServerCommands.TECHS,[param1]);
      }
      
      public function activateTechInSlot(param1:int) : void
      {
         this.main.getConnectionManager().sendCommand(ServerCommands.TECHS,[param1]);
      }
   }
}

