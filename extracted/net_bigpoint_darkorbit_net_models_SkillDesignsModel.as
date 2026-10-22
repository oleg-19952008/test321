package net.bigpoint.darkorbit.net.models
{
   import com.bigpoint.utils.BPLocale;
   import mx.logging.ILogger;
   import mx.logging.Log;
   import net.bigpoint.darkorbit.Main;
   import net.bigpoint.darkorbit.gui.TechCooldown;
   import net.bigpoint.darkorbit.menu.ActionButton;
   import net.bigpoint.darkorbit.menu.MenuManager;
   import net.bigpoint.darkorbit.net.ServerCommands;
   import net.bigpoint.darkorbit.net.models.skills.SkillDesignItem;
   import net.bigpoint.darkorbit.net.models.skills.SkillDesignNames;
   
   public class SkillDesignsModel
   {
      
      private static const logger:ILogger = Log.getLogger("SkillDesignsModel");
      
      public static const NUMBER_OF_SKILLS:int = 6;
      
      public var skillDesigns:Array = [];
      
      public var cooldowns:Array = [];
      
      public var main:Main;
      
      private var menuManager:MenuManager;
      
      public function SkillDesignsModel(param1:Main)
      {
         super();
         this.main = param1;
         this.menuManager = param1.getGuiManager().getMenuManager();
         var _loc2_:int = 1;
         while(_loc2_ <= NUMBER_OF_SKILLS)
         {
            this.skillDesigns[_loc2_] = new SkillDesignItem(_loc2_,param1);
            this.cooldowns[_loc2_] = new TechCooldown(_loc2_,0);
            _loc2_++;
         }
      }
      
      public function unequipAllSkills() : void
      {
         var _loc1_:int = 1;
         while(_loc1_ <= NUMBER_OF_SKILLS)
         {
            SkillDesignItem(this.skillDesigns[_loc1_]).unEquip();
            _loc1_++;
         }
      }
      
      public function setCooldown(param1:int, param2:int) : void
      {
         var _loc4_:SkillDesignItem = null;
         var _loc5_:SkillDesignItem = null;
         var _loc6_:Boolean = false;
         var _loc8_:ActionButton = null;
         var _loc3_:TechCooldown = this.cooldowns[param1] as TechCooldown;
         _loc3_.seconds = param2;
         _loc3_.startingTime = param2;
         _loc3_.update();
         _loc3_.onCompleteCallback = this.handleCooldownReached;
         if(this.skillDesigns == null)
         {
            return;
         }
         var _loc7_:int = 1;
         while(_loc7_ < this.skillDesigns.length)
         {
            _loc4_ = this.skillDesigns[_loc7_] as SkillDesignItem;
            if(_loc4_.type == param1)
            {
               _loc6_ = true;
               _loc4_.status = SkillDesignItem.STATE_COOLING;
               _loc4_.cooldownSeconds = param2;
               _loc4_.hasRunningCooldown = param2 > 0;
               _loc5_ = _loc4_;
            }
            _loc7_++;
         }
         if(_loc6_)
         {
            if(this.menuManager != null)
            {
               this.menuManager.updateTechs();
               _loc7_ = 0;
               while(_loc7_ < this.menuManager.actionButtonsWithCooldowns.length)
               {
                  _loc8_ = ActionButton(this.menuManager.actionButtonsWithCooldowns[_loc7_]);
                  if(this.menuManager.skillDesignIDTobuttonID[param1] == _loc8_.actionID)
                  {
                     this.menuManager.setActionButtonCooldownGeneric(_loc5_,_loc8_,param2);
                  }
                  _loc7_++;
               }
            }
         }
      }
      
      private function handleCooldownReached(param1:int) : void
      {
         var _loc2_:SkillDesignItem = null;
         var _loc3_:Boolean = false;
         if(this.skillDesigns == null)
         {
            return;
         }
         var _loc4_:int = 1;
         while(_loc4_ < this.skillDesigns.length)
         {
            _loc2_ = this.skillDesigns[_loc4_] as SkillDesignItem;
            if(_loc2_.type == param1)
            {
               if(_loc2_.hasRunningCooldown == true)
               {
                  _loc2_.hasRunningCooldown = false;
                  _loc2_.status = SkillDesignItem.STATE_READY;
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
      
      public function activateCurrentSkill() : void
      {
         this.main.getConnectionManager().sendCommand(ServerCommands.SKILL_DESIGNS);
      }
      
      public function logHeroMessage(param1:int, param2:Boolean) : void
      {
         switch(param1)
         {
            case SkillDesignNames.SHIP_SKILL_SOLACE:
               this.main.getGuiManager().writeToLog(BPLocale.getText("msg_instant_healed_as_activator"));
               break;
            case SkillDesignNames.SHIP_SKILL_DIMINISHER:
               if(param2)
               {
                  this.main.getGuiManager().writeToLog(BPLocale.getText("msg_targets_shields_weakened"));
               }
               else
               {
                  this.main.getGuiManager().writeToLog(BPLocale.getText("msg_targets_shields_recovered"));
               }
               break;
            case SkillDesignNames.SHIP_SKILL_SPECTRUM:
               if(param2)
               {
                  this.main.getGuiManager().writeToLog(BPLocale.getText("msg_prismatic_shielding_activated"));
               }
               else
               {
                  this.main.getGuiManager().writeToLog(BPLocale.getText("msg_prismatic_shielding_stopped"));
               }
               break;
            case SkillDesignNames.SHIP_SKILL_SENTINEL:
               if(param2)
               {
                  this.main.getGuiManager().writeToLog(BPLocale.getText("msg_fortress_activated"));
               }
               else
               {
                  this.main.getGuiManager().writeToLog(BPLocale.getText("msg_fortress_stopped"));
               }
               break;
            case SkillDesignNames.SHIP_SKILL_VENOM:
               if(param2)
               {
                  this.main.getGuiManager().writeToLog(BPLocale.getText("msg_singularity_activated"));
               }
               else
               {
                  this.main.getGuiManager().writeToLog(BPLocale.getText("msg_singularity_stopped"));
               }
               break;
            case SkillDesignNames.SHIP_SKILL_LIGHTNING:
               if(param2)
               {
                  this.main.getGuiManager().writeToLog(BPLocale.getText("msg_afterburner_activated"));
               }
               else
               {
                  this.main.getGuiManager().writeToLog(BPLocale.getText("msg_afterburner_stopped"));
               }
         }
      }
      
      public function logNonHeroMessage(param1:int, param2:Boolean) : void
      {
         switch(param1)
         {
            case SkillDesignNames.SHIP_SKILL_SOLACE:
               this.main.getGuiManager().writeToLog(BPLocale.getText("msg_instant_healed_as_group_member"));
               break;
            case SkillDesignNames.SHIP_SKILL_DIMINISHER:
               if(param2)
               {
                  this.main.getGuiManager().writeToLog(BPLocale.getText("msg_shields_weakened"));
               }
               else
               {
                  this.main.getGuiManager().writeToLog(BPLocale.getText("msg_shields_recovered"));
               }
         }
      }
   }
}

