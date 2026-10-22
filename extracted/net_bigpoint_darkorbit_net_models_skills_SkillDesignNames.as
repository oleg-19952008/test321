package net.bigpoint.darkorbit.net.models.skills
{
   import net.bigpoint.darkorbit.net.ServerCommands;
   import net.bigpoint.darkorbit.ship.effects.EffectIDList;
   
   public class SkillDesignNames
   {
      
      private static var names:Array;
      
      private static var codes:Array;
      
      private static var effectIDMap:Array;
      
      public static const SHIP_SKILL_SOLACE:int = 1;
      
      public static const SHIP_SKILL_DIMINISHER:int = 2;
      
      public static const SHIP_SKILL_SPECTRUM:int = 3;
      
      public static const SHIP_SKILL_SENTINEL:int = 4;
      
      public static const SHIP_SKILL_VENOM:int = 5;
      
      public static const SHIP_SKILL_LIGHTNING:int = 6;
      
      public static const SHIP_SKILL_SOLACE_NAME:String = "SHIP_SKILL_SOLACE";
      
      public static const SHIP_SKILL_DIMINISHER_NAME:String = "SHIP_SKILL_DIMINISHER";
      
      public static const SHIP_SKILL_SPECTRUM_NAME:String = "SHIP_SKILL_SPECTRUM";
      
      public static const SHIP_SKILL_SENTINEL_NAME:String = "SHIP_SKILL_SENTINEL";
      
      public static const SHIP_SKILL_VENOM_NAME:String = "SHIP_SKILL_VENOM";
      
      public static const SHIP_SKILL_LIGHTNING_NAME:String = "SHIP_SKILL_LIGHTNING";
      
      public function SkillDesignNames()
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
      
      public static function getEffectIDByCode(param1:int) : int
      {
         if(effectIDMap == null)
         {
            initEffectIDMap();
         }
         return effectIDMap[param1];
      }
      
      private static function initNames() : void
      {
         names = [];
         names[SHIP_SKILL_SOLACE] = SHIP_SKILL_SOLACE_NAME;
         names[SHIP_SKILL_DIMINISHER] = SHIP_SKILL_DIMINISHER_NAME;
         names[SHIP_SKILL_SENTINEL] = SHIP_SKILL_SENTINEL_NAME;
         names[SHIP_SKILL_SPECTRUM] = SHIP_SKILL_SPECTRUM_NAME;
         names[SHIP_SKILL_VENOM] = SHIP_SKILL_VENOM_NAME;
         names[SHIP_SKILL_LIGHTNING] = SHIP_SKILL_LIGHTNING_NAME;
      }
      
      private static function initCodes() : void
      {
         codes = [];
         codes[SHIP_SKILL_SOLACE] = ServerCommands.SKILL_SOLACE;
         codes[SHIP_SKILL_DIMINISHER] = ServerCommands.SKILL_DIMINISHER;
         codes[SHIP_SKILL_SENTINEL] = ServerCommands.SKILL_SENTINEL;
         codes[SHIP_SKILL_SPECTRUM] = ServerCommands.SKILL_SPECTRUM;
         codes[SHIP_SKILL_VENOM] = ServerCommands.SKILL_VENOM;
         codes[SHIP_SKILL_LIGHTNING] = ServerCommands.SPEED_BUFF_COOL_DOWN;
      }
      
      private static function initEffectIDMap() : void
      {
         effectIDMap = [];
         effectIDMap[SHIP_SKILL_SOLACE] = EffectIDList.SOLACE_EFFECT;
         effectIDMap[SHIP_SKILL_DIMINISHER] = EffectIDList.DIMINISHER_EFFECT;
         effectIDMap[SHIP_SKILL_SENTINEL] = EffectIDList.SENTINEL_EFFECT;
         effectIDMap[SHIP_SKILL_SPECTRUM] = EffectIDList.SPECTRUM_EFFECT;
         effectIDMap[SHIP_SKILL_VENOM] = EffectIDList.VENOM_EFFECT;
         effectIDMap[SHIP_SKILL_LIGHTNING] = EffectIDList.SPEED_BUFF_EFFECT;
      }
   }
}

