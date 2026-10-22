package net.bigpoint.darkorbit.net.models.skills
{
   import net.bigpoint.darkorbit.Hero;
   import net.bigpoint.darkorbit.Main;
   import net.bigpoint.darkorbit.gui.CoolDown;
   import net.bigpoint.darkorbit.menu.IAbilityItem;
   
   public class SkillDesignItem implements IAbilityItem
   {
      
      public static const STATE_READY:int = 1;
      
      public static const STATE_ACTIVE:int = 2;
      
      public static const STATE_COOLING:int = 3;
      
      public static const STATE_OFF_FOR_SHORTCUT_BUTTONS:int = 3;
      
      public var type:int;
      
      public var status:int;
      
      public var cooldown:CoolDown;
      
      public var equipped:Boolean = false;
      
      public var main:Main;
      
      public var secondsLeft:Number;
      
      public var name:String;
      
      public var cooldownSeconds:int = 15;
      
      public var hasRunningCooldown:Boolean;
      
      public function SkillDesignItem(param1:int, param2:Main)
      {
         super();
         this.main = param2;
         this.type = param1;
         this.name = SkillDesignNames.getNameByType(this.type);
      }
      
      public function setEquipped() : void
      {
         this.equipped = true;
         Hero.skills[this.type] = true;
      }
      
      public function unEquip() : void
      {
         this.equipped = false;
         Hero.skills[this.type] = false;
      }
      
      public function setReady() : void
      {
         this.equipped = true;
         this.status = STATE_READY;
      }
      
      public function getName() : String
      {
         return this.name;
      }
      
      public function getStatus() : int
      {
         return this.status;
      }
   }
}

