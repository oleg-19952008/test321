package net.bigpoint.darkorbit.net.models.techs
{
   import net.bigpoint.darkorbit.menu.IAbilityItem;
   
   public class TechItem implements IAbilityItem
   {
      
      private static var stateNames:Array;
      
      public static const TYPE_DEFAULT:int = 0;
      
      public static const TYPE_ENERGY_LEECH_ARRAY:int = 1;
      
      public static const TYPE_ENERGY_CHAIN_IMPULSE:int = 2;
      
      public static const TYPE_ROCKET_PROBABILITY_MAXIMIZER:int = 3;
      
      public static const TYPE_SHIELD_BACKUP:int = 4;
      
      public static const TYPE_BATTLE_REPAIR_BOT:int = 5;
      
      public static const TYPE_SPEED_LEECH:int = 6;
      
      public static const TYPE_CLINGING_IMPULSE_DRONE:int = 7;
      
      public static const NUMBER_OF_TYPES:int = 7;
      
      public static const STATE_DEFAULT:int = 0;
      
      public static const STATE_READY:int = 1;
      
      public static const STATE_ACTIVE:int = 2;
      
      public static const STATE_INACTIVE:int = 3;
      
      public var type:int;
      
      public var slot:int;
      
      public var status:int;
      
      public var amount:int;
      
      public var charges:int;
      
      public var secondsLeft:int;
      
      public var cooldownSeconds:int = 15;
      
      public var hasRunningCooldown:Boolean;
      
      private var name:String;
      
      public function TechItem()
      {
         super();
      }
      
      public static function getNameByStatus(param1:int) : String
      {
         if(stateNames == null)
         {
            initStateNames();
         }
         return stateNames[param1];
      }
      
      private static function initStateNames() : void
      {
         stateNames = [];
         stateNames[STATE_DEFAULT] = "DEFAULT";
         stateNames[STATE_READY] = "READY";
         stateNames[STATE_ACTIVE] = "ACTIVE";
         stateNames[STATE_INACTIVE] = "INACTIVE";
      }
      
      public function toString() : String
      {
         return "TechItem: slot " + this.slot + " type: " + this.name + ", status " + getNameByStatus(this.status) + ", amount: " + this.amount + ", secsLeft: " + this.secondsLeft;
      }
      
      public function updateValues(param1:TechItem) : Boolean
      {
         var _loc2_:Boolean = false;
         if(this.amount != param1.amount)
         {
            this.amount = param1.amount;
            _loc2_ = true;
         }
         if(this.charges != param1.charges)
         {
            this.charges = param1.charges;
            _loc2_ = true;
         }
         if(this.status != param1.status)
         {
            this.status = param1.status;
            _loc2_ = true;
         }
         if(this.secondsLeft != param1.secondsLeft)
         {
            this.secondsLeft = param1.secondsLeft;
            _loc2_ = true;
         }
         if(this.type != param1.type)
         {
            this.type = param1.type;
            _loc2_ = true;
         }
         return _loc2_;
      }
      
      public function updateName() : void
      {
         this.name = TechNames.getNameByType(this.type);
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

