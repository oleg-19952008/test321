package net.bigpoint.darkorbit.net.models.skills
{
   public class SkillDesignShipNames
   {
      
      private static var shipNameByShipID:Array;
      
      public static const SHIP_SOLACE_NAME:String = "SOLACE";
      
      public static const SHIP_DIMINISHER_NAME:String = "DIMINISHER";
      
      public static const SHIP_SENTINEL_NAME:String = "SENTINEL";
      
      public static const SHIP_SPECTRUM_NAME:String = "SPECTRUM";
      
      public static const SHIP_VENOM_NAME:String = "VENOM";
      
      public static const SHIP_LIGHTNING_NAME:String = "LIGHTNING";
      
      public static const SHIP_SOLACE_ID:int = 63;
      
      public static const SHIP_DIMINISHER_ID:int = 64;
      
      public static const SHIP_SENTINEL_ID:int = 65;
      
      public static const SHIP_SPECTRUM_ID:int = 66;
      
      public static const SHIP_VENOM_ID:int = 67;
      
      public static const SHIP_LIGHTNING_ID:int = 73;
      
      public function SkillDesignShipNames()
      {
         super();
      }
      
      public static function getShipNameBySkillName(param1:String) : String
      {
         if(shipNameByShipID == null)
         {
            initShipNames();
         }
         return shipNameByShipID[param1];
      }
      
      private static function initShipNames() : void
      {
         shipNameByShipID = [];
         shipNameByShipID[SkillDesignNames.SHIP_SKILL_SOLACE_NAME] = SHIP_SOLACE_NAME;
         shipNameByShipID[SkillDesignNames.SHIP_SKILL_DIMINISHER_NAME] = SHIP_DIMINISHER_NAME;
         shipNameByShipID[SkillDesignNames.SHIP_SKILL_SPECTRUM_NAME] = SHIP_SPECTRUM_NAME;
         shipNameByShipID[SkillDesignNames.SHIP_SKILL_SENTINEL_NAME] = SHIP_SENTINEL_NAME;
         shipNameByShipID[SkillDesignNames.SHIP_SKILL_VENOM_NAME] = SHIP_VENOM_NAME;
         shipNameByShipID[SkillDesignNames.SHIP_SKILL_LIGHTNING_NAME] = SHIP_LIGHTNING_NAME;
      }
   }
}

