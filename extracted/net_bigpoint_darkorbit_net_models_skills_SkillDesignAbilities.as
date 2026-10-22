package net.bigpoint.darkorbit.net.models.skills
{
   public class SkillDesignAbilities
   {
      
      private static var abilitiesNameBySkillID:Array;
      
      public static const SHIP_INSTANT_HEAL_NAME:String = "solace-effect";
      
      public static const SHIP_WEAKEN_SHIELDS_NAME:String = "diminisher-effect";
      
      public static const SHIP_PRISMATIC_SHIELDING_NAME:String = "spectrum-effect";
      
      public static const SHIP_FORTRESS_NAME:String = "sentinel-effect";
      
      public static const SHIP_SINGULARITY_NAME:String = "venom-effect";
      
      public static const SHIP_AFTERBURNER_NAME:String = "speed-buff-effect";
      
      public function SkillDesignAbilities()
      {
         super();
      }
      
      public static function getSkillAbilityBySkillID(param1:int) : String
      {
         if(abilitiesNameBySkillID == null)
         {
            initAbilities();
         }
         return abilitiesNameBySkillID[param1];
      }
      
      private static function initAbilities() : void
      {
         abilitiesNameBySkillID = [];
         abilitiesNameBySkillID[SkillDesignNames.SHIP_SKILL_SOLACE] = SHIP_INSTANT_HEAL_NAME;
         abilitiesNameBySkillID[SkillDesignNames.SHIP_SKILL_DIMINISHER] = SHIP_WEAKEN_SHIELDS_NAME;
         abilitiesNameBySkillID[SkillDesignNames.SHIP_SKILL_SPECTRUM] = SHIP_PRISMATIC_SHIELDING_NAME;
         abilitiesNameBySkillID[SkillDesignNames.SHIP_SKILL_SENTINEL] = SHIP_FORTRESS_NAME;
         abilitiesNameBySkillID[SkillDesignNames.SHIP_SKILL_VENOM] = SHIP_SINGULARITY_NAME;
         abilitiesNameBySkillID[SkillDesignNames.SHIP_SKILL_LIGHTNING] = SHIP_AFTERBURNER_NAME;
      }
   }
}

