package net.bigpoint.darkorbit.net.models.techs
{
   public class TechNames
   {
      
      private static var names:Array;
      
      private static var codes:Array;
      
      public static const TYPE_DEFAULT:int = 0;
      
      public static const TYPE_ENERGY_LEECH_ARRAY:int = 1;
      
      public static const TYPE_ENERGY_CHAIN_IMPULSE:int = 2;
      
      public static const TYPE_ROCKET_PROBABILITY_MAXIMIZER:int = 3;
      
      public static const TYPE_SHIELD_BACKUP:int = 4;
      
      public static const TYPE_BATTLE_REPAIR_BOT:int = 5;
      
      public static const TYPE_SPEED_LEECH:int = 6;
      
      public static const TYPE_CLINGING_IMPULSE_DRONE:int = 7;
      
      public function TechNames()
      {
         super();
      }
      
      public static function getNameByType(param1:int) : String
      {
         if(names == null)
         {
            initNames();
         }
         return names[param1];
      }
      
      public static function getCodeByType(param1:int) : String
      {
         if(codes == null)
         {
            initCodes();
         }
         return codes[param1];
      }
      
      public static function getTypeByCode(param1:String) : int
      {
         if(codes == null)
         {
            initCodes();
         }
         return codes.indexOf(param1);
      }
      
      private static function initNames() : void
      {
         names = [];
         names[TYPE_DEFAULT] = "DEFAULT";
         names[TYPE_ENERGY_LEECH_ARRAY] = "ENERGY_LEECH_ARRAY";
         names[TYPE_ENERGY_CHAIN_IMPULSE] = "ENERGY_CHAIN_IMPULSE";
         names[TYPE_ROCKET_PROBABILITY_MAXIMIZER] = "ROCKET_PROBABILITY_MAXIMIZER";
         names[TYPE_SHIELD_BACKUP] = "SHIELD_BACKUP";
         names[TYPE_SPEED_LEECH] = "SPEED_LEECH";
         names[TYPE_BATTLE_REPAIR_BOT] = "BATTLE_REPAIR_BOT";
         names[TYPE_CLINGING_IMPULSE_DRONE] = "CLINGING_IMPULSE_DRONE";
      }
      
      private static function initCodes() : void
      {
         codes = [];
         codes[TYPE_DEFAULT] = "DEFAULT";
         codes[TYPE_ENERGY_LEECH_ARRAY] = "ELA";
         codes[TYPE_ENERGY_CHAIN_IMPULSE] = "ECI";
         codes[TYPE_ROCKET_PROBABILITY_MAXIMIZER] = "RPM";
         codes[TYPE_SHIELD_BACKUP] = "SBU";
         codes[TYPE_SPEED_LEECH] = "SL";
         codes[TYPE_BATTLE_REPAIR_BOT] = "BRB";
         codes[TYPE_CLINGING_IMPULSE_DRONE] = "CID";
      }
   }
}

